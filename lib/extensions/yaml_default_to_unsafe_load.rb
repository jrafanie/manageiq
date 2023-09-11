# Temporary hack to default yaml to use unsafe_load by default as unknown aliases aren't loaded by default.
# See: https://stackoverflow.com/questions/71191685/visit-psych-nodes-alias-unknown-alias-default-psychbadalias/71192990#71192990

require 'yaml'
module YAML
  class << self
    alias_method :load, :unsafe_load if YAML.respond_to? :unsafe_load
  end
end