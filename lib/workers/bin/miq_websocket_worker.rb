ENV['BUNDLER_GROUPS'] = "ui_dependencies,web_server,web_socket"

# This is modeled after config/environment.rb
require File.expand_path('../../../config/application', __dir__)

Vmdb::Application.initialize!
# MiqWebsocketWorker::Runner.new(...).start
