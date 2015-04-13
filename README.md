# Middleman Thumbnailer

- Generates multiple resized versions from source images, typically small, medium and large versions.
- Generates webp version for each
- and tile source for OpenSeadragon

## Installation
See here for heroku installation guide 
https://github.com/alex88/heroku-buildpack-vips

####VIPS
Installing libvips Image Manipulation Library
[from the official libvips documentation (as at 22 Jan 15)](http://www.vips.ecs.soton.ac.uk/index.php?title=Build_on_Ubuntu)

```shell 

    $ cd /usr/local/
    
``` 
or where ever you wish to install

```shell

    $ git clone git://github.com/jcupitt/libvips.git
    
```

```shell

    $ sudo apt-get install build-essential  libxml2-dev libfftw3-dev  \
    gettext libgtk2.0-dev python-dev liblcms1-dev liboil-dev \
    libmagickwand-dev libopenexr-dev libcfitsio3-dev gobject-introspection flex bison \
    libgsf-1-dev libexif-dev
    
```
dzsave requires 'libgsf-1-dev' 
vips_edit requires 'libexif-dev'

Then

```shell

    $ ./configure 
    $ make 
    $ install
    
``` 

Or from the git sources instead:

```shell

    $ sudo apt-get install automake libtool swig gtk-doc-tools libglib2.0-dev git
    
```

now you can build vips:
if it's the git sources first do ```$ ./bootstrap.sh```

Do with superuser permissions ```$ sudo```

```shell

    $ ./configure
    $ make
    $ sudo make install

```

Configure VIPSHOME in .bashrc. To open ```$ sudo sublime .bashrc```

```shell

    export VIPSHOME=/usr/local
    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$VIPSHOME/lib
    export PATH=$PATH:$VIPSHOME/bin
    export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:$VIPSHOME/lib/pkgconfig
    export MANPATH=$MANPATH:$VIPSHOME/man
    export PYTHONPATH=$VIPSHOME/lib/python2.7/site-packages
    
```

-----

Copyright metadata handled by 
 For webp: Google's webpmux see http://www.webmproject.org/code/
 ``` $ sudo apt-get install webp ```
 For jpeg: exiftool see 
 ``` $ sudo apt-get install libimage-exiftool-perl ```

-----

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

output_filename source files and primary_id must match to ensure output_filename is correct.
`:namespace_directory` only thumbnail images found within this directory (_within_ the images directory of course)