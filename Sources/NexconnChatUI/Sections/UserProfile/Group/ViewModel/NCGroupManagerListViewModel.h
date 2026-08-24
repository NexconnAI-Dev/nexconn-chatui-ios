//
//  NCGroupManagersViewModel.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseCellViewModel.h"
#import "NCBaseViewModel.h"
#import "NCListViewModelProtocol.h"
NS_ASSUME_NONNULL_BEGIN
@class NCGroupManagerListViewModel;
@protocol NCGroupManagerListViewModelDelegate <NSObject>

@optional
/// Called when the user taps a cell
/// @param viewModel viewModel
/// @param viewController The current view controller
/// @param tableView tableView
/// @param indexPath indexPath
/// @param cellViewModel cellViewModel
/// @return `YES` if the app handled the event; `NO` to let the SDK handle it
///
- (BOOL)groupAdmins:(NCGroupManagerListViewModel *)viewModel
     viewController:(UIViewController *)viewController
          tableView:(UITableView *)tableView
       didSelectRow:(NSIndexPath *)indexPath
      cellViewModel:(NCBaseCellViewModel *)cellViewModel;

/// Called when admins have been added
/// @param groupId The group identifier
/// @param addUserIds The list of admin user identifiers to add
/// @param viewController The current view controller
/// @return `YES` if the app handled the event; `NO` to let the SDK handle it
///
- (BOOL)groupAdminsDidAdd:(NSString *)groupId
               addUserIds:(NSArray<NSString *> *)addUserIds
           viewController:(UIViewController *)viewController;

/// Called when an admin is about to be removed
/// @param groupId The group identifier
/// @param removeUserIds The list of admin user identifiers to remove
/// @param viewController The current view controller
/// @return `YES` if the app handled the event; `NO` to let the SDK handle it
///
- (BOOL)groupAdminsWillRemove:(NSString *)groupId
                removeUserIds:(NSArray<NSString *> *)removeUserIds
               viewController:(UIViewController *)viewController;

/// Called when admins have been removed
/// @param groupId The group identifier
/// @param removeUserIds The list of admin user identifiers to remove
/// @param viewController The current view controller
/// @return `YES` if the app handled the event; `NO` to let the SDK handle it
///
- (BOOL)groupAdminsDidRemove:(NSString *)groupId
               removeUserIds:(NSArray<NSString *> *)removeUserIds
              viewController:(UIViewController *)viewController;
@end

/// Group admin list view model
@interface NCGroupManagerListViewModel : NCBaseViewModel <NCListViewModelProtocol>
/// Delegate
@property (nonatomic, weak) id<NCGroupManagerListViewModelDelegate> delegate;

/// Creates an `NCGroupManagerListViewModel` instance
///
/// @param groupId The group owner identifier
+ (instancetype)viewModelWithGroupId:(NSString *)groupId;

/// Binds the responder
- (void)bindResponder:(id<NCListViewModelResponder>)responder;

/// Fetches the admin list
- (void)fetchGroupAdmins;
@end

NS_ASSUME_NONNULL_END
