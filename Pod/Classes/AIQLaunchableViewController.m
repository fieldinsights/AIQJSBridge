#import <AIQCoreLib/AIQDataStore.h>
#import <AIQCoreLib/AIQJSON.h>
#import <AIQCoreLib/AIQLog.h>
#import <AIQCoreLib/AIQMessaging.h>
#import <AIQCoreLib/NSDictionary+Helpers.h>
#import <AIQCoreLib/AIQSynchronization.h>
#import <AIQCoreLib/AIQSynchronizationManager.h>
#import <AIQCoreLib/NSDictionary+Helpers.h>
#import <Reachability/Reachability.h>
#import <Cordova/CDVCommandDelegateImpl.h>
#import <Cordova/CDVURLProtocol.h>

#import "AIQLaunchableViewController.h"
#import "CSSFilteringProtocol.h"
#import "DataSyncProtocol.h"
#import "LocalStorageProtocol.h"
#import "MessagingProtocol.h"
#import "TemporaryResourceProtocol.h"
#import "common.h"

@interface AIQCommandDelegate : CDVCommandDelegateImpl

@property (nonatomic, retain) AIQLaunchableViewController *controller;

@end

@implementation AIQCommandDelegate

- (id)initWithViewController:(AIQLaunchableViewController *)viewController {
    self = [super initWithViewController:viewController];
    if (self) {
        _controller = viewController;
    }
    return self;
}

- (NSString *)pathForResource:(NSString *)resource {
    return [_controller.path stringByAppendingPathComponent:resource];
}

@end

@interface AIQLaunchableViewController () <UIWebViewDelegate, UIAlertViewDelegate> {
    NSMutableArray *_navigationStack;
    NSMutableDictionary *_registeredEvents;
    NSDictionary *_eventMapping;
    Reachability *_reachability;
}

@end

@implementation AIQLaunchableViewController

- (id)init {
    self = [super init];
    if (self) {
        [self initialize];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initialize];
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self initialize];
    }
    return self;
}

- (NSString *)wwwFolderName {
    return _path;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    AIQLogCWarn(2, @"Did receive memory warning, reloading");

    dispatch_async(dispatch_get_main_queue(), ^{
        [self back:self];
//        [self.webView reload];
    });
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if ((! request.URL.scheme) || [@[@"file", @"http", @"https"] containsObject:request.URL.scheme]) {
        [self hashChangedTo:request.URL.fragment ? [NSString stringWithFormat:@"#%@", request.URL.fragment] : request.URL.absoluteString];
    }
    
    return [super webView:webView shouldStartLoadWithRequest:request navigationType:navigationType];
}

- (void)webView:(UIWebView*)theWebView didFailLoadWithError:(NSError*)error {
    [super webView:theWebView didFailLoadWithError:error];

    UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Error"
                                                      message:error.localizedDescription
                                                     delegate:self
                                            cancelButtonTitle:@"Close"
                                            otherButtonTitles:nil];

    [message show];
}

- (void)setArguments:(NSDictionary *)arguments {
    _arguments = arguments;
    if (arguments) {
        NSURLComponents *components = [NSURLComponents componentsWithString:self.startPage];
        components.query = [self.arguments asQuery];
        self.startPage = [components URL].absoluteString;
    }
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [_reachability startNotifier];
    
    [self prepareView];
}

- (void)prepareView {
    if ([self respondsToSelector:@selector(setExtendedLayoutIncludesOpaqueBars:)]) {
        self.extendedLayoutIncludesOpaqueBars = NO;
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    
    self.navigationItem.hidesBackButton = YES;

    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:self action:@selector(back:)];
    backButton.tag = 0x13576420;
    backButton.enabled = NO;
    self.navigationItem.leftBarButtonItem = backButton;
    
    
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.webView.scrollView.bounces = NO;
    self.webView.scrollView.bouncesZoom = NO;
    self.webView.scrollView.scrollsToTop = NO;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.navigationItem.leftBarButtonItem.enabled = YES;
}

- (void)didMoveToParentViewController:(UIViewController *)parent {
    if (! parent) {
        [self close];
    }
    
    [super didMoveToParentViewController:parent];
}

