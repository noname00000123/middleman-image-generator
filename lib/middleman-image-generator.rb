require 'middleman-core'
require 'middleman-image-generator/options'
require 'middleman-image-generator/generator'
require 'middleman-image-generator/manifest'
require 'middleman-image-generator/version'

# Define the name the extension is to be activated with
::Middleman::Extensions.register(:image_generator) do
  require "middleman-image-generator/extension"
  ::Middleman::ImageGenerator::Extension
end