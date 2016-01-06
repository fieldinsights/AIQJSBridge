cordova.define('aiq-plugin-storage', function(require, exports, module) {
    var exec = require('cordova/exec');
    var core = require('aiq-plugin-core');

    function Storage() {
        // Empty constructor
    }

    Storage.prototype.getDocuments = function(type, settings) {
        settings = settings || {};
        if (typeof type !== 'string') {
            if (typeof settings.failure === 'function') {
                settings.failure(new core.InvalidArgumentError('Type not specified'));
            }
            return;
        }
        exec(settings.success, core._proxyError(settings), 'AIQLocalStorage', 'getDocuments', [type, settings.filter]);
    };

    Storage.prototype.getDocument = function(identifier, callbacks) {
        callbacks = callbacks || {};
        if (typeof identifier !== 'string') {
            if (typeof callbacks.failure === 'function') {
                callbacks.failure(new core.InvalidArgumentError('Identifier not specified'));
            }
            return;
        }
        exec(callbacks.success, core._proxyError(callbacks), 'AIQLocalStorage', 'getDocument', [identifier]);
    };

    Storage.prototype.createDocument = function(type, fields, callbacks) {
        callbacks = callbacks || {};
        if (typeof type !== 'string') {
            if (typeof callbacks.failure === 'function') {
                callbacks.failure(new core.InvalidArgumentError('Type not specified'));
            }
            return;
        }
        if (typeof fields !== 'object') {
            if (typeof callbacks.failure === 'function') {
                callbacks.failure(new core.InvalidArgumentError('Fields not specified'));
            }
            return;
        }
        exec(callbacks.success, core._proxyError(callbacks), 'AIQLocalStorage', 'createDocument', [type, fields]);
    };

    Storage.prototype.updateDocument = function(identifier, fields, callbacks) {
        callbacks = callbacks || {};
        if (typeof identifier !== 'string') {
            if (typeof callbacks.failure === 'function') {
                callbacks.failure(new core.InvalidArgumentError('Identifier not specified'));
            }
            return;
        }
        if (typeof fields !== 'object') {
            if (typeof callbacks.failure === 'function') {
                callbacks.failure(new core.InvalidArgumentError('Fields not specified'));
            }
            return;
        }
        exec(callbacks.success, core._proxyError(callbacks), 'AIQLocalStorage', 'updateDocument', [identifier, fields]);
    };

    Storage.prototype.deleteDocument = function(identifier, callbacks) {
        callbacks = callbacks || {};
        if (typeof identifier !== 'string') {
            if (typeof callbacks.failure === 'function') {
                callbacks.failure(new core.InvalidArgumentError('Identifier not specified'));
            }
            return;
        }
        exec(callbacks.success, core._proxyError(callbacks), 'AIQLocalStorage', 'deleteDocument', [identifier]);
    };

    Storage.prototype.getAttachments = function(identifier, callbacks) {
        callbacks = callbacks || {};
        if (typeof identifier !== 'string') {
            if (typeof callbacks.failure === 'function') {
                callbacks.failure(new core.InvalidArgumentError('Identifier not specified'));
            }
            return;
        }
        exec(callbacks.success, core._proxyError(callbacks), 'AIQLocalStorage', 'getAttachments', [identifier]);
    };

    Storage.prototype.getAttachment = function(identifier, name, callbacks) {
        callbacks = callbacks || {};
        if (typeof identifier !== 'string') {
            if (typeof callbacks.failure === 'function') {
                callbacks.failure(new core.InvalidArgumentError('Identifier not specified'));
            }
            return;
        }
        if (typeof name !== 'string') {
            if (typeof callbacks.failure === 'function') {
                callbacks.failure(new core.InvalidArgumentError('Name not specified'));
            }
            return;
        }
        exec(callbacks.success, core._proxyError(callbacks), 'AIQLocalStorage', 'getAttachment', [identifier, name]);
    };

    Storage.prototype.createAttachment = function(identifier, descriptor, callbacks) {
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
        if (typeof descriptor.contentType !== 'string') {
            if (typeof callbacks.failure === 'function') {
                callbacks.failure(new core.InvalidArgumentError('Content type not specified'));
            }
            return;
        }
        if (typeof descriptor.resourceUrl !== 'string') {
            if (typeof callbacks.failure === 'function') {
                callbacks.failure(new core.InvalidArgumentError('Resource not specified'));
            }
            return;
        }
        exec(callbacks.success, core._proxyError(callbacks), 'AIQLocalStorage', 'createAttachment', [identifier, descriptor]);
    };

    Storage.prototype.updateAttachment = function(identifier, name, descriptor, callbacks) {
        callbacks = callbacks || {};
        if (typeof identifier !== 'string') {
            if (typeof callbacks.failure === 'function') {
                callbacks.failure(new core.InvalidArgumentError('Identifier not specified'));
            }
            return;
        }
        if (typeof name !== 'string') {
            if (typeof callbacks.failure === 'function') {
                callbacks.failure(new core.InvalidArgumentError('Name not specified'));
            }
            return;
        }
        if (typeof descriptor !== 'object') {
            if (typeof callbacks.failure === 'function') {
                callbacks.failure(new core.InvalidArgumentError('Descriptor not specified'));
            }
            return;
        }
        if (typeof descriptor.contentType !== 'string') {
            if (typeof callbacks.failure === 'function') {
                callbacks.failure(new core.InvalidArgumentError('Content type not specified'));
            }
            return;
        }
        if (typeof descriptor.resourceUrl !== 'string') {
            if (typeof callbacks.failure === 'function') {
                callbacks.failure(new core.InvalidArgumentError('Resource not specified'));
            }
            return;
        }
        exec(callbacks.success, core._proxyError(callbacks), 'AIQLocalStorage', 'updateAttachment', [identifier, name, descriptor]);
    };

    Storage.prototype.deleteAttachment = function(identifier, name, callbacks) {
        callbacks = callbacks || {};
        if (typeof identifier !== 'string') {
            if (typeof callbacks.failure === 'function') {
                callbacks.failure(new core.InvalidArgumentError('Identifier not specified'));
            }
            return;
        }
        if (typeof name !== 'string') {
            if (typeof callbacks.failure === 'function') {
                callbacks.failure(new core.InvalidArgumentError('Name not specified'));
            }
            return;
        }
        exec(callbacks.success, core._proxyError(callbacks), 'AIQLocalStorage', 'deleteAttachment', [identifier, name]);
    };

    module.exports = new Storage();
});