- (void)close {
    AIQLogCInfo(2, @"Closing application %@", _identifier);

    [_reachability stopNotifier];
    
    [CDVURLProtocol unregisterViewController:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    
    [self.webView stopLoading];
    self.webView.delegate = nil;
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"about:blank"]]];
    [self.webView removeFromSuperview];
    self.webView = nil;
    [_commandQueue dispose];
    [[self.pluginObjects allValues] makeObjectsPerformSelector:@selector(dispose)];
    
    _navigationStack = nil;
    _registeredEvents = nil;
    _eventMapping = nil;
}

- (IBAction)back:(id)sender {
    if ([self canGoBack]) {
        AIQLogCInfo(2, @"Navigating back to %@", _navigationStack.lastObject);
        [_navigationStack removeLastObject];
        [self.webView goBack];
    } else {
        if (! self.webView.canGoBack) {
            AIQLogCInfo(2, @"History is empty, nagivating home");
        } else {
            AIQLogCInfo(2, @"Hash stack is empty, navigating home");
        }

        if (self.webView) {
            [self.webView stopLoading];
            [self.webView loadHTMLString:@"" baseURL:nil];
            self.webView.delegate = nil;
        }

        [[NSNotificationCenter defaultCenter] removeObserver:self];

        [self.navigationController popViewControllerAnimated:YES];
        if (_delegate) {
            [_delegate didClose:self];
        }
    }
}

- (BOOL)canGoBack {
    return (_navigationStack.count > 1) && (self.webView.canGoBack);
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
//    [[NSNotificationCenter defaultCenter] removeObserver:self];
//    [self.navigationController popViewControllerAnimated:YES];
//    if (_delegate) {
//        [_delegate didClose:self];
//    }
}

#pragma mark - private methods

- (void)initialize {
    _commandDelegate = [[AIQCommandDelegate alloc] initWithViewController:self];
    _navigationStack = [NSMutableArray arrayWithObject:@"#/"];
    _registeredEvents = [NSMutableDictionary dictionary];
    _eventMapping = @{@"onAiqDataSyncDocumentCreated": AIQDidCreateDocumentNotification,
                      @"onAiqDataSyncDocumentUpdated": AIQDidUpdateDocumentNotification,
                      @"onAiqDataSyncDocumentDeleted": AIQDidDeleteDocumentNotification,
                      @"onAiqDataSyncDocumentSynchronized": AIQDidSynchronizeDocumentNotification,
                      @"onAiqDataSyncDocumentRejected": AIQDidRejectDocumentNotification,
                      @"onAiqDataSyncSynchronizationComplete": AIQSynchronizationCompleteEvent,
                      @"onAiqDataSyncAttachmentAvailable": AIQAttachmentDidBecomeAvailableNotification,
                      @"onAiqDataSyncAttachmentUnavailable": AIQAttachmentDidBecomeUnavailableNotification,
                      @"onAiqDataSyncAttachmentFailed": AIQAttachmentDidFailNotification,
                      @"onAiqDataSyncAttachmentSynchronized": AIQDidSynchronizeAttachmentNotification,
                      @"onAiqDataSyncAttachmentRejected": AIQDidRejectAttachmentNotification,
                      @"onAiqMessagingAttachmentAvailable": AIQMessageAttachmentDidBecomeAvailableNotification,
                      @"onAiqMessagingAttachmentUnavailable": AIQMessageAttachmentDidBecomeUnavailableNotification,
                      @"onAiqMessagingAttachmentFailed": AIQMessageAttachmentDidFailEvent,
                      @"onAiqMessagingMessageReceived": AIQDidReceiveMessageNotification,
                      @"onAiqMessagingMessageUpdated": AIQDidUpdateMessageNotification,
                      @"onAiqMessagingMessageExpired": AIQDidExpireMessageNotification,
                      @"onAiqMessagingMessageQueued": AIQDidQueueMessageNotification,
                      @"onAiqMessagingMessageAccepted": AIQDidAcceptMessageNotification,
                      @"onAiqMessagingMessageRejected": AIQDidRejectMessageNotification,
                      @"onAiqMessagingMessageDelivered": AIQDidDeliverMessageNotification,
                      @"onAiqMessagingMessageFailed": AIQDidFailMessageNotification};
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAiqDocumentError:) name:AIQDocumentErrorNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAiqAttachmentError:) name:AIQAttachmentErrorNotification object:nil];
    
    _reachability = [Reachability reachabilityForInternetConnection];
    
    __weak typeof(self) weakSelf = self;
    void (^block)(Reachability *) = ^(Reachability *reachability) {
        NetworkStatus status = [reachability currentReachabilityStatus];
        [weakSelf publishEvent:@"DataSyncConnectionStatusChanged" withArguments:@{@"_status": @(status != NotReachable)}];
    };
    _reachability.reachableBlock = block;
    _reachability.unreachableBlock = block;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [NSURLProtocol registerClass:[DataSyncProtocol class]];
        [NSURLProtocol registerClass:[CSSFilteringProtocol class]];
        [NSURLProtocol registerClass:[LocalStorageProtocol class]];
        [NSURLProtocol registerClass:[MessagingProtocol class]];
        [NSURLProtocol registerClass:[TemporaryResourceProtocol class]];
    });
}

