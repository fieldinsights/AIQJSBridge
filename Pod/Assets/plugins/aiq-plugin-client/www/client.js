cordova.define('aiq-plugin-client', function(require, exports, module) {
    var exec = require('cordova/exec');
    var channel = require('cordova/channel');
    var core = require('aiq-plugin-core');
    
    // Wait for the AIQClient plugin to initialize which is done in the
    // onCordovaReady callback below.
    channel.createSticky('onAIQClientReady');
    channel.waitForInitialization('onAIQClientReady');

    function Client() {
        var that = this;

        channel.onCordovaReady.subscribe(function() {
            var callback = function(version) {
                that.version = version;
                channel.onAIQClientReady.fire();
            };
            exec(callback, undefined, 'AIQClient', 'getVersion', []);
        });
    }

    Client.prototype.closeApp = function() {
        exec(undefined, undefined, 'AIQClient', 'closeApp', []);
    };

    Client.prototype.getAppArguments = function() {
        var args = {};
        if (window.location.search.length !== 0) {
            window.location.search.substring(1).split('&').forEach(function(param) {
                var pair = param.split('=');
                if (pair.length === 2) {
                    args[pair[0]] = pair[1];
                } else {
                    args[pair[0]] = null;
                }
            });
        }
        return args;
    };

    Client.prototype.setAppTitle = function(title) {
        title = title || '';
        exec(undefined, undefined, 'AIQClient', 'setAppTitle', [title]);
    };

    Client.prototype.getCurrentUser = function(callbacks) {
        callbacks = callbacks || {};
        exec(callbacks.success, core._proxyError(callbacks), 'AIQClient', 'getCurrentUser', []);
    };

    Client.prototype.getSession = function(callbacks) {
        callbacks = callbacks || {};
        exec(callbacks.success, core._proxyError(callbacks), 'AIQClient', 'getSession', []);
    };

    module.exports = new Client();
});
