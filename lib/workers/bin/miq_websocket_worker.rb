ENV['BUNDLER_GROUPS'] = "ui_dependencies,web_server,web_socket"

require File.expand_path('../../../config/application', __dir__)

Vmdb::Application.initialize!
MiqWebsocketWorker::Runner.start_worker(*ARGV)
