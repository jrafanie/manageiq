class ManageIQ::Providers::AnsibleTower::EmbeddedAnsibleWorker::Runner < MiqWorker::Runner
  def prepare
    set_tower

    Thread.new do
      setup_ansible
      started_worker_record
    end

    self
  end

  # This thread runs forever until a stop request is received, which with send us to do_exit to exit our thread
  def do_work_loop
    Thread.new do
      loop do
        break if worker.reload.started?
        _log.info("waiting for ansible setup")
        heartbeat
        send(poll_method)
      end

      _log.info("entering ansible monitor loop")
      loop do
        heartbeat
        do_work
        send(poll_method)
      end
    end
  end

  def setup_ansible
    _log.info("calling EmbeddedAnsible.configure")
    EmbeddedAnsible.configure unless EmbeddedAnsible.configured?

    _log.info("calling EmbeddedAnsible.start")
    EmbeddedAnsible.start
  end

  def do_work
    if EmbeddedAnsible.running?
      _log.info("#{log_prefix} supervisord is ok!")
    else
      _log.warn("#{log_prefix} supervisord is BAD!")
      EmbeddedAnsible.start
    end
  end

  # Because we're running in a thread on the Server
  # we need to intercept SystemExit and exit our thread,
  # not the main server thread!
  def do_exit(*args)
    EmbeddedAnsible.disable
    super
  rescue SystemExit
    _log.info("#{log_prefix} SystemExit received, exiting monitoring Thread")
    Thread.exit
  end

  def set_tower
    tower = ManageIQ::Providers::AnsibleTower::Provider.seed
    zone  = MiqServer.my_server.zone
    tower.update(:zone => zone) unless tower.zone == zone
  end

  # Base class methods we override since we don't have a separate process.  We might want to make these opt-in features in the base class that this subclass can choose to opt-out.
  def set_process_title; end
  def set_connection_pool_size; end
  def message_sync_active_roles(*_args); end
  def message_sync_config(*_args); end
end
