module Middleman
  module ImageGenerator
    module ResourceCollector

      module_function

      def new_resource(store, output_path, source_path)
        # Build a resource for each new version and store it in Array[] 'new_resources',
        # for the transfer back to the sitemap
        resource = Sitemap::Resource.new(store, output_path, source_path)
        resource.add_metadata(locals: {priority: '1', changefreq: 'never'})

        @new_resources = []
        @new_resources << resource
        @new_resources
      end

      def new_resources
        @new_resources
      end

    end
  end
end