- (void)publishEvent:(NSString *)name withArguments:(NSDictionary *)arguments {
    AIQLogCInfo(2, @"Publishing event %@", name);
    NSString *command = [NSString stringWithFormat:@"cordova.require('cordova/channel').onAiq%@.fire(%@);", name, [arguments JSONString]];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.webView stringByEvaluatingJavaScriptFromString:command];
    });

}

- (void)onAiqDataSyncDocumentCreated:(NSNotification *)notification {
    NSString *solution = notification.userInfo[AIQSolutionUserInfoKey];
    if (! [solution isEqualToString:_solution]) {
        return;
    }
    
    NSString *identifier = notification.userInfo[AIQDocumentIdUserInfoKey];
    NSString *type = notification.userInfo[AIQDocumentTypeUserInfoKey];
    if (! [type hasPrefix:@"_"]) {
        [self publishEvent:@"DataSyncDocumentCreated" withArguments:@{@"_id": identifier, @"_type": type}];
    }
}

- (void)onAiqDataSyncDocumentUpdated:(NSNotification *)notification {
    NSString *solution = notification.userInfo[AIQSolutionUserInfoKey];
    if (! [solution isEqualToString:_solution]) {
        return;
    }
    
    NSString *identifier = notification.userInfo[AIQDocumentIdUserInfoKey];
    NSString *type = notification.userInfo[AIQDocumentTypeUserInfoKey];
    if (! [type hasPrefix:@"_"]) {
        [self publishEvent:@"DataSyncDocumentUpdated" withArguments:@{@"_id": identifier, @"_type": type}];
    }
}

- (void)onAiqDataSyncDocumentDeleted:(NSNotification *)notification {
    NSString *solution = notification.userInfo[AIQSolutionUserInfoKey];
    if (! [solution isEqualToString:_solution]) {
        return;
    }
    
    NSString *identifier = notification.userInfo[AIQDocumentIdUserInfoKey];
    NSString *type = notification.userInfo[AIQDocumentTypeUserInfoKey];
    if ([identifier isEqualToString:_identifier]) {
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Notification"
                                                          message:@"Application has been removed"
                                                         delegate:self
                                                cancelButtonTitle:@"Close"
                                                otherButtonTitles:nil];
        
        [message show];
        [self.navigationController popViewControllerAnimated:YES];
    } else if (! [type hasPrefix:@"_"]) {
        [self publishEvent:@"DataSyncDocumentDeleted" withArguments:@{@"_id": identifier, @"_type": type}];
    }
}

