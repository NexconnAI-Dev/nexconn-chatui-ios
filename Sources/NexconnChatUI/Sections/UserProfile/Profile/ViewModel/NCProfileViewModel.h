//
//  NCUserProfileViewModel.h
//  NexconnUserProfile
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseViewModel.h"
#import "NCListViewModelProtocol.h"
#import "NCProfileCellViewModel.h"
#import "NCProfileFooterViewModel.h"

@class NCProfileViewModel;
NS_ASSUME_NONNULL_BEGIN

@protocol NCProfileViewModelDelegate <NSObject>

@optional

/// Called before loading the footer view model
/// @param viewModel viewModel
/// @param footerViewModel footerViewModel
/// @return The footer view model processed by the app, or `nil` to use the default
///
- (NCProfileFooterViewModel *)profileViewModel:(NCProfileViewModel *)viewModel
                willLoadProfileFooterViewModel:(NCProfileFooterViewModel *)footerViewModel;

/// Called before loading the data source
/// @param viewModel viewModel
/// @param profileList The current data source
/// @return The data source processed by the app, or `nil` to use the default
///
- (NSArray<NSArray<NCProfileCellViewModel *> *> *)
                profileViewModel:(NCProfileViewModel *)viewModel
    willLoadProfileCellViewModel:(NSArray<NSArray<NCProfileCellViewModel *> *> *)profileList;

/// Called when the user taps a cell
///
/// @param viewModel viewModel
/// @param viewController The current view controller
/// @param tableView tableView
/// @param indexPath indexPath
/// @param cellViewModel cellViewModel
/// @return `YES` if the app handled the event; `NO` to let the SDK handle it
///
- (BOOL)profileViewModel:(NCProfileViewModel *)viewModel
          viewController:(UIViewController *)viewController
               tableView:(UITableView *)tableView
            didSelectRow:(NSIndexPath *)indexPath
           cellViewModel:(NCProfileCellViewModel *)cellViewModel;
@end

/// Profile view model
@interface NCProfileViewModel : NCBaseViewModel <NCListViewModelProtocol>

/// Data source
@property (nonatomic, strong, readonly) NSArray<NSArray<NCProfileCellViewModel *> *> *profileList;

/// Footer view model
@property (nonatomic, strong, readonly, nullable) NCProfileFooterViewModel *footerViewModel;

/// Delegate
@property (nonatomic, weak) id<NCProfileViewModelDelegate> delegate;

/// View responder
@property (nonatomic, weak) id<NCListViewModelResponder> responder;

/// Updates the profile
- (void)updateProfile;

/// Loads the footer view
- (UIView *)loadFooterView;

@end

NS_ASSUME_NONNULL_END
