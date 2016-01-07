cordova.define('aiq-plugin-imaging', function(require, exports, module) {
    var exec = require('cordova/exec');
    var core = require('aiq-plugin-core');

    function Imaging() {
        // Empty constructor
    }
    
    Imaging.prototype.capture = function(idOrSettings, settingsOrNil) {
        console.warn('aiq.imaging.capture() is deprecated, use navigator.camera.getPicture() isntead');
        var settings;
        var id;
        if (typeof idOrSettings === 'string') {
            // old, deprecated API
            id = idOrSettings;
            settings = settingsOrNil || {};
        } else {
            // new API, exciting!
            id = undefined;
            settings = idOrSettings || {};
        }
        exec(settings.success, core._proxyError(settings), 'AIQImaging', 'capture', [false, settings.source, id]);
    };

    module.exports = new Imaging();
});
