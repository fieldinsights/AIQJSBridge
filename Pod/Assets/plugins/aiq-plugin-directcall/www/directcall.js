cordova.define('aiq-plugin-directcall', function(require, exports, module) {
    var exec = require('cordova/exec');
    var core = require('aiq-plugin-core');

    function DirectCall() {
        // Empty constructor
    }

    DirectCall.prototype.getResource = function(descriptor, callbacks) {
        callbacks = callbacks || {};

        if (typeof descriptor !== 'object') {
            if (typeof callbacks.failure === 'function') {
                callbacks.failure(new core.InvalidArgumentError('Descriptor not specified'));
            }
            return;
        }

        if (typeof descriptor.endpoint !== 'string') {
            if (typeof callbacks.failure === 'function') {
                callbacks.failure(new core.InvalidArgumentError('Endpoint not specified'));
            }
            return;
        }

        if ((typeof descriptor.body !== 'undefined') || (typeof descriptor.resourceUrl !== 'undefined')) {
            if (typeof callbacks.failure === 'function') {
                callbacks.failure(new core.InvalidArgumentError('Body not allowed'));
            }
            return;
        }
        
        exec(callbacks.success, core._proxyError(callbacks), 'AIQDirectCall', 'call', ['get', descriptor]);
    };

    DirectCall.prototype.postResource = function(descriptor, callbacks) {
        callbacks = callbacks || {};

        if (typeof descriptor !== 'object') {
            if (typeof callbacks.failure === 'function') {
                callbacks.failure(new core.InvalidArgumentError('Descriptor not specified'));
            }
            return;
        }

        if (typeof descriptor.endpoint !== 'string') {
            if (typeof callbacks.failure === 'function') {
                callbacks.failure(new core.InvalidArgumentError('Endpoint not specified'));
            }
            return;
        }

        if ((typeof descriptor.body !== 'undefined') && (typeof descriptor.resourceUrl !== 'undefined')) {
            if (typeof callbacks.failure === 'function') {
                if (typeof descriptor.contentType !== 'undefined') {
                    callbacks.failure(new core.InvalidArgumentError('Body not allowed'));
                } else {
                    callbacks.failure(new core.InvalidArgumentError('Resource not allowed'));
                }
            }
            return;
        }
        
        exec(callbacks.success, core._proxyError(callbacks), 'AIQDirectCall', 'call', ['post', descriptor]);
    };

    DirectCall.prototype.putResource = function(descriptor, callbacks) {
        callbacks = callbacks || {};

        if (typeof descriptor !== 'object') {
            if (typeof callbacks.failure === 'function') {
                callbacks.failure(new core.InvalidArgumentError('Descriptor not specified'));
            }
            return;
        }

        if (typeof descriptor.endpoint !== 'string') {
            if (typeof callbacks.failure === 'function') {
                callbacks.failure(new core.InvalidArgumentError('Endpoint not specified'));
            }
            return;
        }

        if ((typeof descriptor.body !== 'undefined') && (typeof descriptor.resourceUrl !== 'undefined')) {
            if (typeof callbacks.failure === 'function') {
                if (typeof descriptor.contentType !== 'undefined') {
                    callbacks.failure(new core.InvalidArgumentError('Body not allowed'));
                } else {
                    callbacks.failure(new core.InvalidArgumentError('Resource not allowed'));
                }
            }
            return;
        }
        
        exec(callbacks.success, core._proxyError(callbacks), 'AIQDirectCall', 'call', ['put', descriptor]);
    };

    DirectCall.prototype.deleteResource = function(descriptor, callbacks) {
        callbacks = callbacks || {};

        if (typeof descriptor !== 'object') {
            if (typeof callbacks.failure === 'function') {
                callbacks.failure(new core.InvalidArgumentError('Descriptor not specified'));
            }
            return;
        }

        if (typeof descriptor.endpoint !== 'string') {
            if (typeof callbacks.failure === 'function') {
                callbacks.failure(new core.InvalidArgumentError('Endpoint not specified'));
            }
            return;
        }

        if ((typeof descriptor.body !== 'undefined') || (typeof descriptor.resourceUrl !== 'undefined')) {
            if (typeof callbacks.failure === 'function') {
                callbacks.failure(new core.InvalidArgumentError('Body not allowed'));
            }
            return;
        }
        
        exec(callbacks.success, core._proxyError(callbacks), 'AIQDirectCall', 'call', ['delete', descriptor]);
    };
    
    module.exports = new DirectCall();
});
