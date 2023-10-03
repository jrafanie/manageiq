module YamlLoadAliases
  DEFAULT_PERMITTED_CLASSES = [Regexp, Symbol, Date, Time, ActiveSupport::TimeWithZone, ActiveSupport::TimeZone]
  # Psych 4 aliases load as safe_load.  Some loads happen early, like reading the database.yml so we don't want to load our
  # constants at that time, such as MiqExpression, Ruport, so we have two sets of permitted classes.
  def safe_load(*args, **kwargs)
    super(*args, **kwargs.merge(:aliases => true, :permitted_classes => DEFAULT_PERMITTED_CLASSES))
  rescue NameError, Psych::DisallowedClass
    super(*args, **kwargs.merge(:aliases => true, :permitted_classes => DEFAULT_PERMITTED_CLASSES + [MiqExpression, Ruport::Data::Table]))
  end
end

if Psych::VERSION >= "4.0"
  require 'yaml'
  YAML.singleton_class.prepend(YamlLoadAliases)
end
