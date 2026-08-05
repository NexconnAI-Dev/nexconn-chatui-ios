//
//  NCFriendListPermanentCellViewModel.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseCellViewModel.h"
#import "NCCellViewModelProtocol.h"
NS_ASSUME_NONNULL_BEGIN

/// Friend list permanent cell
@interface NCFriendListPermanentCellViewModel : NCBaseCellViewModel<NCCellViewModelProtocol>

/// Initializes the instance
- (instancetype)initWithTitle:(NSString *)title
                     portrait:(UIImage *)portrait
                   touchBlock:(NCPermanentCellViewModelBlock)touchBlock;

/// Registers the cell
+ (void)registerCellForTableView:(UITableView *)tableView;
@end

NS_ASSUME_NONNULL_END
