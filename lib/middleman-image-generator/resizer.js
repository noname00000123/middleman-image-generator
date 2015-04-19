var sys      = require('sys'),
    exec     = require('child_process').exec,
    fs       = require('fs'),
    _        = require('underscore'),
    sharp    = require('sharp'),
    data     = process.argv[2];

function log(error, stdout, stderr) { sys.puts(stdout) }

var queue = JSON.parse(fs.readFileSync(data, 'utf8'));

_.each(queue, function(batch) {
    var input         = batch['input'],
        inputPath     = input['path'],
        display_types = batch['output'][3];

    _.each(display_types, function(display_type) {
        var batch     = display_type,
            settings  = batch[1],
            crop      = settings['crop'],
            sharpen   = settings['sharpen'],
            extract   = settings['extract'],
            greyscale = settings['greyscale'],
            gravity   = settings['gravity'];

        _.each(batch[0], function (version) {
            var output_path = version['path'] + '/' + version['basename'],
                webp        = output_path + '.webp',
                jpg         = output_path + '.jpg',
                metaWebp    = 'webpmux -set xmp ' + inputPath.slice(0, -4) + '.xmp ' + webp + ' -o ' + webp,
                metaJpg     = 'exiftool -tagsfromfile ' + inputPath.slice(0, -4) + '.xmp -all:all -overwrite_original ' + jpg,

                inputStream  = fs.createReadStream(inputPath),
                outputStream = fs.createWriteStream(webp);

            var transformer = sharp(inputPath)
                .metadata(function (err, metadata) {
                    var h = metadata.height,
                        w = metadata.width;

                    // if portrait width = min else landscape height = min
                    // will make larger images, if too large, do inverse
                    if (crop) {
                        var x = gravity['x'],
                            y = gravity['y'];

                        //transformer.crop(x, y);
                        transformer
                            .resize(version['dim'], version['dim'])
                            .crop(sharp.gravity.center);
                    }

                    else if (extract['offset']['top']) {
                        var top = extract['offset']['top'],
                            left = extract['offset']['left'],
                            w = extract['dims']['w'],
                            h = extract['dims']['h'];

                        transformer
                            .extract(top, left, w, h);
                    }

                    else {
                        transformer
                            .resize(w < h ? w = version['dim'] : h = version['dim']);
                    }

                    transformer.withoutEnlargement()
                        .quality(version['quality'])
                        .interpolateWith('nohalo');

                    if (sharpen) {
                        transformer.sharpen();
                    }

                    // TODO greyscale isn't pretty
                    if (greyscale) {
                        transformer.greyscale();
                    }

                    transformer.toFile(webp, function () {
                        // Error terminates processing
                        // if (err) {
                        //     throw err;
                        // } else {
                        //     process.exit(0);
                        // }

                        // Then add metadata to output
                        exec(metaWebp, log);
                    });

                    // Generate jpg
                    transformer.toFile(jpg, function () {
                        // Error terminates processing
                        // if (err) {
                        //     throw err;
                        // } else {
                        //     process.exit(0);
                        // }

                        // Then add metadata to output
                        exec(metaJpg, log);
                    });
                });
        });
    });
});
