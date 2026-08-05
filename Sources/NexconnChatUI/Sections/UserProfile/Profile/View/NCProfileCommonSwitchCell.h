//
//  NCProfileCommonSwitchCell.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCProfileCommonCell.h"

NS_ASSUME_NONNULL_BEGIN

UIKIT_EXTERN NSString * _Nullable const NCProfileCommonSwitchCellIdentifier;

@protocol NCProfileCommonSwitchCellDelegate <NSObject>

- (void)switchValueChanged:(UISwitch *)switchView;

@end

@interface NCProfileCommonSwitchCell : NCProfileCommonCell

@property (nonatomic, weak) id<NCProfileCommonSwitchCellDelegate> delegate;

@property (nonatomic, strong) UISwitch *switchView;

@end

NS_ASSUME_NONNULL_END
