#import <AIQCoreLib/AIQDirectCall.h>
#import <AIQCoreLib/AIQError.h>
#import <AIQCoreLib/AIQLog.h>
#import <AIQCoreLib/AIQJSON.h>
#import <AIQCoreLib/AIQSession.h>

#import "AIQDirectCallPlugin.h"
#import "AIQLaunchableViewController.h"

@interface AIQDirectCallPlugin () <AIQDirectCallDelegate>

/* What a cool assemblery-sounding name! */
@property (nonatomic, retain) NSMutableDictionary *callRegister;

@end

@implementation AIQDirectCallPlugin

- (void)pluginInitialize {
    [super pluginInitialize];
    self.callRegister = [NSMutableDictionary dictionary];
}

- (void)call:(CDVInvokedUrlCommand *)command {
    NSString *method = [[command argumentAtIndex:0 withDefault:nil andClass:[NSString class]] uppercaseString];
    if (! method) {
        AIQLogCInfo(2, @"No method specified, falling back to GET");
        method = @"GET";
    }

    NSDictionary *descriptor = [command argumentAtIndex:1 withDefault:nil andClass:[NSDictionary class]];
    if (! descriptor) {
        AIQLogCWarn(2, @"Descriptor not specified");
        [self failWithErrorCode:AIQErrorInvalidArgument message:@"Descriptor not specified" command:command keepCallback:NO];
        return;
    }

    NSString *endpoint = descriptor[@"endpoint"];

    AIQLogCInfo(2, @"Performing %@ to %@", method, endpoint);

    NSError *error = nil;
    NSString *solution = ((AIQLaunchableViewController *)self.viewController).solution;
    AIQDirectCall *call = [[AIQSession currentSession] directCallForSolution:solution endpoint:endpoint error:&error];
    if (! call) {
        [self failWithError:error command:command];
        return;
    }

    call.method = method;
    call.parameters = descriptor[@"params"];
    call.headers = descriptor[@"headers"];

    id body = descriptor[@"body"];
    NSString *resourceUrl = descriptor[@"resourceUrl"];
    if (((! [self isUndefined:body]) || (! [self isUndefined:resourceUrl])) && (([method isEqualToString:@"GET"]) || ([method isEqualToString:@"DELETE"]))) {
        AIQLogCWarn(2, @"Body argument not allowed in %@ method", method);
        [self failWithErrorCode:AIQErrorInvalidArgument message:@"Body not allowed" command:command keepCallback:NO];
        return;
    }

    if (! [self isUndefined:body]) {
        if ([body isKindOfClass:[NSString class]]) {
            call.contentType = @"text/plain";
            call.body = [body dataUsingEncoding:NSUTF8StringEncoding];
        } else if ([body isKindOfClass:[NSNumber class]]) {
            call.contentType = @"text/plain";
            call.body = [[body stringValue] dataUsingEncoding:NSUTF8StringEncoding];
        } else if (([body isKindOfClass:[NSArray class]]) || ([body isKindOfClass:[NSDictionary class]])) {
            call.contentType = @"application/json";
            call.body = [body JSONData];
        }
    } else {
        if (! [self isUndefined:resourceUrl]) {
            call.contentType = descriptor[@"contentType"];
            if (! call.contentType) {
                call.contentType = @"application/octet-stream";
            }

            NSFileManager *fileManager = [NSFileManager defaultManager];
            NSString *path = [((AIQLaunchableViewController *)self.viewController).path stringByAppendingPathComponent:resourceUrl];
            if ([fileManager fileExistsAtPath:path]) {
                call.body = [fileManager contentsAtPath:path];
            } else {
                call.body = [NSData dataWithContentsOfURL:[NSURL URLWithString:resourceUrl]];
            }
            if (! call.body) {
                AIQLogCWarn(2, @"Resource not specified");
                [self failWithErrorCode:AIQErrorInvalidArgument message:@"Resource not specified" command:command keepCallback:NO];
                return;
            }
        }
    }
    call.delegate = self;
    self.callRegister[@(call.hash)] = command;
    [call start];
}

#pragma mark - AIQDirectCallDelegate

