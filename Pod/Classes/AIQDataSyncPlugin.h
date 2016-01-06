#import "AIQPlugin.h"

@interface AIQDataSyncPlugin : AIQPlugin

- (void)getDocument:(CDVInvokedUrlCommand *)command;
- (void)getDocuments:(CDVInvokedUrlCommand *)command;
- (void)createDocument:(CDVInvokedUrlCommand *)command;
- (void)updateDocument:(CDVInvokedUrlCommand *)command;
- (void)deleteDocument:(CDVInvokedUrlCommand *)command;

- (void)getAttachment:(CDVInvokedUrlCommand *)command;
- (void)getAttachments:(CDVInvokedUrlCommand *)command;
- (void)createAttachment:(CDVInvokedUrlCommand *)command;
- (void)updateAttachment:(CDVInvokedUrlCommand *)command;
- (void)deleteAttachment:(CDVInvokedUrlCommand *)command;

- (void)synchronize:(CDVInvokedUrlCommand *)command;

- (void)getConnectionStatus:(CDVInvokedUrlCommand *)command;

@end
