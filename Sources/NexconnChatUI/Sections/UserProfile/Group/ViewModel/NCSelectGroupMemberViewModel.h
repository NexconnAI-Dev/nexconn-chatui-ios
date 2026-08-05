//
//  NCSelectGroupMemberViewModel.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseViewModel.h"
#import "NCListViewModelProtocol.h"
#import "NCRemoveGroupMemberCellViewModel.h"
#import "NCSearchBarViewModel.h"
NS_ASSUME_NONNULL_BEGIN
@class NCSelectGroupMemberViewModel;
@protocol NCSelectGroupMemberViewModelDelegate <NSObject>

@optional

/// Called before loading the search view model
///
/// @param viewModel viewModel
/// @param searchViewModel searchViewModel
/// @return Custom search view model, or `nil` to use the default
///
- (NCSearchBarViewModel *_Nullable)selectGroupMember:(NCSelectGroupMemberViewModel *)viewModel
                          willLoadSearchBarViewModel:(NCSearchBarViewModel *)searchViewModel;

/// Called before loading the data source
///
/// @param viewModel viewModel
/// @param dataSource The current data source
/// @return The data source processed by the app, or `nil` to use the default
///
- (NSArray <NCRemoveGroupMemberCellViewModel *> *)selectGroupMember:(NCSelectGroupMemberViewModel *)viewModel
                                          willLoadItemsInDataSource:(NSArray <NCRemoveGroupMemberCellViewModel *>*)dataSource;

/// Called when the user taps a cell
///
/// @param viewModel viewModel
/// @param viewController The current view controller
/// @param tableView tableView
/// @param indexPath indexPath
/// @param cellViewModel cellViewModel
/// @return `YES` if the app handled the event; `NO` to let the SDK handle it
///
- (BOOL)selectGroupMember:(NCSelectGroupMemberViewModel *)viewModel
           viewController:(UIViewController*)viewController
                tableView:(UITableView *)tableView
             didSelectRow:(NSIndexPath *)indexPath
            cellViewModel:(NCRemoveGroupMemberCellViewModel *)cellViewModel;

/// Selection completion callback
///
/// @param viewModel viewModel
/// @param selectUserIds The list of selected user identifiers
/// @param viewController The current view controller
/// @return `YES` if the app handled the event; `NO` to let the SDK handle it
///
- (BOOL)selectGroupMemberDidSelectComplete:(NCSelectGroupMemberViewModel *)viewModel
                             selectUserIds:(NSMutableArray <NSString *>*)selectUserIds
                            viewController:(UIViewController*)viewController;

@end

/// Select group member view model
@interface NCSelectGroupMemberViewModel : NCBaseViewModel<NCListViewModelProtocol>
/// Delegate
@property (nonatomic, weak) id<NCSelectGroupMemberViewModelDelegate> delegate;

/// Selection completion block
@property (nonatomic, copy) void (^selectionDidCompelteBlock)(NSArray <NSString *>*selectUserIds, UIViewController *selectVC);

/// List of selected users
@property (nonatomic, strong, readonly) NSMutableArray <NSString *>*selectUserIds;

/// Current data source
@property (nonatomic, strong, readonly) NSArray <NCRemoveGroupMemberCellViewModel *>*memberList;

/// Group identifier
@property (nonatomic, copy, readonly) NSString *groupId;

/// Maximum number of selections per operation
@property (nonatomic, assign, setter=setMaxSelectCount:) NSInteger maxSelectCount;

/// Over-limit tip text
@property (nonatomic, copy) NSString *tip;

/// Hidden user identifiers
@property (nonatomic, strong) NSArray <NSString *> *hideUserIds;

/// Creates an `NCRemoveGroupMembersViewModel` instance
///
/// @param groupId The group owner identifier
/// @param existingUserIds The list of already-existing user identifiers
+ (instancetype)viewModelWithGroupId:(NSString *)groupId
                     existingUserIds:(nullable NSArray *)existingUserIds;

/// Binds the responder
- (void)bindResponder:(id<NCListViewModelResponder>)responder;

/// Loads data source with pagination
- (void)fetchGroupMembersByPage;

/// Configures the current view controller
- (UISearchBar *)configureSearchBar;

/// Ends editing mode
- (void)endEditingState;

/// Called when selection completes
- (void)selectionDidDone;

@end

NS_ASSUME_NONNULL_END
