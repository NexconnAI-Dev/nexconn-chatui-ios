//
//  NCChannelListDataSource.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NCChannelModel.h"

@protocol NCChannelListDataSourceDelegate;


/// Data source for the channel list page. It fetches and processes data, then notifies the channel list page to refresh.

/// Regular class owned by the channel list page.
@interface NCChannelListDataSource : NSObject

/// Channel types to display. This field is used to fetch data for matching channel types.
@property (nonatomic, strong) NSArray *displayConversationTypeArray;

/// Cell background color in normal and dark mode.
@property (nonatomic, strong) UIColor *cellBackgroundColor;

/// Pinned cell background color in normal and dark mode.
@property (nonatomic, strong) UIColor *topCellBackgroundColor;

/// Whether the channel list page is in the appeared state. When it is not visible, incoming messages do not refresh the page; channels are reloaded in viewWillAppear.
@property (nonatomic, assign) BOOL isConverstaionListAppear;

/// Data source for the channel list page. This is not thread-safe and must be handled on the main thread.
@property (nonatomic, strong) NSMutableArray *dataList;

/// Data source delegate. It mainly callbacks the channel list page after partial data processing so the page can refresh.
@property (nonatomic, weak) id<NCChannelListDataSourceDelegate> delegate;

/// Forces loading channel list data, usually called in viewWillApper.
/// - Parameter completion: Channel list data.
///  Callback is invoked on the UI thread.
- (void)forceLoadConversationModelList:(void (^)(NSMutableArray<NCChannelModel *> *modelList))completion;

/// Loads more channel list data, usually triggered by a pull-up action.
/// - Parameter completion: Newly loaded channel list data.
///  Callback is invoked on the UI thread.
- (void)loadMoreConversations:(void (^)(NSMutableArray<NCChannelModel *> *modelList))completion;

/// Refreshes the specified channel.
/// - Parameters:
///   - channelType: Channel type.
///   - channelId: Channel ID.
///   - subChannelId: Sub-channel ID. Pass nil when it is not a community sub-channel.
- (void)refreshConversationForChannelType:(NCChannelType)channelType
                                channelId:(NSString *)channelId
                             subChannelId:(nullable NSString *)subChannelId;

/// Deletes the specified channel.
/// - Parameters:
///   - model: Channel model to delete.
///   - completion: Deletion result callback. success is YES when deletion succeeds.
- (void)deleteConversation:(NCChannelModel *)model completion:(void (^)(BOOL success))completion;
@end

@protocol NCChannelListDataSourceDelegate <NSObject>

- (NSMutableArray<NCChannelModel *> *)dataSource:(NCChannelListDataSource *)datasource willReloadTableData:(NSMutableArray<NCChannelModel *> *)modelList;

- (void)dataSource:(NCChannelListDataSource *)dataSource willReloadAtIndexPaths:(NSArray <NSIndexPath *> *)indexPaths;
- (void)dataSource:(NCChannelListDataSource *)dataSource willInsertAtIndexPaths:(NSArray <NSIndexPath *> *)indexPaths;
- (void)dataSource:(NCChannelListDataSource *)dataSource willDeleteAtIndexPaths:(NSArray <NSIndexPath *> *)deleteIndexPaths willInsertAtIndexPaths:(NSArray <NSIndexPath *> *)insertIndexPaths;

- (void)refreshConversationTableViewIfNeededInDataSource:(NCChannelListDataSource *)datasource;

- (void)notifyUpdateUnreadMessageCountInDataSource;

- (BOOL)showConversationOnTopPriority;
@end
