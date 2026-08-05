//
//  NCSelectUserViewModel.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseViewModel.h"
#import "NCSearchBarViewModel.h"
#import "NCListViewModelProtocol.h"
#import "NCSelectUserCellViewModel.h"

@class NCSelectUserViewModel;
typedef NS_ENUM(NSUInteger, NCSelectUserType) {
    NCSelectUserTypeCreateGroup,
    NCSelectUserTypeInviteJoinGroup,
};

NS_ASSUME_NONNULL_BEGIN
/// Select user delegate
@protocol NCSelectUserViewModelDelegate <NSObject>
@optional

/// Called before loading the search view model
///
/// @param viewModel viewModel
/// @param searchViewModel searchViewModel
/// @return Custom search view model, or `nil` to use the default
///
- (NCSearchBarViewModel *_Nullable)selectUserViewModel:(NCSelectUserViewModel *)viewModel
                            willLoadSearchBarViewModel:(NCSearchBarViewModel *)searchViewModel;

/// Called before loading the data source
///
/// @param viewModel viewModel
/// @param dataSource The current data source
/// @return The data source processed by the app, or `nil` to use the default
///
- (NSArray <NCSelectUserCellViewModel *>* _Nullable)selectUserViewModel:(NCSelectUserViewModel *)viewModel
                                     willLoadItemsInDataSource:(NSArray <NCSelectUserCellViewModel *>*)dataSource;

/// Called when the user taps a cell
///
/// @param viewModel viewModel
/// @param viewController The current view controller
/// @param tableView tableView
/// @param indexPath indexPath
/// @param cellViewModel cellViewModel
/// @return `YES` if the app handled the event; `NO` to let the SDK handle it
///
- (BOOL)selectUserViewModel:(NCSelectUserViewModel *)viewModel
             viewController:(UIViewController*)viewController
                  tableView:(UITableView *)tableView
               didSelectRow:(NSIndexPath *)indexPath
              cellViewModel:(NCSelectUserCellViewModel *)cellViewModel;

/// Selection completion callback
///
/// @param viewModel viewModel
/// @param selectUserIds The list of selected user identifiers
/// @param viewController The current view controller
/// @return `YES` if the app handled the event; `NO` to let the SDK handle it
///
- (BOOL)selectUserDidSelectComplete:(NCSelectUserViewModel *)viewModel
                      selectUserIds:(NSMutableArray <NSString *>*)selectUserIds
                     viewController:(UIViewController*)viewController;


@end

/// Select user view model
@interface NCSelectUserViewModel : NCBaseViewModel<NCListViewModelProtocol>

/// Creates an `NCSelectUserViewModel` instance
///
/// @param type The contact selection type
/// @param groupId The group identifier
///
/// @return The instance
///
+ (instancetype)viewModelWithType:(NCSelectUserType)type
                          groupId:(NSString *_Nullable)groupId;

/// Delegate
@property (nonatomic, weak) id<NCSelectUserViewModelDelegate> delegate;

/// List of selected users
@property (nonatomic, strong, readonly) NSMutableArray <NSString *>*selectUserIds;

/// Maximum number of selections per operation. Defaults to 30, range: (0, 100].
@property (nonatomic, assign, setter=setMaxSelectCount:) NSInteger maxSelectCount;

@property (nonatomic, copy) void (^selectionDidCompelteBlock)(NSArray <NSString *>*selectUserIds, UIViewController *selectVC);

/// Configures the search bar
- (UISearchBar *)configureSearchBarForViewController:(UIViewController *)viewController;

/// Section name
- (NSArray *)sectionIndexTitles;

/// Fetches data
- (void)fetchData;

/// Binds the responder
- (void)bindResponder:(id<NCListViewModelResponder>)responder;

/// Ends editing mode
- (void)endEditingState;

/// Called when selection completes
- (void)selectionDidDone;

/// Returns the empty state tip text
- (NSString *)emptyTip;

@end

NS_ASSUME_NONNULL_END
