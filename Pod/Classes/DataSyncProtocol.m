#import <AIQCoreLib/AIQDataStore.h>
#import <AIQCoreLib/AIQError.h>
#import <AIQCoreLib/AIQLog.h>
#import <AIQCoreLib/AIQSession.h>

#import "DataSyncProtocol.h"
#import "NSURL+Helpers.h"

@implementation DataSyncProtocol

+ (void)load {
    [NSURLProtocol registerClass:[DataSyncProtocol class]];
}

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    return [request.URL.scheme isEqualToString:@"aiq-datasync"];
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

- (void)startLoading {
    AIQLogCInfo(2, @"Start loading");
    if (! [self.request.URL.host isEqualToString:@"attachment"]) {
        [self.client URLProtocol:self didFailWithError:[AIQError errorWithCode:AIQErrorConnectionFault message:[NSString stringWithFormat:@"Unknown command: %@", self.request.URL.host]]];
        return;
    }
    
    NSError *error = nil;
    NSDictionary *params = [self.request.URL queryAsDictionary];
    NSString *name = params[@"name"];
    NSString *identifier = params[@"identifier"];
    NSString *solution = params[@"solution"];
    AIQDataStore *store = [[AIQSession currentSession] dataStoreForSolution:solution error:&error];
    if (! store) {
        [self.client URLProtocol:self didFailWithError:error];
        return;
    }
    
    if (! [store attachmentWithName:name existsForDocumentWithId:identifier]) {
        NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:self.request.URL statusCode:404 HTTPVersion:@"1.0" headerFields:@{}];
        [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
        [self.client URLProtocolDidFinishLoading:self];
        return;
    }
    
    NSDictionary *attachment = [store attachmentWithName:name forDocumentWithId:identifier error:&error];
    if (! attachment) {
        [self.client URLProtocol:self didFailWithError:error];
        return;
    }
    
    AIQAttachmentState state = [attachment[kAIQAttachmentState] intValue];
    if (state != AIQAttachmentStateAvailable) {
        NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:self.request.URL statusCode:404 HTTPVersion:@"1.0" headerFields:@{}];
        [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
        [self.client URLProtocolDidFinishLoading:self];
        return;
    }
    
    NSData *data = [store dataForAttachmentWithName:name fromDocumentWithId:identifier error:&error];
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