- (void)onAiqDataSyncDocumentSynchronized:(NSNotification *)notification {
    NSString *solution = notification.userInfo[AIQSolutionUserInfoKey];
    if (! [solution isEqualToString:_solution]) {
        return;
    }
    
    NSString *identifier = notification.userInfo[AIQDocumentIdUserInfoKey];
    NSString *type = notification.userInfo[AIQDocumentTypeUserInfoKey];
    if (! [type hasPrefix:@"_"]) {
        [self publishEvent:@"DataSyncDocumentSynchronized" withArguments:@{@"_id": identifier, @"_type": type}];
    }
}

- (void)onAiqDataSyncDocumentRejected:(NSNotification *)notification {
    NSString *solution = notification.userInfo[AIQSolutionUserInfoKey];
    if (! [solution isEqualToString:_solution]) {
        return;
    }
    
    NSString *identifier = notification.userInfo[AIQDocumentIdUserInfoKey];
    NSString *type = notification.userInfo[AIQDocumentTypeUserInfoKey];
    if (! [type hasPrefix:@"_"]) {
        [self publishEvent:@"DataSyncDocumentRejected" withArguments:@{@"_id": identifier, @"_type": type}];
    }
}

- (void)onAiqDataSyncSynchronizationComplete:(NSNotification *)notification {
    [self publishEvent:@"DataSyncSynchronizationComplete" withArguments:@{}];
}

- (void)onAiqDataSyncAttachmentAvailable:(NSNotification *)notification {
    NSString *solution = notification.userInfo[AIQSolutionUserInfoKey];
    if (! [solution isEqualToString:_solution]) {
        return;
    }
    
    NSString *identifier = notification.userInfo[AIQDocumentIdUserInfoKey];
    NSString *type = notification.userInfo[AIQDocumentTypeUserInfoKey];
    NSString *name = notification.userInfo[AIQAttachmentNameUserInfoKey];
    [self publishEvent:@"DataSyncAttachmentAvailable" withArguments:@{@"_id": identifier, @"_type": type, @"_name": name}];
}

- (void)onAiqDataSyncAttachmentUnavailable:(NSNotification *)notification {
    NSString *solution = notification.userInfo[AIQSolutionUserInfoKey];
    if (! [solution isEqualToString:_solution]) {
        return;
    }
    
    NSString *identifier = notification.userInfo[AIQDocumentIdUserInfoKey];
    NSString *type = notification.userInfo[AIQDocumentTypeUserInfoKey];
    NSString *name = notification.userInfo[AIQAttachmentNameUserInfoKey];
    [self publishEvent:@"DataSyncAttachmentUnavailable" withArguments:@{@"_id": identifier, @"_type": type, @"_name": name}];
}

- (void)onAiqDataSyncAttachmentFailed:(NSNotification *)notification {
    NSString *solution = notification.userInfo[AIQSolutionUserInfoKey];
    if (! [solution isEqualToString:_solution]) {
        return;
    }
    
    NSString *identifier = notification.userInfo[AIQDocumentIdUserInfoKey];
    NSString *type = notification.userInfo[AIQDocumentTypeUserInfoKey];
    NSString *name = notification.userInfo[AIQAttachmentNameUserInfoKey];
    [self publishEvent:@"DataSyncAttachmentFailed" withArguments:@{@"_id": identifier, @"_type": type, @"_name": name}];
}

- (void)onAiqDataSyncAttachmentSynchronized:(NSNotification *)notification {
    NSString *solution = notification.userInfo[AIQSolutionUserInfoKey];
    if (! [solution isEqualToString:_solution]) {
        return;
    }
    
    NSString *identifier = notification.userInfo[AIQDocumentIdUserInfoKey];
    NSString *type = notification.userInfo[AIQDocumentTypeUserInfoKey];
    NSString *name = notification.userInfo[AIQAttachmentNameUserInfoKey];
    [self publishEvent:@"DataSyncAttachmentSynchronized" withArguments:@{@"_id": identifier, @"_type": type, @"_name": name}];
}

