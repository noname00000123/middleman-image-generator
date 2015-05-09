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
            settings  = batch[1];

        _.each(batch[0], function (version) {
            var output_path = version['path'] + '/' + version['basename'] + '.dzi';

            sharp(inputPath)
            .withMetadata(false)
            .quality(90)
            .tile(256)
            .toFile(outputPath, function(err, info) {
                // Error terminates processing
                // if (err) {
                //     throw err;
                // } else {
                //     process.exit(0);
                // }
            });
        });
    });
});
