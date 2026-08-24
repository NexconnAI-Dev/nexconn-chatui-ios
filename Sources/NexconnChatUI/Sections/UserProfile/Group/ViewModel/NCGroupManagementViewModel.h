//
//  NCGroupManagementViewModel.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseCellViewModel.h"
#import "NCBaseViewModel.h"
#import "NCListViewModelProtocol.h"
NS_ASSUME_NONNULL_BEGIN
@class NCGroupManagementViewModel;
@protocol NCGroupManagementViewModelDelegate <NSObject>

@optional

/// Called before loading the data source
/// @param viewModel viewModel
/// @param dataSource The current data source
/// @return The data source processed by the app, or `nil` to use the default
///
- (NSArray<NSArray<NCBaseCellViewModel *> *> *)
              groupManagement:(NCGroupManagementViewModel *)viewModel
    willLoadItemsInDataSource:(NSArray<NSArray<NCBaseCellViewModel *> *> *)dataSource;

/// Called when the user taps a cell
/// @param viewModel viewModel
/// @param viewController The current view controller
/// @param tableView tableView
/// @param indexPath indexPath
/// @param cellViewModel cellViewModel
/// @return `YES` if the app handled the event; `NO` to let the SDK handle it
///
- (BOOL)groupManagement:(NCGroupManagementViewModel *)viewModel
         viewController:(UIViewController *)viewController
              tableView:(UITableView *)tableView
           didSelectRow:(NSIndexPath *)indexPath
          cellViewModel:(NCBaseCellViewModel *)cellViewModel;

@end
/// Group management view model
@interface NCGroupManagementViewModel : NCBaseViewModel <NCListViewModelProtocol>

/// Delegate
@property (nonatomic, weak) id<NCGroupManagementViewModelDelegate> delegate;

/// Creates an `NCGroupManagementViewModel` instance
///
/// @param groupId The group owner identifier
+ (instancetype)viewModelWithGroupId:(NSString *)groupId;

/// Binds the responder
- (void)bindResponder:(id<NCListViewModelResponder>)responder;

/// Returns the data source
- (void)fetchDataSources;
@end

NS_ASSUME_NONNULL_END
