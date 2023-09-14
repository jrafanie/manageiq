require "yaml"

module PsychLoadWithAliases
	def load(yaml, **kwargs)
    super
  rescue Psych::BadAlias
    super(yaml, **kwargs.merge(:aliases => true))
  end
end if Psych::VERSION >= "4.0.0"

YAML.singleton_class.prepend(PsychLoadWithAliases)