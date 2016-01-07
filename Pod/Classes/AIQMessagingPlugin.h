#import "AIQPlugin.h"

@interface AIQMessagingPlugin : AIQPlugin

// Server originated messages
- (void)getMessage:(CDVInvokedUrlCommand *)command;
- (void)getMessages:(CDVInvokedUrlCommand *)command;
- (void)markMessageAsRead:(CDVInvokedUrlCommand *)command;
- (void)deleteMessage:(CDVInvokedUrlCommand *)command;
- (void)getAttachment:(CDVInvokedUrlCommand *)command;
- (void)getAttachments:(CDVInvokedUrlCommand *)command;

// Client originated messages
- (void)sendMessage:(CDVInvokedUrlCommand *)command;
- (void)getMessageStatus:(CDVInvokedUrlCommand *)command;
- (void)getMessageStatuses:(CDVInvokedUrlCommand *)command;

@end
