#import "AIQSession+RACExtensions.h"
#import "RACReplaySubject.h"

@implementation AIQSession (RACExtensions)

+ (RACSignal *)resume {
    RACReplaySubject *subject = [RACReplaySubject subject];

    NSError *error = nil;
    AIQSession *session = [AIQSession resume:&error];
    if (session) {
        [subject sendNext:session];
        [subject sendCompleted];
    } else {
        [subject sendError:error];
    }

    return subject;
}

- (RACSignal *)openForUser:(NSString *)username password:(NSString *)password inOrganization:(NSString *)organization {
    return [self openForUser:username password:password info:nil inOrganization:organization];
}

- (RACSignal *)openForUser:(NSString *)username password:(NSString *)password info:(NSDictionary *)info inOrganization:(NSString *)organization {
    RACReplaySubject *subject = [RACReplaySubject subject];

    [self openForUser:username password:password info:info inOrganization:organization success:^{
        [subject sendCompleted];
    } failure:^(NSError *error) {
        [subject sendError:error];
    }];

    return subject;
}

- (RACSignal *)close {
    RACReplaySubject *subject = [RACReplaySubject subject];

    [self close:^{
        [subject sendCompleted];
    } failure:^(NSError *error) {
        [subject sendError:error];
    }];

    return subject;
}

@end