module ThreadWorkerMixin
  extend ActiveSupport::Concern

  def start_runner
    self.class::Runner.start_worker(worker_options)
  end

  # kill -9 doesn't make sense for threads, let stop handle shutting it down
  def kill
    stop
  end

  def status_update
    # Thread workers will have to monitor memory/cpu on their own
  end
end
