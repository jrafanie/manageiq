module MiqServer::EagerLoad
  extend ActiveSupport::Concern

  def eager_load
    eager_load_app
    eager_require_gems
  end

  def eager_load_app
    before = $LOADED_FEATURES.length
    config = Rails.application.config
    config.paths.add "app/models",        :eager_load => true, :glob => "**/*.rb"
    config.paths.add "app/mailers",       :eager_load => true, :glob => "**/*.rb"
    config.paths.add "app/controllers",   :eager_load => true, :glob => "**/*.rb"
    config.paths.add "app/presenters",    :eager_load => true, :glob => "**/*.rb"
    config.paths.add "app/services",      :eager_load => true, :glob => "**/*.rb"
    config.paths.add "gems/pending/util", :eager_load => true, :glob => "**/*.rb"
    config.paths.add "lib",               :eager_load => true, :glob => "**/*.rb"
    config.eager_load_paths = Rails.application.paths.eager_load
    Rails.application.eager_load!
    _log.info("Eager loaded: #{$LOADED_FEATURES.length - before} files")
  end

  # Require default gems with require => false
  def eager_require_gems
    gems = Bundler.environment.dependencies.select do |dependency|
      next unless dependency.groups.include?(:default)
      next unless dependency.autorequire == [] # require => false is an empty array of autor
      require_one_gem(dependency)
    end
    _log.info("Eager loaded: #{gems.length} gems")
  end

  def require_one_gem(dependency)
    # Inspired by bundler:
    # https://github.com/bundler/bundler/blob/58b6757f601b3660ca6258b5afca0798ff1f7aea/lib/b
    begin
      Kernel.require(dependency.name)
    rescue LoadError => e
      if dependency.name.include?("-")
        begin
          namespaced_file = dependency.name.gsub("-", "/")
          Kernel.require namespaced_file
        rescue LoadError => e
          _log.warn("Failed to require #{dependency.name}, #{e.message.truncate(50)}")
          false
        end
      end
    end
  end
end
