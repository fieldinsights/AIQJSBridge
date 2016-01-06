#import <AIQCoreLib/AIQDataStore.h>
#import <AIQCoreLib/AIQError.h>
#import <AIQCoreLib/AIQLog.h>
#import <AIQCoreLib/AIQMessaging.h>
#import <AIQCoreLib/AIQSession.h>
#import <AIQCoreLib/NSDictionary+Helpers.h>

#import "AIQLaunchableViewController.h"
#import "AIQMessagingPlugin.h"

@interface AIQMessagingPlugin () {
    NSString *_solution;
    AIQDataStore *_dataStore;
    AIQMessaging *_messaging;
}

@end

@implementation AIQMessagingPlugin

- (void)pluginInitialize {
    _solution = ((AIQLaunchableViewController *)self.viewController).solution;
    _dataStore = [[AIQSession currentSession] dataStoreForSolution:_solution error:nil];
    _messaging = [[AIQSession currentSession] messagingForSolution:_solution error:nil];
}

- (void)dispose {
    [_dataStore close];
    _dataStore = nil;
    
    [_messaging close];
    _messaging = nil;
    
    _solution = nil;
}

- (void)getMessage:(CDVInvokedUrlCommand *)command {
    [self.commandDelegate runInBackground:^{
        NSError *error = nil;

        NSString *identifier = [command argumentAtIndex:0 withDefault:nil andClass:[NSString class]];
        AIQLogCInfo(2, @"Getting message %@", identifier);

        NSDictionary *message = [_messaging messageForId:identifier error:&error];
        if (! message) {
            AIQLogCError(2, @"Could not get message %@: %@", identifier, error.localizedDescription);
            [self failWithError:error command:command];
            return;
        }

        AIQLogCInfo(2, @"Message %@ found", identifier);

        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:message];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    }];
}

- (void)getMessages:(CDVInvokedUrlCommand *)command {
    [self.commandDelegate runInBackground:^{
        NSError *error = nil;

        NSString *type = [command argumentAtIndex:0 withDefault:nil andClass:[NSString class]];
        BOOL withPayload = [[command argumentAtIndex:1 withDefault:@YES andClass:[NSNumber class]] boolValue];
        NSDictionary *filter = [command argumentAtIndex:2 withDefault:nil andClass:[NSDictionary class]];

        if (filter) {
            AIQLogCInfo(2, @"Getting filtered documents of type %@", type);
        } else {
            AIQLogCInfo(2, @"Getting documents of type %@", type);
        }

        NSMutableArray *messages = [NSMutableArray array];
        BOOL success = [_messaging messagesOfType:type order:AIQMessageOrderDescending processor:^(NSDictionary *message, NSError *__autoreleasing *error) {
            if ((! filter) || ([message matches:filter error:error])) {
                if (withPayload) {
                    [messages addObject:message];
                } else {
                    NSMutableDictionary *mutableMessage = [message mutableCopy];
                    [mutableMessage removeObjectForKey:@"payload"];
                    [messages addObject:mutableMessage];
                }
            }
        } error:&error];

        if (! success) {
            AIQLogCError(2, @"Could not get messages of type %@: %@", type, error.localizedDescription);
            [self failWithError:error command:command];
            return;
        }

        AIQLogCInfo(2, @"Found %lu messages of type %@", (unsigned long)messages.count, type);

        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:messages];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    }];
}

- (void)markMessageAsRead:(CDVInvokedUrlCommand *)command {
    [self.commandDelegate runInBackground:^{
        NSError *error = nil;

        NSString *identifier = [command argumentAtIndex:0 withDefault:nil andClass:[NSString class]];
        AIQLogCInfo(2, @"Marking message %@ as read", identifier);

        if (! [_messaging markMessageAsReadForId:identifier error:&error]) {
            AIQLogCError(2, @"Error marking message %@ as read: %@", identifier, error.localizedDescription);
            [self failWithError:error command:command];
            return;
        }

        AIQLogCInfo(2, @"Message %@ marked as read", identifier);

        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    }];
}

- (void)deleteMessage:(CDVInvokedUrlCommand *)command {
    [self.commandDelegate runInBackground:^{
        NSError *error = nil;

        NSString *identifier = [command argumentAtIndex:0 withDefault:nil andClass:[NSString class]];
        AIQLogCInfo(2, @"Deleting message %@", identifier);

        if (! [_messaging deleteMessageWithId:identifier error:&error]) {
            AIQLogCError(2, @"Could not delete message %@: %@", identifier, error.localizedDescription);
            [self failWithError:error command:command];
            return;
        }

        AIQLogCInfo(2, @"Message %@ deleted", identifier);

        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    }];
}

