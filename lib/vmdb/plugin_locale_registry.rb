module Vmdb
  class PluginLocaleRegistry
    class << self
      def register(plugin_name, locale_path, js_locale_path = nil)
        registrations[plugin_name] = {
          locale_path: locale_path,
          js_locale_path: js_locale_path,
          registered_at: Time.now
        }

        # Auto-register with FastGettext
        if locale_path && File.directory?(locale_path)
          Vmdb::Gettext::Domains.add_plugin_domain(plugin_name, locale_path, :po)
          Vmdb::Gettext::Domains.add_plugin_domain(plugin_name, locale_path, :mo)
          Vmdb::Gettext::Domains.reload_chain

          Rails.logger.info("PluginLocaleRegistry: Registered #{plugin_name} with locale path #{locale_path}")
        end

        registrations[plugin_name]
      end

      def registrations
        @registrations ||= {}
      end

      def registered?(plugin_name)
        registrations.key?(plugin_name)
      end

      def locale_path_for(plugin_name)
        registrations.dig(plugin_name, :locale_path)
      end

      def js_locale_path_for(plugin_name)
        registrations.dig(plugin_name, :js_locale_path)
      end

      def js_locale_paths
        registrations.values.map { |r| r[:js_locale_path] }.compact
      end

      def all_locale_paths
        registrations.values.map { |r| r[:locale_path] }.compact
      end

      def reset!
        @registrations = {}
      end
    end
  end
end
