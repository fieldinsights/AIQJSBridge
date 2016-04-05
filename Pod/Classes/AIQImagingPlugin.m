#import <AIQCoreLib/AIQDataStore.h>
#import <AIQCoreLib/AIQError.h>
#import <AIQCoreLib/AIQLog.h>
#import <AIQCoreLib/AIQSession.h>

#import "AIQImagingPlugin.h"
#import "UIImage+Helpers.h"
#import "CLImageEditor.h"
#import "AIQLaunchableViewController.h"

@interface AIQImagingPlugin () <UINavigationControllerDelegate,
UIImagePickerControllerDelegate,
UIPopoverControllerDelegate,
CLImageEditorDelegate>

@property (nonatomic, retain) NSString *documentId;
@property (nonatomic, retain) UIImagePickerController *imagePicker;
@property (nonatomic, retain) CLImageEditor *imageEditor;
@property (nonatomic, retain) UIPopoverController *popoverController;
@property (nonatomic, retain) CDVInvokedUrlCommand *command;

@end

@implementation AIQImagingPlugin

- (void)capture:(CDVInvokedUrlCommand *)command {
    BOOL allowsEditing = [[command argumentAtIndex:0 withDefault:@NO andClass:[NSNumber class]] boolValue];
    NSString *source = [command argumentAtIndex:1 withDefault:@"camera" andClass:[NSString class]];
    _documentId = [command argumentAtIndex:2 withDefault:nil andClass:[NSString class]];
    
    _imagePicker = [[UIImagePickerController alloc] init];
    _imagePicker.view.frame = self.viewController.view.frame;
    _imagePicker.modalPresentationStyle = UIModalPresentationCurrentContext;
    _imagePicker.delegate = self;
    if (source) {
        if ([source isEqualToString:@"camera"]) {
            if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
                AIQLogCInfo(2, @"Taking picture with built-in camera");
                _imagePicker.sourceType =  UIImagePickerControllerSourceTypeCamera;
            } else {
                AIQLogCWarn(2, @"Device does not have a camera, defaulting to library");
                _imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            }
        } else if ([source isEqualToString:@"library"]) {
            AIQLogCInfo(2, @"Selecting image from a library");
            _imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        } else {
            if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
                AIQLogCInfo(2, @"Taking picture with built-in camera");
                _imagePicker.sourceType =  UIImagePickerControllerSourceTypeCamera;
            } else {
                AIQLogCInfo(2, @"Selecting image from a library");
                _imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            }
        }
    } else {
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
            AIQLogCInfo(2, @"Taking picture with built-in camera");
            _imagePicker.sourceType =  UIImagePickerControllerSourceTypeCamera;
        } else {
            AIQLogCInfo(2, @"Selecting image from a library");
            _imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        }
    }
    
    if (allowsEditing) {
        AIQLogCInfo(2, @"Enabling image editor");
        _imagePicker.allowsEditing = allowsEditing;
    }
    
    _command = command;
    
    UIViewController *root = [[UIApplication sharedApplication].delegate window].rootViewController;
    if ((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) && (_imagePicker.sourceType == UIImagePickerControllerSourceTypePhotoLibrary)) {
        _popoverController = [[UIPopoverController alloc] initWithContentViewController:_imagePicker];
        _popoverController.delegate = self;
        [_popoverController presentPopoverFromRect:self.webView.frame inView:root.view permittedArrowDirections:0 animated:YES];
    } else {
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
        [root presentViewController:_imagePicker animated:YES completion:nil];
    }
}