- (void)getAttachment:(CDVInvokedUrlCommand *)command {
    [self.commandDelegate runInBackground:^{
        NSError *error = nil;

        NSString *identifier = [command argumentAtIndex:0 withDefault:nil andClass:[NSString class]];
        NSString *name = [command argumentAtIndex:1 withDefault:nil andClass:[NSString class]];

        AIQLogCInfo(2, @"Getting attachment %@ for message %@", name, identifier);

        NSDictionary *attachment = [_messaging attachmentWithName:name forMessageWithId:identifier error:&error];
        if (! attachment) {
            AIQLogCError(2, @"Could not get attachment %@ for message %@: %@", name, identifier, error.localizedDescription);
            [self failWithError:error command:command];
            return;
        }

        AIQLogCInfo(2, @"Attachment %@ found for document %@", name, identifier);

        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:[self descriptorFromAttachment:attachment forMessageWithId:identifier]];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    }];
}

- (void)getAttachments:(CDVInvokedUrlCommand *)command {
    [self.commandDelegate runInBackground:^{
        NSError *error = nil;

        NSString *identifier = [command argumentAtIndex:0 withDefault:nil andClass:[NSString class]];
        AIQLogCInfo(2, @"Getting attachments for message %@", identifier);

        NSArray *attachments = [_messaging attachmentsForMessageWithId:identifier error:&error];
        if (! attachments) {
            AIQLogCError(2, @"Could not get attachments for message %@: %@", identifier, error.localizedDescription);
            [self failWithError:error command:command];
            return;
        }

        AIQLogCInfo(2, @"Found %lu attachments for message %@", (unsigned long)attachments.count, identifier);
        NSMutableArray *descriptors = [NSMutableArray arrayWithCapacity:attachments.count];

        for (NSDictionary *attachment in attachments) {
            [descriptors addObject:[self descriptorFromAttachment:attachment forMessageWithId:identifier]];
        }

        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:descriptors];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    }];
}

- (void)sendMessage:(CDVInvokedUrlCommand *)command {
    [self.commandDelegate runInBackground:^{
        NSError *error = nil;

        NSString *destination = [command argumentAtIndex:0 withDefault:nil andClass:[NSString class]];
        NSDictionary *payload = [command argumentAtIndex:1 withDefault:nil andClass:[NSDictionary class]];
        NSArray *attachments = [command argumentAtIndex:2 withDefault:nil andClass:[NSArray class]];
        BOOL urgent = [[command argumentAtIndex:3 withDefault:@NO andClass:[NSNumber class]] boolValue];
        BOOL expectResponse = [[command argumentAtIndex:4 withDefault:@YES andClass:[NSNumber class]] boolValue];

        AIQLogCInfo(2, @"Sending %@ message to %@", (urgent ? @" urgent" : @""), destination);
        
        NSMutableDictionary *fixedAttachments = [NSMutableDictionary dictionaryWithCapacity:attachments.count];
        for (NSDictionary *attachment in attachments) {
            if (fixedAttachments[attachment[@"name"]]) {
                [self failWithErrorCode:AIQErrorInvalidArgument message:@"Duplicate attachment name" args:nil command:command keepCallback:NO];
                return;
            }
            
            NSString *resourceUrl = attachment[@"resourceUrl"];
            if ([resourceUrl rangeOfString:@"://"].location == NSNotFound) {
                resourceUrl = [((AIQLaunchableViewController *)self.viewController).path stringByAppendingPathComponent:resourceUrl];
            }

            NSMutableDictionary *fixedAttachment = [attachment mutableCopy];
            fixedAttachment[@"resourceUrl"] = resourceUrl;
            fixedAttachments[attachment[@"name"]] = fixedAttachment;
        }

        NSDictionary *status = [_messaging sendMessage:payload
                                       withAttachments:fixedAttachments.allValues
                                                  from:((AIQLaunchableViewController *)self.viewController).identifier
                                                    to:destination
                                                urgent:urgent
                                        expectResponse:expectResponse
                                                 error:&error];
        if (! status) {
            AIQLogCError(2, @"Failed to send a message to %@: %@", destination, error.localizedDescription);
            [self failWithError:error command:command];
            return;
        }

        AIQLogCInfo(2, @"Message sent to %@", destination);

        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:[self resultFromStatus:status]];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    }];
}

