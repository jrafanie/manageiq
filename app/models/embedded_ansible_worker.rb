class EmbeddedAnsibleWorker < MiqWorker
  require_nested :Runner
  include ThreadWorkerMixin

  self.required_roles = ['embedded_ansible']

  # Base class methods we override since we don't have a separate process.  We might want to make these opt-in features in the base class that this subclass can choose to opt-out.
  def release_db_connection; end
end
