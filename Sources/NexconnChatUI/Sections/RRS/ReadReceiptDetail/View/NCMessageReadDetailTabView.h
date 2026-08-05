//
//  NCMessageReadDetailTabView.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseView.h"
#import "NCMessageReadDetailDefine.h"

NS_ASSUME_NONNULL_BEGIN

@class NCMessageReadDetailTabView;

@protocol NCReadReceiptDetailTabViewDelegate <NSObject>

/// Tab switching callback
- (void)tabView:(NCMessageReadDetailTabView *)tabView didSelectTabAtIndex:(NCMessageReadDetailTabType)tabType;

@end

/// Tab switching view
@interface NCMessageReadDetailTabView : NCBaseView

@property (nonatomic, weak) id<NCReadReceiptDetailTabViewDelegate> delegate;

@property (nonatomic, strong) UIButton *readButton;
@property (nonatomic, strong) UIButton *unreadButton;
@property (nonatomic, strong) UIView *indicatorView;
@property (nonatomic, strong) UIView *separatorLine;

@property (nonatomic, strong) UIColor *selectedColor;
@property (nonatomic, strong) UIColor *unselectedColor;

/// Sets the colors
/// @param selectedColor The selected color
/// @param unselectedColor The unselected color
- (void)setupSelectedColor:(UIColor *)selectedColor unselectedColor:(UIColor *)unselectedColor;

/// Sets the count
/// @param readCount The read count
/// @param unreadCount The unread count
- (void)setupReadCount:(NSInteger)readCount unreadCount:(NSInteger)unreadCount;

/// Selects the specified tab
- (void)selectTabAtIndex:(NCMessageReadDetailTabType)tabType;

@end

NS_ASSUME_NONNULL_END