- (void)onAiqDataSyncAttachmentRejected:(NSNotification *)notification {
    NSString *solution = notification.userInfo[AIQSolutionUserInfoKey];
    if (! [solution isEqualToString:_solution]) {
        return;
    }
    
    NSString *identifier = notification.userInfo[AIQDocumentIdUserInfoKey];
    NSString *type = notification.userInfo[AIQDocumentTypeUserInfoKey];
    NSString *name = notification.userInfo[AIQAttachmentNameUserInfoKey];
    [self publishEvent:@"DataSyncAttachmentRejected" withArguments:@{@"_id": identifier, @"_type": type, @"_name": name}];
}

- (void)onAiqMessagingAttachmentAvailable:(NSNotification *)notification {
    NSString *solution = notification.userInfo[AIQSolutionUserInfoKey];
    if (! [solution isEqualToString:_solution]) {
        return;
    }
    
    NSString *identifier = notification.userInfo[AIQDocumentIdUserInfoKey];
    NSString *type = notification.userInfo[AIQMessageTypeUserInfoKey];
    NSString *name = notification.userInfo[AIQAttachmentNameUserInfoKey];
    [self publishEvent:@"MessagingAttachmentAvailable" withArguments:@{@"_id": identifier, @"type": type, @"_name": name}];
}

- (void)onAiqMessagingAttachmentUnavailable:(NSNotification *)notification {
    NSString *solution = notification.userInfo[AIQSolutionUserInfoKey];
    if (! [solution isEqualToString:_solution]) {
        return;
    }
    
    NSString *identifier = notification.userInfo[AIQDocumentIdUserInfoKey];
    NSString *type = notification.userInfo[AIQMessageTypeUserInfoKey];
    NSString *name = notification.userInfo[AIQAttachmentNameUserInfoKey];
    [self publishEvent:@"MessagingAttachmentUnavailable" withArguments:@{@"_id": identifier, @"type": type, @"_name": name}];
}

- (void)onAiqMessagingAttachmentFailed:(NSNotification *)notification {
    NSString *solution = notification.userInfo[AIQSolutionUserInfoKey];
    if (! [solution isEqualToString:_solution]) {
        return;
    }
    
    NSString *identifier = notification.userInfo[AIQDocumentIdUserInfoKey];
    NSString *type = notification.userInfo[AIQMessageTypeUserInfoKey];
    NSString *name = notification.userInfo[AIQAttachmentNameUserInfoKey];
    [self publishEvent:@"MessagingAttachmentFailed" withArguments:@{@"_id": identifier, @"type": type, @"_name": name}];
}

- (void)onAiqMessagingMessageReceived:(NSNotification *)notification {
    NSString *solution = notification.userInfo[AIQSolutionUserInfoKey];
    if (! [solution isEqualToString:_solution]) {
        return;
    }
    
    NSString *identifier = notification.userInfo[AIQDocumentIdUserInfoKey];
    NSString *type = notification.userInfo[AIQMessageTypeUserInfoKey];
    [self publishEvent:@"MessagingMessageReceived" withArguments:@{@"_id": identifier, @"type": type}];
}

- (void)onAiqMessagingMessageUpdated:(NSNotification *)notification {
    NSString *solution = notification.userInfo[AIQSolutionUserInfoKey];
    if (! [solution isEqualToString:_solution]) {
        return;
    }
    
    NSString *identifier = notification.userInfo[AIQDocumentIdUserInfoKey];
    NSString *type = notification.userInfo[AIQMessageTypeUserInfoKey];
    [self publishEvent:@"MessagingMessageUpdated" withArguments:@{@"_id": identifier, @"type": type}];
}

- (void)onAiqMessagingMessageExpired:(NSNotification *)notification {
    NSString *solution = notification.userInfo[AIQSolutionUserInfoKey];
    if (! [solution isEqualToString:_solution]) {
        return;
    }
    
    NSString *identifier = notification.userInfo[AIQDocumentIdUserInfoKey];
    NSString *type = notification.userInfo[AIQMessageTypeUserInfoKey];
    [self publishEvent:@"MessagingMessageExpired" withArguments:@{@"_id": identifier, @"type": type}];
}

