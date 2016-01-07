#import <sys/time.h>
#import <AIQCoreLib/AIQLog.h>

#import "CSSFilteringProtocol.h"

@interface CSSFilteringProtocol () <NSURLConnectionDataDelegate>

@property (nonatomic, retain) NSMutableData *data;
@property (nonatomic, retain) NSURLConnection *connection;

@end

@implementation CSSFilteringProtocol

+ (void)load {
    [NSURLProtocol registerClass:[CSSFilteringProtocol class]];
}

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    return (([request.URL.scheme isEqualToString:@"file"]) && // only for local files
            ([[request.URL.pathExtension lowercaseString] isEqualToString:@"html"]));
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

+ (BOOL)requestIsCacheEquivalent:(NSURLRequest *)a toRequest:(NSURLRequest *)b {
    return NO;
}

- (void)startLoading {
    AIQLogCInfo(2, @"Start loading");

    if (! [[NSFileManager defaultManager] fileExistsAtPath:self.request.URL.path]) {
        NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:self.request.URL statusCode:404 HTTPVersion:@"1.0" headerFields:@{}];
        [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
        [self.client URLProtocolDidFinishLoading:self];
        return;
    }

    NSError *error = nil;
    NSMutableString *body = [NSMutableString stringWithContentsOfFile:self.request.URL.path encoding:NSUTF8StringEncoding error:&error];
    if (! body) {
        [self.client URLProtocol:self didFailWithError:error];
        return;
    }

    struct timeval time;
    gettimeofday(&time, NULL);
    long millis = (time.tv_sec * 1000) + (time.tv_usec / 1000);

    NSRange range = NSMakeRange(0, body.length);
    while(range.location != NSNotFound) {
        range = [body rangeOfString:@".css" options:NSCaseInsensitiveSearch range:range];
        if(range.location != NSNotFound) {
            unichar c = [body characterAtIndex:range.location + range.length];
            if (c == '?') {
                [body replaceCharactersInRange:NSMakeRange(range.location, range.length + 1) withString:[NSString stringWithFormat:@".css?__aiq_v=%ld&", millis]];
            } else if (c == '"') {
                [body replaceCharactersInRange:range withString:[NSString stringWithFormat:@".css?__aiq_v=%ld", millis]];
            }
            range = NSMakeRange(range.location + range.length, body.length - (range.location + range.length));
        }
    }

    range = NSMakeRange(0, body.length);
    while(range.location != NSNotFound) {
        range = [body rangeOfString:@".js" options:NSCaseInsensitiveSearch range:range];
        if(range.location != NSNotFound) {
            unichar c = [body characterAtIndex:range.location + range.length];
            if (c == '?') {
                [body replaceCharactersInRange:NSMakeRange(range.location, range.length + 1) withString:[NSString stringWithFormat:@".js?__aiq_v=%ld&", millis]];
            } else if (c == '"') {
                [body replaceCharactersInRange:range withString:[NSString stringWithFormat:@".js?__aiq_v=%ld", millis]];
            }
            range = NSMakeRange(range.location + range.length, body.length - (range.location + range.length));
        }
    }

    NSData *data = [body dataUsingEncoding:NSUTF8StringEncoding];
    NSURLResponse *response = [[NSURLResponse alloc] initWithURL:self.request.URL MIMEType:@"text/html" expectedContentLength:data.length textEncodingName:@"UTF-8"];
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    [self.client URLProtocol:self didLoadData:data];
    [self.client URLProtocolDidFinishLoading:self];
}

- (void)stopLoading {

}

@end
