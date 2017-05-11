ENV['BUNDLER_GROUPS'] = ""

# This is modeled after config/environment.rb
require File.expand_path('../../../config/application', __dir__)

# Require the bundler groups this worker needs
# Bundler.require(...)

Vmdb::Application.initialize!
# MiqGenericWorker::Runner.new(...).start
