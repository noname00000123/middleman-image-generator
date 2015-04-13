var sys      = require('sys'),
    exec     = require('child_process').exec,
    fs       = require('fs'),
    _        = require('underscore'),
    sharp    = require('sharp'),
    batch    = process.argv[2];


function puts(error, stdout, stderr) { sys.puts(stdout) }

var data = JSON.parse(fs.readFileSync(batch, 'utf8')),
    // TODO loop through to create vars for each version
    input       = data[0][0]['input'],
    input_path  = input['path'],
    output      = data[0][0]['output'],
    settings    = output[1];

_.each(output, function(i) {
        var output_path = i['path'] + '/' + i['basename'],
            webp = output_path + '.webp',
            jpg = output_path + '.jpg',
            cmd = 'webpmux -set xmp ' + input_path.slice(0, -4) + '.xmp ' + webp + ' -o ' + webp;

        var img = sharp(input_path);

        img.metadata(function(err, metadata) {
            var h = metadata.height,
                w = metadata.width,
                // if portrait width = min else landscape height = min
                // will make larger images, if too large, do inverse
                dims = w < h ? w = i['dim'] : h = i['dim'];

            img.resize(dims)
                .sharpen()
                .quality(i['quality'])
                .interpolateWith('nohalo')
                .withoutEnlargement()
                .toFile(webp, function (err) {
                    if (err) {
                        throw err;
                    } else {
                        process.exit(0);
                    }
                });

//                .toBuffer(function(err, outputBuffer, info) {
//                    buffer = outputBuffer;
//                });
//
//            buffer.toFile(webp, function (err) {
//                if (err) {
//                    throw err;
//                } else {
//                    process.exit(0);
//                }
//            });
//
//            buffer.toFile(jpg, function (err) {
//                if (err) {
//                    throw err;
//                } else {
//                    process.exit(0);
//                }
//            });

        });

// TODO and jpg
//        sharp(input_path)
//            .resize(i['width'], i['height'])
//            .sharpen()
//            .quality(i['quality'])
//            .interpolateWith('nohalo')
//            .withoutEnlargement()
//            .toFile(jpg, function(err) {
//                if (err) {
//                    throw err;
//                } else {
//                    process.exit(0);
//                }
//            });


        // Then add metadata to output
        exec(cmd, puts);

    }
);