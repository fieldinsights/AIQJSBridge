#import <AIQCoreLib/AIQContext.h>
#import <AIQCoreLib/AIQError.h>
#import <AIQCoreLib/AIQLog.h>
#import <AIQCoreLib/AIQSession.h>

#import "AIQContextPlugin.h"

@implementation AIQContextPlugin

- (void)getGlobal:(CDVInvokedUrlCommand *)command {
    NSError *error = nil;
    AIQContext *context = [[AIQSession currentSession] context:&error];
    if (! context) {
        AIQLogCError(2, @"Error retrieving context: %@", error.localizedDescription);
        [self failWithError:error command:command];
        return;
    }

    NSString *providerName = [command argumentAtIndex:0 withDefault:nil andClass:[NSString class]];

    AIQLogCInfo(2, @"Retrieving global context for provider %@", providerName);

    id value = [context valueForName:providerName error:&error];
    if (value) {
        AIQLogCInfo(2, @"Global context found for provider %@", providerName);
    } else {
        AIQLogCWarn(2, @"No global context for provider %@", providerName);
        [self failWithError:error command:command];
        return;
    }

    [self.commandDelegate sendPluginResult:[self resultFromValue:value] callbackId:command.callbackId];
}

- (void)getLocal:(CDVInvokedUrlCommand *)command {
    NSError *error = nil;
    AIQContext *context = [[AIQSession currentSession] context:&error];
    if (! context) {
        AIQLogCError(2, @"Error retrieving context: %@", error.localizedDescription);
        [self failWithError:error command:command];
        return;
    }

    NSString *key = [command argumentAtIndex:0 withDefault:nil andClass:[NSString class]];

    AIQLogCInfo(2, @"Retrieving local context for key %@", key);
    id value = [context valueForName:@"com.appearnetworks.aiq.apps" error:&error];
    if (! value) {
        AIQLogCWarn(2, @"Could not retrieve local context for key %@: %@", key, error.localizedDescription);
        [self failWithError:error command:command];
        return;
    }

    value = [(NSDictionary *)value valueForKey:key];
    if (! value) {
        AIQLogCWarn(2, @"No local context for key %@", key);
        [self failWithErrorCode:AIQErrorNameNotFound message:@"Local context not found" command:command keepCallback:NO];
        return;
    }

    AIQLogCInfo(2, @"Local context for key %@ found", key);

    [self.commandDelegate sendPluginResult:[self resultFromValue:value] callbackId:command.callbackId];
}

- (void)setLocal:(CDVInvokedUrlCommand *)command {
    NSError *error = nil;
    AIQContext *context = [[AIQSession currentSession] context:&error];
    if (! context) {
        AIQLogCError(2, @"Error retrieving context: %@", error.localizedDescription);
        [self failWithError:error command:command];
        return;
    }

    NSString *key = [command argumentAtIndex:0 withDefault:nil andClass:[NSString class]];
    id value = [command argumentAtIndex:1 withDefault:nil];

    id apps = [context valueForName:@"com.appearnetworks.aiq.apps" error:&error];
    if (apps) {
        NSMutableDictionary *dictionary = [(NSDictionary *)apps mutableCopy];
        if (value) {
            [dictionary setValue:value forKey:key];
        } else {
            [dictionary removeObjectForKey:key];
        }
        if (! [context setValue:dictionary forName:@"com.appearnetworks.aiq.apps" error:&error]) {
            AIQLogCError(2, @"Error setting local context: %@", error.localizedDescription);
            [self failWithError:error command:command];
            return;
        }

        [self.commandDelegate sendPluginResult:[self resultFromValue:value] callbackId:command.callbackId];
    } else {
        if (error) {
            AIQLogCError(2, @"Error retrieving local context: %@", error.localizedDescription);
            [self failWithError:error command:command];
            return;
        }

        NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
        [dictionary setValue:value forKey:key];
        if (! [context setValue:dictionary forName:@"com.appearnetworks.aiq.apps" error:&error]) {
            AIQLogCError(2, @"Error setting local context: %@", error.localizedDescription);
            [self failWithError:error command:command];
            return;
        }

        [self.commandDelegate sendPluginResult:[self resultFromValue:value] callbackId:command.callbackId];
    }
}

#pragma mark - Private API

- (CDVPluginResult *)resultFromValue:(id)value {
    CDVPluginResult *result;
    if ([value isKindOfClass:[NSDictionary class]]) {
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:value];
    } else if ([value isKindOfClass:[NSArray class]]) {
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:value];
    } else if ([value isKindOfClass:[NSString class]]) {
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:value];
    } else {
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDouble:[value doubleValue]];
    }
    return result;
}

@end
