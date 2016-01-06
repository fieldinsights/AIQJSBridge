#import <Cordova/CDVPlugin.h>

@interface AIQPlugin : CDVPlugin

- (void)failWithErrorCode:(NSInteger)code message:(NSString *)message command:(CDVInvokedUrlCommand *)command keepCallback:(BOOL)keepCallback;
- (void)failWithErrorCode:(NSInteger)code message:(NSString *)message args:(NSDictionary *)args command:(CDVInvokedUrlCommand *)command keepCallback:(BOOL)keepCallback;
- (void)failWithError:(NSError *)error command:(CDVInvokedUrlCommand *)command;

- (BOOL)isUndefined:(id)object;

@end
