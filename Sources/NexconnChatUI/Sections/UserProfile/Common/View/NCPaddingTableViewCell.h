//
//  NCPaddingTableViewCell.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseTableViewCell.h"
extern NSInteger const NCUserManagementPadding;
extern NSInteger const NCUserManagementImageCellLineLeading;
extern NSInteger const NCUserManagementImageCellLineTrailing;

NS_ASSUME_NONNULL_BEGIN

@interface NCPaddingTableViewCell : NCBaseTableViewCell
@property (nonatomic, strong) UIView *lineView;
@property (nonatomic, strong) UIView *paddingContainerView;
@property (nonatomic, assign) BOOL hideSeparatorLine;
- (void)updateLineViewConstraints:(NSInteger)leading trailing:(NSInteger)trailing;

- (void)updatePaddingContainer:(NSInteger)leading trailing:(NSInteger)trailing;
@end

NS_ASSUME_NONNULL_END
