#import "AIQPlugin.h"

@interface AIQCorePlugin : AIQPlugin

- (void)registerCallback:(CDVInvokedUrlCommand *)command;
- (void)unregisterCallback:(CDVInvokedUrlCommand *)command;
- (void)hashChanged:(CDVInvokedUrlCommand *)command;

@end
