cordova.define('aiq-plugin-core', function(require, exports, module) {
    var exec = require('cordova/exec');
    var channel = require('cordova/channel');

    channel.onAIQReady = cordova.addStickyDocumentEventHandler('aiq-ready');

    function Core() {
        this.version = '1.4.0';

        var createError = function(name, ParentError) {
            var constructor = function(message) {
                this.name = name + 'Error';
                this.message = message;
            };
            constructor.prototype = new ParentError();
            constructor.prototype.constructor = constructor;
            return constructor;
        };                                                                                                                                                                                   

        this.AIQError = createError('AIQ', Error);
        this.NotFoundError = createError('NotFound', this.AIQError);
        this.IdNotFoundError = createError('IdNotFound', this.NotFoundError);
        this.NameNotFoundError = createError('NameNotFound', this.NotFoundError);
        this.ResourceNotFoundError = createError('ResourceNotFound', this.NotFoundError);
        this.InvalidArgumentError = createError('InvalidArgument', this.AIQError);
        this.ConnectionError = createError('Connection', this.AIQError);
        this.ContainerError = createError('Container', this.AIQError);
        this.OutOfMemoryError = createError('OutOfMemory', this.ContainerError);

        channel.onCordovaReady.subscribe(function() {
            window.addEventListener('hashchange', function() {
                exec(undefined, undefined, 'AIQCore', 'hashChanged', [window.location.hash]);
            }, false);

            // Fire events registered before the channel was created
            var event = document.createEvent('Events');
            event.initEvent('aiq-ready', false, false);
            document.dispatchEvent(event);

            // Wake all channel subscribers
            channel.onAIQReady.fire();
        });
    }

    Core.prototype._proxyError = function(callbacks) {
        var that = this;
        return function(descriptor) {
            if (typeof callbacks.failure === 'function') {
                var ErrorClass;
                if (descriptor.internal) {
                    if (descriptor.code === 1) {
                        ErrorClass = that.IdNotFoundError;
                    } else if (descriptor.code === 2) {
                        ErrorClass = that.NameNotFoundError;
                    } else if (descriptor.code === 3) {
                        ErrorClass = that.ResourceNotFoundError;
                    } else if (descriptor.code === 4) {
                        ErrorClass = that.InvalidArgumentError;
                    } else if (descriptor.code === 5) {
                        ErrorClass = that.ConnectionError;
                    } else if (descriptor.code === 6) {
                        ErrorClass = that.ContainerError;
                    } else if (descriptor.code === 7) {
                        ErrorClass = that.OutOfMemoryError;
                    } else {
                        ErrorClass = that.AIQError;
                    }
                } else {
                    ErrorClass = Error;
                }
                var error = new ErrorClass(descriptor.message);
                Object.keys(descriptor.args).forEach(function(key) {
                    error[key] = descriptor.args[key];
                });
                callbacks.failure.call(callbacks, error);
            }
        };
    };

    module.exports = new Core();
});
