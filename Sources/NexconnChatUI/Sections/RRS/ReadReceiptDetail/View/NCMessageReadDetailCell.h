//
//  NCMessageReadDetailCell.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseTableViewCell.h"
#import "NCMessageReadDetailCellViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface NCMessageReadDetailCell : NCBaseTableViewCell

+ (NSString *)reuseIdentifier;

/// Binds the ViewModel.
/// - Parameters viewModel: Cell ViewModel
- (void)bindViewModel:(NCMessageReadDetailCellViewModel *)viewModel;

@end

NS_ASSUME_NONNULL_END
