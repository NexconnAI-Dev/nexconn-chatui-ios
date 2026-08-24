//
//  NCGroupRemoveMembersViewModel.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseViewModel.h"
#import "NCListViewModelProtocol.h"
#import "NCRemoveGroupMemberCellViewModel.h"
#import "NCSearchBarViewModel.h"

@class NCRemoveGroupMembersViewModel;
NS_ASSUME_NONNULL_BEGIN

@protocol NCGroupRemoveMembersViewModelDelelgate <NSObject>
@optional

/// Called before loading the search view model
///
/// @param viewModel viewModel
/// @param searchViewModel searchViewModel
/// @return Custom search view model, or `nil` to use the default
///
- (NCSearchBarViewModel *_Nullable)groupRemoveMembers:(NCRemoveGroupMembersViewModel *)viewModel
                           willLoadSearchBarViewModel:(NCSearchBarViewModel *)searchViewModel;

/// Called before loading the data source
///
/// @param viewModel viewModel
/// @param dataSource The current data source
/// @return The data source processed by the app, or `nil` to use the default
///
- (NSArray<NCRemoveGroupMemberCellViewModel *> *)
           groupRemoveMembers:(NCRemoveGroupMembersViewModel *)viewModel
    willLoadItemsInDataSource:(NSArray<NCRemoveGroupMemberCellViewModel *> *)dataSource;

/// Called when the user taps a cell
///
/// @param viewModel viewModel
/// @param viewController The current view controller
/// @param tableView tableView
/// @param indexPath indexPath
/// @param cellViewModel cellViewModel
/// @return `YES` if the app handled the event; `NO` to let the SDK handle it
///
- (BOOL)groupRemoveMembers:(NCRemoveGroupMembersViewModel *)viewModel
            viewController:(UIViewController *)viewController
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
- (BOOL)groupRemoveMembersDidSelectComplete:(NCRemoveGroupMembersViewModel *)viewModel
                              selectUserIds:(NSMutableArray<NSString *> *)selectUserIds
                             viewController:(UIViewController *)viewController;
@end

/// Remove group member view model
@interface NCRemoveGroupMembersViewModel : NCBaseViewModel <NCListViewModelProtocol>

/// Delegate
@property (nonatomic, weak) id<NCGroupRemoveMembersViewModelDelelgate> delegate;

/// List of selected users
@property (nonatomic, strong, readonly) NSMutableArray<NSString *> *selectUserIds;

/// Current data source
@property (nonatomic, strong, readonly) NSArray<NCRemoveGroupMemberCellViewModel *> *memberList;

/// Group identifier
@property (nonatomic, copy, readonly) NSString *groupId;

/// Maximum number of selections per operation. Defaults to 30, range: (0, 100].
@property (nonatomic, assign, setter=setMaxSelectCount:) NSInteger maxSelectCount;

/// Creates an `NCRemoveGroupMembersViewModel` instance
+ (instancetype)viewModelWithGroupId:(NSString *)groupId;

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
