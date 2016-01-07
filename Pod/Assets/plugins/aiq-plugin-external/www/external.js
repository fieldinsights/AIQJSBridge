cordova.define('aiq-plugin-external', function(require, exports, module) {
    var exec = require('cordova/exec');
    var core = require('aiq-plugin-core');

    function External() {
        // Empty constructor
    }

    External.prototype.openMap = function(settings) {
        settings = settings || {};

        if (typeof settings.latitude !== 'number') {
            if (typeof settings.failure === 'function') {
                settings.failure(new core.InvalidArgumentError('Latitude not specified'));
            }
            return;
        }

        if (typeof settings.longitude !== 'number') {
            if (typeof settings.failure === 'function') {
                settings.failure(new core.InvalidArgumentError('Longitude not specified'));
            }
            return;
        }
        
        exec(settings.success, core._proxyError(settings), 'AIQExternal', 'openMap', [settings]);
    };

    module.exports = new External();
});
