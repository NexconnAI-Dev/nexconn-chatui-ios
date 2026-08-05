//
//  NCApplyFriendListViewModel.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NCBaseViewModel.h"
#import "NCListViewModelProtocol.h"
#import "NCNavigationItemsViewModel.h"
#import "NCCellViewModelProtocol.h"
#import "NCApplyFriendCellViewModel.h"
#import "NCApplyFriendSectionItem.h"
#import <NexconnChatSDK/NexconnChatSDK.h>
NS_ASSUME_NONNULL_BEGIN

@class NCApplyFriendListViewModel;

@protocol NCApplyFriendListDelegate <NSObject>
@optional
/// Delivers the current data source to the app for processing
///   - viewModel: viewModel
/// @param dataSource The current data source
/// @return The data source processed by the app, or `nil` to use the default
///

- (NSArray <NCApplyFriendCellViewModel *> *_Nullable)applyFriendListViewModel:(NCApplyFriendListViewModel *)viewModel
                                                    willLoadItemsInDataSource:(NSArray *_Nullable)dataSource;

/// Configures custom right navigation items
/// @param viewModel viewModel
/// @return Custom navigation items view model, or `nil` to use the default
///
- (NCNavigationItemsViewModel *_Nullable)willConfigureRightNavigationItemsForApplyFriendListViewModel:(NCApplyFriendListViewModel *)viewModel;

/// Called when the user taps a cell
///   - viewModel: viewModel
///   - viewController: viewController
///   - tableView: tableView
///   - indexPath: indexPath
///   - viewModel: CellViewModel
/// @return `YES` if the app handled the event; `NO` to let the SDK handle it
///
- (BOOL)applyFriendListViewModel:(NCApplyFriendListViewModel *)viewModel
                  viewController:(UIViewController*)viewController
                       tableView:(UITableView *)tableView
                    didSelectRow:(NSIndexPath *)indexPath
                   cellViewModel:(NCApplyFriendCellViewModel *)cellViewModel;
@end

/// Friend request list view controller
@interface NCApplyFriendListViewModel : NCBaseViewModel<NCListViewModelProtocol>

/// Delegate
@property (nonatomic, weak) id<NCApplyFriendListDelegate> delegate;

/// Initializes the instance
/// @param items The data source
/// @param option The configuration
/// @param types The list of types
/// @param status The list of statuses
- (instancetype)initWithSectionItems:(nullable NSArray <NCApplyFriendSectionItem *>*)items
                              option:(nullable NCFriendApplicationsQueryParams *)option
                               types:(nullable NSArray<NSNumber *> *)types
                              status:(nullable NSArray<NSNumber *> *)status;

/// Configures the navigation items
/// @param viewController viewController
- (NSArray *)configureRightNaviItemsForViewController:(UIViewController *)viewController;

/// Fetches data
- (void)fetchData;

/// Binds the responder
- (void)bindResponder:(UIViewController <NCListViewModelResponder>*)responder;

/// Cell height
///   - tableView: tableView
///   - indexPath: indexPath
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;

/// Header height
///   - tableView: tableView
///   - indexPath: indexPath
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section;

/// Loads more data
- (void)loadMoreData;

/// Header height
///   - tableView: tableView
///   - indexPath: indexPath
/// @return The list of actions
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
- (NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView
                  editActionsForRowAtIndexPath:(NSIndexPath *)indexPath;
#pragma clang diagnostic pop

@end

NS_ASSUME_NONNULL_END
