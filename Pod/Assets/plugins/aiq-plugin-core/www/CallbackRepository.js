cordova.define('aiq-plugin-core-callback-repository', function(require, exports, module) {
    var channel = require('cordova/channel');
    var exec = require('cordova/exec');


    function CallbackRepository(parent) {
        this._parent = parent;
        this._events = {};
    }

    CallbackRepository.prototype._externalToInternal = function(external) {
        var internal = 'onAiq' + this._parent.constructor.name;
        external.split('-').forEach(function(segment) {
            internal += segment.substr(0, 1).toUpperCase() + segment.substr(1);
        });
        return internal;
    };

    CallbackRepository.prototype.subscribeToEvent = function(name, key, values) {
        var internalName = this._externalToInternal(name);
        var that = this;
        channel.create(internalName).subscribe(function(event) {
            var properties = that._events[name] || {};
            var propertyName = (key ? event[key] : '__global');
            if (! properties.hasOwnProperty(propertyName)) {
                return;
            }
            var args = [];
            if (values) {
                values.forEach(function(value) {
                    args.push(event[value]);
                });
            }
            properties[propertyName].forEach(function(callback) {
                callback.apply(undefined, args);
            });
        });
    };

    CallbackRepository.prototype.registerCallback = function(name, key, callback) {
        var that = this;
        exec(function() {
            var properties = that._events[name] || {};
            var propertyName = key || '__global';
            var callbacks = properties[propertyName] || [];
            callbacks.push(callback);
            properties[propertyName] = callbacks;
            that._events[name] = properties;
        }, function(error) {
            console.warn('Could not register callback for event ' + name + ': ' + error.message);
        }, 'AIQCore', 'registerCallback', [this._externalToInternal(name)]);
    };

    CallbackRepository.prototype.unregisterCallback = function(events, callback, keys) {
        events = events || Object.keys(this._events);
        var that = this;
        events.forEach(function(name) {
            var properties = that._events[name];
            if (! properties) {
                console.warn('Event ' + name + ' not registered');
                return;
            }
            var count = 0;
            Object.keys(properties).forEach(function(property) {
                if ((keys.length === 0) || (keys.indexOf(property) !== -1)) {
                    if (typeof callback === 'function') {
                        var callbacks = properties[property];
                        var index;
                        while ((index = callbacks.indexOf(callback)) !== -1) {
                            callbacks.splice(index, 1);
                            count += 1;
                        }
                        if (callbacks.length === 0) {
                            delete properties[property];
                        } else {
                            properties[property] = callbacks;
                        }
                    } else {
                        count += properties[property].length;
                        delete properties[property];
                    }
                }
            });
            if (Object.keys(properties).length === 0) {
                delete that._events[name];
            }
            exec(undefined, function(error) {
                console.warn('Could not unregister callback for event ' + name + ': ' + error.message);
            }, 'AIQCore', 'unregisterCallback', [that._externalToInternal(name), count]);
        });
    };

    module.exports = CallbackRepository;
});
