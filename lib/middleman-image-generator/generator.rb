require 'fileutils'
require 'find'
require 'json'
require 'yaml'
#require 'middleman-image-generator/resource_collector'

# Enqueue batches and process
module Middleman
  module ImageGenerator
    class Generator
      #include ResourceCollector

      attr_reader :app, :builder, :options

      def self.generate!(app, builder, options)
        new(app, builder, options).process_queue
      end

      def initialize(app, builder, options)
        @app = app
        @builder = builder
        @options = options

        #@manifest = File.join(app.source_dir, "image_manifest.yml")
        @images_dir = File.join(app.source_dir, app.images_dir)

        @content_types = options.sources.map{|source| source[:type]}

        # Store batch_parameters in an array so they are accessible to all methods
        @batch_parameters = []

        @new_files = []
      end

      # Collect source files, if active and unprocessed we will prepare batch paramaters
      def select_unprocessed
        processed = read_manifest.to_a

        @content_types.each do |type|
          new_files = collect_specific(type).reject{|file| processed.any?{|item| item['path'].to_s == file.to_s && item['modified'].to_s == File.mtime(file).to_s}}
          new_files.each do |file|
            input_basename = File.basename(file, File.extname(file))
            @new_files << {content_type: type, path: file, basename: input_basename}
          end
        end
      end

      def prepare_batch_paramaters
        # Clear previous iteration of array
        @batch_parameters = []

        select_unprocessed

        @new_files.each do |file|
          type            = file[:content_type]
          input_path      = file[:path]
          input_basename  = file[:basename]
          output_path     = output_path(input_path)

          ensure_dir_exists(output_path)

          if output_prefix(type).length > 1
            output_basename = output_prefix(type).select{|item| item[:id].to_i == input_basename.to_i}.first[:title]
          else
            output_basename = output_prefix(type)[0][:title]
          end

          options.display_types.each_with_index do |display_type, index|
            # $display_type = display_type.keys[0].to_s
            # A display type will have its own versions stored in $output_parameters
            $output_parameters = []
          end

          input  = {path: input_path, basename: input_basename}
          output = versions(output_path, output_basename, $output_parameters)

          batch = []
          batch << [input: input, output: output]

          @batch_parameters << batch.flatten
        end

        @batch_parameters.flatten
      end

      def process_queue
        batch = prepare_batch_paramaters

        if @new_files.present?
          queue = write_queue(batch)

          log = []

          @new_files.each do |file|
            log << file[:path]
            log
          end

          # Generate resized lossy compressed image files according to version parameters
          manufacture(queue)

          # Generate enlargements when required
          options.sources.select{|item| item[:enlargements].present?}.each do |item|
            @new_files.each do |file|
              if file[:content_type].to_s == item[:type].to_s
                input_path      = file[:path]
                input_basename  = file[:basename]

                manufacture_dzi(input_path, input_basename, File.expand_path(item[:enlargements][:path]))
              end
            end
          end

          update_manifest(log)
        end
      end

      private

      # Collect all assets found in predefined directories
      def collect_all
        # TODO refactor using Find
        glob_rule = "#{@images_dir}/{#{@content_types.join(',')}}/**/[0-9]*.{#{options.filetypes.join(',')}}"

        # Store the paths in an Array[]
        Dir[glob_rule]
      end

      # Collect assets found in a specific directory
      def collect_specific(dir=str)
        # TODO ensure user is aware of naming convention, filename must be numeric
        glob_rule = "#{@images_dir}/#{dir == 'secondary_items' ? 'secondary_items/{demonstrations,details,invites,studies}' : dir}/**/[0-9]*.{#{options.filetypes.join(',')}}"

        Dir[glob_rule]
      end

      # To ensure images are available to the sitemap, versions should be generated before_build
      # and stored in 'reversioned' folder inside each source image directory
      def output_path(input_path, options=nil)
        # Unless alternate output_path specified
        options ||= File.join(File.dirname(input_path), 'reversioned')
      end

      # Collect pre-generated filenames for association with corresponding images
      def output_prefix(type)
        options.sources.select{|item| item[:type] == type}.first[:filenames]
      end

      # Ensure there is a directory to receive versions
      def ensure_dir_exists(output_dir)
        unless File.directory?(output_dir)
          FileUtils.mkdir_p(output_dir)
        end
      end

      # Revised. Marshall batch paramaters, filenames and dimensions for each display_type
      def versions(output_path, output_basename, output_parameters)
        output = []

        options.display_types.each do |display_type|
          versions_per_display_type = []

          versions = display_type.map do |item|
            sizes = []

            # Populate versions array with sizes
            item[1][:sizes].each do |size|
              q = size[:quality]
              min = size[:min_dimension]

              sizes << {
                  path: output_path,
                  basename: [
                    output_basename,
                    item[0], # $display_type,
                    "q#{q}",
                    "w#{min}"
                  ].join('_'),
                  #display_type: item[0], #$display_type,
                  quality: q,
                  dim: min,
              }

              # Multiply by a factor of two for inclusion
              # of a double sized version for hi-dpi screens
              if options.retina_versions && item[0].to_s != 'indexable'
                double = min.to_i * 2

                sizes << {
                    path: output_path,
                    basename: [
                      output_basename,
                      item[0], #$display_type,
                      "q#{q}",
                      "w#{double}_x2"
                    ].join('_'),
                    #display_type: item[0], #$display_type,
                    quality: q,
                    dim: double,
                }
              end
            end

            output_parameters << [sizes, item[1][:settings]]
          end

          versions_per_display_type << versions[0]
          output << versions_per_display_type[0]
        end

        # Return the settings and version parameters
        # unique to this display type in an array
        output
      end

      def write_queue(collection)
        tmp_dir      = File.join(Dir.pwd, 'source/assets/images/tmp')
        tmp_filename = "#{tmp_dir}/batch#{Time.now.to_i}.json"

        # Do it once after the batch has been written to the tmp_file.
        File.open(tmp_filename, "w") do |file|
          file.write(collection.to_json)
          file.close
        end

        tmp_filename
      end

      # For each of the required image types generate resized versions.
      # Add Copyright metadata and ICC profile http://www.color.org/srgbprofiles.xalter
      # execute lovell/sharp for processing, provides friendlier interface than libvips itself
      # node.js required
      def manufacture(queue)
        # TODO consider using Tempfile class
        path  = File.expand_path("..", Dir.pwd)
        cmd   = "node #{path}/middleman-image-generator/lib/middleman-image-generator/resizer.js #{queue}"

        # Wait until the file exists
        until File.exists?(queue)
          sleep 1
        end

        %x[`#{cmd}`]

        # Delete tmp_file after completion
        File.delete(queue)
      end

      def manufacture_dzi(input_path, input_filename, output_dir)
        ensure_dir_exists(output_dir)

        # Append filename to output_dir
        output_path = File.join(output_dir, input_filename)

        # TODO Determine appropriate quality setting, 90 reduces size by roughly two thirds.
        IO.popen("vips dzsave #{input_path} #{output_path} --suffix .jpg[Q=90] --depth onetile --strip")
      end

      def read_manifest
        # TODO what are we gonna do if its empty?
        YAML.load_file(File.join(app.source_dir, "image_manifest.yml"))
      end

      def update_manifest(resources)
        return unless options.manifest
        manifest.build_and_write(resources)
      end

      # Check carried out in prepare_batch_parameters
      # def updated_images
      #   collect_all.select { |path| file_updated?(path) }
      # end

      # def file_updated?(file_path)
      #   return true unless options.manifest
      #   File.mtime(file_path) != manifest.resource(file_path)
      # end

      def manifest
        @manifest ||= Manifest.new(app)
      end

    end
  end
end

# def output_path(input_path, options=nil)
  # Build array containing dir levels
  # dir_levels = Pathname(input_path).each_filename.to_a
  # Determine location of 'source' in path to then divert to 'build'
  # divert_at = dir_levels.index('source')
  # Capture dir levels after 'source'
  # relative_path = File.join(dir_levels[(divert_at + 1) ... -1])