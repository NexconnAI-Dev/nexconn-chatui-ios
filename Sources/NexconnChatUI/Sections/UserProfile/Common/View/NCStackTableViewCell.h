//
//  NCStackTableViewCell.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCPaddingTableViewCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface NCStackTableViewCell : NCPaddingTableViewCell
@property (nonatomic, strong) UIStackView *contentStackView;

@end

NS_ASSUME_NONNULL_END
