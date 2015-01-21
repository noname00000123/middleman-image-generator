require 'middleman-image-generator/resource_collector'

module Middleman
  module ImageGenerator
    class ResourceList
      include ResourceCollector

      attr_reader :app, :options

      def self.manipulate(app, resources, options)
        new(app, resources, options).manipulate_resources
      end

      def initialize(app, resources, options)
        @app = app
        @resources = resources
        @options = options
      end

      def manipulate_resources
        modified_resources << new_resources
        modified_resources << manifest_resource
      end

      private

      def modified_resources
        @resources.map do |resource|
          puts resource.destination_path
          if resource_up_to_date?(resource)
            Middleman::Sitemap::Resource.new(
              app.sitemap,
              resource.destination_path,
              File.join(app.build_dir, resource.destination_path)
            )
          else
            resource
          end
        end
      end

      def manifest_resource
        resource_args = [app.sitemap, Manifest::MANIFEST_FILENAME]

        if File.exist?(File.join(app.build_dir, Manifest::MANIFEST_FILENAME))
          resource_args << File.join(app.build_dir, Manifest::MANIFEST_FILENAME)
        end

        Middleman::ImageGenerator::ManifestResource.new(*resource_args)
      end

      def resource_up_to_date?(resource)
        image_resource?(resource) &&
          sitemap_resource?(resource) &&
          resource_exists?(resource) &&
          resource_current?(resource)
      end

      def image_resource?(resource)
        options.filetypes.include?(File.extname(resource.destination_path))
      end

      def sitemap_resource?(resource)
        resource.class.name == 'Middleman::Sitemap::Resource'
      end

      def resource_exists?(resource)
        File.exist?(resource_build_path(resource))
      end

      def resource_current?(resource)
        File.mtime(resource_build_path(resource)) > File.mtime(resource.source_file)
      end

      def resource_build_path(resource)
        File.join(app.build_dir, resource.destination_path)
      end
    end
  end
end