//
//  NCLoadingTipView.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NCLoadingTipView : UIView

+ (NCLoadingTipView *)loadingWithTip:(NSString *)tip
                          parentView:(UIView *)parentView;
+ (NCLoadingTipView *)loadingWithTip:(NSString *)tip;
- (void)startLoading;
- (void)stopLoading;
@end

NS_ASSUME_NONNULL_END
