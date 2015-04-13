require 'fileutils'
require 'mime-types'

require 'middleman-core/core_extensions/data'
require 'middleman-image-generator/generator'

module Middleman
  module ImageGenerator
    class Extension < Middleman::Extension

      def before_build(builder)
        Middleman::ImageGenerator::Generator.generate!(app, builder,options)
        # TODO ensure manifest actually checks for existing work before running the generator
        # TODO before rest of app files are generted spawn sitemap and feed in images
        # Have since decided to generate reversioned images in source folder instead
      end

      private

      def setup_options(options={}, &_block)
        @options = Middleman::ImageGenerator::Options.new(options)

        yield @options if block_given?

        @options.freeze
      end

    end
  end
end