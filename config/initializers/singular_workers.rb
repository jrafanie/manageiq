unless Rails.env.production?
  Dir.glob("app/models/*_worker.rb").each do |worker_file|
    worker = File.basename(worker_file, ".rb")
    klass = worker.classify.constantize
    klass.singleton_class.send(:define_method, 'workers') { 1 } unless MiqServer.minimal_env?
  end
end

