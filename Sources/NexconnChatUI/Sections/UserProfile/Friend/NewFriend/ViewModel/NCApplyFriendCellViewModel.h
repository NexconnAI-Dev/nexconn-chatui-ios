//
//  NCApplyFriendCellViewModel.h
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
typedef NS_ENUM(NSInteger, NCFriendApplyCellStyle) {
    NCFriendApplyCellStyleNone, // No style
    NCFriendApplyCellStyleNormal, // Normal
    NCFriendApplyCellStyleFolder, // Collapsed
    NCFriendApplyCellStyleExpand  // Expanded
};


/// Friend request list cell view model
@interface NCApplyFriendCellViewModel : NCBaseCellViewModel<NCCellViewModelProtocol>

/// Request info
@property (nonatomic, strong) NCFriendApplicationInfo *application;

/// Style
@property (nonatomic, assign) NCFriendApplyCellStyle style;

/// Initializes the instance
- (instancetype)initWithApplicationInfo:(NCFriendApplicationInfo *)application;

/// Accepts the request
- (void)approveApplication;

/// Rejects the request
- (void)rejectApplication;

/// Expands the remark section
- (void)expandRemark;

/// Cell height
- (CGFloat)cellHeight;

/// Registers the cell
+ (void)registerCellForTableView:(UITableView *)tableView;


/// Determines whether to show the expand button based on the remark size
/// @param size The current size
/// @param natureSize The natural size
- (BOOL)shouldHideExpandButton:(CGSize)size natureSize:(CGSize)natureSize;
/// Binds the responder
- (void)bindResponder:(UIViewController <NCListViewModelResponder>*)responder;

/// Header height
///   - tableView: tableView
///   - indexPath: indexPath
/// @return The list of actions
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
- (NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView
                  editActionsForRowAtIndexPath:(NSIndexPath *)indexPath  
                                    completion:(void(^)(NSInteger errorCode))completion;
#pragma clang diagnostic pop
@end

NS_ASSUME_NONNULL_END
