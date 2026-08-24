//
//  NCSearchUserProfileViewModel.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//
#import "NCBaseViewModel.h"
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@protocol NCSearchUserProfileViewModelDelegate <NSObject>
@optional
/// Called when the text field content changes
///
/// @param searchBar searchBar
/// @param searchText searchText
///
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText;

/// Search user profile view model
///
/// @param text The text content
///
- (void)searchUserProfileWithText:(NSString *)text;

@end

/// Searches for users
@interface NCSearchUserProfileViewModel : NCBaseViewModel

/// Delegate
@property (nonatomic, weak) id<NCSearchUserProfileViewModelDelegate> delegate;

/// searchBar
@property (nonatomic, strong) UISearchBar *searchBar;

/// Initializes the instance
///
/// @param placeholder The placeholder text
- (instancetype)initWithPlaceholder:(NSString *)placeholder;

/// Ends editing mode
- (void)endEditingState;
@end

NS_ASSUME_NONNULL_END
