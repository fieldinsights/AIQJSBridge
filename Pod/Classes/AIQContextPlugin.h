#import "AIQPlugin.h"

@interface AIQContextPlugin : AIQPlugin

- (void)getGlobal:(CDVInvokedUrlCommand *)command;
- (void)getLocal:(CDVInvokedUrlCommand *)command;
- (void)setLocal:(CDVInvokedUrlCommand *)command;

@end
