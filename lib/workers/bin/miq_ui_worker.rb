ENV['BUNDLER_GROUPS'] = "web_server,ui_dependencies"

# This is modeled after config/environment.rb
require File.expand_path('../../../config/application', __dir__)

Vmdb::Application.initialize!
# MiqUiWorker::Runner.new(...).start
