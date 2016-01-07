cordova.define('aiq-plugin-device', function(require, exports, module) {
    var exec = require('cordova/exec');
    var channel = require('cordova/channel');

    // Wait for the AIQDevice plugin to initialize which is done in the
    // onCordovaReady callback below.
    channel.createSticky('onAIQDeviceReady');
    channel.waitForInitialization('onAIQDeviceReady');

    function Device() {
        var that = this;
        
        channel.onCordovaReady.subscribe(function() {
            require('cordova-plugin-device.device').getInfo(function(info) {
                that.os = info.platform;
                that.version = info.version;
                channel.onAIQDeviceReady.fire();
            });
        });
    }

    Device.prototype.getNetworkInfo = function(callback) {
        console.warn('aiq.device.getNetworkInfo() is deprecated, use navigator.connection instead');
        exec(callback, undefined, 'AIQDevice', 'getNetworkInfo', []);
    };
    
    module.exports = new Device();
});
