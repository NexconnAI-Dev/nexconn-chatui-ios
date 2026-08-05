//
//  NCGroupMemberAddtionalCell.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCStackTableViewCell.h"
UIKIT_EXTERN NSString * _Nullable const NCGroupMemberAdditionalCellIdentifier;

NS_ASSUME_NONNULL_BEGIN

@interface NCGroupMemberAdditionalCell : NCStackTableViewCell
@property (nonatomic, strong) UIImageView *portraitImageView;
@property (nonatomic, strong) UILabel *labName;
- (void)showPortraitByImage:(UIImage *)image;
@end

NS_ASSUME_NONNULL_END
