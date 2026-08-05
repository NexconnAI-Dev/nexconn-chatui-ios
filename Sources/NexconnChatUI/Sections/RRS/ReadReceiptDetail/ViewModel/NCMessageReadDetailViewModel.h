//
//  NCMessageReadDetailViewModel.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "NCMessageReadDetailViewConfig.h"
#import "NCMessageModel.h"
#import "NCMessageReadDetailCellViewModel.h"
#import "NCMessageReadDetailDefine.h"

NS_ASSUME_NONNULL_BEGIN

/// Read receipt detail view model responder
@protocol NCMessageReadDetailViewModelResponder <NSObject>

@optional

/// Reloads the list
/// @param isEmpty Whether the list is empty
/// @param tabType The tab type
- (void)updateUserListForTabType:(NCMessageReadDetailTabType)tabType
                         isEmpty:(BOOL)isEmpty
                     hasMoreData:(BOOL)hasMoreData;

/// Current view controller
/// @return The current view controller
- (UIViewController *)currentViewController;

/// Updates the read/unread count for the tab
/// @param readCount The read count
/// @param unreadCount The unread count
- (void)updateTabViewWithReadCount:(NSInteger)readCount unreadCount:(NSInteger)unreadCount;

@end

/// Read receipt detail list view model
@interface NCMessageReadDetailViewModel : NSObject

/// Responder
@property (nonatomic, weak) id<NCMessageReadDetailViewModelResponder> responder;

/// Message model
@property (nonatomic, strong, readonly) NCMessageModel *messageModel;

/// Configuration
@property (nonatomic, strong, readonly) NCMessageReadDetailViewConfig *config;

/// Current tab type
@property (nonatomic, assign, readonly) NCMessageReadDetailTabType currentTabType;

/// List of users who have read
@property (nonatomic, strong, readonly) NSMutableArray<NCMessageReadDetailCellViewModel *> *readUserList;

/// List of users who have not read
@property (nonatomic, strong, readonly) NSMutableArray<NCMessageReadDetailCellViewModel *> *unreadUserList;

/// Initializes the view model
/// @param messageModel The message model
/// @param config The configuration
- (instancetype)initWithMessageModel:(NCMessageModel *)messageModel
                              config:(nullable NCMessageReadDetailViewConfig *)config;

/// Binds the responder
/// @param responder The responder
- (void)bindResponder:(id<NCMessageReadDetailViewModelResponder>)responder;

/// Switches the tab
/// @param tabType The tab type
- (void)switchTabToType:(NCMessageReadDetailTabType)tabType;

/// Fetches data
- (void)loadData;

/// Fetches more data with pagination
- (void)loadMoreData;

/// Returns the number of sections for the specified tab
/// @param tabType The tab type
/// @return The number of sections
- (NSInteger)numberOfSectionsForTabType:(NCMessageReadDetailTabType)tabType;

/// Returns the number of rows for the specified tab
/// @param tabType The tab type
/// @param section The section index
/// @return The number of rows
- (NSInteger)numberOfRowsForTabType:(NCMessageReadDetailTabType)tabType inSection:(NSInteger)section;

/// Returns the cell view model for the specified tab and index
/// @param tabType The tab type
/// @param index The index
/// @return The cell view model, or `nil` if the index is out of bounds
- (NCMessageReadDetailCellViewModel *)cellViewModelForTabType:(NCMessageReadDetailTabType)tabType atIndex:(NSInteger)index;

/// Returns the cell height for the specified tab and index
/// @param tabType The tab type
/// @param index The index
/// @return The cell height, or 0 if the index is out of bounds
- (CGFloat)cellHeightForTabType:(NCMessageReadDetailTabType)tabType atIndex:(NSInteger)index;

@end

NS_ASSUME_NONNULL_END
