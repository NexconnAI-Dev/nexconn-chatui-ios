//
//  NCGroupMentionViewModel.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseViewModel.h"
#import "NCGroupMemberCellViewModel.h"
#import "NCSearchBarViewModel.h"
#import "NCListViewModelProtocol.h"
#import "NCChatUIUserInfo.h"
#import <NexconnChatSDK/NexconnChatSDK.h>
// @all userId
extern NSString  * _Nonnull const NCMentionAllUsersID;
NS_ASSUME_NONNULL_BEGIN

@interface NCGroupMentionViewModel : NCBaseViewModel<NCListViewModelProtocol>

/// Data source
@property (nonatomic, strong, readonly) NSArray <NCGroupMemberCellViewModel *>*memberList;

/// Number of members loaded per page. Defaults to 50, range: (0, 100].
@property (nonatomic, assign, setter=setPageCount:) NSInteger pageCount;

/// Group identifier
@property (nonatomic, copy, readonly) NSString *groupId;


/// Creates an `NCGroupMentionViewModel` instance
+ (instancetype)viewModelWithGroupId:(NSString *)groupId
                       selectedBlock:(void (^)(NCChatUIUserInfo *selectedUserInfo))selectedBlock
                              cancel:(void (^)(void))cancelBlock;

/// Binds the responder
- (void)bindResponder:(id<NCListViewModelResponder>)responder;

/// Loads group members with pagination
- (void)fetchGroupMembersByPage;

/// Configures the search bar
///
/// @return The configured search bar
- (UISearchBar *)configureSearchBar;

/// Ends editing mode
- (void)endEditingState;

- (void)selectionCanceled;

@end

NS_ASSUME_NONNULL_END
