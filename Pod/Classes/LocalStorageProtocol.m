#import <AIQCoreLib/AIQDataStore.h>
#import <AIQCoreLib/AIQLocalStorage.h>
#import <AIQCoreLib/AIQLog.h>
#import <AIQCoreLib/AIQSession.h>

#import "LocalStorageProtocol.h"
#import "NSURL+Helpers.h"

@implementation LocalStorageProtocol

+ (void)load {
    [NSURLProtocol registerClass:[LocalStorageProtocol class]];
}

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    return [request.URL.scheme isEqualToString:@"aiq-localstorage"];
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

- (void)startLoading {
    AIQLogCInfo(2, @"Start loading");
    if (! [self.request.URL.host isEqualToString:@"attachment"]) {
        NSString *message = [NSString stringWithFormat:@"Unknown command: %@", self.request.URL.host];
        NSDictionary *userInfo = @{NSLocalizedDescriptionKey: message};
        NSError *error = [NSError errorWithDomain:@"com.appearnetworks.aiq.LocalStorage" code:-1 userInfo:userInfo];
        [self.client URLProtocol:self didFailWithError:error];
        return;
    }

    NSError *error = nil;
    NSDictionary *params = [self.request.URL queryAsDictionary];
    NSString *name = params[@"name"];
    NSString *identifier = params[@"identifier"];
    NSString *solution = params[@"solution"];

    AIQLocalStorage *storage = [[AIQSession currentSession] localStorageForSolution:solution error:&error];
    if (! storage) {
        [self.client URLProtocol:self didFailWithError:error];
        return;
    }
    
    NSDictionary *attachment = [storage attachmentWithName:name forDocumentWithId:identifier error:&error];
    if (! attachment) {
        [self.client URLProtocol:self didFailWithError:error];
        return;
    }
    
    NSData *data = [storage dataForAttachmentWithName:name fromDocumentWithId:identifier error:&error];
    if (! data) {
        [self.client URLProtocol:self didFailWithError:error];
        return;
    }
    
    NSDictionary *headers = @{@"Access-Control-Allow-Origin" : @"*",
                              @"Access-Control-Allow-Headers" : @"Content-Type",
                              @"Content-Type": attachment[kAIQAttachmentContentType]};
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:self.request.URL statusCode:200 HTTPVersion:@"1.1" headerFields:headers];
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageAllowedInMemoryOnly];
    [self.client URLProtocol:self didLoadData:data];
    [self.client URLProtocolDidFinishLoading:self];
}

- (void)stopLoading {

}

@end
