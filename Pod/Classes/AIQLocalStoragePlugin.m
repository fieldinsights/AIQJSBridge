#import <AIQCoreLib/AIQDataStore.h>
#import <AIQCoreLib/AIQError.h>
#import <AIQCoreLib/AIQLocalStorage.h>
#import <AIQCoreLib/AIQLog.h>
#import <AIQCoreLib/AIQSession.h>
#import <AIQCoreLib/NSDictionary+Helpers.h>

#import "AIQLaunchableViewController.h"
#import "AIQLocalStoragePlugin.h"

@interface AIQLocalStoragePlugin () {
    NSString *_solution;
    AIQLocalStorage *_localStorage;
}

@end

@implementation AIQLocalStoragePlugin

- (void)pluginInitialize {
    _solution = ((AIQLaunchableViewController *)self.viewController).solution;
    _localStorage = [[AIQSession currentSession] localStorageForSolution:_solution error:nil];
}

- (void)dispose {
    [_localStorage close];
}

- (void)getDocument:(CDVInvokedUrlCommand *)command {
    [self.commandDelegate runInBackground:^{
        NSError *error = nil;

        NSString *identifier = [command argumentAtIndex:0 withDefault:nil andClass:[NSString class]];
        AIQLogCInfo(2, @"Getting document %@", identifier);

        NSDictionary *document = [_localStorage documentForId:identifier error:&error];
        if (! document) {
            AIQLogCError(2, @"Could not get document: %@", error.localizedDescription);
            [self failWithError:error command:command];
            return;
        }
        AIQLogCInfo(2, @"Document %@ found", identifier);

        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:document];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    }];
}

- (void)getDocuments:(CDVInvokedUrlCommand *)command {
    [self.commandDelegate runInBackground:^{
        NSError *error = nil;
        
        NSString *type = [command argumentAtIndex:0 withDefault:nil andClass:[NSString class]];
        NSDictionary *filter = [command argumentAtIndex:1 withDefault:nil andClass:[NSDictionary class]];

        if (filter) {
            AIQLogCInfo(2, @"Getting filtered documents of type %@", type);
        } else {
            AIQLogCInfo(2, @"Getting documents of type %@", type);
        }

        NSMutableArray *documents = [NSMutableArray array];
        BOOL success = [_localStorage documentsOfType:type processor:^(NSDictionary *document, NSError *__autoreleasing *error) {
            if ((! filter) || ([document matches:filter error:error])) {
                [documents addObject:document];
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
    }];
}

- (void)createDocument:(CDVInvokedUrlCommand *)command {
    [self.commandDelegate runInBackground:^{
        NSError *error = nil;

        NSString *type = [command argumentAtIndex:0 withDefault:nil andClass:[NSString class]];
        NSDictionary *fields = [command argumentAtIndex:1 withDefault:nil andClass:[NSDictionary class]];

        AIQLogCInfo(2, @"Creating document of type %@", type);

        NSDictionary *document = [_localStorage createDocumentOfType:type withFields:fields error:&error];
        if (! document) {
            AIQLogCWarn(2, @"Could not create document of type %@: %@", type, error.localizedDescription);
            [self failWithError:error command:command];
            return;
        }
        AIQLogCInfo(2, @"Created document %@ of type %@", document[kAIQDocumentId], type);

        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:document];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    }];
}

- (void)updateDocument:(CDVInvokedUrlCommand *)command {
    [self.commandDelegate runInBackground:^{
        NSError *error = nil;

        NSString *identifier = [command argumentAtIndex:0 withDefault:nil andClass:[NSString class]];
        NSDictionary *fields = [command argumentAtIndex:1 withDefault:nil andClass:[NSDictionary class]];

        AIQLogCInfo(2, @"Updating document %@", identifier);

        NSDictionary *document = [_localStorage updateFields:fields forDocumentWithId:identifier error:&error];
        if (! document) {
            AIQLogCWarn(2, @"Could not update document %@: %@", identifier, error.localizedDescription);
            [self failWithError:error command:command];
            return;
        }

        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:document];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    }];
}

- (void)deleteDocument:(CDVInvokedUrlCommand *)command {
    [self.commandDelegate runInBackground:^{
        NSError *error = nil;

        NSString *identifier = [command argumentAtIndex:0 withDefault:nil andClass:[NSString class]];

        BOOL deleted = [_localStorage deleteDocumentWithId:identifier error:&error];
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

        AIQLogCInfo(2, @"Getting attachment %@ for document %@", name, identifier);

        NSDictionary *attachment = [_localStorage attachmentWithName:name forDocumentWithId:identifier error:&error];
        if (! attachment) {
            AIQLogCWarn(2, @"Could not retrieve attachment %@ for document %@: %@", name, identifier, error.localizedDescription);
            [self failWithError:error command:command];
            return;
        }

        AIQLogCInfo(2, @"Attachment %@ for document %@ found", name, identifier);

        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:[self descriptorFromAttachment:attachment forDocumentWithId:identifier]];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    }];
}

