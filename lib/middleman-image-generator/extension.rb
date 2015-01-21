require 'fileutils'
require 'mime-types'

require 'middleman-image-generator/generator'

module Middleman
  module ImageGenerator
    class Extension < Middleman::Extension

      def after_build(builder)
        Middleman::ImageGenerator::Generator.generate!(app, builder,options)
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