ENV['BUNDLER_GROUPS'] = "web_server"

# This is modeled after config/environment.rb
require File.expand_path('../../../config/application', __dir__)

Vmdb::Application.initialize!
# MiqWebServiceWorker::Runner.new(...).start