- (void)getAttachments:(CDVInvokedUrlCommand *)command {
    [self.commandDelegate runInBackground:^{
        NSError *error = nil;

        NSString *identifier = [command argumentAtIndex:0 withDefault:nil andClass:[NSString class]];

        AIQLogCInfo(2, @"Getting attachments for document %@", identifier);

        NSArray *attachments = [_localStorage attachmentsForDocumentWithId:identifier error:&error];
        if (! attachments) {
            AIQLogCWarn(2, @"Could not retrieve attachments for document %@: %@", identifier, error.localizedDescription);
            [self failWithError:error command:command];
            return;
        }

        AIQLogCInfo(2, @"Found %lu attachments for document %@", (unsigned long)attachments.count, identifier);
        NSMutableArray *descriptors = [NSMutableArray arrayWithCapacity:attachments.count];
        for (NSDictionary *attachment in attachments) {
            [descriptors addObject:[self descriptorFromAttachment:attachment forDocumentWithId:identifier]];
        }

        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:descriptors];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    }];
}

- (void)createAttachment:(CDVInvokedUrlCommand *)command {
    [self.commandDelegate runInBackground:^{
        NSError *error = nil;

        NSString *identifier = [command argumentAtIndex:0 withDefault:nil andClass:[NSString class]];
        NSDictionary *dictionary = [command argumentAtIndex:1 withDefault:nil andClass:[NSDictionary class]];
        if ((! dictionary) || (! [dictionary isKindOfClass:[NSDictionary class]])) {
            AIQLogCError(2, @"Could not create attachment for document %@: descriptor not specified", identifier);
            [self failWithErrorCode:AIQErrorInvalidArgument message:@"Descriptor not specified" command:command keepCallback:NO];
            return;
        }

        NSString *name = dictionary[@"name"];
        if (! name) {
            name = [[NSUUID UUID] UUIDString];
        }
        NSString *contentType = dictionary[@"contentType"];
        NSString *resourceUrl = dictionary[@"resourceUrl"];

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
            [self failWithErrorCode:AIQErrorResourceNotFound message:@"Resource not found" args:nil command:command keepCallback:NO];
            return;
        }

        NSDictionary *attachment = [_localStorage createAttachmentWithName:name contentType:contentType andData:data forDocumentWithId:identifier error:&error];
        if (! attachment) {
            AIQLogCError(2, @"Could not create attachment %@ for document %@: %@", name, identifier, error.localizedDescription);
            [self failWithError:error command:command];
            return;
        }

        AIQLogCInfo(2, @"Attachment %@ for document %@ created", name, identifier);
        
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
        if ((! dictionary) || (! [dictionary isKindOfClass:[NSDictionary class]])) {
            AIQLogCError(2, @"Could not create attachment for document %@: descriptor not specified", identifier);
            [self failWithErrorCode:AIQErrorInvalidArgument message:@"Descriptor not specified" command:command keepCallback:NO];
            return;
        }

        NSString *contentType = dictionary[@"contentType"];
        NSString *resourceUrl = dictionary[@"resourceUrl"];

        NSData *data;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *path = [((AIQLaunchableViewController *)self.viewController).path stringByAppendingPathComponent:resourceUrl];
        if ([fileManager fileExistsAtPath:path]) {
            data = [fileManager contentsAtPath:path];
        } else {
            data = [NSData dataWithContentsOfURL:[NSURL URLWithString:resourceUrl]];
        }
        
        if (! data) {
            [self failWithErrorCode:AIQErrorResourceNotFound message:@"Resource not found" args:nil command:command keepCallback:NO];
        }

        AIQLogCInfo(2, @"Updating attachment %@ for document %@", name, identifier);

        NSDictionary *attachment = [_localStorage updateData:data withContentType:contentType forAttachmentWithName:name fromDocumentWithId:identifier error:&error];
        if (! attachment) {
            AIQLogCWarn(2, @"Could not update attachment %@ for document %@: %@", name, identifier, error.localizedDescription);
            [self failWithError:error command:command];
            return;
        }

        AIQLogCInfo(2, @"Attachment %@ for document %@ updated", name, identifier);

        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:[self descriptorFromAttachment:attachment forDocumentWithId:identifier]];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    }];
}

- (void)deleteAttachment:(CDVInvokedUrlCommand *)command {
    [self.commandDelegate runInBackground:^{
        NSError *error = nil;

        NSString *identifier = [command argumentAtIndex:0 withDefault:nil andClass:[NSString class]];
        NSString *name = [command argumentAtIndex:1 withDefault:nil andClass:[NSString class]];

        AIQLogCInfo(2, @"Deleting attachment %@ for document %@", name, identifier);

        BOOL deleted = [_localStorage deleteAttachmentWithName:name fromDocumentWithId:identifier error:&error];
        if (! deleted) {
            AIQLogCWarn(2, @"Could not delete attachment %@ for document %@: %@", name, identifier, error.localizedDescription);
            [self failWithError:error command:command];
            return;
        }

        AIQLogCInfo(2, @"Attachment %@ for document %@ deleted", name, identifier);

        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    }];
}

#pragma mark - Private API

- (NSDictionary *)descriptorFromAttachment:(NSDictionary *)attachment forDocumentWithId:(NSString *)identifier {
    long long millis = (long long)([[NSDate date] timeIntervalSince1970] * 1000.0);

    NSMutableDictionary *descriptor = [NSMutableDictionary dictionaryWithCapacity:3];
    descriptor[@"name"] = attachment[kAIQAttachmentName];
    descriptor[@"contentType"] = attachment[kAIQAttachmentContentType];
    descriptor[@"resourceUrl"] = [NSString stringWithFormat:@"aiq-localstorage://attachment?name=%@&identifier=%@&solution=%@&__aiq_ms=%lld",
                                  attachment[kAIQAttachmentName],
                                  identifier,
                                  _solution,
                                  millis];
    return descriptor;
}

@end
