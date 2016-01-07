#import <AIQCoreLib/AIQDataStore.h>
#import <AIQCoreLib/AIQError.h>
#import <AIQCoreLib/AIQLog.h>
#import <AIQCoreLib/AIQSession.h>
#import <AIQCoreLib/AIQSynchronization.h>
#import <AIQCoreLib/NSDictionary+Helpers.h>
#import <Reachability/Reachability.h>

#import "AIQDataSyncPlugin.h"
#import "AIQLaunchableViewController.h"

@interface AIQDataSyncPlugin () {
    NSString *_solution;
    AIQDataStore *_dataStore;
    Reachability *_reachability;
}

@end

@implementation AIQDataSyncPlugin

- (void)pluginInitialize {
    _solution = ((AIQLaunchableViewController *)self.viewController).solution;
    _dataStore = [[AIQSession currentSession] dataStoreForSolution:_solution error:nil];
    _reachability = [Reachability reachabilityForInternetConnection];
}

- (void)dispose {
    [_dataStore close];
}

- (void)getDocument:(CDVInvokedUrlCommand *)command {
    [self.commandDelegate runInBackground:^{
        NSError *error = nil;
        NSString *identifier = [command argumentAtIndex:0 withDefault:nil andClass:[NSString class]];
        AIQLogCInfo(2, @"Getting document %@ from solution %@", identifier, _solution);
        
        NSDictionary *document = [_dataStore documentForId:identifier error:&error];
        if (! document) {
            AIQLogCError(2, @"Could not get document: %@", error.localizedDescription);
            [self failWithError:error command:command];
            return;
        }
        AIQLogCInfo(2, @"Document %@ found", identifier);
        
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:[self documentFromRaw:document]];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    }];
}

- (void)getDocuments:(CDVInvokedUrlCommand *)command {
    [self.commandDelegate runInBackground:^{
        @autoreleasepool {
            NSError *error = nil;
            NSString *type = [command argumentAtIndex:0 withDefault:nil andClass:[NSString class]];
            NSDictionary *filter = [command argumentAtIndex:1 withDefault:nil andClass:[NSDictionary class]];
            
            if (filter) {
                AIQLogCInfo(2, @"Getting filtered documents of type %@ for solution %@", type, _solution);
            } else {
                AIQLogCInfo(2, @"Getting documents of type %@ for solution %@", type, _solution);
            }
            
            NSMutableArray *documents = [NSMutableArray array];
            BOOL success = [_dataStore documentsOfType:type processor:^(NSDictionary *raw, NSError *__autoreleasing *error) {
                NSDictionary *processed = [self documentFromRaw:raw];
                if ((! filter) || ([processed matches:filter error:error])) {
                    [documents addObject:processed];
                }
            } error:&error];
            
            if (! success) {
                AIQLogCWarn(2, @"Could not list documents of type %@: %@", type, error.localizedDescription);
                [self failWithError:error command:command];
                return;
            }
            AIQLogCInfo(2, @"Found %lu documents of type %@", (unsigned long)documents.count, type);
            
            CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:documents];
            [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
        }
    }];
}

- (void)createDocument:(CDVInvokedUrlCommand *)command {
    [self.commandDelegate runInBackground:^{
        NSError *error = nil;
        NSString *type = [command argumentAtIndex:0 withDefault:nil andClass:[NSString class]];
        NSDictionary *fields = [command argumentAtIndex:1 withDefault:nil andClass:[NSDictionary class]];
        
        AIQLogCInfo(2, @"Creating document of type %@ for solution %@", type, _solution);
        
        NSDictionary *document = [_dataStore createDocumentOfType:type withFields:fields error:&error];
        if (! document) {
            AIQLogCWarn(2, @"Could not create document of type %@: %@", type, error.localizedDescription);
            [self failWithError:error command:command];
            return;
        }
        AIQLogCInfo(2, @"Created document %@ of type %@", document[kAIQDocumentId], type);
        
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:[self documentFromRaw:document]];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    }];
}

- (void)updateDocument:(CDVInvokedUrlCommand *)command {
    [self.commandDelegate runInBackground:^{
        NSError *error = nil;
        NSString *identifier = [command argumentAtIndex:0 withDefault:nil andClass:[NSString class]];
        NSDictionary *fields = [command argumentAtIndex:1 withDefault:nil andClass:[NSDictionary class]];
        
        AIQLogCInfo(2, @"Updating document %@ for solution %@", identifier, _solution);
        
        NSDictionary *document = [_dataStore updateFields:fields forDocumentWithId:identifier error:&error];
        if (! document) {
            AIQLogCWarn(2, @"Could not update document %@: %@", identifier, error.localizedDescription);
            [self failWithError:error command:command];
            return;
        }
        
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:[self documentFromRaw:document]];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    }];
}

