module Middleman
  module ImageGenerator
    # An options store that handles default options will accept user defined overrides
    class Options

      OPTIONS = {
        manifest: true,

        filetypes: [:jpg, :jpeg, :png, :tiff],

        namespaces: ["**"],

        versions: {
          sml: {quality: 'Q=80', dimensions: '500'},
          med: {quality: 'Q=80', dimensions: '750'},
          lrg: {quality: 'Q=100', dimensions: '1000'}
        }
      }

      attr_accessor *OPTIONS.keys.map(&:to_sym)

      def initialize(user_options = {})
        set_options(user_options)
      end

      def options
        Hash[instance_variables.map {|name| [symbolize_key(name), instance_variable_get(name)]}].reject {|key| OPTIONS.include?(key)}
      end

      private

      def symbolize_key(key)
        key.to_s[1..-1].to_sym
      end

      def set_options(user_options)
        OPTIONS.keys.each do |name|
          instance_variable_set(:"@#{name}", user_options.fetch(name, OPTIONS[name]))
        end
      end
    end
  end
end