-(void)edit:(CDVInvokedUrlCommand *)command
{
    NSString *imageUri = [command argumentAtIndex:0 withDefault:nil andClass:[NSString class]];
    NSString *solution = ((AIQLaunchableViewController *)self.viewController).solution;

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *error = nil;
        AIQDataStore *dataStore = [[AIQSession currentSession] dataStoreForSolution:solution error:&error];

        if (! dataStore) {
            AIQLogCError(2, @"Error retrieving data store: %@", error.localizedDescription);
            [self failWithError:error command:command];
            return;
        }

        NSData* imageData = [dataStore dataForAttachmentAtPath:imageUri];

        if (! imageData) {
            AIQLogCError(2, @"Error loading image data");
            [self failWithError:nil command:command];
            return;
        }

        UIImage *image = [UIImage imageWithData:imageData];

        if (! image) {
            AIQLogCError(2, @"Error loading image data");
            [self failWithError:nil command:command];
            return;
        }

        dispatch_sync(dispatch_get_main_queue(), ^{
            AIQLogCInfo(2, @"Editing image at %@", imageUri);
            _command = command;

            _imageEditor = [[CLImageEditor alloc] initWithImage:image];
            _imageEditor.delegate = self;

            UIViewController *root = [[UIApplication sharedApplication].delegate window].rootViewController;
            [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
            [root presentViewController:_imageEditor animated:YES completion:nil];
        });
    });
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    AIQLogCInfo(2, @"Image selected");
    if (_popoverController) {
        [_popoverController dismissPopoverAnimated:YES];
        _popoverController = nil;
        
        UIImage *image;
        if (picker.allowsEditing) {
            image = [info valueForKey:UIImagePickerControllerEditedImage];
        } else {
            image = [info valueForKey:UIImagePickerControllerOriginalImage];
        }
        
        [self completeWithImage:image];
    } else {
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
        [_imagePicker dismissViewControllerAnimated:YES completion:^{
            _imagePicker = nil;
            
            UIImage *image;
            if (picker.allowsEditing) {
                image = [info valueForKey:UIImagePickerControllerEditedImage];
            } else {
                image = [info valueForKey:UIImagePickerControllerOriginalImage];
            }
            
            [self completeWithImage:image];
        }];
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    AIQLogCInfo(2, @"Picker dismissed");
    if (_popoverController) {
        [_popoverController dismissPopoverAnimated:YES];
        _popoverController = nil;
    } else {
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
        [_imagePicker dismissViewControllerAnimated:YES completion:nil];
        _imagePicker = nil;
    }
    _popoverController = nil;
    
    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:@{@"cancel": @YES}];
    [self.commandDelegate sendPluginResult:result callbackId:_command.callbackId];
}

#pragma mark - UIPopoverControllerDelegate

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    AIQLogCInfo(2, @"Picker dismissed");
    _popoverController = nil;
    _imagePicker = nil;
    
    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:@{@"cancel": @YES}];
    [self.commandDelegate sendPluginResult:result callbackId:_command.callbackId];
}

#pragma mark - CLImageEditor delegate

- (void) imageEditor:(CLImageEditor *)editor didFinishEdittingWithImage:(UIImage *)image {
    AIQLogCInfo(2, @"Done editing image");

    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
    [_imageEditor dismissViewControllerAnimated:YES completion:^{
        _imageEditor = nil;
        [self completeWithImage:image];
    }];
}

- (void) imageEditorDidCancel:(CLImageEditor *)editor {
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
    [_imageEditor dismissViewControllerAnimated:YES completion:nil];
    _imageEditor = nil;

    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:@{@"cancel": @YES}];
    [self.commandDelegate sendPluginResult:result callbackId:_command.callbackId];
}

#pragma mark - Private API

