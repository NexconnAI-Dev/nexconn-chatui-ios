//
//  NCBaseView.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSInteger NCUserManagementViewPadding;
NS_ASSUME_NONNULL_BEGIN
@interface NCBaseView : UIView

- (void)setupView;
- (void)setupConstraints;
@end

NS_ASSUME_NONNULL_END
