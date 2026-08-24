//
//  NCFriendListViewModel.h
//  NexconnUserProfile
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseViewModel.h"
#import "NCListViewModelProtocol.h"
#import "NCNavigationItemsViewModel.h"
#import "NCSearchBarViewModel.h"
#import <UIKit/UIKit.h>

#import "NCCellViewModelProtocol.h"
#import "NCFriendListCellViewModel.h"
#import "NCFriendListPermanentCellViewModel.h"

NS_ASSUME_NONNULL_BEGIN
@class NCFriendListViewModel;
@protocol NCFriendListViewModelDelegate <NSObject>
@optional
/// Delivers the current data source to the app for processing
///   - viewModel: viewModel
/// @param dataSource The current data source
/// @return The data source processed by the app, or `nil` to use the default
///
- (NSArray *_Nullable)friendListViewModel:(NCFriendListViewModel *)viewModel
                willLoadItemsInDataSource:(NSArray *_Nullable)dataSource;

/// Configures custom right navigation items
/// @param viewModel viewModel
/// @return Custom navigation items view model, or `nil` to use the default
///
- (NCNavigationItemsViewModel *_Nullable)willConfigureRightNavigationItemsForFriendListViewModel:
    (NCFriendListViewModel *)viewModel;

/// Configures custom search functionality
/// @param viewModel viewModel
/// @return Custom search view model, or `nil` to use the default
///
- (NCSearchBarViewModel *_Nullable)willConfigureSearchBarViewModelForFriendListViewModel:
    (NCFriendListViewModel *)viewModel;

/// Adds a permanent cell view model
/// @param viewModel viewModel
/// @return The view model to display in the first section
///
- (NSArray<NCFriendListPermanentCellViewModel *> *_Nullable)
    appendPermanentCellViewModelsForFriendListViewModel:(NCFriendListViewModel *)viewModel;

/// Called when the user taps a cell
///   - viewModel: viewModel
///   - viewController: viewController
///   - tableView: tableView
///   - indexPath: indexPath
///   - viewModel: CellViewModel
/// @return `YES` if the app handled the event; `NO` to let the SDK handle it
///
- (BOOL)friendListViewModel:(NCFriendListViewModel *)viewModel
             viewController:(UIViewController *)viewController
                  tableView:(UITableView *)tableView
               didSelectRow:(NSIndexPath *)indexPath
              cellViewModel:(NCBaseCellViewModel *)cellViewModel;
@end

/// Friend list view model
@interface NCFriendListViewModel : NCBaseViewModel <NCListViewModelProtocol>

/// Delegate
@property (nonatomic, weak) id<NCFriendListViewModelDelegate> delegate;

/// Configures the navigation items
- (NSArray *)configureRightNaviItemsForViewController:(UIViewController *)viewController;

/// Configures the search bar
- (UISearchBar *)configureSearchBarForViewController:(UIViewController *)viewController;

/// Section title
- (NSArray *)sectionIndexTitles;

/// Fetches data
- (void)fetchData;

/// Binds the responder
- (void)bindResponder:(UIViewController<NCListViewModelResponder> *)responder;

@end

NS_ASSUME_NONNULL_END