- (void)getMessageStatus:(CDVInvokedUrlCommand *)command {
    [self.commandDelegate runInBackground:^{
        NSError *error = nil;

        NSString *identifier = [command argumentAtIndex:0 withDefault:nil andClass:[NSString class]];
        AIQLogCInfo(2, @"Getting status of message %@", identifier);

        NSDictionary *status = [_messaging statusOfMessageWithId:identifier error:&error];
        if (! status) {
            AIQLogCError(2, @"Could not get status of message %@: %@", identifier, error.localizedDescription);
            [self failWithError:error command:command];
            return;
        }

        status = [self resultFromStatus:status];

        AIQLogCInfo(2, @"Message %@ is %@", identifier, status[kAIQMessageState]);

        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:status];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    }];
}

- (void)getMessageStatuses:(CDVInvokedUrlCommand *)command {
    [self.commandDelegate runInBackground:^{
        NSError *error = nil;

        NSString *destination = [command argumentAtIndex:0 withDefault:nil andClass:[NSString class]];
        AIQLogCInfo(2, @"Getting statuses statuses for destination %@", destination);
        
        NSDictionary *filter = [command argumentAtIndex:1 withDefault:nil andClass:[NSDictionary class]];
        if (filter) {
            AIQLogCInfo(2, @"Listing message statuses with filter for destination %@", destination);
        } else {
            AIQLogCInfo(2, @"Listing message statuses for destination %@", destination);
        }

        NSMutableArray *statuses = [NSMutableArray array];
        BOOL success = [_messaging statusesOfMessagesForDestination:destination processor:^(NSDictionary *status, NSError *__autoreleasing *error) {
            NSDictionary *current = [self resultFromStatus:status];
            if ((! filter) || ([current matches:filter error:error])) {
                [statuses addObject:current];
            }
        } error:&error];
        
        if (! success) {
            AIQLogCError(2, @"Could not get message statuses for destination %@: %@", destination, error.localizedDescription);
            [self failWithError:error command:command];
            return;
        }

        AIQLogCInfo(2, @"Found %lu statuses of messages for destination %@", (unsigned long)statuses.count, destination);
        
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:statuses];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    }];
}

#pragma mark - Private API

- (NSDictionary *)descriptorFromAttachment:(NSDictionary *)attachment forMessageWithId:(NSString *)identifier {
    AIQAttachmentState state = [[attachment valueForKey:kAIQAttachmentState] intValue];
    NSMutableDictionary *descriptor = [NSMutableDictionary dictionaryWithCapacity:4];
    descriptor[@"name"] = attachment[kAIQAttachmentName];
    descriptor[@"contentType"] = attachment[kAIQAttachmentContentType];
    if (state == AIQAttachmentStateAvailable) {
        long long millis = (long long)([[NSDate date] timeIntervalSince1970] * 1000.0);
        descriptor[@"resourceUrl"] = [NSString stringWithFormat:@"aiq-messaging://attachment?name=%@&identifier=%@&solution=%@&__aiq_ms=%lld",
                                      attachment[kAIQAttachmentName],
                                      identifier,
                                      _solution,
                                      millis];
        descriptor[@"state"] = @"available";
    } else if (state == AIQAttachmentStateUnavailable) {
        descriptor[@"state"] = @"unavailable";
    } else {
        descriptor[@"state"] = @"failed";
    }
    return descriptor;
}

- (NSDictionary *)resultFromStatus:(NSDictionary *)status {
    NSMutableDictionary *result = [status mutableCopy];
    AIQMessageState state = [status[kAIQMessageState] integerValue];
    if (state == AIQMessageStateAccepted) {
        result[kAIQMessageState] = @"accepted";
    } else if (state == AIQMessageStateDelivered) {
        result[kAIQMessageState] = @"delivered";
    } else if (state == AIQMessageStateFailed) {
        result[kAIQMessageState] = @"failed";
    } else if (state == AIQMessageStateQueued) {
        result[kAIQMessageState] = @"queued";
    } else if (state == AIQMessageStateRejected) {
        result[kAIQMessageState] = @"rejected";
    }
    return result;
}

@end
