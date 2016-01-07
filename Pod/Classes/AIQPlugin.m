#import <AIQCoreLib/AIQError.h>

#import "AIQPlugin.h"

@implementation AIQPlugin

- (void)failWithErrorCode:(NSInteger)code message:(NSString *)message command:(CDVInvokedUrlCommand *)command keepCallback:(BOOL)keepCallback {
    [self failWithErrorCode:code message:message args:nil command:command keepCallback:keepCallback];
}

- (void)failWithErrorCode:(NSInteger)code message:(NSString *)message args:(NSDictionary *)args command:(CDVInvokedUrlCommand *)command keepCallback:(BOOL)keepCallback {
    if (! args) {
        args = @{};
    }
    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:@{@"internal": @YES,
                                                                                                             @"code": @(code),
                                                                                                             @"message": message ? message : [NSNull null],
                                                                                                             @"args": args}];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

- (void)failWithError:(NSError *)error command:(CDVInvokedUrlCommand *)command {
    id message = (error && error.localizedDescription) ? error.localizedDescription : [NSNull null];
    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:@{@"internal": @(error.domain == AIQErrorDomain),
                                                                                                             @"code": @(error.code),
                                                                                                             @"message": message,
                                                                                                             @"args": @{}}];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

- (BOOL)isUndefined:(id)object {
    if (! object) {
        return YES;
    }
    if ([object isEqual:[NSNull null]]) {
        return YES;
    }
    return NO;
}

@end
