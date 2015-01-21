# Middleman Thumbnailer

- Generates multiple resized versions from source images, typically small, medium and large versions.
- Generates webp version for each
- and tile source for OpenSeadragon

## Installation

Add this line to your `Gemfile`:

```ruby

gem 'middleman-image-generator'

```

And something like this to your `config.rb`:

```ruby

  require 'middleman-image-generator'
  
  activate :image_generator,
            allowable_filetypes: [:jpg, :jpeg, :png, :tiff],
            versions: {
                 sml: {quality: 'Q=80', dimensions: '200'},
                 med: {quality: 'Q=80', dimensions: '400'},
                 lrg: {quality: 'lossless', dimensions: '600'},
            },
            namespace_directory: %w(primary_items)
            
```

If you have a file in images called (for example) 1.jpg, thumbnail versions will be created called:
  1-sml.jpg
  1-med.jpg
  1-lrg.jpg

## Config Options

`:namespace_directory` only thumbnail images found within this directory (_within_ the images directory of course)