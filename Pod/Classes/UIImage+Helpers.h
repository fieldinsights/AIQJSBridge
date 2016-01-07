//
//  UIImage+Helpers.h
//  AIQ
//
//  Created by Marcin Łuków on 3/8/12.
//  Copyright (c) 2012 Appear Networks. All rights reserved.
//

@interface UIImage (Helpers)

+ (void)initialize;

/*!
 @method scaleTo:
 
 @abstract Scales the image to the given size.
 @discussion This method can be used to scale the image to the
 given size, keeping the image proportions.
 
 @param size target size
 @return scaled image, will not be null
 */
- (UIImage *)scaleTo:(CGSize)size;

- (UIImage *)scaleTo:(CGSize)size force:(BOOL)force;

/*!
 @method scaleToMatch:
 
 @discussion Returns the scaled size of the image.
 @discussion Thi method can be used to obtain the new size of the
 image, matching the given size and keeping the image proportions.
 
 @param size target size
 @return new image size
 */
- (CGSize)scaleToMatch:(CGSize)size;

@end
