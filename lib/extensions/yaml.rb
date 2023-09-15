require "yaml"

module PsychLoadWithAliases
	def load(yaml, **kwargs)
    super(yaml, **kwargs.merge(:permitted_classes => Vmdb::Application.config.active_record.yaml_column_permitted_classes))
  rescue Psych::BadAlias
    super(yaml, **kwargs.merge(:aliases => true, :permitted_classes => Vmdb::Application.config.active_record.yaml_column_permitted_classes))
  end
end if Psych::VERSION >= "4.0.0"

YAML.singleton_class.prepend(PsychLoadWithAliases)