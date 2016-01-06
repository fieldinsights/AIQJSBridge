//
//  UIImage+Helpers.m
//  AIQ
//
//  Created by Marcin Łuków on 3/8/12.
//  Copyright (c) 2012 Appear Networks. All rights reserved.
//

#import <objc/runtime.h>
#import <objc/message.h>

#import "UIImage+Helpers.h"

static Method origImageNamedMethod = nil;

@implementation UIImage (Helpers)

+ (void)initialize {
    if(!origImageNamedMethod) {
        origImageNamedMethod = class_getClassMethod(self, @selector(imageNamed:));
        method_exchangeImplementations(origImageNamedMethod, class_getClassMethod(self, @selector(retina4ImageNamed:)));
    }
}

+ (UIImage *)retina4ImageNamed:(NSString *)imageName {
    NSMutableString *imageNameMutable = [imageName mutableCopy];
    NSRange retinaAtSymbol = [imageName rangeOfString:@"@"];
    if (retinaAtSymbol.location != NSNotFound) {
        [imageNameMutable insertString:@"-568h" atIndex:retinaAtSymbol.location];
    } else {
        CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
        if ([UIScreen mainScreen].scale == 2.f && screenHeight == 568.0f) {
            NSRange dot = [imageName rangeOfString:@"."];
            if (dot.location != NSNotFound) {
                [imageNameMutable insertString:@"-568h" atIndex:dot.location];
            } else {
                [imageNameMutable appendString:@"-568h"];
            }
        }
    }
    
    UIImage* ret = [UIImage retina4ImageNamed:imageNameMutable];
    if (ret)
        return ret;
    else
        return [UIImage retina4ImageNamed:imageName];
}

- (UIImage *)scaleTo:(CGSize)size {
    return [self scaleTo:size force:YES];
}

- (UIImage *)scaleTo:(CGSize)size force:(BOOL)force {
    UIImage *result;
    
    if ((size.width >= self.size.width) && (size.height >= self.size.height) && (! force)) {
        result = self;
    } else {
        CGFloat scaledWidth = size.width;
        CGFloat scaledHeight = size.height;
        
        if (! CGSizeEqualToSize(self.size, size)) {
            CGFloat widthFactor = size.width / self.size.width;
            CGFloat heightFactor = size.height / self.size.height;
            CGFloat scaleFactor = (widthFactor < heightFactor) ? widthFactor : heightFactor;
            scaledWidth  = self.size.width * scaleFactor;
            scaledHeight = self.size.height * scaleFactor;
        }
        
        UIGraphicsBeginImageContext(CGSizeMake(scaledWidth, scaledHeight));
        
        CGRect thumbnailRect = CGRectZero;
        thumbnailRect.origin = CGPointMake(0.0f, 0.0f);
        thumbnailRect.size.width  = scaledWidth;
        thumbnailRect.size.height = scaledHeight;
        
        [self drawInRect:thumbnailRect];
        
        result = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    
    return result;
}

- (CGSize)scaleToMatch:(CGSize)size {
    CGFloat targetWidth = size.width;
    CGFloat targetHeight = size.height;
    
    CGFloat scaleFactor = 0.0f;
    CGFloat scaledWidth = targetWidth;
    CGFloat scaledHeight = targetHeight;
    
    if (! CGSizeEqualToSize(self.size, size)) {
        CGFloat widthFactor = targetWidth / self.size.width;
        CGFloat heightFactor = targetHeight / self.size.height;
        
        if (widthFactor < heightFactor) {
            scaleFactor = widthFactor;
        } else {
            scaleFactor = heightFactor;
        }
        
        scaledWidth  = self.size.width * scaleFactor;
        scaledHeight = self.size.height * scaleFactor;
    }
    
    return CGSizeMake(scaledWidth, scaledHeight);
}

@end
