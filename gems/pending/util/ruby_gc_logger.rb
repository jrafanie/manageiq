module RubyGCLogger
  def start_gc_statistics_thread(seconds = 60)
    require 'tempfile'
    require 'objspace'
    require 'miq-process'

    prefix   = self.class.name
    prefix   = prefix.deconstantize.underscore.gsub("/", "-") if prefix.include?("::")
    # Make a time based filename
    csv      = File.open(Rails.root.join("log", "#{prefix.underscore}_#{Process.pid}.csv"), "w+")
    csv.sync = true
    # Thread.abort_on_exception = true
    Thread.new do
      csv.puts(gc_stat_header.join(",".freeze))
      loop do
        csv.puts(gc_stat_line.join(",".freeze))
        sleep seconds
      end
    end

    at_exit { csv.close }
    csv.path
  end

  private

  def gc_stat_line
    gc_stat       = GC.stat
    live_objects  = gc_stat[:total_allocated_objects] - gc_stat[:total_freed_objects]
    young_objects = live_objects - gc_stat[:old_objects]

    [Time.now.iso8601, live_objects, young_objects, ObjectSpace.memsize_of_all] +
      MiqProcess.processInfo.values_at(*miq_process_keys) +
      gc_stat.values_at(*gc_stat_keys) +
      ObjectSpace.count_objects.values_at(*count_objects_keys) +
      ObjectSpace.count_objects_size.values_at(*count_objects_size_keys)
  end

  def gc_stat_header
    [:time, :live_objects, :young_objects, :memsize_of_all] +
      miq_process_keys +
      gc_stat_keys +
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
