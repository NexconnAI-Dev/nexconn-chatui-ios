//
//  NCProfileGenderCell.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseImageView.h"
#import "NCStackTableViewCell.h"

UIKIT_EXTERN NSString *_Nonnull const NCProfileGenderCellIdentifier;

NS_ASSUME_NONNULL_BEGIN

@interface NCProfileGenderCell : NCStackTableViewCell

@property (nonatomic, strong) UILabel *titleLabel;

@property (nonatomic, strong) NCBaseImageView *selectView;

@end

NS_ASSUME_NONNULL_END
