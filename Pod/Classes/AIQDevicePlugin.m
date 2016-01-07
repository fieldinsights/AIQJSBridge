#import <Reachability/Reachability.h>

#import "AIQDevicePlugin.h"

@implementation AIQDevicePlugin

- (void)getNetworkInfo:(CDVInvokedUrlCommand *)command {
    NetworkStatus status = [[Reachability reachabilityForInternetConnection] currentReachabilityStatus];
    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:(status != NotReachable)];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

@end
