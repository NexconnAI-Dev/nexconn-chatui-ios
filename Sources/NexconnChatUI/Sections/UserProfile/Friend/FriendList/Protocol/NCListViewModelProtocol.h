//
//  NCListViewModelProtocol.h
//  NexconnUserProfile
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// List responder
@protocol NCListViewModelResponder <NSObject>
@optional
/// Reloads the list
///
/// @param isEmpty Whether the list is empty
- (void)reloadData:(BOOL)isEmpty;

/// Called when reload finishes
///
/// @param success Whether the operation succeeded
/// @param tips The tip message
- (void)refreshingFinished:(BOOL)success withTips:(NSString *)tips;

/// Displays a tip message
///
/// @param tips The tip message
- (void)showTips:(NSString *)tips;

/// Begins loading
- (void)startLoading;

/// Begins loading
- (void)endLoading;

/// Updates the item
///
/// @param indexPath indexPath
- (void)updateItem:(NSIndexPath *)indexPath;

/// Current view controller
/// @return ViewController
- (UIViewController *)currentViewController;

/// Updates the title
- (void)updateTitle:(NSString *)title;

/// Loads the footer view
- (void)reloadFooterView;

@end

/// List view model protocol
@protocol NCListViewModelProtocol <NSObject>

@optional
/// Registers the cell
///
/// @param tableView tableView
- (void)registerCellForTableView:(UITableView *)tableView;

/// Handles cell tap
///
/// @param viewController viewController
/// @param tableView tableView
/// @param indexPath indexPath
- (void)viewController:(UIViewController *)viewController
             tableView:(UITableView *)tableView
          didSelectRow:(NSIndexPath *)indexPath;

/// Returns the cell height
///
/// @param tableView tableView
/// @param indexPath indexPath
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;

/// Number of sections
///
/// @return The number of sections
- (NSInteger)numberOfSections;

/// Number of items in the section
///
/// @param section section
/// @return The number of sections
- (NSInteger)numberOfRowsInSection:(NSInteger)section;

/// Returns the cell
///
/// @param tableView tableView
/// @param indexPath indexPath
/// @return cell
- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath;

/// Header view height
///
/// @param section section
/// @return The header view height
- (CGFloat)heightForHeaderInSection:(NSInteger)section;

/// Header view
///
/// @param tableView tableView
/// @param section section
/// @return The number of sections
- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section;
@end

NS_ASSUME_NONNULL_END