- (void)deleteDocument:(CDVInvokedUrlCommand *)command {
    [self.commandDelegate runInBackground:^{
        NSError *error = nil;
        NSString *identifier = [command argumentAtIndex:0 withDefault:nil andClass:[NSString class]];
        
        AIQLogCInfo(2, @"Deleting document %@ for solution %@", identifier, _solution);
        BOOL deleted = [_dataStore deleteDocumentWithId:identifier error:&error];
        if (! deleted) {
            AIQLogCWarn(2, @"Could not delete document %@: %@", identifier, error.localizedDescription);
            [self failWithError:error command:command];
            return;
        }
        
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    }];
}

- (void)getAttachment:(CDVInvokedUrlCommand *)command {
    [self.commandDelegate runInBackground:^{
        NSError *error = nil;
        NSString *identifier = [command argumentAtIndex:0 withDefault:nil andClass:[NSString class]];
        NSString *name = [command argumentAtIndex:1 withDefault:nil andClass:[NSString class]];
        
        AIQLogCInfo(2, @"Getting attachment %@ of document %@ for solution %@", name, identifier, _solution);
        
        NSDictionary *attachment = [_dataStore attachmentWithName:name forDocumentWithId:identifier error:&error];
        if (! attachment) {
            AIQLogCWarn(2, @"Could not retrieve attachment %@ of document %@: %@", name, identifier, error.localizedDescription);
            [self failWithError:error command:command];
            return;
        }
        
        AIQLogCInfo(2, @"Attachment %@ of document %@ found", name, identifier);
        
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:[self descriptorFromAttachment:attachment forDocumentWithId:identifier]];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    }];
}

- (void)getAttachments:(CDVInvokedUrlCommand *)command {
    [self.commandDelegate runInBackground:^{
        NSError *error = nil;
        NSString *identifier = [command argumentAtIndex:0 withDefault:nil andClass:[NSString class]];
        
        AIQLogCInfo(2, @"Getting attachments of document %@ for solution %@", identifier, _solution);
        
        NSMutableArray *descriptors = [NSMutableArray array];
        BOOL success = [_dataStore attachmentsForDocumentWithId:identifier processor:^(NSDictionary *attachment, NSError **error) {
            [descriptors addObject:[self descriptorFromAttachment:attachment forDocumentWithId:identifier]];
        } error:&error];
        
        if (! success) {
            AIQLogCWarn(2, @"Could not retrieve attachments of document %@: %@", identifier, error.localizedDescription);
            [self failWithError:error command:command];
            return;
        }
        
        AIQLogCInfo(2, @"Found %lu attachments of document %@", (unsigned long)descriptors.count, identifier);
        
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:descriptors];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    }];
}

- (void)createAttachment:(CDVInvokedUrlCommand *)command {
    [self.commandDelegate runInBackground:^{
        NSError *error = nil;
        NSString *identifier = [command argumentAtIndex:0 withDefault:nil andClass:[NSString class]];
        NSDictionary *dictionary = [command argumentAtIndex:1 withDefault:nil andClass:[NSDictionary class]];
        if (! dictionary) {
            AIQLogCError(2, @"Could not create attachment of document %@: descriptor not specified", identifier);
            [self failWithError:[NSError errorWithDomain:AIQErrorDomain code:AIQErrorInvalidArgument userInfo:@{NSLocalizedDescriptionKey: @"Descriptor not specified"}] command:command];
            return;
        }
        
        NSString *name = dictionary[@"name"];
        if ([self isUndefined:name]) {
            name = [[NSUUID UUID] UUIDString];
        }
        NSString *contentType = dictionary[@"contentType"];
        NSString *resourceUrl = dictionary[@"resourceUrl"];
        
        if (! resourceUrl) {
            AIQLogCError(2, @"Could not create attachment %@ of document %@: resource not specified", name, identifier);
            [self failWithErrorCode:AIQErrorInvalidArgument message:@"Resource not specified" command:command keepCallback:NO];
            return;
        }
        
        NSData *data;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *path = [((AIQLaunchableViewController *)self.viewController).path stringByAppendingPathComponent:resourceUrl];
        if ([fileManager fileExistsAtPath:path]) {
            data = [fileManager contentsAtPath:path];
        } else {
            data = [NSData dataWithContentsOfURL:[NSURL URLWithString:resourceUrl] options:NSDataReadingUncached error:&error];
        }
        
        if (! data) {
            AIQLogCError(2, @"Could not retrieve data from %@: %@", resourceUrl, error.localizedDescription);
            [self failWithErrorCode:AIQErrorResourceNotFound message:@"Resource not found" command:command keepCallback:NO];
            return;
        }
        
        NSDictionary *attachment = [_dataStore createAttachmentWithName:name contentType:contentType andData:data forDocumentWithId:identifier error:&error];
        if (! attachment) {
            AIQLogCError(2, @"Could not create attachment %@ of document %@: %@", name, identifier, error.localizedDescription);
            [self failWithError:error command:command];
            return;
        }
        
        AIQLogCInfo(2, @"Attachment %@ of document %@ created", name, identifier);
        
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:[self descriptorFromAttachment:attachment forDocumentWithId:identifier]];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    }];
}

