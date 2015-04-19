require 'fileutils'
require 'find'
require 'json'
require 'middleman-image-generator/resource_collector'

# Enqueue batches and process
module Middleman
  module ImageGenerator
    class Generator
      include ResourceCollector

      attr_reader :app, :builder, :options

      def self.generate!(app, builder, options)
        new(app, builder, options).process_queue
      end

      def initialize(app, builder, options)
        @app = app
        @builder = builder
        @options = options

        @images_dir = File.join(app.source_dir, app.images_dir)

        @content_types = options.sources.map{|source| source[:type]}

        # Store batch_parameters in an array so they are accessible to all methods
        @batch_parameters = []
      end

      def prepare_batch_paramaters
        # Clear previous iteration of array
        @batch_parameters = []

        @content_types.each do |type|
          # Collect source files, if active generate required versions
          collect_specific(type).each do |file|
            input_path      = file
            input_basename  = File.basename(input_path, File.extname(input_path))

            output_path = output_path(input_path)

            # TODO this is probably not the appropriate place to do this,
            # but I can't think of a better way to pass output_path out to check the dir exists
            ensure_dir_exists(output_path)

            if output_prefix(type).length > 1
              output_basename = output_prefix(type).select{|item| item[:id].to_i == input_basename.to_i}.first[:title]
            else
              output_basename = output_prefix(type)[0][:title]
            end

            # There's an implied display type for each version.
            # Each display type will be formatted to suit different display conditions,
            # ie. a thumbnail might be used when displaying many images on an index page.
            # Thumbnails must then be small. We will set the image generator to produce versions to suit these conditions
            options.display_types.each_with_index do |display_type, index|
              # Store the display type in a variable, it may be used in the output filename
              # $display_type = display_type.keys[0].to_s

              # A display type will have its own versions
              $output_parameters = []
            end

            input  = {path: input_path, basename: input_basename}
            output = versions(output_path, output_basename, $output_parameters)

            batch = []
            batch << [input: input, output: output]

            @batch_parameters << batch.flatten
          end
        end

        @batch_parameters.flatten
      end

      def process_queue
        queue = write_queue(prepare_batch_paramaters)

        # Generate resized lossy compressed image files according to version parameters
        #manufacture(queue)

        # Generate enlargements when required
        # options.sources.select{|item| item[:enlargements].present?}.each do |item|
        #   collect_specific(item[:type]).each do |file|
        #     input_path      = file
        #     input_basename  = File.basename(input_path, File.extname(input_path))
        #
        #     manufacture_dzi(
        #         input_path,
        #         input_basename,
        #         File.expand_path(item[:enlargements][:path])
        #     )
        #   end
        # end

        update_manifest

        # TODO no longer necessary to add files to the sitemap now that they are put to source before_build
        # manipulate_resource_list(new_resources)
      end

      private

      # Collect all assets found in predefined directories
      def collect_all
        # content_types = []
        # content_types << options.sources.each{|item| item[:type]}

        # TODO ensure reversioned folder isn't collected filename must be of numeric
        glob_rule = "#{@images_dir}/{#{@content_types.join(',')}}/**/[0-9]*.{#{options.filetypes.join(',')}}"

        # TODO refactor using Find
        # Find.find(@images_dir) do |path|
        #   if File.directory? path
        #     if File.dirname(path).any?(@content_types)
        #       unless File.extname(path).any?(options.filetypes)
        #         Find.prune
        #       end
        #     end
        #   end
        # end

        # Store the paths in an Array[]
        Dir[glob_rule]

        # Or
        # ::Middleman::Util.all_files_under(app.images_dir)
      end

      # Collect assets found in a specific directory
      def collect_specific(dir=str)
        # TODO ensure reversioned folder isn't collected
        # TODO account for different file structure in secondary_items
        # TODO refactor using Find would help with above
        # TODO ensure user is aware of naming convention, filename must be numeric
        # TODO new regex will not return contents of reversion dir
        glob_rule = "#{@images_dir}/#{dir == 'secondary_items' ? 'secondary_items/{demonstrations,details,invites,studies}' : dir}/**/[0-9]*.{#{options.filetypes.join(',')}}"

        Dir[glob_rule]
      end

      # To ensure images are available to the sitemap, versions should be generated before_build
      # and stored in 'reversioned' folder inside each source image directory
      def output_path(input_path, options=nil)
        # Build array containing dir levels
        # dir_levels = Pathname(input_path).each_filename.to_a
        # Determine location of 'source' in path to then divert to 'build'
        # divert_at = dir_levels.index('source')
        # Capture dir levels after 'source'
        # relative_path = File.join(dir_levels[(divert_at + 1) ... -1])

        # Unless alternate output_path
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

        # Might do this in a seperate method, then loop through everything no need to call shell script per file. Do it once after we've caught everything in the file.
        # Write json to tmp_file
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