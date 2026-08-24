//
//  NCGroupNotificationNaviItemsViewModel.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCNavigationItemsViewModel.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, NCGroupNotificationCategory) {
    NCGroupNotificationCategoryAll,           // All
    NCGroupNotificationCategoryToBeConfirmed, // Pending
    NCGroupNotificationCategoryDealt,         // Completed
    NCGroupNotificationCategoryExpired        // Expired
};

@protocol NCGroupNotificationNaviItemsViewModelDelegate <NSObject>

/// Called when the user selects a display category
- (void)userDidSelectCategory:(NCGroupNotificationCategory)category;

@end

@interface NCGroupNotificationNaviItemsViewModel : NCNavigationItemsViewModel
/// Delegate
@property (nonatomic, weak) id<NCGroupNotificationNaviItemsViewModelDelegate> delegate;
@end

NS_ASSUME_NONNULL_END
