#import <AIQCoreLib/AIQDataStore.h>
#import <AIQCoreLib/AIQError.h>
#import <AIQCoreLib/AIQLog.h>
#import <AIQCoreLib/AIQMessaging.h>
#import <AIQCoreLib/AIQSession.h>

#import "MessagingProtocol.h"
#import "NSURL+Helpers.h"

@implementation MessagingProtocol

+ (void)load {
    [NSURLProtocol registerClass:[MessagingProtocol class]];
}

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    return [request.URL.scheme isEqualToString:@"aiq-messaging"];
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
    AIQMessaging *messaging = [[AIQSession currentSession] messagingForSolution:solution error:&error];
    if (! messaging) {
        [self.client URLProtocol:self didFailWithError:error];
        return;
    }
    
    if (! [messaging attachmentWithName:name existsForMessageWithId:identifier]) {
        NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:self.request.URL statusCode:404 HTTPVersion:@"1.0" headerFields:@{}];
        [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
        [self.client URLProtocolDidFinishLoading:self];
        return;
    }
    
    NSDictionary *attachment = [messaging attachmentWithName:name forMessageWithId:identifier error:&error];
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
    
    NSData *data = [messaging dataForAttachmentWithName:name fromMessageWithId:identifier error:&error];
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
