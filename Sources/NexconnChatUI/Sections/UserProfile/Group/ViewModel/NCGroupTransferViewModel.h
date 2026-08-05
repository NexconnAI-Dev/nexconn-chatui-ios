//
//  NCGroupMembersViewModel.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseViewModel.h"
#import "NCGroupMemberCellViewModel.h"
#import "NCSearchBarViewModel.h"
#import "NCListViewModelProtocol.h"

NS_ASSUME_NONNULL_BEGIN
@class NCGroupTransferViewModel;
/// Group member list delegate
@protocol NCGroupTransferViewModelDelegate <NSObject>
@optional
/// Called before loading the search view model
///
/// @param viewModel viewModel
/// @param searchViewModel searchViewModel
/// @return Custom search view model, or `nil` to use the default
///
- (NCSearchBarViewModel *_Nullable)groupMemberList:(NCGroupTransferViewModel *)viewModel
                        willLoadSearchBarViewModel:(NCSearchBarViewModel *)searchViewModel;

/// Called before loading the data source
/// @param viewModel viewModel
/// @param dataSource The current data source
/// @return The data source processed by the app, or `nil` to use the default
///
- (NSArray <NCGroupMemberCellViewModel *> * )groupMemberList:(NCGroupTransferViewModel *)viewModel
                                   willLoadItemsInDataSource:(NSArray <NCGroupMemberCellViewModel *> * )dataSource;

/// Called when the user taps a cell
/// @param viewModel viewModel
/// @param viewController The current view controller
/// @param tableView tableView
/// @param indexPath indexPath
/// @param cellViewModel cellViewModel
/// @return `YES` if the app handled the event; `NO` to let the SDK handle it
///
- (BOOL)groupMemberList:(NCGroupTransferViewModel *)viewModel
         viewController:(UIViewController*)viewController
              tableView:(UITableView *)tableView
           didSelectRow:(NSIndexPath *)indexPath
          cellViewModel:(NCGroupMemberCellViewModel *)cellViewModel;

/// Called when group ownership has been transferred
/// @param groupId The group identifier
/// @param newOwnerId The new owner's user identifier
/// @param viewController The current view controller
/// @return `YES` if the app handled the event; `NO` to let the SDK handle it
///
- (BOOL)groupOwnerDidTransfer:(NSString *)groupId
                   newOwnerId:(NSString *)newOwnerId
               viewController:(UIViewController*)viewController;
@end

/// Group member list view model
@interface NCGroupTransferViewModel : NCBaseViewModel<NCListViewModelProtocol>

/// Delegate
@property (nonatomic, weak) id<NCGroupTransferViewModelDelegate> delegate;

/// Data source
@property (nonatomic, strong, readonly) NSArray <NCGroupMemberCellViewModel *>*memberList;

/// Number of members loaded per page. Defaults to 50, range: (0, 100].
@property (nonatomic, assign, setter=setPageCount:) NSInteger pageCount;

/// Group identifier
@property (nonatomic, copy, readonly) NSString *groupId;

/// Creates an `NCGroupTransferOwnerViewModel` instance
+ (instancetype)viewModelWithGroupId:(NSString *)groupId;

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
@end

NS_ASSUME_NONNULL_END
