//
//  NCProfileCommonImageCell.h
//  NexconnUserProfile
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCImageView.h"
#import "NCProfileCommonCell.h"
UIKIT_EXTERN NSString *_Nullable const NCProfileImageCellIdentifier;

NS_ASSUME_NONNULL_BEGIN

@interface NCProfileCommonImageCell : NCProfileCommonCell

@property (nonatomic, strong) NCImageView *portraitImageView;

- (void)hiddenArrow:(BOOL)hiddenArrow;

@end

NS_ASSUME_NONNULL_END