- (void)completeWithImage:(UIImage *)originalImage {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIImage *image = [self fixRotation:originalImage];
        NSData *data = UIImageJPEGRepresentation([image scaleTo:CGSizeMake(1500.0f, 1500.0f) force:NO], 0.5f);
        
        CFUUIDRef uuid = CFUUIDCreate(NULL);
        CFStringRef uuidString = CFUUIDCreateString(NULL, uuid);
        CFRelease(uuid);
        NSString *name = CFBridgingRelease(uuidString);
        NSString *solution = ((AIQLaunchableViewController *)self.viewController).solution;
        
        if (_documentId) {
            // backward compatibility ftw
            NSError *error = nil;
            AIQDataStore *dataStore = [[AIQSession currentSession] dataStoreForSolution:solution error:&error];
            if (! dataStore) {
                AIQLogCError(2, @"Error retrieving data store: %@", error.localizedDescription);
                [self failWithError:error command:_command];
                return;
            }
            
            AIQLogCInfo(2, @"Storing image for document %@", _documentId);
            NSDictionary *attachment = [dataStore createAttachmentWithName:name contentType:@"image/jpeg" andData:data forDocumentWithId:_documentId error:&error];
            [dataStore close];
            if (! attachment) {
                AIQLogCError(2, @"Error storing image for document %@: %@", _documentId, error.localizedDescription);
                [self failWithError:error command:_command];
                return;
            }
            
            AIQLogCInfo(2, @"Image %@ stored for document %@", name, _documentId);
            AIQAttachmentState state = [attachment[kAIQAttachmentState] intValue];
            NSMutableDictionary *args = [NSMutableDictionary dictionaryWithCapacity:4];
            [args setValue:name forKey:@"name"];
            if (state == AIQAttachmentStateAvailable) {
                [args setValue:@"available" forKey:@"state"];
            } else if (state == AIQAttachmentStateUnavailable) {
                [args setValue:@"unavailable" forKey:@"state"];
            } else {
                [args setValue:@"failed" forKey:@"state"];
            }
            [args setValue:attachment[kAIQAttachmentContentType] forKey:@"contentType"];
            [args setValue:[NSString stringWithFormat:@"aiq-datasync://attachment?name=%@&identifier=%@&solution=%@", name, _documentId, solution] forKey:@"resourceId"];
            AIQLogCInfo(2, @"Image successfully stored for document %@", _documentId);
            
            CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:args];
            [self.commandDelegate sendPluginResult:result callbackId:_command.callbackId];
        } else {
            // the new way
            NSError *error = nil;
            NSString *folder = [NSString stringWithFormat:@"%02lX", (long)[[AIQSession currentSession] sessionId].hash];
            NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:folder];
            NSFileManager *fileManager = [NSFileManager defaultManager];
            if (! [fileManager fileExistsAtPath:path]) {
                [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error];
            }
            if (! [data writeToFile:[path stringByAppendingPathComponent:name] options:NSDataWritingFileProtectionNone error:&error]) {
                AIQLogCError(2, @"Error storing image: %@", error.localizedDescription);
                [self failWithError:error command:_command];
                return;
            }
            
            NSMutableDictionary *args = [NSMutableDictionary dictionaryWithCapacity:2];
            [args setValue:@"image/jpeg" forKey:@"contentType"];
            [args setValue:[NSString stringWithFormat:@"aiq-resource://resource?id=%@&contentType=image/jpeg&folder=%@", name, folder] forKey:@"resourceUrl"];
            AIQLogCInfo(2, @"Temporary image successfully stored");
            
            CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:args];
            [self.commandDelegate sendPluginResult:result callbackId:_command.callbackId];
        }
    });
}

- (UIImage *)fixRotation:(UIImage *)image {
    if (image.imageOrientation == UIImageOrientationUp) {
        return image;
    }
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (image.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.width, image.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, image.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        case UIImageOrientationUp:
        case UIImageOrientationUpMirrored:
            break;
    }
    
    switch (image.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        case UIImageOrientationUp:
        case UIImageOrientationDown:
        case UIImageOrientationLeft:
        case UIImageOrientationRight:
            break;
    }
    
    CGContextRef ctx = CGBitmapContextCreate(NULL,
                                             image.size.width,
                                             image.size.height,
                                             CGImageGetBitsPerComponent(image.CGImage),
                                             0,
                                             CGImageGetColorSpace(image.CGImage),
                                             CGImageGetBitmapInfo(image.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (image.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            // Grr...
            CGContextDrawImage(ctx, CGRectMake(0,0,image.size.height,image.size.width), image.CGImage);
            break;
            
        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,image.size.width,image.size.height), image.CGImage);
            break;
    }
    
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    
    return img;
}

@end
