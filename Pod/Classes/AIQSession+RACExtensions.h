#ifndef AIQCoreLib_AIQSession_RACExtensions_h
#define AIQCoreLib_AIQSession_RACExtensions_h

#import "AIQSession.h"
#import "RACSignal.h"

@interface AIQSession (RACExtensions)

+ (RACSignal *)resume;

- (RACSignal *)openForUser:(NSString *)username
                  password:(NSString *)password
            inOrganization:(NSString *)organization;

- (RACSignal *)openForUser:(NSString *)username
                  password:(NSString *)password
                      info:(NSDictionary *)info
            inOrganization:(NSString *)organization;

- (RACSignal *)close;

@end

#endif /* AIQCoreLib_AIQSession_RACExtensions_h */