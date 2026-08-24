//
//  NCApplyNaviItemsViewModel.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCNavigationItemsViewModel.h"

typedef NS_ENUM(NSInteger, NCApplicationCategory) {
    NCApplicationCategoryBoth,
    NCApplicationCategoryReceived,
    NCApplicationCategorySent
};
NS_ASSUME_NONNULL_BEGIN

@protocol NCApplyNaviItemsViewModelDelegate <NSObject>

/// Called when the user selects a display category
- (void)userDidSelectCategory:(NCApplicationCategory)category;

@end

/// Friend request navigation items view model
@interface NCApplyNaviItemsViewModel : NCNavigationItemsViewModel

/// Delegate
@property (nonatomic, weak) id<NCApplyNaviItemsViewModelDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
