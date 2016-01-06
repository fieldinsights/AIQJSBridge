#import <AIQCoreLib/AIQContext.h>
#import <AIQCoreLib/AIQError.h>
#import <AIQCoreLib/AIQJSON.h>
#import <AIQCoreLib/AIQLog.h>
#import <AIQCoreLib/AIQSession.h>

#import "AIQClientPlugin.h"
#import "AIQLaunchableViewController.h"

@interface ClientButton : UIButton

@property (nonatomic, retain) id<CDVCommandDelegate> commandDelegate;
@property (nonatomic, retain) NSString *imagePath;
@property (nonatomic, retain) NSString *label;
@property (nonatomic, retain) NSString *onClickId;

@end

@implementation ClientButton

- (void)setCommandDelegate:(id<CDVCommandDelegate>)commandDelegate {
    _commandDelegate = commandDelegate;
    [self addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
}

- (IBAction)buttonPressed:(id)sender {
    ClientButton *button = (ClientButton *)sender;
    if (button.tag != -1) {
        NSMutableDictionary *args = [NSMutableDictionary dictionaryWithCapacity:5];
        [args setValue:_onClickId forKey:@"id"];
        [args setValue:button.imagePath forKey:@"image"];
        [args setValue:button.label forKey:@"label"];
        [args setValue:[NSNumber numberWithBool:button.enabled] forKey:@"enabled"];
        [args setValue:[NSNumber numberWithBool:!button.hidden] forKey:@"visible"];

        [_commandDelegate evalJs:[NSString stringWithFormat:@"aiq.client.navbar._callAction('%@', %@);", _onClickId, [args JSONString]]];
    }
}

- (CGRect)imageRectForContentRect:(CGRect)contentRect {
    CGFloat offset = (self.frame.size.height - 24.0f) / 2.0f;
    return CGRectMake(offset, offset, 24.0f, 24.0f);
}

- (CGRect)titleRectForContentRect:(CGRect)contentRect {
    CGFloat offset = (self.frame.size.height - 24.0f) / 2.0f;
    return CGRectMake(24.0f + 1.5f * offset, 0.0f, self.frame.size.width - 24.0f - 3.0f * offset, self.frame.size.height);
}

@end

@interface AIQClientPlugin ()

@property (nonatomic, retain) NSMutableArray *buttons;
@property (nonatomic, assign) NSUInteger currentId;

@end

@implementation AIQClientPlugin

- (void)pluginInitialize {
    _buttons = [NSMutableArray array];
    _currentId = 0;
}

- (void)getVersion:(CDVInvokedUrlCommand *)command {
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:version];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

- (void)setAppTitle:(CDVInvokedUrlCommand *)command {
    NSString *title = [command argumentAtIndex:0];

    AIQLogCInfo(2, @"Setting title to %@", title);

    self.viewController.navigationItem.title = title;
    [self.viewController.navigationController.navigationBar setNeedsLayout];

    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

- (void)closeApp:(CDVInvokedUrlCommand *)command {
    AIQLogCInfo(2, @"Closing application");

    AIQLaunchableViewController *controller = (AIQLaunchableViewController *)self.viewController;
    [controller.navigationController popViewControllerAnimated:YES];
    if (controller.delegate) {
        [controller.delegate didClose:controller];
    }
}

- (void)getCurrentUser:(CDVInvokedUrlCommand *)command {
    AIQLogCInfo(2, @"Getting current user");
    NSDictionary *userProfile = [[AIQSession currentSession] propertyForName:@"user"];
    if (! userProfile) {
        AIQLogCWarn(2, @"User profile not available");
        [self failWithErrorCode:AIQErrorContainerFault message:@"User profile not available" command:command keepCallback:YES];
        return;
    }

    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:userProfile];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

- (void)getSession:(CDVInvokedUrlCommand *)command {
    AIQLogCInfo(2, @"Getting user session");
    
    NSError *error = nil;
    AIQContext *context = [[AIQSession currentSession] context:&error];
    if (! context) {
        AIQLogCError(2, @"Did fail to retrieve context: %@", error.localizedDescription);
        [self failWithError:error command:command];
        return;
    }
    
    NSMutableArray *keys = [NSMutableArray array];
    BOOL success = [context names:^(NSString *name, NSError *__autoreleasing *error) {
        [keys addObject:name];
    } error:&error];
    if (! success) {
        AIQLogCError(2, @"Did fail to retrieve context keys: %@", error.localizedDescription);
        [self failWithError:error command:command];
        return;
    }
    
    NSMutableDictionary *session = [NSMutableDictionary dictionary];
    if ([keys containsObject:@"com.appearnetworks.aiq.user"]) {
        id value = [context valueForName:@"com.appearnetworks.aiq.user" error:&error];
        if (! value) {
            AIQLogCError(2, @"Did fail to retrieve user information: %@", error.localizedDescription);
            [self failWithError:error command:command];
            return;
        }
        
        session[@"_user"] = value;
        [keys removeObject:@"com.appearnetworks.aiq.user"];
    }
    
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    for (NSString *key in keys) {
        id value = [context valueForName:key error:&error];
        if (! value) {
            AIQLogCError(2, @"Did fail to retrieve context value for key %@: %@", key, error.localizedDescription);
            [self failWithError:error command:command];
            return;
        }
        data[key] = value;
    }
    session[@"_data"] = data;
    
    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:session];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

#pragma mark - Navbar Buttons

- (void)getButton:(CDVInvokedUrlCommand *)command {
    NSString *identifier = [command argumentAtIndex:0 withDefault:nil andClass:[NSString class]];

    if (! identifier) {
        AIQLogCWarn(2, @"Identifier not specified");
        [self failWithErrorCode:AIQErrorInvalidArgument message:@"Identifier not specified" command:command keepCallback:YES];
        return;
    }

    ClientButton *button = (ClientButton *)[self buttonWithId:identifier].customView;
    if (! button) {
        AIQLogCWarn(2, @"Button not found: %@", identifier);
        [self failWithErrorCode:AIQErrorIdNotFound message:@"Button not found" command:command keepCallback:YES];
        return;
    }

    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:[self descriptorForButton:button]];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

- (void)getButtons:(CDVInvokedUrlCommand *)command {
    NSMutableArray *descriptors = [NSMutableArray arrayWithCapacity:_buttons.count];
    for (int i = 0; i < _buttons.count; i++) {
        UIBarButtonItem *item = [_buttons objectAtIndex:i];
        ClientButton *button = (ClientButton *)item.customView;
        [descriptors addObject:[self descriptorForButton:button]];
    }

    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:descriptors];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

- (void)addButton:(CDVInvokedUrlCommand *)command {
    NSDictionary *properties = [command argumentAtIndex:0 withDefault:nil andClass:[NSDictionary class]];
    NSString *imagePath = properties[@"image"];
    NSString *onClickId = properties[@"onClickId"];

    if ([self isUndefined:imagePath]) {
        AIQLogCWarn(2, @"Image not specified");
        [self failWithErrorCode:AIQErrorInvalidArgument message:@"Image not specified" command:command keepCallback:YES];
        return;
    }

    if ([self isUndefined:onClickId]) {
        AIQLogCWarn(2, @"Action not specified");
        [self failWithErrorCode:AIQErrorInvalidArgument message:@"Action not specified" command:command keepCallback:YES];
        return;
    }

    NSString *label = properties[@"label"];
    BOOL enabled = [properties[@"enabled"] boolValue];
    BOOL visible = [properties[@"visible"] boolValue];

    if ((visible) && ([self visibleButtonCount] == 3)) {
        AIQLogCWarn(2, @"Too many visible buttons");
        [self failWithErrorCode:AIQErrorInvalidArgument message:@"Too many visible buttons" command:command keepCallback:YES];
        return;
    }

    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *path = [((AIQLaunchableViewController *)self.viewController).path stringByAppendingPathComponent:imagePath];
    if (! [fileManager fileExistsAtPath:path]) {
        AIQLogCWarn(2, @"Resource not found: %@", imagePath);
        [self failWithErrorCode:AIQErrorResourceNotFound message:@"Resource not found" command:command keepCallback:YES];
        return;
    }
    NSData *data = [fileManager contentsAtPath:path];
    UIImage *image = [UIImage imageWithData:data scale:[UIScreen mainScreen].scale];

    AIQLogCInfo(2, @"Adding button with identifier %lu", (unsigned long)_currentId);

    ClientButton *button = [ClientButton buttonWithType:UIButtonTypeCustom];
    button.onClickId = onClickId;

    button.label = [self isUndefined:label] ? nil : label;

    [button setImage:image forState:UIControlStateNormal];
    button.imagePath = imagePath;

    if ((label) && (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)) {
        [button setTitle:label forState:UIControlStateNormal];
    }

    button.enabled = enabled;
    button.alpha = enabled ? 1.0f : 0.5f;
    button.hidden = !visible;
    button.tag = _currentId;
    button.commandDelegate = self.commandDelegate;
    _currentId++;

    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:button];
    item.enabled = enabled;

    [_buttons addObject:item];

    [self setupButton:button];
    [self refreshButtons];

    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:[self descriptorForButton:button]];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

- (void)updateButton:(CDVInvokedUrlCommand *)command {
    NSString *identifier = [command argumentAtIndex:0 withDefault:nil andClass:[NSString class]];
    NSDictionary *properties = [command argumentAtIndex:1 withDefault:nil andClass:[NSDictionary class]];
    if ([self isUndefined:identifier]) {
        AIQLogCWarn(2, @"Identifier not specified");
        [self failWithErrorCode:AIQErrorInvalidArgument message:@"Identifier not specified" command:command keepCallback:YES];
        return;
    }

    UIBarButtonItem *item = [self buttonWithId:identifier];
    if (! item) {
        AIQLogCWarn(2, @"Button not found: %@", identifier);
        [self failWithErrorCode:AIQErrorIdNotFound message:@"Button not found" command:command keepCallback:YES];
        return;
    }
    ClientButton *button = (ClientButton *)item.customView;

    BOOL visible = !button.hidden;
    if ([properties valueForKey:@"visible"]) {
        visible = [properties[@"visible"] boolValue];
        if ((visible) && (button.hidden) && ([self visibleButtonCount] == 3)) {
            AIQLogCWarn(2, @"Too many visible buttons");
            [self failWithErrorCode:AIQErrorInvalidArgument message:@"Too many visible buttons" command:command keepCallback:YES];
            return;
        }
    }

    if (! [self isUndefined:[properties valueForKey:@"image"]]) {
        NSString *imagePath = properties[@"image"];
        NSString *path = [((AIQLaunchableViewController *)self.viewController).path stringByAppendingPathComponent:imagePath];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if (! [fileManager fileExistsAtPath:path]) {
            AIQLogCWarn(2, @"Resource not found: %@", imagePath);
            [self failWithErrorCode:AIQErrorResourceNotFound message:@"Resource not found" command:command keepCallback:YES];
            return;
        }

        NSData *data = [fileManager contentsAtPath:path];
        UIImage *image = [UIImage imageWithData:data scale:[UIScreen mainScreen].scale];
        [button setImage:image forState:UIControlStateNormal];
        button.imagePath = imagePath;
    }

    button.hidden = !visible;

    if (! [self isUndefined:[properties valueForKey:@"label"]]) {
        button.label = properties[@"label"];
        if ((button.label) && (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)) {
            [button setTitle:button.label forState:UIControlStateNormal];
        }
    }

    if ([properties valueForKey:@"enabled"]) {
        BOOL enabled = [[properties valueForKey:@"enabled"] boolValue];
        item.enabled = enabled;
        button.enabled = enabled;
    }
    [self setupButton:button];
    [self refreshButtons];

    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:[self descriptorForButton:button]];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

- (void)deleteButton:(CDVInvokedUrlCommand *)command {
    NSString *identifier = [command argumentAtIndex:0 withDefault:nil andClass:[NSString class]];
    if ([self isUndefined:identifier]) {
        AIQLogCWarn(2, @"Identifier not specified");
        [self failWithErrorCode:AIQErrorInvalidArgument message:@"Identifier not specified" command:command keepCallback:YES];
        return;
    }

    NSInteger tag = identifier.integerValue;
    BOOL found = NO;
    for (int i = 0; (i < _buttons.count) && (! found); i++) {
        UIBarButtonItem *item = [_buttons objectAtIndex:i];
        if (item.customView.tag == tag) {
            ClientButton *button = (ClientButton *)item.customView;
            [self.commandDelegate evalJs:[NSString stringWithFormat:@"aiq.client.navbar._removeAction(%@);", button.onClickId]];
            [_buttons removeObjectAtIndex:i];
            found = YES;
        }
    }
    if (! found) {
        AIQLogCWarn(2, @"Button not found: %@", identifier);
        [self failWithErrorCode:AIQErrorIdNotFound message:@"Button not found" command:command keepCallback:YES];
        return;
    }

    [self refreshButtons];

    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

- (void)clean:(CDVInvokedUrlCommand *)command {
    [_buttons removeAllObjects];
    self.viewController.navigationItem.rightBarButtonItems = [NSArray array];
    self.viewController.navigationItem.title = nil;

    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

#pragma mark - Private API

- (UIBarButtonItem *)buttonWithId:(NSString *)identifier {
    UIBarButtonItem *result = nil;
    NSInteger tag = [identifier integerValue];
    for (int i = 0; (i < _buttons.count) && (! result); i++) {
        UIBarButtonItem *item = [_buttons objectAtIndex:i];
        if (item.customView.tag == tag) {
            result = item;
        }
    }
    return result;
}

- (NSUInteger)visibleButtonCount {
    NSUInteger result = 0;
    for (UIBarButtonItem *item in _buttons) {
        if (! item.customView.hidden) {
            result++;
        }
    }
    return result;
}

- (void)refreshButtons {
    NSMutableArray *newButtons = [NSMutableArray array];
    for (UIBarButtonItem *item in _buttons) {
        if (! item.customView.hidden) {
            [newButtons addObject:item];
        }
    }
    self.viewController.navigationItem.rightBarButtonItems = newButtons;
    [self.viewController.navigationController.navigationBar setNeedsLayout];
}

- (void)setupButton:(UIButton *)button {
    CGFloat height = self.viewController.navigationController.navigationBar.frame.size.height;
    CGFloat offset = (height - 24.0f) / 2.0f;

    if (button.titleLabel.text) {
        CGSize size = [button.titleLabel.text sizeWithAttributes:@{NSFontAttributeName: button.titleLabel.font}];
        CGFloat labelWidth = MIN(size.width, 90.0f);
        button.frame = CGRectMake(button.frame.origin.x, 0.0f, 24.0f + 3.0f * offset + labelWidth, height);
    } else {
        button.frame = CGRectMake(button.frame.origin.x, 0.0f, 24.0f + 2.0f * offset, height);
    }

    button.titleLabel.font = [UIFont fontWithName:@"Arial" size:24.0f];

    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:button.titleLabel.text];
    [string addAttribute:NSKernAttributeName value:[NSNull null] range:NSMakeRange(0, string.length)];
    button.titleLabel.attributedText = string;


    button.titleLabel.adjustsFontSizeToFitWidth = YES;
    button.titleLabel.minimumScaleFactor = 15.0f;
}

- (NSDictionary *)descriptorForButton:(ClientButton *)button {
    NSMutableDictionary *descriptor = [NSMutableDictionary dictionary];
    descriptor[@"id"] = [NSString stringWithFormat:@"%ld", (long)button.tag];
    descriptor[@"image"] = button.imagePath;
    if (button.label) {
        descriptor[@"label"] = button.label;
    }
    descriptor[@"enabled"] = [NSNumber numberWithBool:button.enabled];
    descriptor[@"visible"] = [NSNumber numberWithBool:!button.hidden];
    return descriptor;
}

@end
