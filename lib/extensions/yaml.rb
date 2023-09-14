require "yaml"

module PsychLoadWithAliases
	def load(yaml, **kwargs)
    super(yaml, **kwargs.merge(:permitted_classes => [Symbol, Date, Time, ActiveSupport::TimeWithZone, ActiveSupport::TimeZone]))
  rescue Psych::BadAlias
    super(yaml, **kwargs.merge(:aliases => true, :permitted_classes => [Symbol, Date, Time, ActiveSupport::TimeWithZone, ActiveSupport::TimeZone]))
  end
end if Psych::VERSION >= "4.0.0"

# require 'miq_expression'
# require 'regexp'
# require 'ruport'

# MiqExpression, Ruport::Data::Table


    # config.active_record.yaml_column_permitted_classes = [Regexp, Symbol, Time]
    # config.active_record.yaml_column_permitted_classes = [Symbol, Date, Time, ActiveSupport::TimeWithZone, ActiveSupport::TimeZone]


YAML.singleton_class.prepend(PsychLoadWithAliases)