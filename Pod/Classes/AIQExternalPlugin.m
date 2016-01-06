#import <AIQCoreLib/AIQError.h>
#import <AIQCoreLib/AIQLog.h>

#import "AIQExternalPlugin.h"

@interface AIQExternalPlugin ()

@property (nonatomic, retain) NSNumberFormatter *formatter;

@end

@implementation AIQExternalPlugin

- (void)openMap:(CDVInvokedUrlCommand *)command {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _formatter = [[NSNumberFormatter alloc] init];
        _formatter.numberStyle = NSNumberFormatterDecimalStyle;
        _formatter.decimalSeparator = @".";
    });

    NSDictionary *settings = [command argumentAtIndex:0 withDefault:nil andClass:[NSDictionary class]];
    if ([self isUndefined:settings[@"latitude"]]) {
        AIQLogCWarn(2, @"Could not open maps, latitude not specified");
        [self failWithErrorCode:AIQErrorInvalidArgument message:@"Latitude not specified" command:command keepCallback:NO];
        return;
    }

    if ([self isUndefined:settings[@"longitude"]]) {
        AIQLogCWarn(2, @"Could not open maps, longitude not specified");
        [self failWithErrorCode:AIQErrorInvalidArgument message:@"Longitude not specified" command:command keepCallback:NO];
        return;
    }

    float latitude = [[settings valueForKey:@"latitude"] floatValue];
    float longitude = [[settings valueForKey:@"longitude"] floatValue];
    NSString *label = [settings valueForKey:@"label"];
    NSString *url = @"https://maps.google.com/maps?";
    if ([self isUndefined:label]) {
        url = [url stringByAppendingFormat:@"ll=%@,%@",
               [_formatter stringFromNumber:@(latitude)],
               [_formatter stringFromNumber:@(longitude)]];
    } else {
        label = [label stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        url = [url stringByAppendingFormat:@"q=%@@%@,%@",
               label,
               [_formatter stringFromNumber:@(latitude)],
               [_formatter stringFromNumber:@(longitude)]];
    }
    if (! [self isUndefined:[settings valueForKey:@"zoom"]]) {
        int zoom = 21 * ([[settings valueForKey:@"zoom"] intValue] / 100.0f);
        url = [url stringByAppendingFormat:@"&z=%d", zoom];
    }
    AIQLogCInfo(2, @"Launching maps");
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];

    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

@end
