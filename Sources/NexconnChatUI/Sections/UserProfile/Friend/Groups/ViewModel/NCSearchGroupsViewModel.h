//
//  NCSearchGroupsViewModel.h
//  NexconnChatUI
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
@class NCSearchGroupsViewModel;
@class NCUIPagingQueryOption;

@protocol NCSearchGroupsViewModelDelegate <NSObject>

@optional

/// Delivers the current data source to the app for processing
///   - viewModel: viewModel
/// @param dataSource The current data source
/// @return The data source processed by the app, or `nil` to use the default
///
- (NSArray *_Nullable)searchGroupsViewModel:(NCSearchGroupsViewModel *_Nonnull)viewModel
                  willLoadItemsInDataSource:(NSArray *_Nullable)dataSource;

/// Configures custom right navigation items
/// @param viewModel viewModel
/// @return Custom navigation items view model, or `nil` to use the default
///
- (NCNavigationItemsViewModel *_Nullable)willConfigureRightNavigationItemsForSearchGroupsViewModel:
    (NCSearchGroupsViewModel *_Nonnull)viewModel;

/// Configures custom search functionality
/// @param viewModel viewModel
/// @return Custom search view model, or `nil` to use the default
///
- (NCSearchBarViewModel *_Nullable)willConfigureSearchBarViewModelForSearchGroupsViewModel:
    (NCSearchGroupsViewModel *_Nonnull)viewModel;

/// Called when the user taps a cell
///   - viewModel: viewModel
///   - viewController: viewController
///   - tableView: tableView
///   - indexPath: indexPath
///   - viewModel: CellViewModel
/// @return `YES` if the app handled the event; `NO` to let the SDK handle it
///
- (BOOL)searchGroupsViewModel:(NCSearchGroupsViewModel *_Nonnull)viewModel
               viewController:(UIViewController *_Nonnull)viewController
                    tableView:(UITableView *_Nonnull)tableView
                 didSelectRow:(NSIndexPath *_Nonnull)indexPath
                cellViewModel:(NCBaseCellViewModel *_Nonnull)cellViewModel;
@end

@interface NCSearchGroupsViewModel : NCBaseViewModel <NCListViewModelProtocol>
@property (nonatomic, weak) id<NCSearchGroupsViewModelDelegate> _Nullable delegate;

/// Initializes the instance
/// @param option The query parameters
- (instancetype)initWithOption:(nullable NCUIPagingQueryOption *)option;

/// Configures the navigation buttons
/// @param viewController VC
- (NSArray *_Nonnull)configureRightNaviItemsForViewController:
    (UIViewController *_Nonnull)viewController;

/// Configures the search module
/// @param viewController VC
- (UISearchBar *_Nonnull)configureSearchBarForViewController:
    (UIViewController *_Nonnull)viewController;

/// Binds the event responder
/// @param responder The responder
- (void)bindResponder:(UIViewController<NCListViewModelResponder> *_Nonnull)responder;

/// Ends the search bar editing state
- (void)endEditingState;

/// Loads more data
- (void)loadMoreData;
@end
NS_ASSUME_NONNULL_END
