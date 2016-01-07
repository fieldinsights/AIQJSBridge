cordova.define('aiq-plugin-client-navbar', function(require, exports, module) {
    var exec = require('cordova/exec');
    var core = require('aiq-plugin-core');

    function Navbar() {
        this._callbacks = {};
        this._callbackId = 0;
    }

    Navbar.prototype._callAction = function(callbackId, args) {
        if (typeof callbackId === 'string') {
            callbackId = parseInt(callbackId, 10);
        }
        var callback = this._callbacks[callbackId];
        if (typeof callback === 'function') {
            callback(args);
        }
    };

    Navbar.prototype._removeAction = function(callbackId) {
        delete this._callbacks[callbackId];
    };

    Navbar.prototype._clean = function(callback) {
        var that = this;
        exec(function() {
            that._callbacks = {};
            that._callbackId = 0;
            if (typeof callback === 'function') {
                callback();
            }
        }, undefined, 'AIQClient', 'clean', []);
    };

    Navbar.prototype.getButton = function(identifier, callbacks) {
        callbacks = callbacks || {};

        if (typeof identifier !== 'string') {
            if (typeof callbacks.failure === 'function') {
                callbacks.failure(new core.InvalidArgumentError('Identifier not specified'));
            }
            return;
        }
        
        exec(callbacks.success, core._proxyError(callbacks), 'AIQClient', 'getButton', [identifier]);
    };

    Navbar.prototype.getButtons = function(callbacks) {
        callbacks = callbacks || {};
        exec(callbacks.success, core._proxyError(callbacks), 'AIQClient', 'getButtons', []);
    };

    Navbar.prototype.addButton = function(descriptor, callbacks) {
        callbacks = callbacks || {};

        if (typeof descriptor !== 'object') {
            if (typeof callbacks.failure === 'function') {
                callbacks.failure(new core.InvalidArgumentError('Descriptor not specified'));
            }
            return;
        }

        if (typeof descriptor.image !== 'string') {
            if (typeof callbacks.failure === 'function') {
                callbacks.failure(new core.InvalidArgumentError('Image not specified'));
            }
            return;
        }

        if (typeof descriptor.onClick !== 'function') {
            if (typeof callbacks.failure === 'function') {
                callbacks.failure(new core.InvalidArgumentError('Action not specified'));
            }
            return;
        }

        this._callbacks[this._callbackId] = descriptor.onClick;
        descriptor.onClickId = this._callbackId;
        delete descriptor.onClick;
        this._callbackId = this._callbackId + 1;
            
        if ((descriptor.enabled === undefined) || (typeof descriptor.enabled !== 'boolean')) {
            descriptor.enabled = true;
        }
        
        if ((descriptor.visible === undefined)|| (typeof descriptor.visible !== 'boolean')) {
            descriptor.visible = true;
        }
    
        exec(callbacks.success, core._proxyError(callbacks), 'AIQClient', 'addButton', [descriptor]);
    };

    Navbar.prototype.updateButton = function(identifier, descriptor, callbacks) {
        callbacks = callbacks || {};

        if (typeof identifier !== 'string') {
            if (typeof callbacks.failure === 'function') {
                callbacks.failure(new core.InvalidArgumentError('Identifier not specified'));
            }
            return;
        }

        if (typeof descriptor !== 'object') {
            if (typeof callbacks.failure === 'function') {
                callbacks.failure(new core.InvalidArgumentError('Descriptor not specified'));
            }
            return;
        }

        exec(callbacks.success, core._proxyError(callbacks), 'AIQClient', 'updateButton', [identifier, descriptor]);
    };

    Navbar.prototype.deleteButton = function(identifier, callbacks) {
        callbacks = callbacks || {};

        if (typeof identifier !== 'string') {
            if (typeof callbacks.failure === 'function') {
                callbacks.failure(new core.InvalidArgumentError('Identifier not specified'));
            }
            return;
        }
        
        exec(callbacks.success, core._proxyError(callbacks), 'AIQClient', 'deleteButton', [identifier]);
    };

    module.exports = new Navbar();
});
