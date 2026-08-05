//
//  NCGroupMemberCellViewModel.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseCellViewModel.h"
#import <NexconnChatSDK/NexconnChatSDK.h>
NS_ASSUME_NONNULL_BEGIN

/// Group member cell view model
@interface NCGroupMemberCellViewModel : NCBaseCellViewModel<NCCellViewModelProtocol>

/// Group member
@property (nonatomic, strong, readonly) NCGroupMemberInfo *memberInfo;

/// Remark (available only if set by the friend)
@property (nonatomic, strong, nullable) NSString *remark;

/// Whether to hide the arrow indicator
@property (nonatomic, assign) BOOL hiddenArrow;


/// Local cell portrait image. Once set, `memberInfo.avatarUrl` is ignored.
@property (nonatomic, strong, nullable) UIImage *cellPortraitImage;

/// Registers the cell
+ (void)registerCellForTableView:(UITableView *)tableView;

/// Creates an `NCGroupMemberCellViewModel` instance
- (instancetype)initWithMember:(NCGroupMemberInfo *)memberInfo;

@end

NS_ASSUME_NONNULL_END
