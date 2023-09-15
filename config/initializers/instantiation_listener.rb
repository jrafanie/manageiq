unless ENV['MIQ_QUIET']
  ActiveSupport::Notifications.subscribe('instantiation.active_record') do |name, start, finish, _id, payload|
    logger = ActiveRecord::Base.logger
    if logger.debug?
      elapsed = finish - start
      name = payload[:class_name]
      count = payload[:record_count]

      logger.debug('  %s Inst Including Associations (%.1fms - %drows)' % [name || 'SQL', (elapsed * 1000), count])
    end
  end
end



# require 'miq_expression'
# require 'regexp'
# require 'ruport'

# MiqExpression, Ruport::Data::Table

    # config.active_record.yaml_column_permitted_classes = [Regexp, Symbol, Time]
    # config.active_record.yaml_column_permitted_classes = [Symbol, Date, Time, ActiveSupport::TimeWithZone, ActiveSupport::TimeZone]



Vmdb::Application.config.active_record.yaml_column_permitted_classes = [MiqExpression, Symbol, Date, Time, ActiveSupport::TimeWithZone, ActiveSupport::TimeZone]

