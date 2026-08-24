//
//  NCAddFriendViewModel.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseViewModel.h"
#import "NCCellViewModelProtocol.h"
#import "NCListViewModelProtocol.h"
#import "NCNavigationItemsViewModel.h"
#import "NCSearchUserProfileViewModel.h"
#import <NexconnChatSDK/NexconnChatSDK.h>

NS_ASSUME_NONNULL_BEGIN
@class NCUserSearchViewModel;
@protocol NCUserSearchViewModelDelegate <NSObject>
@optional
/// Configures custom right navigation items
/// @param viewModel viewModel
/// @return Custom navigation items view model, or `nil` to use the default
///
- (NCNavigationItemsViewModel *_Nullable)willConfigureRightNavigationItemsForUserSearchViewModel:
    (NCUserSearchViewModel *)viewModel;

/// Configures custom search functionality
/// @param viewModel viewModel
/// @return Custom search view model, or `nil` to use the default
///
- (NCSearchUserProfileViewModel *_Nullable)willConfigureSearchBarViewModelForUserSearchViewModel:
    (NCUserSearchViewModel *)viewModel;

/// Triggers the user search event
///   - viewModel: viewModel
/// @param text The search keyword
/// @return `YES` if the app handled the event; `NO` to let the SDK handle it
///
- (BOOL)userSearchViewModel:(NCUserSearchViewModel *)viewModel
    searchUserProfileWithText:(NSString *)text;

/// Displays the user detail
///   - viewModel: viewModel
/// @param profile The user info
/// @return `YES` if the app handled the event; `NO` to let the SDK handle it
///
- (BOOL)userSearchViewModel:(NCUserSearchViewModel *)viewModel
            showUserProfile:(NCUserProfile *)profile;
@end

/// User search view model
@interface NCUserSearchViewModel : NCBaseViewModel

/// Delegate
@property (nonatomic, weak) id<NCUserSearchViewModelDelegate> delegate;

/// Configures the navigation buttons
- (NSArray *)configureRightNaviItemsForViewController:(UIViewController *)viewController;

/// Configures the search bar
- (UISearchBar *)configureSearchBarForViewController:(UIViewController *)viewController;

/// Binds the responder
- (void)bindResponder:(UIViewController<NCListViewModelResponder> *)responder;

/// Ends editing mode
- (void)endEditingState;
@end

NS_ASSUME_NONNULL_END
