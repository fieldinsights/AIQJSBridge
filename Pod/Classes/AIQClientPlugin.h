#import "AIQPlugin.h"

@interface AIQClientPlugin : AIQPlugin

- (void)setAppTitle:(CDVInvokedUrlCommand *)command;
- (void)closeApp:(CDVInvokedUrlCommand *)command;
- (void)getCurrentUser:(CDVInvokedUrlCommand *)command;
- (void)getSession:(CDVInvokedUrlCommand *)command;

- (void)getButton:(CDVInvokedUrlCommand *)command;
- (void)getButtons:(CDVInvokedUrlCommand *)command;
- (void)addButton:(CDVInvokedUrlCommand *)command;
- (void)updateButton:(CDVInvokedUrlCommand *)command;
- (void)deleteButton:(CDVInvokedUrlCommand *)command;

- (void)clean:(CDVInvokedUrlCommand *)command;

@end
