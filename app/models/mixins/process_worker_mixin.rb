module ProcessWorkerMixin
  extend ActiveSupport::Concern

  PROCESS_INFO_FIELDS = %i(priority memory_usage percent_memory percent_cpu memory_size cpu_time proportional_set_size)
  PROCESS_TITLE_PREFIX = "MIQ:".freeze

  module ClassMethods
    def before_fork
      preload_for_worker_role if respond_to?(:preload_for_worker_role)
    end

    def after_fork
      close_pg_sockets_inherited_from_parent
      DRb.stop_service
      renice(Process.pid)
    end

    # When we fork, the children inherits the parent's file descriptors
    # so we need to close any inherited raw pg sockets in the child.
    def close_pg_sockets_inherited_from_parent
      owner_to_pool = ActiveRecord::Base.connection_handler.instance_variable_get(:@owner_to_pool)
      owner_to_pool[Process.ppid].values.compact.each do |pool|
        pool.connections.each do |conn|
          socket = conn.raw_connection.socket
          _log.info "Closing socket: #{socket}"
          IO.for_fd(socket).close
        end
      end
    end

    def renice(pid)
      AwesomeSpawn.run("renice", :params =>  {:n => nice_increment, :p => pid })
    end

    def nice_increment
      delta = worker_settings[:nice_delta]
      delta.kind_of?(Integer) ? delta.to_s : "+10"
    end
  end

  def start_runner
    self.class.before_fork
    pid = fork(:cow_friendly => true) do
      self.class.after_fork
      self.class::Runner.start_worker(worker_options)
      exit!
    end

    Process.detach(pid)
    pid
  end

  def start
    self.pid = start_runner
    save

    msg = "Worker started: ID [#{id}], PID [#{pid}], GUID [#{guid}]"
    MiqEvent.raise_evm_event_queue(miq_server, "evm_worker_start", :event_details => msg, :type => self.class.name)

    _log.info(msg)
    self
  end

  def stop
    miq_server.stop_worker_queue(self)
  end

  # Let the worker monitor start a new worker
  alias_method :restart, :stop

  def kill
    unless pid.nil?
      begin
        _log.info("Killing worker: ID [#{id}], PID [#{pid}], GUID [#{guid}], status [#{status}]")
        Process.kill(9, pid) if is_alive?
      rescue => err
        _log.warn("Worker ID [#{id}] PID [#{pid}] GUID [#{guid}] has been killed, but with the following error: #{err}")
      end
    end

    destroy
  end

  def status_update
    begin
      pinfo = MiqProcess.processInfo(pid)
    rescue Errno::ESRCH
      update(:status => MiqWorker::STATUS_ABORTED)
      _log.warn("No such process [#{friendly_name}] with PID=[#{pid}], aborting worker.")
    rescue => err
      _log.warn("Unexpected error: #{err.message}, while requesting process info for [#{friendly_name}] with PID=[#{pid}]")
    else
      # Ensure the hash only contains the values we want to store in the table
      pinfo.slice!(*PROCESS_INFO_FIELDS)
      pinfo[:os_priority] = pinfo.delete(:priority)
      update_attributes!(pinfo)
    end
  end

  def actually_running?
    MiqProcess.is_worker?(pid)
  end
end
