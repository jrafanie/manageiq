module RubyGCLogger
  def start_gc_statistics_thread(seconds = 60)
    require 'tempfile'
    require 'objspace'
    prefix   = self.class.name
    prefix   = prefix.deconstantize if prefix.include?("::")
    # Make a time based filename
    csv      = File.open(prefix.underscore, "a+")
    Thread.new do
      csv.puts(gc_stat_header.join(","))
      loop do
        csv.puts(gc_stat_line.join(","))
        csv.flush
        sleep seconds
      end
    end
    csv.path
  end

  private

  def gc_stat_line
    [Time.now.iso8601] +
      MiqProcess.processInfo.values_at(*miq_process_keys) +
      GC.stat.values_at(*gc_stat_keys) +
      [ObjectSpace.memsize_of_all] +
      ObjectSpace.count_objects.values_at(*count_objects_keys) +
      ObjectSpace.count_objects_size.values_at(*count_objects_size_keys)
  end

  def gc_stat_header
    [:time] +
      miq_process_keys +
      gc_stat_keys +
      [:memsize_of_all] +
      count_objects_keys +
      count_objects_size_keys.collect { |key| key.to_s.concat("_SIZE").to_sym }
  end

  def gc_stat_keys
    @gc_stat_keys ||= GC.stat.keys
  end

  def miq_process_keys
    @miq_process_keys ||= [:memory_usage, :memory_size]
  end

  def count_objects_keys
    @count_objects_keys ||= ObjectSpace.count_objects.keys
  end

  def count_objects_size_keys
    @count_objects_size_keys ||= ObjectSpace.count_objects_size.keys
  end
end
