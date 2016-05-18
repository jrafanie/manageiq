require_relative "./evm_test_helper"

if defined?(RSpec) && defined?(RSpec::Core::RakeTask)
namespace :test do
  namespace :automation do
    desc "Setup environment for automation specs"
    task :setup => :setup_db

    task :teardown
  end

  def automation_directories_for_parallel
    Dir.glob("./spec/automation")
  end

  task :automation_parallel => [:initialize, "evm:compile_sti_loader"] do
    require 'parallel_tests'

    ParallelTests::CLI.new.run(["--type", "rspec"] + automation_directories_for_parallel)
  end

  desc "Run all automation specs"
  RSpec::Core::RakeTask.new(:automation => [:initialize, "evm:compile_sti_loader"]) do |t|
    EvmTestHelper.init_rspec_task(t)
    t.pattern = EvmTestHelper::AUTOMATION_SPECS
  end
end
end # ifdef
