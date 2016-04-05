#import "AIQPlugin.h"

@interface AIQImagingPlugin : AIQPlugin

- (void)capture:(CDVInvokedUrlCommand *)command;
- (void)edit:(CDVInvokedUrlCommand *)command;

@end
