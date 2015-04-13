var _         = require("underscore"),
    sharp     = require('sharp'),
    versions  = process.argv[2];

_.each(versions,
    function() {
        var ver = versions[0];

        // define defaults
        // then add per versions options

//        sharp(ver.input_path.path)
//            .resize(ver.dimensions, null)
//            .sharpen()
//            .withMetadata()
//            .quality(ver.quality)
//            .interpolateWith('nohalo')
//            .withoutEnlargement()
//            .toFile('output.webp', function(err) {
//                if (err) {
//                    throw err;
//                } else {
//                    process.exit(0);
//                }
//            })
//
//            // I don't think this will work, it seems buffer is cleared as soon as toFile called
//            .toFile('output.jpg', function(err) {
//                if (err) {
//                    throw err;
//                } else {
//                    process.exit(0);
//                }
//            });
    }
);

