//
//  NCSelectUserCell.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCStackTableViewCell.h"
#import "NCImageView.h"
#import "NCUserProfileDefine.h"
UIKIT_EXTERN NSString  * _Nonnull const NCSelectUserCellIdentifier;

NS_ASSUME_NONNULL_BEGIN

@interface NCSelectUserCell : NCStackTableViewCell

@property (nonatomic, strong) NCBaseImageView *selectImageView;

@property (nonatomic, strong) NCImageView *portraitImageView;

@property (nonatomic, strong) UILabel *nameLabel;

- (void)updateSelectState:(NCSelectState)state;
- (void)appendViewAtEnd:(UIView *)view;
@end

NS_ASSUME_NONNULL_END
