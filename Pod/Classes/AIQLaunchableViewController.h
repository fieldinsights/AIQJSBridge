#ifndef AIQJSBridge_AIQLaunchableViewController_h
#define AIQJSBridge_AIQLaunchableViewController_h

/*!
 @header AIQLaunchableViewController.h
 @author Marcin Lukow
 @copyright 2012 Appear Networks Systems AB
 @updated 2012-01-02
 @brief View controller for displaying launchables.
 @version 1.0.0
 */

#import <Cordova/CDVViewController.h>

@class AIQLaunchableViewController;
@class AIQContext;
@class AIQDataStore;
@class AIQLocalStorage;
@class AIQMessaging;


/** Delegate for the launchable module.
 
 This delegate, if specified, will be notified about the actions performed on the
 controller.
 
 @since 1.0.0
 */
@protocol AIQLaunchableViewControllerDelegate <NSObject>

/** Notifies that the controller has been closed.
 
 This action is called when the launchable has closed itself or when user navigated
 out of the launchable using the back button.
 
 @param controller AIQLaunchableViewController instance that generated the event. Will
 not be nil.
 */
- (void)didClose:(AIQLaunchableViewController *)controller;

/** Tells the delegate to perform synchronization.
 
 This action is callen when the launchable requests synchronization.
 
 @param controller AIQLaunchableViewController instance that generated the event. Will
 not be nil.
 
 @since 1.0.0
 */
- (void)synchronize:(AIQLaunchableViewController *)controller;

@end

@interface AIQLaunchableViewController : CDVViewController


/**---------------------------------------------------------------------------------------
 * @name Properties
 * ---------------------------------------------------------------------------------------
 */

/** AIQLaunchableViewController delegate.
 
 This delegate, if specified, will be notified about the actions performed on the
 controller. May be nil.
 
 @since 1.0.0
 @see AIQLaunchableViewControllerDelegate
 */
@property (nonatomic, retain) id<AIQLaunchableViewControllerDelegate> delegate;

@property (nonatomic, retain) NSString *name;

/** Launchable icon.
 
 The icon to be displayed on the navigation bar of the controller. May be nil.
 
 @since 1.0.0
 */
@property (nonatomic, retain) UIImage *icon;

/** Launchable path.
 
 This path is used to load the launchable contents. Must not be nil and must point to
 the extracted launchable folder.
 
 @since 1.0.0
 */
@property (nonatomic, retain) NSString *path;

/** Launchable identifier.
 
 Business document identifier is used to listen for document events and close the view
 in case the owner document has been deleted. Must not be nil.
 
 @since 1.0.0
 */
@property (nonatomic, retain) NSString *identifier;

@property (nonatomic, retain) NSString *solution;

/** Launchable arguments.
 
 This is the dictionary of arguments to be passed to the launchable. May be nil, otherwise
 it will be transformed into request arguments to the launchable.
 
 @since 1.0.0
 */
@property (nonatomic, retain) NSDictionary *arguments;

/**---------------------------------------------------------------------------------------
 * @name Other methods
 * ---------------------------------------------------------------------------------------
 */

/** Navigates back.
 
 This method can be used to go back within the launchable. If the launchable displays its
 root view, the launchable controller will be closed.
 
 @param sender UIControl instance that generated the event. May be nil.
 
 @since 1.0.0
 */
- (IBAction)back:(id)sender;

/** Closes the launchable.
 
 This method can be used to close the launchable controller.
 
 @since 1.0.0
 */
- (void)close;

- (BOOL)canGoBack;

@end

#endif /* AIQJSBridge_AIQLaunchableViewController_h */
