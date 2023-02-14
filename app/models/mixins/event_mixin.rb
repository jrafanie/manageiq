# EventMixin expects that event_where_clause is defined in the model.
module EventMixin
  extend ActiveSupport::Concern

  included do
    supports :timeline
  end

  def first_event(assoc = :ems_events)
    event = find_one_event(assoc, "timestamp ASC")
    event.try(:timestamp)
  end

  def last_event(assoc = :ems_events)
    event = find_one_event(assoc, "timestamp DESC")
    event.try(:timestamp)
  end

  def first_and_last_event(assoc = :ems_events)
    [first_event(assoc), last_event(assoc)].compact
  end

  def has_events?(assoc = :ems_events)
    # TODO: homemade caching is probably harfmul as it's not expected.
    # It should be considered for removal.
    @has_events ||= {}
    return @has_events[assoc] if @has_events.key?(assoc)
    @has_events[assoc] = events_assoc_class(assoc).where(event_where_clause(assoc)).exists?
  end

  def events_assoc_class(assoc)
    assoc.to_s.classify.constantize
  end

  def events_table_name(assoc)
    events_assoc_class(assoc).table_name
  end

  #TODO: Remove me, this is a hack so the UI always calls what I want to call
  # The UI should call ems_event_filter or miq_event_filter for management events and policy events
  def event_stream_filter
    miq_event_filter
  end

  def ems_event_filter
    { self.class.ems_event_filter_column => id }
  end

  def miq_event_filter
    { self.class.miq_event_filter_column => id }
  end

  def policy_event_filter
    miq_event_filter
    # TODO: policy_events are busted.  What we call policy in the ui is miq events and policy_events are not used?
    # for now, we just do the miq_event_filter
    # { self.class.policy_event_filter_column => id }
  end

  private

  def find_one_event(assoc, order)
    ewc = event_where_clause(assoc)
    events_assoc_class(assoc).where(ewc).order(order).first unless ewc.blank?
  end

  module ClassMethods

    def ems_event_filter_column
      @_ems_event_filter_column ||= reflect_on_association(:ems_events).try(:foreign_key) || name.foreign_key
    end

    def miq_event_filter_column
      @_miq_event_filter_column ||= reflect_on_association(:miq_events).try(:foreign_key) || "target_id".freeze
    end

    def policy_event_filter_column
      @_policy_event_filter_column ||= reflect_on_association(:policy_events).try(:foreign_key) || "target_id".freeze
    end
  end
end