- (void)onAiqMessagingMessageQueued:(NSNotification *)notification {
    NSString *solution = notification.userInfo[AIQSolutionUserInfoKey];
    if (! [solution isEqualToString:_solution]) {
        return;
    }
    
    NSString *identifier = notification.userInfo[AIQDocumentIdUserInfoKey];
    NSString *destination = notification.userInfo[AIQMessageDestinationUserInfoKey];
    [self publishEvent:@"MessagingMessageQueued" withArguments:@{@"_id": identifier, @"_destination": destination}];
}

- (void)onAiqMessagingMessageAccepted:(NSNotification *)notification {
    NSString *solution = notification.userInfo[AIQSolutionUserInfoKey];
    if (! [solution isEqualToString:_solution]) {
        return;
    }
    
    NSString *identifier = notification.userInfo[AIQDocumentIdUserInfoKey];
    NSString *destination = notification.userInfo[AIQMessageDestinationUserInfoKey];
    [self publishEvent:@"MessagingMessageAccepted" withArguments:@{@"_id": identifier, @"_destination": destination}];
}

- (void)onAiqMessagingMessageRejected:(NSNotification *)notification {
    NSString *solution = notification.userInfo[AIQSolutionUserInfoKey];
    if (! [solution isEqualToString:_solution]) {
        return;
    }
    
    NSString *identifier = notification.userInfo[AIQDocumentIdUserInfoKey];
    NSString *destination = notification.userInfo[AIQMessageDestinationUserInfoKey];
    [self publishEvent:@"MessagingMessageRejected" withArguments:@{@"_id": identifier, @"_destination": destination}];
}

- (void)onAiqMessagingMessageDelivered:(NSNotification *)notification {
    NSString *solution = notification.userInfo[AIQSolutionUserInfoKey];
    if (! [solution isEqualToString:_solution]) {
        return;
    }
    
    NSString *identifier = notification.userInfo[AIQDocumentIdUserInfoKey];
    NSString *destination = notification.userInfo[AIQMessageDestinationUserInfoKey];
    [self publishEvent:@"MessagingMessageDelivered" withArguments:@{@"_id": identifier, @"_destination": destination}];
}

- (void)onAiqMessagingMessageFailed:(NSNotification *)notification {
    NSString *solution = notification.userInfo[AIQSolutionUserInfoKey];
    if (! [solution isEqualToString:_solution]) {
        return;
    }
    
    NSString *identifier = notification.userInfo[AIQDocumentIdUserInfoKey];
    NSString *destination = notification.userInfo[AIQMessageDestinationUserInfoKey];
    [self publishEvent:@"MessagingMessageFailed" withArguments:@{@"_id": identifier, @"_destination": destination}];
}

- (void)onAiqDocumentError:(NSNotification *)notification {
    NSString *solution = notification.userInfo[AIQSolutionUserInfoKey];
    if (! [solution isEqualToString:_solution]) {
        return;
    }
    
    NSInteger statusCode = [notification.userInfo[AIQErrorCodeUserInfoKey] integerValue];
    if (statusCode == 502) {
        AIQSynchronizationStatus status = [notification.userInfo[AIQSynchronizationStatusUserInfoKey] integerValue];
        NSString *action;
        if (status == AIQSynchronizationStatusCreated) {
            action = @"creating";
        } else if (status == AIQSynchronizationStatusUpdated) {
            action = @"updating";
        } else {
            action = @"deleting";
        }
        NSString *command = [NSString stringWithFormat:@"console.error('Invalid response from the Integration Adapter when %@ document %@. Please see server logs for more details.');", action, notification.userInfo[AIQDocumentIdUserInfoKey]];
        [self.webView stringByEvaluatingJavaScriptFromString:command];
    }
}

- (void)onAiqAttachmentError:(NSNotification *)notification {
    NSString *solution = notification.userInfo[AIQSolutionUserInfoKey];
    if (! [solution isEqualToString:_solution]) {
        return;
    }
    
    NSInteger statusCode = [notification.userInfo[AIQErrorCodeUserInfoKey] integerValue];
    if (statusCode == 502) {
        AIQSynchronizationStatus status = [notification.userInfo[AIQSynchronizationStatusUserInfoKey] integerValue];
        NSString *action;
        if (status == AIQSynchronizationStatusCreated) {
            action = @"creating";
        } else if (status == AIQSynchronizationStatusUpdated) {
            action = @"updating";
        } else {
            action = @"deleting";
        }
        NSString *command = [NSString stringWithFormat:@"console.error('Invalid response from the Integration Adapter when %@ attachment %@ for document %@. Please see server logs for more details.');", action, notification.userInfo[AIQAttachmentNameUserInfoKey], notification.userInfo[AIQDocumentIdUserInfoKey]];
        [self.webView stringByEvaluatingJavaScriptFromString:command];
    }
}

