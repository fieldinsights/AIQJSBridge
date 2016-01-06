//
//  NSURL+Helpers.m
//  AIQ
//
//  Created by Marcin Lukow on 2/2/12.
//  Copyright (c) 2012 Appear Networks Systems AB. All rights reserved.
//

#import "NSURL+Helpers.h"

@implementation NSURL (Helpers)

- (NSDictionary *)queryAsDictionary {
    NSArray *params = [self.query componentsSeparatedByString:@"&"];
    NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity:params.count];
    for (NSString *param in params) {
        NSArray *pair = [param componentsSeparatedByString:@"="];
        [result setValue:[pair objectAtIndex:1] forKey:[pair objectAtIndex:0]];
    }
    return [NSDictionary dictionaryWithDictionary:result];
}

@end
