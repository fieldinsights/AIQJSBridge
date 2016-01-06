#import <AIQCoreLib/AIQLog.h>

#import "AIQCorePlugin.h"
#import "AIQLaunchableViewController.h"
#import "AIQJSBridgeInternal.h"

@interface AIQLaunchableViewController ()

- (void)hashChangedTo:(NSString *)hash;
- (BOOL)callbackRegisteredForEvent:(NSString *)event error:(NSError **)error;
- (BOOL)callbackUnregisteredForEvent:(NSString *)event count:(NSUInteger)count error:(NSError **)error;

@end

@implementation AIQCorePlugin

- (void)registerCallback:(CDVInvokedUrlCommand *)command {
    NSString *event = [command argumentAtIndex:0];

    AIQLogCInfo(2, @"Registering callback for %@", event);
    NSError *error = nil;
    if (! [(AIQLaunchableViewController *)self.viewController callbackRegisteredForEvent:event error:&error]) {
        AIQLogCError(2, @"Failed to register callback for %@: %@", event, error.localizedDescription);
        [self failWithError:error command:command];
        return;
    }

    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

- (void)unregisterCallback:(CDVInvokedUrlCommand *)command {
    NSString *event = [command argumentAtIndex:0];
    NSUInteger count = [[command argumentAtIndex:1 withDefault:@(1)] integerValue];
    
    AIQLogCInfo(2, @"Unregistering callback for %@", event);
    NSError *error = nil;
    if (! [(AIQLaunchableViewController *)self.viewController callbackUnregisteredForEvent:event count:count error:&error]) {
        AIQLogCError(2, @"Failed to unregister callback for %@: %@", event, error.localizedDescription);
        [self failWithError:error command:command];
        return;
    }

    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

- (void)hashChanged:(CDVInvokedUrlCommand *)command {
    [(AIQLaunchableViewController *)self.viewController hashChangedTo:[command argumentAtIndex:0]];

    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

@end
