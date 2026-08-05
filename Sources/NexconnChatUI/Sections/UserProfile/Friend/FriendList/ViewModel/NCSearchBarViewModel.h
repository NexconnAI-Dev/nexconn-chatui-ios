//
//  NCUFriendListSearchBarViewModel.h
//  NexconnUserProfile
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NCBaseViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@protocol NCSearchBarViewModelDelegate <NSObject>
@optional
/// Called when the text field content changes
///
/// @param searchBar searchBar
/// @param searchText searchText
///
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText;

/// Called when the text field editing state changes
///
/// @param searchBar searchBar
/// @param inSearching Whether a search is active
///
- (void)searchBar:(UISearchBar *)searchBar editingStateChanged:(BOOL)inSearching;

/// Called when the text field is about to begin editing
///
/// @param searchBar searchBar
/// @return `YES` to begin editing; `NO` to cancel
///
- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar;
@end

/// Search view model
@interface NCSearchBarViewModel : NCBaseViewModel

/// Delegate
@property (nonatomic, weak) id<NCSearchBarViewModelDelegate> delegate;

/// Search view
@property (nonatomic, strong) UISearchBar *searchBar;

/// Initializes the instance
- (instancetype)initWithResponder:(UIViewController *)responder;

/// Whether this is the first responder
- (BOOL)isCurrentFirstResponder;

/// Ends editing mode
- (void)endEditingState;
@end

NS_ASSUME_NONNULL_END
