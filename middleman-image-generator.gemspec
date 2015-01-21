# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'middleman-image-generator/version'

Gem::Specification.new do |s|
  s.name        = "middleman-image-generator"
  s.version     = Middleman::ImageGenerator::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["noname00000123"]
  s.email       = ["noname00000123@gmail.com"]
  s.homepage    = "https://github.com/noname00000123/middleman-image-generator"
  s.summary     = %q{Generate thumbnail versions of image files}
  s.description = s.summary

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_paths = ["lib"]

  # s.add_runtime_dependency("middleman", ["~> 3.2.2"])
  s.add_runtime_dependency("rake", [">= 0"])
  s.add_runtime_dependency("rmagick", ["~> 2.13.0"])
  s.add_runtime_dependency("mime-types", ["2.1"])

  s.add_development_dependency 'rspec'

  s.add_dependency "middleman-core", [">= 3.2.2"]
end
