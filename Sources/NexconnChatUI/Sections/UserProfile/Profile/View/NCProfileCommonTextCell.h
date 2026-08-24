//
//  NCProfileCommonTextCell.h
//  NexconnUserProfile
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCProfileCommonCell.h"
UIKIT_EXTERN NSString *_Nullable const NCProfileTextCellIdentifier;

NS_ASSUME_NONNULL_BEGIN

@interface NCProfileCommonTextCell : NCProfileCommonCell

@property (nonatomic, strong) UILabel *detailLabel;

@end

NS_ASSUME_NONNULL_END