- (void)updateAttachment:(CDVInvokedUrlCommand *)command {
    [self.commandDelegate runInBackground:^{
        NSError *error = nil;
        NSString *identifier = [command argumentAtIndex:0 withDefault:nil andClass:[NSString class]];
        NSString *name = [command argumentAtIndex:1 withDefault:nil andClass:[NSString class]];
        NSDictionary *dictionary = [command argumentAtIndex:2 withDefault:nil andClass:[NSDictionary class]];
        if (! dictionary) {
            AIQLogCError(2, @"Could not update attachment of document %@: descriptor not specified", identifier);
            [self failWithErrorCode:AIQErrorInvalidArgument message:@"Descriptor not specified" command:command keepCallback:NO];
            return;
        }
        
        NSString *contentType = dictionary[@"contentType"];
        NSString *resourceUrl = dictionary[@"resourceUrl"];
        
        if (! resourceUrl) {
            AIQLogCError(2, @"Could not create attachment %@ of document %@: resource not specified", name, identifier);
            [self failWithErrorCode:AIQErrorInvalidArgument message:@"Resource not specified" command:command keepCallback:NO];
            return;
        }
        
        NSData *data;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *path = [((AIQLaunchableViewController *)self.viewController).path stringByAppendingPathComponent:resourceUrl];
        if ([fileManager fileExistsAtPath:path]) {
            data = [fileManager contentsAtPath:path];
        } else {
            data = [NSData dataWithContentsOfURL:[NSURL URLWithString:resourceUrl]];
        }
        
        if (! data) {
            AIQLogCError(2, @"Could not retrieve data from %@: %@", resourceUrl, error.localizedDescription);
            [self failWithErrorCode:AIQErrorResourceNotFound message:@"Resource not found" command:command keepCallback:NO];
            return;
        }
        
        AIQLogCInfo(2, @"Updating attachment %@ of document %@ for solution %@", name, identifier, _solution);
        
        NSDictionary *attachment = [_dataStore updateData:data withContentType:contentType forAttachmentWithName:name fromDocumentWithId:identifier error:&error];
        if (! attachment) {
            AIQLogCWarn(2, @"Could not update attachment %@ of document %@: %@", name, identifier, error.localizedDescription);
            [self failWithError:error command:command];
            return;
        }
        
        AIQLogCInfo(2, @"Attachment %@ of document %@ updated", name, identifier);
        
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:[self descriptorFromAttachment:attachment forDocumentWithId:identifier]];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    }];
}

- (void)deleteAttachment:(CDVInvokedUrlCommand *)command {
    [self.commandDelegate runInBackground:^{
        NSError *error = nil;
        
        NSString *identifier = [command argumentAtIndex:0 withDefault:nil andClass:[NSString class]];
        NSString *name = [command argumentAtIndex:1 withDefault:nil andClass:[NSString class]];
        
        AIQLogCInfo(2, @"Deleting attachment %@ of document %@ for solution %@", name, identifier, _solution);
        
        BOOL deleted = [_dataStore deleteAttachmentWithName:name fromDocumentWithId:identifier error:&error];
        if (! deleted) {
            AIQLogCWarn(2, @"Could not delete attachment %@ of document %@: %@", name, identifier, error.localizedDescription);
            [self failWithError:error command:command];
            return;
        }
        
        AIQLogCInfo(2, @"Attachment %@ of document %@ deleted", name, identifier);
        
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    }];
}

- (void)synchronize:(CDVInvokedUrlCommand *)command {
    AIQLogCInfo(2, @"Forcing synchronization");
    
    [((AIQLaunchableViewController *)self.viewController).delegate synchronize:(AIQLaunchableViewController *)self.viewController];
    
    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

- (void)getConnectionStatus:(CDVInvokedUrlCommand *)command {
    [self.commandDelegate runInBackground:^{
        AIQLogCInfo(2, @"Getting connection status");
        NetworkStatus status = [_reachability currentReachabilityStatus];
        
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:(status != NotReachable)];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    }];
}

