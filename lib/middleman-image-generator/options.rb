module Middleman
  module ImageGenerator
    # An options store that handles default options will accept user defined overrides
    class Options

      OPTIONS = {
        # Write new source images to a manifest
        manifest: true,
        # Create double sized images for retina displays
        retina_versions: true,
        # Accepted image source types
        filetypes: [:jpg, :jpeg, :png, :tiff],
        # An array of directories containing source images
        sources: ["**"],
        # Define version parameters and settings to control quality of output
        display_types: {
          sml: {quality: 'Q=80', dims: '500'},
          med: {quality: 'Q=80', dims: '750'},
          lrg: {quality: 'Q=100', dims: '1000'}
        },
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