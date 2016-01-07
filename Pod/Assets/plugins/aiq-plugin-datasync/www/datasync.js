cordova.define('aiq-plugin-datasync', function(require, exports, module) {
    var exec = require('cordova/exec');
    var core = require('aiq-plugin-core');

    function DataSync() {
        var CallbackRepository = require('aiq-plugin-core-callback-repository');
        this._callbackRepository = new CallbackRepository(this);
        
        this._callbackRepository.subscribeToEvent('document-created', '_type', ['_id']);
        this._callbackRepository.subscribeToEvent('document-updated', '_type', ['_id']);
        this._callbackRepository.subscribeToEvent('document-deleted', '_type', ['_id']);
        this._callbackRepository.subscribeToEvent('document-synchronized', '_type', ['_id']);
        this._callbackRepository.subscribeToEvent('document-rejected', '_type', ['_id']);
        this._callbackRepository.subscribeToEvent('synchronization-complete');
        this._callbackRepository.subscribeToEvent('connection-status-changed', undefined, ['_status']);
        this._callbackRepository.subscribeToEvent('attachment-available', '_id', ['_id', '_name']);
        this._callbackRepository.subscribeToEvent('attachment-unavailable', '_id', ['_id', '_name']);
        this._callbackRepository.subscribeToEvent('attachment-failed', '_id', ['_id', '_name']);
        this._callbackRepository.subscribeToEvent('attachment-synchronized', '_id', ['_id', '_name']);
        this._callbackRepository.subscribeToEvent('attachment-rejected', '_id', ['_id', '_name']);
        

        this.PERMISSION_DENIED = "PERMISSION_DENIED";
        this.DOCUMENT_NOT_FOUND = "DOCUMENT_NOT_FOUND";
        this.DOCUMENT_TYPE_NOT_FOUND = "DOCUMENT_TYPE_NOT_FOUND";
        this.RESTRICTED_DOCUMENT_TYPE = "RESTRICTED_DOCUMENT_TYPE";
        this.CREATE_CONFLICT = "CREATE_CONFLICT";
        this.UPDATE_CONFLICT = "UPDATE_CONFLICT";
        this.LARGE_ATTACHMENT = "LARGE_ATTACHMENT";
        this.UNKNOWN_REASON = "UNKNOWN_REASON";
    }

    DataSync.prototype.getDocuments = function(type, settings) {
        settings = settings || {};

        if (typeof type !== 'string') {
            if (typeof settings.failure === 'function') {
                settings.failure(new core.InvalidArgumentError('Type not specified'));
            }
            return;
        }
        
        exec(settings.success, core._proxyError(settings), 'AIQDataSync', 'getDocuments', [type, settings.filter]);
    };

    DataSync.prototype.getDocument = function(identifier, callbacks) {
        callbacks = callbacks || {};

        if (typeof identifier !== 'string') {
            if (typeof callbacks.failure === 'function') {
                callbacks.failure(new core.InvalidArgumentError('Identifier not specified'));
            }
            return;
        }
        
        exec(callbacks.success, core._proxyError(callbacks), 'AIQDataSync', 'getDocument', [identifier]);
    };

    DataSync.prototype.createDocument = function(type, fields, callbacks) {
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
        
        exec(callbacks.success, core._proxyError(callbacks), 'AIQDataSync', 'createDocument', [type, fields]);
    };

    DataSync.prototype.updateDocument = function(identifier, fields, callbacks) {
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
        
        exec(callbacks.success, core._proxyError(callbacks), 'AIQDataSync', 'updateDocument', [identifier, fields]);
    };

    DataSync.prototype.deleteDocument = function(identifier, callbacks) {
        callbacks = callbacks || {};

        if (typeof identifier !== 'string') {
            if (typeof callbacks.failure === 'function') {
                callbacks.failure(new core.InvalidArgumentError('Identifier not specified'));
            }
            return;
        }
        
        exec(callbacks.success, core._proxyError(callbacks), 'AIQDataSync', 'deleteDocument', [identifier]);
    };

    DataSync.prototype.getAttachments = function(identifier, callbacks) {
        callbacks = callbacks || {};

        if (typeof identifier !== 'string') {
            if (typeof callbacks.failure === 'function') {
                callbacks.failure(new core.InvalidArgumentError('Identifier not specified'));
            }
            return;
        }
        
        exec(callbacks.success, core._proxyError(callbacks), 'AIQDataSync', 'getAttachments', [identifier]);
    };

    DataSync.prototype.getAttachment = function(identifier, name, callbacks) {
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
        
        exec(callbacks.success, core._proxyError(callbacks), 'AIQDataSync', 'getAttachment', [identifier, name]);
    };

    DataSync.prototype.createAttachment = function(identifier, descriptor, callbacks) {
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
        
        exec(callbacks.success, core._proxyError(callbacks), 'AIQDataSync', 'createAttachment', [identifier, descriptor]);
    };

    DataSync.prototype.updateAttachment = function(identifier, name, descriptor, callbacks) {
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
        
        exec(callbacks.success, core._proxyError(callbacks), 'AIQDataSync', 'updateAttachment', [identifier, name, descriptor]);
    };

    DataSync.prototype.deleteAttachment = function(identifier, name, callbacks) {
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
        
        exec(callbacks.success, core._proxyError(callbacks), 'AIQDataSync', 'deleteAttachment', [identifier, name]);
    };

    DataSync.prototype.bind = function(event, settings) {
        if (typeof event !== 'string') {
            console.warn('aiq.datasync.bind() failed (event must be a string)');
            return;
        }
        if (typeof settings !== 'object') {
            console.warn('aiq.datasync.bind() failed (settings must be an object)');
            return;
        }
        if (typeof settings.callback !== 'function') {
            console.warn('aiq.datasync.bind() failed (settings.callback must be a function)');
            return;
        }

        var that = this;

        if (event.indexOf('document-') === 0) {
            // document event
            if (typeof settings._type !== 'string') {
                console.warn('aiq.datasync.bind() failed (settings._type must be a string)');
                return;
            }
            this._callbackRepository.registerCallback(event, settings._type, settings.callback);
        } else if (event.indexOf('attachment-') === 0) {
            // attachment event
            if (typeof settings._id !== 'string') {
                console.warn('aiq.datasync.bind() failed (setting._id must be a string)');
                return;
            }
            if (typeof settings.name === 'string') {
                this._callbackRepository.registerCallback(event, settings._id + ':' + settings.name, settings.callback);
            } else {
                this._callbackRepository.registerCallback(event, settings._id, settings.callback);
            }
        } else {
            this._callbackRepository.registerCallback(event, undefined, settings.callback);
        }
    };

    DataSync.prototype.bindDocumentEvent = function(event, type, callback) {
        console.warn('aiq.datasync.bindDocumentEvent() is deprecated, use aiq.datasync.bind() instead');
        this.bind(event, {
            _type: type,
            callback: callback
        });
    };

    DataSync.prototype.bindAttachmentEvent = function(event, id, name, callback) {
        console.warn('aiq.datasync.bindAttachmentEvent() is deprecated, use aiq.datasync.bind() instead');
        this.bind(event, {
            _id: id,
            name: name,
            callback: callback
        });
    };

    DataSync.prototype.bindEvent = function(event, callback) {
        console.warn('aiq.datasync.bindEvent() is deprecated, use aiq.datasync.bind() instead');
        this.bind(event, {
            callback: callback
        });
    };

    DataSync.prototype.unbind = function(callbackOrEvent, settingsOrNil) {
        if (typeof callbackOrEvent === 'function') {
            // the old way, callback only
            console.warn('aiq.datasync.unbind(callback) is deprecated, use aiq.datasync.unbind(event, [settings]) instead');
            this._callbackRepository.unregisterCallback(undefined, callbackOrEvent, []);
        } else if (typeof callbackOrEvent === 'string') {
            // the new way, event name plus optional map of additional arguments
            settingsOrNil = settingsOrNil || {};
            var callback = settingsOrNil.callback;
            var keys = [];
            if (typeof settingsOrNil._id === 'string') {
                keys.push(settingsOrNil._id);
            }
            if (typeof settingsOrNil._type === 'string') {
                keys.push(settingsOrNil._type);
            }
            this._callbackRepository.unregisterCallback([callbackOrEvent], callback, keys);
        }
    };

    DataSync.prototype.synchronize = function() {
        exec(undefined, undefined, 'AIQDataSync', 'synchronize', []);
    };

    module.exports = new DataSync();
});
