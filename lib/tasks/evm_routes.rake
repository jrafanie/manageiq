namespace :evm do
  namespace :routes do
    task :load_full_routes do
      MiqUiWorker.load_full_routes
    end
  end
end

load 'rails/tasks/routes.rake'
Rake::Task['routes'].enhance([:environment, "evm:routes:load_full_routes"])
