require 'fileutils'
require 'find'
require 'json'
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

        @content_types = options.sources.map{|source| source[:type]}
      end

      def process_versions
        @content_types.each do |type|
          # Collect source files, if active generate required versions
          collect_specific(type).each do |file|
            input_path      = file
            input_basename  = File.basename(input_path, File.extname(input_path))

            output_path = output_path(input_path)

            if output_prefix(type).length > 1
              output_basename = output_prefix(type).select{|item| item[:id].to_i == input_basename.to_i}.first[:title]
            else
              output_basename = output_prefix(type)[0][:title]
            end

            # There's an implied use case for each version.
            # Each use case will be formatted to suit different display conditions,
            # ie. a thumbnail might be used when displaying many images on an index page.
            # Thumbnails must then be small. We will set the image generator to produce versions to suit these conditions
            options.versions.each_with_index do |use_case, index|
              # Store the use case in a variable, it may be used in the output filename
              $use_case = use_case.keys.to_s

              # A use case will have its own versions
              $versions = []
              $index    = index
            end

            input  = {path: input_path, basename: input_basename}
            output = versions($index, output_path, output_basename, $versions)

            batch = []
            batch << [input: input, output: output[0]]

            # Generate resized lossy compressed image files according to version parameters
            # generate_resized_versions(batch)

            # Generate enlargements when required
            # options.sources.select{|item| item[:enlargements].present?}.each do |item|
            #   generate_dzi(
            #       input_path,
            #       input_basename,
            #       File.expand_path(item[:enlargements][:path])
            #   )
            # end
          end
        end

        update_manifest

        # TODO no longer necessary to add files to the sitemap now that they are put to source before_build
        # manipulate_resource_list(new_resources)
      end

      # Method taken from middleman-imageoptim by which images
      # in sprockets load path were added to the sitemap.
      # I am trying to push only the newly generated versions
      # to the sitemap. Will this work?
      # def manipulate_resource_list(resources)
      #   return resources unless options.manifest
      #
      #   Middleman::ImageGenerator::ResourceList.manipulate(app, resources, options)
      # end

      private

      # Collect all assets found in predefined directories
      def collect_all
        # content_types = []
        # content_types << options.sources.each{|item| item[:type]}

        # TODO ensure reversioned folder isn't collected
        glob_rule = "#{@images_dir}/{#{@content_types.join(',')}}/**/*.{#{options.filetypes.join(',')}}"

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
        glob_rule = "#{@images_dir}/#{dir == 'secondary_items' ? 'secondary_items/{demonstrations,details,invites,studies}' : dir}/**/*.{#{options.filetypes.join(',')}}"

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

      def ensure_enlargements_dir_exists(output_dir)
        # Ensure there is a directory to receive the enlargements
        unless File.directory?(output_dir)
          FileUtils.mkdir_p(output_dir)
        end
      end

      # Add filename in/output paths to parameters hash
      #def versions(versions, input_path, input_basename, output_path, output_basename)
      #   versions.each do |version, parameters|
      #     parameters[:input]     = {basename: input_basename,
      #                               path: input_path}
      #
      #     parameters[:output]    = {basename: "#{output_basename}_#{version}",
      #                               path: File.join(output_path, "#{output_basename}_#{version}")}
      #   end
      # end

      # Revised. Arrange per version paramaters, filenames and dimensions
      def versions(index, output_path, output_basename, array)
        options.versions[index].map do |version|
          version     = version[1]
          sizes       = version[:sizes]
          settings    = version[:settings]

          # Populate versions array with sizes
          sizes.each do |size|
            q = size[:quality]
            w = size[:dims][:w]
            h = size[:dims][:h]

            array << {
                path: output_path,
                basename: [output_basename, "q#{q}", "w#{w}"].join('_'),
                use_case: $use_case,
                quality: q,
                width: w,
                height: h
            }

            # Multiply by a factor of two for inclusion of a double sized version for hi-dpi screens
            if options.retina_versions
              w2x = w.to_i * 2
              # ensure nil remains nil
              h2x = h == nil ? nil : h.to_i * 2

              array << {
                  path: output_path,
                  basename: [output_basename, "q#{q}", "w#{w2x}_x2"].join('_'),
                  use_case: $use_case,
                  quality: q,
                  width: w2x,
                  height: h2x
              }
            end
          end

          # Return settings unique to versions required by this use case
          settings
          # And the versions array
          array
        end
      end

      # For each of the required image types generate resized versions.
      # Add Copyright metadata and ICC profile http://www.color.org/srgbprofiles.xalter
      def generate_resized_versions(output_versions)
        IO.popen("node /home/user/Documents/webdev/staticgenerators/middleman/middleman-image-generator/lib/middleman-image-generator/resizer.js")

#         output_versions.each do |version, parameters|
#           input_path = "#{parameters[:input_path]}"
#           output_path = "#{parameters[:output_path]}"
#
#           input_ext = File.extname(input_path)
#           input_basename = File.basename(input_path, input_ext)
#           input_dir = File.dirname(input_path)
#
#           # JPEG versions
#           # WEBP versions, add xmp with google's webpmux see http://www.webmproject.org/code/
#           IO.popen(
#             %{vipsthumbnail #{input_path} --size #{parameters[:dimensions]}x1000 --interpolator nohalo --delete #{parameters[:options]} -o #{output_path}.jpg[#{parameters[:quality]},strip,optimize_coding]
#
# exiftool -tagsfromfile #{File.join(input_dir, input_basename)}.xmp -all:all -overwrite_original #{output_path}.jpg
#
# vipsthumbnail #{input_path} --size #{parameters[:dimensions]} --interpolator nohalo --delete #{parameters[:options]} -o #{output_path}.webp[#{parameters[:quality]},strip]
#
# webpmux -set xmp #{File.join(input_dir, input_basename)}.xmp #{output_path}.webp -o #{output_path}.webp}).read
#
#           new_resource(@app.sitemap, output_path, output_path)
#         end
      end

      def generate_dzi(input_path, input_filename, output_dir)
        ensure_enlargements_dir_exists(output_dir)

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