- (void)hashChangedTo:(NSString *)hash {
    NSUInteger index = [_navigationStack indexOfObject:hash];
    if (index == NSNotFound) {
        AIQLogCInfo(2, @"Changing hash to %@", hash);
    } else {
        AIQLogCInfo(2, @"Changing hash back to %@", hash);
        NSArray *array = [_navigationStack subarrayWithRange:NSMakeRange(0, index)];
        _navigationStack = [NSMutableArray arrayWithArray:array];
    }
    [_navigationStack addObject:hash];
}

- (BOOL)callbackRegisteredForEvent:(NSString *)event error:(NSError *__autoreleasing *)error {
    @synchronized(_registeredEvents) {
        if (error) {
            *error = nil;
        }

        NSString *internalEvent = _eventMapping[event];
        if (! internalEvent) {
            AIQLogCWarn(1, @"No registered callback for event %@, ignoring", event);
            if (error) {
                *error = [NSError errorWithDomain:@"com.appearnetworks.aiq.core" code:0 userInfo:@{NSLocalizedDescriptionKey: @"Unknown event"}];
            }
            return NO;
        }
        AIQLogCInfo(2, @"Registering callback for event %@", internalEvent);
        NSNumber *number = _registeredEvents[internalEvent];
        if (! number) {
            number = @0;
        }
        NSInteger count = number.integerValue + 1;
        _registeredEvents[internalEvent] = @(count);
        if (count == 1) {
            AIQLogCInfo(2, @"Starting listening to event %@", internalEvent);
            SEL selector = NSSelectorFromString([event stringByAppendingString:@":"]);
            LISTEN(self, selector, internalEvent);
        }
        return YES;
    }
}

- (BOOL)callbackUnregisteredForEvent:(NSString *)event count:(NSUInteger)count error:(NSError *__autoreleasing *)error {
    @synchronized(_registeredEvents) {
        if (error) {
            *error = nil;
        }

        NSString *internalEvent = _eventMapping[event];
        if (! internalEvent) {
            if (error) {
                *error = [NSError errorWithDomain:@"com.appearnetworks.aiq.core" code:0 userInfo:@{NSLocalizedDescriptionKey: @"Unknown event"}];
            }
            return NO;
        }
        NSNumber *number = _registeredEvents[internalEvent];
        if (! number) {
            if (error) {
                *error = [NSError errorWithDomain:@"com.appearnetworks.aiq.core" code:1 userInfo:@{NSLocalizedDescriptionKey: @"Event not registered"}];
            }
            return NO;
        }
        if (count == 0) {
            if (error) {
                *error = [NSError errorWithDomain:@"com.appearnetworks.aiq.core" code:2 userInfo:@{NSLocalizedDescriptionKey: @"No events to unregister"}];
            }
        }
        if (count > number.integerValue) {
            if (error) {
                *error = [NSError errorWithDomain:@"com.appearnetworks.aiq.core" code:3 userInfo:@{NSLocalizedDescriptionKey: @"Too many events"}];
            }
            return NO;
        }
        AIQLogCInfo(2, @"Unregistering %lu callback(s) for event %@", (unsigned long)count, internalEvent);
        NSUInteger newCount = number.integerValue - count;
        _registeredEvents[internalEvent] = @(newCount);
        if (newCount == 0) {
            AIQLogCInfo(2, @"Stopping listening to event %@", internalEvent);
            [[NSNotificationCenter defaultCenter] removeObserver:self name:internalEvent object:nil];

        }
        return YES;
    }
}

@end
