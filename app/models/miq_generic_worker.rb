class MiqGenericWorker < MiqQueueWorkerBase
  require_nested :Runner

  self.default_queue_name     = "generic"
  self.check_for_minimal_role = false
  self.workers                = -> { MiqServer.minimal_env? ? 1 : worker_settings[:count] }

  def self.after_fork
    GC.disable
    $smaps_log = Logger.new("/root/smaps.log")
    $smaps_log.info("XXX #{self}.after_fork")
    start_memory_log_thread
    $smaps_log.info("XXX #{self}.after_fork")
    sleep 30
    $smaps_log.info("XXX #{self}.after_fork before super")
    super
    $smaps_log.info("XXX #{self}.after_fork after super")
    GC.enable
  end

  def self.start_memory_log_thread
    Thread.new do
      require 'sys-uname'
      require 'logger'
      return unless Sys::Platform::IMPL == :linux

      file = "/proc/#{Process.pid}/smaps"

      loop do
        results = GC.stat
        results[:shared_memory] = 0
        results[:private_memory] = 0
        lines = File.read(file)
        lines.scan(/.+?Shared_Dirty:\s+(\d+).+?Private_Dirty:\s+(\d+)/m) do |shared_dirty, private_dirty|
          results[:shared_memory] += shared_dirty.to_i
          results[:private_memory] += private_dirty.to_i
        end
        $smaps_log.info(results.inspect)

        sleep 2
      end
    end
  end
end
