//
//  NCCellViewModelProtocol.h
//  NexconnUserProfile
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
typedef void (^NCPermanentCellViewModelBlock)(UIViewController *);
/// Cell view model protocol
@protocol NCCellViewModelProtocol <NSObject>
@optional

/// Returns the cell
///
/// @param tableView tableView
/// @param indexPath indexPath
/// @return cell
- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath;

/// Cell height
///
/// @param tableView tableView
/// @param indexPath indexPath
/// @return The cell height
- (CGFloat)tableView:(nonnull UITableView *)tableView
    heightForRowAtIndexPath:(nonnull NSIndexPath *)indexPath;

/// Handles cell tap
///
/// @param vc The current view controller
- (void)itemDidSelectedByViewController:(UIViewController *)vc;
@end

NS_ASSUME_NONNULL_END
