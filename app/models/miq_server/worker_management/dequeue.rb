module MiqServer::WorkerManagement::Dequeue
  extend ActiveSupport::Concern

  def peek(queue_name, priority, limit, role = @active_role_names)
    MiqQueue.peek(
      :conditions => {:queue_name => queue_name, :priority => priority, :role => role},
      :select     => "id, lock_version, priority, role",
      :limit      => limit
    )
  end

  def get_worker_dequeue_method(worker_class)
    (@child_worker_settings[worker_class.settings_name][:dequeue_method] || :drb).to_sym
  end

  def reset_queue_messages
    @queue_messages_lock.synchronize(:EX) do
      @queue_messages = {}
    end
  end

  def get_queue_priority_for_worker(w)
    w[:class].respond_to?(:queue_priority) ? w[:class].queue_priority : MiqQueue::MIN_PRIORITY
  end

  def get_queue_message_for_worker(w)
    return nil if w.nil? || w[:queue_name].nil?

    @queue_messages_lock.synchronize(:EX) do
      queue_name = w[:queue_name]
      queue_hash = @queue_messages[queue_name]
      return nil unless queue_hash.kind_of?(Hash)

      messages = queue_hash[:messages]
      return nil unless messages.kind_of?(Array)

      messages.each_index do |index|
        msg = messages[index]
        next if msg.nil?
        next if MiqQueue.lower_priority?(msg[:priority], get_queue_priority_for_worker(w))
        next unless w[:class].required_roles.blank? || msg[:role].blank? || w[:class].required_roles.to_miq_a.include?(msg[:role])
        return messages.delete_at(index)
      end

      return nil
    end
  end

  def get_queue_message(pid)
    update_worker_last_heartbeat(pid)
    @workers_lock.synchronize(:SH) do
      w = @workers[pid]
      msg = get_queue_message_for_worker(w)
      msg ? [msg[:id], msg[:lock_version]] : nil
    end unless @workers_lock.nil?
  end

  def prefetch_max_per_worker
    ::Settings.server.prefetch_max_per_worker || 100
  end

  def prefetch_min_per_worker
    ::Settings.server.prefetch_min_per_worker || 10
  end

  def prefetch_stale_threshold
    (::Settings.server.prefetch_stale_threshold || 30.seconds).to_i_with_method
  end

  def prefetch_below_threshold?(queue_name, wcount)
    @queue_messages_lock.synchronize(:SH) do
      return false if @queue_messages[queue_name].nil?
      return (@queue_messages[queue_name][:messages].length <= (prefetch_min_per_worker * wcount))
    end
  end

  def prefetch_stale?(queue_name)
    @queue_messages_lock.synchronize(:SH) do
      return true if @queue_messages[queue_name].nil?
      return ((Time.now.utc - @queue_messages[queue_name][:timestamp]) > prefetch_stale_threshold)
    end
  end

  def prefetch_has_lower_priority_than_miq_queue?(queue_name)
    @queue_messages_lock.synchronize(:SH) do
      return true if @queue_messages[queue_name].nil? || @queue_messages[queue_name][:messages].nil?
      msg = @queue_messages[queue_name][:messages].first
      return true if msg.nil?
      return peek(queue_name, MiqQueue.priority(msg[:priority], :higher, 1), 1).any?
    end
  end

  def get_worker_count_and_priority_by_queue_name
    queue_names = {}
    @workers_lock.synchronize(:SH) do
      @workers.each do |_pid, w|
        next if w[:queue_name].nil?
        next if w[:class].nil?
        next unless get_worker_dequeue_method(w[:class]) == :drb
        options = (queue_names[w[:queue_name]] ||= [0, MiqQueue::MAX_PRIORITY])
        options[0] += 1
        options[1]  = MiqQueue.lower_priority(get_queue_priority_for_worker(w), options[1])
      end
    end unless @workers_lock.nil?
    queue_names
  end

  def queue_names_with_no_queue_work
    no_work_queue_names = []
    @queue_messages_lock.synchronize(:SH) do
      @queue_messages.each do |queue_name, message_hash|
        if message_hash[:messages].empty?
          _log.info("XXX: queue_name: #{queue_name} has NO queue work")
          no_work_queue_names << queue_name
        else
          _log.info("XXX: queue_name: #{queue_name} has queue work")
        end
      end
    end
    no_work_queue_names
  end

  def scale_down_queue_workers
    queue_names_with_no_queue_work.each do |queue_name|
      klasses = worker_classes_for_queue_name[queue_name]
      if klasses.empty?
        _log.info("XXX: queue_name: #{queue_name} There are no classes for this queue...skipping")
        next
      else
        _log.info("XXXYYY: queue_name: #{queue_name} There are classes for this queue")
      end

      klasses.each do |k|
        if (k.workers - 1) >= k.minimum_workers
          original_worker_class_counts[k] ||= k.workers
          _log.info("XXXYYY: queue_name: #{queue_name}, scaling down class: #{k.name} from #{k.workers} to #{k.workers - 1}")
          k.workers -= 1
        else
          _log.info("XXX: queue_name: #{queue_name}, class: #{k.name} #{k.workers} is already at the minumum workers #{k.minimum_workers}...skipping")
        end
      end
    end
  end

  def scale_up_queue_workers
    original_worker_class_counts.each do |k, count|
      role = []
      if k.required_roles.present?
        missing_roles = k.required_roles - @active_role_names
        if missing_roles.empty?
          _log.info("XXXYYY: #{k} all required roles are active: #{k.required_roles.inspect}, active_roles: #{@active_role_names.inspect}")
        else
          # skip worker classes without the required roles active
          _log.info("XXX: #{k} is missing active required roles for #{missing_roles}... skipping")
          next
        end
        role = k.required_roles
      end

      msg = peek(k.default_queue_name, k.queue_priority || MiqQueue::MIN_PRIORITY, 1, role)
      if !msg.empty?
        if k.workers < count
          _log.info("XXXYYY: found work: #{msg.inspect.truncate(25)}, scaling up class: #{k.name} from #{k.workers} to #{k.workers + 1}, original count: #{count}")
          k.workers += 1
        else
          _log.info("XXX: found work: #{msg.inspect.truncate(25)}, but class: #{k.name} is already scaled up to #{k.workers}...skipping")
        end
      end

      # If we've scaled up to the original value, stop tracking this class
      if k.workers == count
        _log.info("XXX: #{k.name} has scaled back to the original worker count: #{k.workers}")
        original_worker_class_counts.delete(k)
      end
    end
  end

  def original_worker_class_counts
    @original_worker_class_counts ||= {}
  end

  def worker_classes_for_queue_name
    @worker_classes_for_queue_name ||=
      begin
        mapping = {}
        MiqQueueWorkerBase.subclasses.each do |c|
          mapping[c.default_queue_name] ||= []
          mapping[c.default_queue_name] << c
        end
        mapping
      end
  end

  def populate_queue_messages
    queue_names = get_worker_count_and_priority_by_queue_name
    @queue_messages_lock.synchronize(:EX) do
      queue_names.each do |queue_name, (wcount, priority)|
        if prefetch_below_threshold?(queue_name, wcount) || prefetch_stale?(queue_name) || prefetch_has_lower_priority_than_miq_queue?(queue_name)
          @queue_messages[queue_name] ||= {}
          @queue_messages[queue_name][:timestamp] = Time.now.utc
          @queue_messages[queue_name][:messages]  = peek(queue_name, priority, (prefetch_max_per_worker * wcount)).collect do |q|
            {:id => q.id, :lock_version => q.lock_version, :priority => q.priority, :role => q.role}
          end
          _log.info("Fetched #{@queue_messages[queue_name][:messages].length} miq_queue rows for queue_name=#{queue_name}, wcount=#{wcount.inspect}, priority=#{priority.inspect}") if @queue_messages[queue_name][:messages].length > 0
        end
      end
    end
  end
end
