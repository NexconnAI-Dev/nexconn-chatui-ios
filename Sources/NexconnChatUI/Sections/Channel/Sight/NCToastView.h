//
//  NCToastView.h
//  NCChatUIExtension
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NCToastView : UIView

/**
 *  Shows a toast with the given string.
 *  @param toastString String to display.
 *  @param rootView Parent view for display.
 */
+ (void)showToast:(NSString *)toastString rootView:(UIView *)rootView;

@end