#pragma mark - Private API

- (NSDictionary *)descriptorFromAttachment:(NSDictionary *)attachment forDocumentWithId:(NSString *)identifier {
    long long millis = (long long)([[NSDate date] timeIntervalSince1970] * 1000.0);
    
    NSMutableDictionary *descriptor = [NSMutableDictionary dictionaryWithCapacity:5];
    descriptor[@"name"] = attachment[kAIQAttachmentName];
    descriptor[@"contentType"] = attachment[kAIQAttachmentContentType];
    AIQAttachmentState state = [attachment[kAIQAttachmentState] intValue];
    if (state == AIQAttachmentStateAvailable) {
        descriptor[@"resourceUrl"] = [NSString stringWithFormat:@"aiq-datasync://attachment?name=%@&identifier=%@&solution=%@&__aiq_ms=%lld",
                                      attachment[kAIQAttachmentName],
                                      identifier,
                                      _solution,
                                      millis];
        descriptor[@"resourceId"] = [NSString stringWithFormat:@"aiq-datasync://attachment?name=%@&identiier=%@&solution=%@&__aiq_ms=%lld",
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
    AIQSynchronizationStatus status = [attachment[kAIQAttachmentStatus] intValue];
    if (status == AIQSynchronizationStatusCreated) {
        descriptor[@"status"] = @"created";
    } else if (status == AIQSynchronizationStatusUpdated) {
        descriptor[@"status"] = @"updated";
    } else if (status == AIQSynchronizationStatusSynchronized) {
        descriptor[@"status"] = @"synchronized";
    } else {
        descriptor[@"status"] = @"rejected";
        AIQRejectionReason reason = [attachment[kAIQAttachmentRejectionReason] integerValue];
        if (reason == AIQRejectionReasonPermissionDenied) {
            descriptor[@"reason"] = @"PERMISSION_DENIED";
        } else if (reason == AIQRejectionReasonDocumentNotFound) {
            descriptor[@"reason"] = @"DOCUMENT_NOT_FOUND";
        } else if (reason == AIQRejectionReasonRestrictedType) {
            descriptor[@"reason"] = @"RESTRICTED_DOCUMENT_TYPE";
        } else if (reason == AIQRejectionReasonCreateConflict) {
            descriptor[@"reason"] = @"CREATE_CONFLICT";
        } else if (reason == AIQRejectionReasonUpdateConflict) {
            descriptor[@"reason"] = @"UPDATE_CONFLICT";
        } else if (reason == AIQRejectionReasonLargeAttachment) {
            descriptor[@"reason"] = @"LARGE_ATTACHMENT";
        } else {
            descriptor[@"reason"] = @"UNKNOWN_REASON";
        }
    }
    
    return descriptor;
}

- (NSDictionary *)documentFromRaw:(NSDictionary *)raw {
    NSMutableDictionary *processed = [NSMutableDictionary dictionaryWithDictionary:raw];
    AIQSynchronizationStatus status = [processed[kAIQDocumentStatus] intValue];
    [processed removeObjectForKey:kAIQDocumentStatus];
    if (status == AIQSynchronizationStatusCreated) {
        processed[@"_status"] = @"created";
    } else if (status == AIQSynchronizationStatusUpdated) {
        processed[@"_status"] = @"updated";
    } else if (status == AIQSynchronizationStatusSynchronized) {
        processed[@"_status"] = @"synchronized";
    } else {
        processed[@"_status"] = @"rejected";
        AIQRejectionReason reason = [processed[kAIQDocumentRejectionReason] intValue];
        [processed removeObjectForKey:kAIQDocumentRejectionReason];
        if (reason == AIQRejectionReasonPermissionDenied) {
            processed[@"_reason"] = @"PERMISSION_DENIED";
        } else if (reason == AIQRejectionReasonTypeNotFound) {
            processed[@"_reason"] = @"DOCUMENT_TYPE_NOT_FOUND";
        } else if (reason == AIQRejectionReasonRestrictedType) {
            processed[@"_reason"] = @"RESTRICTED_DOCUMENT_TYPE";
        } else if (reason == AIQRejectionReasonCreateConflict) {
            processed[@"_reason"] = @"CREATE_CONFLICT";
        } else if (reason == AIQRejectionReasonUpdateConflict) {
            processed[@"_reason"] = @"UPDATE_CONFLICT";
        } else {
            processed[@"_reason"] = @"UNKNOWN_REASON";
        }
    }
    return processed;
}

@end
