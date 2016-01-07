cordova.define('aiq-plugin-context', function(require, exports, module) {
    var exec = require('cordova/exec');
    var core = require('aiq-plugin-core');

    var Context = function() {
        // Empty constructor
    };

    Context.prototype.getGlobal = function(name, callbacks) {
        callbacks = callbacks || {};

        if (typeof name !== 'string') {
            if (typeof callbacks.failure === 'function') {
                callbacks.failure(new core.InvalidArgumentError('Name not specified'));
            }
            return;
        }

        exec(callbacks.success, aiq._proxyError(callbacks), 'AIQContext', 'getGlobal', [name]);
    };
    
    Context.prototype.getLocal = function(name, callbacks) {
        callbacks = callbacks || {};

        if (typeof name !== 'string') {
            if (typeof callbacks.failure === 'function') {
                callbacks.failure(new core.InvalidArgumentError('Name not specified'));
            }
            return;
        }

        exec(callbacks.success, aiq._proxyError(callbacks), 'AIQContext', 'getLocal', [name]);
    };
    
    Context.prototype.setLocal = function(name, value, callbacks) {
        callbacks = callbacks || {};

        if (typeof name !== 'string') {
            if (typeof callbacks.failure === 'function') {
                callbacks.failure(new core.InvalidArgumentError('Name not specified'));
            }
            return;
        }
        
        exec(callbacks.success, aiq._proxyError(callbacks), 'AIQContext', 'setLocal', [key, value]);
    };

    module.exports = new Context();
});
