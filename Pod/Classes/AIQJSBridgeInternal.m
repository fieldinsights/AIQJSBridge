//
//  AIQJSBridgeInternal.m
//  AIQJSBridge
//
//  Created by Marcin Lukow on 2014-01-15.
//  Copyright (c) 2014 Appear Networks Systems AB. All rights reserved.
//

#import "AIQJSBridgeInternal.h"
#import <Cordova/CDVAvailability.h>

@implementation AIQJSBridgeInternal

+ (NSUInteger)apiLevel {
    return 8;
}

+ (NSString *)cordovaVersion {
    return CDV_VERSION;
}

@end
