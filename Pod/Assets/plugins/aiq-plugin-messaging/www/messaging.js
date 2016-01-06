cordova.define('aiq-plugin-messaging', function(require, exports, module) {
    var exec = require('cordova/exec');
    var core = require('aiq-plugin-core');

    function Messaging() {
        var CallbackRepository = require('aiq-plugin-core-callback-repository');
        this._callbackRepository = new CallbackRepository(this);
        
        this._callbackRepository.subscribeToEvent('message-received', 'type', ['_id']);
        this._callbackRepository.subscribeToEvent('message-updated', 'type', ['_id']);
        this._callbackRepository.subscribeToEvent('message-expired', 'type', ['_id']);
        this._callbackRepository.subscribeToEvent('attachment-available', '_id', ['_id', '_name']);
        this._callbackRepository.subscribeToEvent('attachment-unavailable', '_id', ['_id', '_name']);
        this._callbackRepository.subscribeToEvent('attachment-failed', '_id', ['_id', '_name']);
        this._callbackRepository.subscribeToEvent('message-queued', '_destination', ['_id', '_destination']);
        this._callbackRepository.subscribeToEvent('message-accepted', '_destination', ['_id', '_destination']);
        this._callbackRepository.subscribeToEvent('message-rejected', '_destination', ['_id', '_destination']);
        this._callbackRepository.subscribeToEvent('message-delivered', '_destination', ['_id', '_destination']);
        this._callbackRepository.subscribeToEvent('message-failed', '_destination', ['_id', '_destination']);
    }

    Messaging.prototype._clean = function(callback) {
        if (typeof callback === 'function') {
            callback();
        }
    };

    Messaging.prototype.getAttachment = function(identifier, name, callbacks) {
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
        
        exec(callbacks.success, core._proxyError(callbacks), 'AIQMessaging', 'getAttachment', [identifier, name]);
    };
    
    Messaging.prototype.getAttachments = function(identifier, callbacks) {
        callbacks = callbacks || {};

        if (typeof identifier !== 'string') {
            if (typeof callbacks.failure === 'function') {
                callbacks.failure(new core.InvalidArgumentError('Identifier not specified'));
            }
            return;
        }
        
        exec(callbacks.success, core._proxyError(callbacks), 'AIQMessaging', 'getAttachments', [identifier]);
    };

    Messaging.prototype.getMessage = function(identifier, callbacks) {
        callbacks = callbacks || {};

        if (typeof identifier !== 'string') {
            if (typeof callbacks.failure === 'function') {
                callbacks.failure(new core.InvalidArgumentError('Identifier not specified'));
            }
            return;
        }
        
        exec(callbacks.success, core._proxyError(callbacks), 'AIQMessaging', 'getMessage', [identifier]);
    };

    Messaging.prototype.getMessages = function(type, settings) {
        settings = settings || {};

        if (typeof type !== 'string') {
            if (typeof settings.failure === 'function') {
                settings.failure(new core.InvalidArgumentError('Type not specified'));
            }
            return;
        }

        if (typeof settings.withPayload !== 'boolean') {
            settings.withPayload = true;
        }
        
        exec(settings.success,
             core._proxyError(settings),
             'AIQMessaging',
             'getMessages',
             [type, settings.withPayload, settings.filter]);
    };

    Messaging.prototype.markMessageAsRead = function(identifier, callbacks) {
        callbacks = callbacks || {};

        if (typeof identifier !== 'string') {
            if (typeof callbacks.failure === 'function') {
                callbacks.failure(new core.InvalidArgumentError('Identifier not specified'));
            }
            return;
        }

        exec(function() {
            if (typeof callbacks.success === 'function') {
                callbacks.success();
            }
        }, core._proxyError(callbacks), 'AIQMessaging', 'markMessageAsRead', [identifier]);
    };

    Messaging.prototype.deleteMessage = function(identifier, callbacks) {
        callbacks = callbacks || {};

        if (typeof identifier !== 'string') {
            if (typeof callbacks.failure === 'function') {
                callbacks.failure(new core.InvalidArgumentError('Identifier not specified'));
            }
            return;
        }
        
        exec(callbacks.success, core._proxyError(callbacks), 'AIQMessaging', 'deleteMessage', [identifier]);
    };

    Messaging.prototype.sendMessage = function(descriptor, attachmentsOrCallbacks, callbacksOrNil) {
        var attachments;
        var callbacks;
        if ((attachmentsOrCallbacks instanceof Array) || (typeof callbacksOrNil === 'object')) {
            attachments = attachmentsOrCallbacks || [];
            callbacks = callbacksOrNil || {};
        } else {
            attachments = [];
            callbacks = attachmentsOrCallbacks || {};
        }
        callbacks = callbacks || {};

        if (typeof descriptor !== 'object') {
            if (typeof callbacks.failure === 'function') {
                callbacks.failure(new core.InvalidArgumentError('Descriptor not specified'));
            }
            return;
        }

        if (typeof descriptor.destination !== 'string') {
            if (typeof callbacks.failure === 'function') {
                callbacks.failure(new core.InvalidArgumentError('Destination not specified'));
            }
            return;
        }

        if (typeof descriptor.payload === 'undefined') {
            if (typeof callbacks.failure === 'function') {
                callbacks.failure(new core.InvalidArgumentError('Payload not specified'));
            }
            return;
        }

        if (typeof descriptor.urgent !== 'boolean') {
            descriptor.urgent = false;
        }

        if (typeof descriptor.expectResponse !== 'boolean') {
            descriptor.expectResponse = true;
        }

        if (attachments instanceof Array) {
            var failed = attachments.some(function(attachment) {
                if (typeof attachment.contentType !== 'string') {
                    if (typeof callbacks.failure === 'function') {
                        callbacks.failure(new core.InvalidArgumentError('Content type not specified'));
                    }
                    return true;
                }
                
                if (typeof attachment.resourceUrl !== 'string') {
                    if (typeof callbacks.failure === 'function') {
                        callbacks.failure(new core.InvalidArgumentError('Resource not specified'));
                    }
                    return true;
                }

                return false;
            });

            if (failed) {
                return;
            }
        }
        
        exec(callbacks.success, core._proxyError(callbacks), 'AIQMessaging', 'sendMessage', [descriptor.destination, descriptor.payload, attachments, descriptor.urgent, descriptor.expectResponse]);
    };
    
    Messaging.prototype.getMessageStatus = function(identifier, callbacks) {
        callbacks = callbacks || {};

        if (typeof identifier !== 'string') {
            if (typeof callbacks.failure === 'function') {
                callbacks.failure(new core.InvalidArgumentError('Identifier not specified'));
            }
            return;
        }
        
        exec(callbacks.success, core._proxyError(callbacks), 'AIQMessaging', 'getMessageStatus', [identifier]);
    };

    Messaging.prototype.getMessageStatuses = function(destination, settings) {
        settings = settings || {};

        if (typeof destination !== 'string') {
            if (typeof settings.failure === 'function') {
                settings.failure(new core.InvalidArgumentError('Destination not specified'));
            }
            return;
        }
        
        exec(settings.success, core._proxyError(settings), 'AIQMessaging', 'getMessageStatuses', [destination, settings.filter]);
    };

    Messaging.prototype.bind = function(event, callbacks) {
        if (typeof event !== 'string') {
            return;
        }
        if (typeof callbacks !== 'object') {
            return;
        }
        if (typeof callbacks.callback !== 'function') {
            return;
        }

        var that = this;
        
        if (['message-received', 'message-updated', 'message-expired'].indexOf(event) !== -1) {
            // SO message event
            if (typeof callbacks._id === 'string') {
                this._callbackRepository.registerCallback(event, callbacks._id, callbacks.callback);
            } else if (typeof callbacks.type === 'string') {
                this._callbackRepository.registerCallback(event, callbacks.type, callbacks.callback);
            }
        } else if (['message-queued', 'message-accepted', 'message-rejected', 'message-delivered', 'message-failed'].indexOf(event) !== -1) {
            // CO message event
            if (typeof callbacks.destination !== 'string') {
                return;
            }
            this._callbackRepository.registerCallback(event, callbacks.destination, callbacks.callback);
        } else if (['attachment-available', 'attachment-unavailable', 'attachment-failed'].indexOf(event) !== -1) {
            // SO attachment event
            if (typeof callbacks._id !== 'string') {
                return;
            }
            this._callbackRepository.registerCallback(event, callbacks._id, callbacks.callback);
        }
    };

    Messaging.prototype.bindMessageEvent = function(event, typeOrDestination, callback) {
        console.warn('aiq.messaging.bindMessageEvent() is deprecated, use aiq.messaging.bind() instead');
        this.bind(event, {
            type: typeOrDestination,
            destination: typeOrDestination,
            callback: callback
        });
    };

    Messaging.prototype.unbind = function(callbackOrEvent, settingsOrNil) {
        if (typeof callbackOrEvent === 'function') {
            // the old way, callback only
            console.warn('aiq.messaging.unbind(callback) is deprecated, use aiq.messaging.unbind(event, [callbacks]) instead');
            this._callbackRepository.unregisterCallback(undefined, callbackOrEvent, []);
        } else if (typeof callbackOrEvent === 'string') {
            // the new way, event name plus optional map of additional arguments
            settingsOrNil = settingsOrNil || {};
            var callback = settingsOrNil.callback;
            var keys = [];
            if (typeof settingsOrNil._id === 'string') {
                keys.push(settingsOrNil._id);
            }
            if (typeof settingsOrNil.type === 'string') {
                keys.push(settingsOrNil.type);
            }
            if (typeof settingsOrNil.destination === 'string') {
                keys.push(settingsOrNil.destination);
            }
            this._callbackRepository.unregisterCallback([callbackOrEvent], callback, keys);
        }
    };

    module.exports = new Messaging();
});
