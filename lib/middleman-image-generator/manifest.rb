module Middleman
  module ImageGenerator
    class Manifest
      MANIFEST_FILENAME = 'image_manifest.yml'

      attr_reader :app

      def initialize(app)
        @app = app
      end

      def path
        File.join(app.source_dir, MANIFEST_FILENAME)
      end

      def build_and_write(new_resources)
        write(dump(build(new_resources)))
      end

      # def resource(key)
      #   resources[key.to_s]
      # end

      private

      # def resources
      #   @resources ||= load(path)
      # end

      def dump(source)
        YAML.dump(source)
      end

      def load(path)
        YAML.load(File.read(path))
      end

      # Combine new_files with current state
      # TODO Would rather append than rewrite the entire file
      def build(resources)
        current = YAML.load_file(path)

        resources.each do |resource|
          item = {}
          item['path'] = resource
          item['modified'] = File.mtime(resource).to_s
          item['processed'] = Time.now.to_s

          current << item
        end

        current
      end

      def write(manifest)
        File.open(path, 'w') do |manifest_file|
          manifest_file.write(manifest)
        end
      end
    end
  end
end