- (void)directCall:(AIQDirectCall *)directCall didFinishWithStatus:(NSInteger)status headers:(NSDictionary *)headers andData:(NSData *)data {
    AIQLogCInfo(2, @"Did finish loading");
    
    CDVInvokedUrlCommand *command = [self commandForDirectCall:directCall];

    NSString *contentType = [headers valueForKey:@"Content-Type"];
    NSDictionary *arg = @{@"contentType": contentType, @"status": @(status), @"headers": headers};

    if ([contentType hasPrefix:@"application/json"]) {
        // parse JSON response
        id object = [data JSONObject];

        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsMultipart:@[object, arg]];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    } else if ([contentType hasPrefix:@"text/"]) {
        NSString *text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsMultipart:@[text, arg]];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    } else {
        NSString *name = [[NSUUID UUID] UUIDString];
        NSString *folder = [NSString stringWithFormat:@"%02lX", (long)[[AIQSession currentSession] sessionId].hash];
        NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:folder];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSError *error = nil;
        if (! [fileManager fileExistsAtPath:path]) {
            [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error];
        }
        [data writeToFile:[path stringByAppendingPathComponent:name] options:NSDataWritingFileProtectionNone error:&error];
        NSString *resourceUrl = [NSString stringWithFormat:@"aiq-resource://resource?id=%@&contentType=%@&folder=%@", name, contentType, folder];

        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsMultipart:@[resourceUrl, arg]];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    }
}

- (void)directCall:(AIQDirectCall *)directCall didFailWithError:(NSError *)error headers:(NSDictionary *)headers andData:(NSData *)data {
    AIQLogCWarn(2, @"Did fail with error: %@", error.localizedDescription);
    
    CDVInvokedUrlCommand *command = [self commandForDirectCall:directCall];

    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];

    if (error.code == AIQErrorConnectionFault) {
        NSNumber *status = [error.userInfo valueForKey:AIQDirectCallStatusCodeKey];
        if (status) {
            if (status.integerValue == AIQErrorUnauthorized) {
                AIQLogCWarn(2, @"Access token has expired");
                if (! [[AIQSession currentSession] close:&error]) {
                    AIQLogCError(2, @"Could not close session: %@", error.localizedDescription);
                    abort();
                }
                return;
            }
            
            dictionary[@"errorCode"] = status;
        }

        if (headers) {
            dictionary[@"headers"] = headers;

            NSString *contentType = headers[@"Content-Type"];
            if (contentType) {
                dictionary[@"contentType"] = contentType;
                
                if ([contentType hasPrefix:@"text/"]) {
                    dictionary[@"body"] = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                } else if ([contentType isEqualToString:@"application/json"]) {
                    dictionary[@"body"] = [data JSONObject];
                } else {
                    // create temporary file
                    NSString *name = [[NSUUID UUID] UUIDString];
                    NSError *error = nil;
                    NSString *folder = [NSString stringWithFormat:@"%02lX", (long)[[AIQSession currentSession] sessionId].hash];
                    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:folder];
                    NSFileManager *fileManager = [NSFileManager defaultManager];
                    if (! [fileManager fileExistsAtPath:path]) {
                        [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error];
                    }
                    [data writeToFile:[path stringByAppendingPathComponent:name] options:NSDataWritingFileProtectionNone error:nil];
                    dictionary[@"resourceUrl"] = [NSString stringWithFormat:@"aiq-resource://resource?id=%@&contentType=%@&folder=%@", name, contentType, folder];
                }
            }
        }
    }

    [self failWithErrorCode:error.code message:error.localizedDescription args:dictionary command:command keepCallback:NO];
}

- (void)directCallDidCancel:(AIQDirectCall *)directCall {
    AIQLogCInfo(2, @"Did cancel");
    
    CDVInvokedUrlCommand *command = [self commandForDirectCall:directCall];

    [self failWithErrorCode:AIQErrorConnectionFault message:@"Request cancelled" args:@{@"errorCode": @-1} command:command keepCallback:NO];
}

#pragma mark - Private API

- (CDVInvokedUrlCommand *)commandForDirectCall:(AIQDirectCall *)call {
    NSNumber *hash = @(call.hash);
    CDVInvokedUrlCommand *command = self.callRegister[hash];
    [self.callRegister removeObjectForKey:hash];
    return command;
}

@end
