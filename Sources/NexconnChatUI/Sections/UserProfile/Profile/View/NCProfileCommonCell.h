//
//  NCProfileCommonCell.h
//  NexconnUserProfile
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseImageView.h"
#import "NCPaddingTableViewCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface NCProfileCommonCell : NCPaddingTableViewCell

@property (nonatomic, strong) UILabel *titleLabel;

@property (nonatomic, strong) NCBaseImageView *arrowView;

@property (nonatomic, strong) UIStackView *contentStackView;

@end

NS_ASSUME_NONNULL_END
