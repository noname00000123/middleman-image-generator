require 'fileutils'
require 'middleman-image-generator/resource_collector'

module Middleman
  module ImageGenerator
    class Generator
      include ResourceCollector

      attr_reader :app, :builder, :options

      def self.generate!(app, builder, options)
        new(app, builder, options).process_versions
      end

      def initialize(app, builder, options)
        @app = app
        @builder = builder
        @options = options

        @images_dir = File.join(app.source_dir, app.images_dir)
      end

      def process_versions
        collect_all.each do |file|
          input_path     = Pathname.new(file)
          input_filename = File.basename(input_path, File.extname(input_path))

          # Add in/output paths to options.versions parameters Hash{}
          output_versions = versions(
            options.versions,
            input_filename,
            input_path,
            output_path(input_path)
          )

          # Generate resized lossy compressed image files
          # according to version parameters
          generate_resized_versions(output_versions)
        end

        collect_namespace('primary_items').each do |file|
          input_path     = Pathname.new(file)
          input_filename = File.basename(input_path, File.extname(input_path))

          generate_dzi(
            input_path,
            input_filename,
            output_path(
              input_path,
              'assets/images/secondary_items/enlargements'
            )
          )
        end

        update_manifest

        manipulate_resource_list(new_resources)
      end

      # Method taken from middleman-imageoptim by which images
      # in sprockets load path were added to the sitemap.
      # I am trying to push only the newly generated versions
      # to the sitemap. Will this work?
      def manipulate_resource_list(resources)
        return resources unless options.manifest

        Middleman::ImageGenerator::ResourceList.manipulate(app, resources, options)
      end

      private

      def collect_all
        glob_rule = "#{@images_dir}/{#{options.namespaces.join(',')}}/**/*.{#{options.filetypes.join(',')}}"

        # Store the paths in an Array[]
        Dir[glob_rule]

        # Or
        # ::Middleman::Util.all_files_under(app.images_dir)
      end

      def collect_namespace(namespace=str)
        glob_rule = "#{@images_dir}/#{namespace}/**/*.{#{options.filetypes.join(',')}}"

        # Store the paths in an Array[]
        Dir[glob_rule]
      end

      def ensure_enlargements_dir_exists(output_dir)
        # Ensure there is a directory to receive the enlargements
        unless File.directory?(output_dir)
          FileUtils.mkdir_p(output_dir)
        end
      end

      def output_path(input_path, options=nil)
        # Build array containing dir levels
        dir_levels = Pathname(input_path).each_filename.to_a
        # Determine location of 'source' in path to then divert to 'build'
        divert_at = dir_levels.index('source')
        # Capture dir levels after 'source'
        relative_path = File.join(dir_levels[(divert_at + 1) ... -1])

        # Unless alternate output_path set use relative_path
        options ||= relative_path

        # Reconstruct an absolute path to output dir
        Pathname.new(File.expand_path(File.join('build', options)))
      end

      # Add filename in/output paths to parameters hash
      def versions(versions, input_filename, input_path, output_path)
        versions.each do |version, parameters|
          parameters[:input_name] = input_filename
          parameters[:input_path] = input_path
          parameters[:output_path] = File.join(output_path, "#{input_filename}_#{version}")
        end
      end

      # For each of the required image types generate resized versions.
      def generate_resized_versions(output_versions)
        output_versions.each do |version, parameters|
          ['jpg', 'webp'].each do |type|

            input_path = "#{parameters[:input_path]}"
            output_path = "#{parameters[:output_path]}.#{type}"
            #output_filename = File.basename(output_path)

            IO.popen("vipsthumbnail #{input_path} --size #{parameters[:dimensions]} --sharpen mild -o #{output_path}[#{parameters[:quality]},strip]").read

            new_resource(@app.sitemap, output_path, output_path)
          end
        end
      end

      def generate_dzi(input_path, input_filename, output_dir)
        ensure_enlargements_dir_exists(output_dir)

        # Append filename to output_dir
        output_path = File.join(output_dir, input_filename)

        IO.popen("vips dzsave #{input_path} #{output_path} --suffix .jpg[Q=100]")
      end

      def update_manifest
        return unless options.manifest
        manifest.build_and_write(collect_all)
      end

      def updated_images
        collect_all.select { |path| file_updated?(path) }
      end

      def file_updated?(file_path)
        return true unless options.manifest
        File.mtime(file_path) != manifest.resource(file_path)
      end

      def manifest
        @manifest ||= Manifest.new(app)
      end

    end
  end
end
