//
//  NCMyGroupsViewModel.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseViewModel.h"
#import "NCListViewModelProtocol.h"
#import "NCNavigationItemsViewModel.h"
#import "NCCellViewModelProtocol.h"
#import "NCGroupInfoCellViewModel.h"
#import "NCSearchBarViewModel.h"

NS_ASSUME_NONNULL_BEGIN
@class NCMyGroupsViewModel;
@class NCUIPagingQueryOption;

@protocol NCMyGroupsViewModelDelegate <NSObject>
@optional
/// Delivers the current data source to the app for processing
///   - viewModel: viewModel
/// @param dataSource The current data source
/// @return The data source processed by the app, or `nil` to use the default
///
- (NSArray *_Nullable)myGroupsViewModel:(NCMyGroupsViewModel *)viewModel
              willLoadItemsInDataSource:(NSArray *_Nullable)dataSource;

/// Configures custom right navigation items
/// @param viewModel viewModel
/// @return Custom navigation items view model, or `nil` to use the default
///
- (NCNavigationItemsViewModel *_Nullable)willConfigureRightNavigationItemsForMyGroupsViewModel:(NCMyGroupsViewModel *)viewModel;


/// Configures custom search functionality
/// @param viewModel viewModel
/// @return Custom search view model, or `nil` to use the default
///
- (NCSearchBarViewModel *_Nullable)willConfigureSearchBarViewModelForMyGroupsViewModel:(NCMyGroupsViewModel *)viewModel;

/// Called when the user taps a cell
///   - viewModel: viewModel
///   - viewController: viewController
///   - tableView: tableView
///   - indexPath: indexPath
///   - viewModel: CellViewModel
/// @return `YES` if the app handled the event; `NO` to let the SDK handle it
///
- (BOOL)myGroupsViewModel:(NCMyGroupsViewModel *)viewModel
           viewController:(UIViewController*)viewController
                tableView:(UITableView *)tableView
             didSelectRow:(NSIndexPath *)indexPath
            cellViewModel:(NCBaseCellViewModel *)cellViewModel;
@end

/// Group list view model
@interface NCMyGroupsViewModel : NCBaseViewModel<NCListViewModelProtocol>

/// Delegate
@property (nonatomic, weak) id<NCMyGroupsViewModelDelegate> delegate;

/// Initializes the instance
/// @param option The query parameters
- (instancetype)initWithOption:(nullable NCUIPagingQueryOption *)option;

/// Configures the navigation items
- (NSArray *)configureRightNaviItemsForViewController:(UIViewController *)viewController;

/// Configures the search bar
- (UISearchBar *)configureSearchBarForViewController:(UIViewController *)viewController;

/// Fetches data
- (void)fetchData;

/// Binds the responder
- (void)bindResponder:(UIViewController <NCListViewModelResponder>*)responder;

/// Loads more data
- (void)loadMoreData;
@end

NS_ASSUME_NONNULL_END
