//
//  NCGroupNotificationViewModel.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//
#import <UIKit/UIKit.h>
#import "NCListViewModelProtocol.h"
#import <NexconnChatSDK/NexconnChatSDK.h>
#import "NCBaseViewModel.h"
#import "NCNavigationItemsViewModel.h"
#import "NCBaseCellViewModel.h"

NS_ASSUME_NONNULL_BEGIN
@class NCGroupNotificationViewModel;

@protocol NCGroupNotificationViewModelDelegate <NSObject>
@optional
/// Delivers the current data source to the app for processing
///   - viewModel: viewModel
/// @param dataSource The current data source
/// @return The data source processed by the app, or `nil` to use the default
///
- (NSArray *_Nullable)groupNotificationViewModel:(NCGroupNotificationViewModel *)viewModel
      willLoadItemsInDataSource:(NSArray *_Nullable)dataSource;

/// Configures custom right navigation items
/// @param viewModel viewModel
/// @return Custom navigation items view model, or `nil` to use the default
///
- (NCNavigationItemsViewModel *_Nullable)willConfigureRightNavigationItemsForGroupNotificationViewModel:(NCGroupNotificationViewModel *)viewModel;

/// Called when the user taps a cell
///   - viewModel: viewModel
///   - viewController: viewController
///   - tableView: tableView
///   - indexPath: indexPath
///   - viewModel: CellViewModel
/// @return `YES` if the app handled the event; `NO` to let the SDK handle it
///
- (BOOL)groupNotificationViewModel:(NCGroupNotificationViewModel *)viewModel
                    viewController:(UIViewController*)viewController
                         tableView:(UITableView *)tableView
                      didSelectRow:(NSIndexPath *)indexPath
                     cellViewModel:(NCBaseCellViewModel *)cellViewModel;
@end


@interface NCGroupNotificationViewModel : NCBaseViewModel<NCListViewModelProtocol>

/// Delegate
@property (nonatomic, weak) id<NCGroupNotificationViewModelDelegate> delegate;
/// Query parameters (pageToken, count, order)
@property (nonatomic, strong) NCGroupApplicationsQueryParams *option;

/// Initializes the instance
/// @param option The search configuration
/// @param types The request types
/// @param status The request statuses
- (instancetype)initWithOption:(nullable NCGroupApplicationsQueryParams *)option
                         types:(nullable NSArray<NSNumber *> *)types
                        status:(nullable NSArray<NSNumber *> *)status;
/// Configures the navigation items
- (NSArray *)configureRightNaviItemsForViewController:(UIViewController *)viewController;

/// Fetches data
- (void)fetchData;

/// Binds the responder
- (void)bindResponder:(UIViewController <NCListViewModelResponder>*)responder;

/// Cell height
///   - tableView: tableView
///   - indexPath: indexPath
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;

/// Loads more data
- (void)loadMoreData;

/// Loads data
/// @param option The query parameters
/// @param types The types
/// @param status The status
- (void)fetchDataWithOption:(NCGroupApplicationsQueryParams *)option
                      types:(nonnull NSArray<NSNumber *> *)types
                     status:(nonnull NSArray<NSNumber *> *)status;
@end

NS_ASSUME_NONNULL_END
