#import "AIQViewController.h"
#import "AIQSession+RACExtensions.h"

@interface AIQViewController () {
    AIQSession *_session;
}

@end

@implementation AIQViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    if ([AIQSession canResume]) {
        [[AIQSession resume] subscribeNext:^(AIQSession *session) {
            NSLog(@"Did resume session");
            _session = session;
        } error:^(NSError *error) {
            NSLog(@"Did fail to resume session: %@", error);
        }];
    } else {
        _session = [AIQSession sessionWithBaseURL:[NSURL URLWithString:@"XXX"]];
        [[_session openForUser:@"XXX" password:@"XXX" inOrganization:@"XXX"] subscribeError:^(NSError *error) {
            NSLog(@"Did fail to open session: %@", error.localizedDescription);
        } completed:^{
            NSLog(@"Did open session");
        }];
    }
}

@end
