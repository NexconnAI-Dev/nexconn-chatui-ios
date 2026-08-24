//
//  NCAlertView.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NCAlertView : UIView

/*!
 Show AlertController

 @param title title
 @param message  message
 @param cancelTitle Cancel title

  Displayed on the keyWindow's rootViewController by default
 */
+ (void)showAlertController:(NSString *)title
                    message:(NSString *)message
                cancelTitle:(NSString *)cancelTitle;

/*!
 Show AlertController

 @param title title
 @param message  message
 @param cancelTitle Cancel title
 @param controller Parent controller for presenting the AlertController; if nil, uses the
 keyWindow's rootViewController
 */
+ (void)showAlertController:(NSString *)title
                    message:(NSString *)message
                cancelTitle:(NSString *)cancelTitle
           inViewController:(UIViewController *)controller;

/*!
 Show AlertController (with auto-dismiss)

 @param title title
 @param message  message
 @param timeInterval Dismiss interval

  Displayed on the keyWindow's rootViewController by default
 */
+ (void)showAlertController:(NSString *)title
                    message:(NSString *)message
           hiddenAfterDelay:(NSTimeInterval)timeInterval;

/*!
 Show AlertController (with auto-dismiss)

 @param title title
 @param message  message
 @param timeInterval Dismiss interval
 @param controller Parent controller for presenting the AlertController; if nil, uses the
 keyWindow's rootViewController
 */
+ (void)showAlertController:(NSString *)title
                    message:(NSString *)message
           hiddenAfterDelay:(NSTimeInterval)timeInterval
           inViewController:(UIViewController *)controller;

/*!
 Show AlertController (with auto-dismiss)

 @param title title
 @param message  message
 @param timeInterval Dismiss interval
 @param controller Parent controller for presenting the AlertController; if nil, uses the
 keyWindow's rootViewController
 @param completion  Callback when the AlertController is dismissed
 */
+ (void)showAlertController:(NSString *)title
                    message:(NSString *)message
           hiddenAfterDelay:(NSTimeInterval)timeInterval
           inViewController:(UIViewController *)controller
          dismissCompletion:(void (^)(void))completion;

/*!
 Show AlertController

 @param actionTitles List of action titles
 @param cancelTitle Cancel title
 @param style    ActionSheet or Alert
 @param actionsBlock Action callback; the index and alertAction correspond to actionTitles order
 @param controller Parent controller for presenting the AlertController; if nil, uses the
 keyWindow's rootViewController
 */
+ (void)showAlertController:(NSArray *)actionTitles
                cancelTitle:(NSString *)cancelTitle
             preferredStyle:(UIAlertControllerStyle)style
               actionsBlock:(void (^)(int index, UIAlertAction *alertAction))actionsBlock
           inViewController:(UIViewController *)controller;

/*!
 Show AlertController

 @param title title
 @param message  message
 @param actionTitles List of action titles
 @param cancelTitle Cancel title
 @param confirmTitle Confirm title
 @param style    ActionSheet or Alert
 @param actionsBlock Action callback; the index and alertAction correspond to actionTitles order
 @param cancelBlock Callback for tapping the cancel button
 @param confirmBlock  Callback for tapping the confirm button
 @param controller Parent controller for presenting the AlertController; if nil, uses the
 keyWindow's rootViewController
 */
+ (void)showAlertController:(NSString *)title
                    message:(NSString *)message
               actionTitles:(NSArray *)actionTitles
                cancelTitle:(NSString *)cancelTitle
               confirmTitle:(NSString *)confirmTitle
             preferredStyle:(UIAlertControllerStyle)style
               actionsBlock:(void (^)(int index, UIAlertAction *alertAction))actionsBlock
                cancelBlock:(void (^)(void))cancelBlock
               confirmBlock:(void (^)(void))confirmBlock
           inViewController:(UIViewController *)controller;
@end
