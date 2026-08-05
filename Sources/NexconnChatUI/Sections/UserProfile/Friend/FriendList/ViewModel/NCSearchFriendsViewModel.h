//
//  NCSearchFriendsViewModel.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NCBaseViewModel.h"
#import "NCListViewModelProtocol.h"
#import "NCNavigationItemsViewModel.h"
#import "NCSearchBarViewModel.h"

#import "NCCellViewModelProtocol.h"
#import "NCFriendListCellViewModel.h"
#import "NCFriendListPermanentCellViewModel.h"
NS_ASSUME_NONNULL_BEGIN
@class NCSearchFriendsViewModel;

@protocol NCSearchFriendsViewModelModelDelegate <NSObject>

@optional

/// Delivers the current data source to the app for processing
///   - viewModel: viewModel
/// @param dataSource The current data source
/// @return The data source processed by the app, or `nil` to use the default
///
- (NSArray *_Nullable)searchFriendsViewModel:(NCSearchFriendsViewModel *_Nonnull)viewModel
                   willLoadItemsInDataSource:(NSArray *_Nullable)dataSource;

/// Configures custom right navigation items
/// @param viewModel viewModel
/// @return Custom navigation items view model, or `nil` to use the default
///
- (NCNavigationItemsViewModel *_Nullable)willConfigureRightNavigationItemsForSearchFriendsViewModel:(NCSearchFriendsViewModel *_Nonnull)viewModel;


/// Configures custom search functionality
/// @param viewModel viewModel
/// @return Custom search view model, or `nil` to use the default
///
- (NCSearchBarViewModel *_Nullable)willConfigureSearchBarViewModelForSearchFriendsViewModel:(NCSearchFriendsViewModel *_Nonnull)viewModel;

/// Called when the user taps a cell
///   - viewModel: viewModel
///   - viewController: viewController
///   - tableView: tableView
///   - indexPath: indexPath
///   - viewModel: CellViewModel
/// @return `YES` if the app handled the event; `NO` to let the SDK handle it
///
- (BOOL)searchFriendsViewModel:(NCSearchFriendsViewModel *_Nonnull)viewModel
                viewController:(UIViewController*_Nonnull)viewController
                     tableView:(UITableView *_Nonnull)tableView
                  didSelectRow:(NSIndexPath *_Nonnull)indexPath
                 cellViewModel:(NCBaseCellViewModel *_Nonnull)cellViewModel;
@end

@interface NCSearchFriendsViewModel : NCBaseViewModel<NCListViewModelProtocol>
@property (nonatomic, weak) id<NCSearchFriendsViewModelModelDelegate> _Nullable delegate;

- (NSArray *_Nonnull)configureRightNaviItemsForViewController:(UIViewController *_Nonnull)viewController;
- (UISearchBar *_Nonnull)configureSearchBarForViewController:(UIViewController *_Nonnull)viewController;
- (NSArray *_Nonnull)sectionIndexTitles;
- (void)bindResponder:(id<NCListViewModelResponder>_Nonnull)responder;
- (void)endEditingState;
@end
NS_ASSUME_NONNULL_END
