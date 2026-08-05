//
//  NCGroupInfoCellViewModel.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <NexconnChatSDK/NexconnChatSDK.h>
#import "NCCellViewModelProtocol.h"
#import "NCBaseCellViewModel.h"
#import "NCListViewModelProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface NCGroupInfoCellViewModel : NCBaseCellViewModel
@property (nonatomic, strong) NCGroupInfo *groupInfo;

/// Initializes the instance
/// @param groupInfo The group info
/// @param keyword The highlight keyword
- (instancetype)initWithGroupInfo:(NCGroupInfo *)groupInfo
                          keyword:(NSString *)keyword;

/// Registers the cell
+ (void)registerCellForTableView:(UITableView *)tableView;

@end

NS_ASSUME_NONNULL_END
