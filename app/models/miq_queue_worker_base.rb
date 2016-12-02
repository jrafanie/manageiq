class MiqQueueWorkerBase < MiqWorker
  require_nested :Runner

  def self.queue_priority
    MiqQueue::MIN_PRIORITY
  end

  def self.minimum_workers
    1
  end
end
