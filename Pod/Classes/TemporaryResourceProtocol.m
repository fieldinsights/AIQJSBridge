#import <AIQCoreLib/AIQLog.h>

#import "TemporaryResourceProtocol.h"
#import "NSURL+Helpers.h"

@implementation TemporaryResourceProtocol

+ (void)load {
    [NSURLProtocol registerClass:[TemporaryResourceProtocol class]];
}

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    return [request.URL.scheme isEqualToString:@"aiq-resource"];
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

- (void)startLoading {
    AIQLogCInfo(2, @"Start loading");
    if (! [self.request.URL.host isEqualToString:@"resource"]) {
        NSDictionary *userInfo = @{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Unknown command: %@", self.request.URL.host]};
        NSError *error = [NSError errorWithDomain:@"com.appearnetworks.aiq.resource" code:-1 userInfo:userInfo];
        [self.client URLProtocol:self didFailWithError:error];
        return;
    }

    NSDictionary *params = [self.request.URL queryAsDictionary];
    NSString *identifier = [params valueForKey:@"id"];
    NSString *contentType = [params valueForKey:@"contentType"];
    NSString *folder = [params valueForKey:@"folder"];

    NSString *resourceUrl = [[NSTemporaryDirectory() stringByAppendingPathComponent:folder] stringByAppendingPathComponent:identifier];

    NSError *error = nil;
    NSData *data = [NSData dataWithContentsOfFile:resourceUrl options:NSDataReadingUncached error:&error];
    if (! data) {
        [self.client URLProtocol:self didFailWithError:error];
        return;
    }
    
    NSDictionary *headers = @{@"Access-Control-Allow-Origin" : @"*",
                              @"Access-Control-Allow-Headers" : @"Content-Type",
                              @"Content-Type": contentType};
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:self.request.URL statusCode:200 HTTPVersion:@"1.1" headerFields:headers];
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageAllowedInMemoryOnly];
    [self.client URLProtocol:self didLoadData:data];
    [self.client URLProtocolDidFinishLoading:self];
}

- (void)stopLoading {

}

@end
