//
//  NCApplyFriedSectionItem.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef BOOL (^NCFriendApplyItemFilterBlock)(id _Nonnull obj, NSInteger start, NSInteger end,
                                             BOOL *_Nonnull stop);

typedef NSComparisonResult (^NCFriedApplyItemCompareBlock)(id _Nonnull obj1, id _Nonnull obj2);

NS_ASSUME_NONNULL_BEGIN

@interface NCApplyFriendSectionItem : NSObject

// Start timestamp (in milliseconds)
@property (nonatomic, assign) NSInteger timeStart;

/// Deadline timestamp (in milliseconds)
@property (nonatomic, assign) NSInteger timeEnd;

/// Title
@property (nonatomic, copy) NSString *title;

- (instancetype)initWithFilterBlock:(NCFriendApplyItemFilterBlock _Nullable)filterBlock
                       compareBlock:(NCFriedApplyItemCompareBlock _Nullable)compareBlock;

- (NSArray *)filterAndSortItems:(NSArray *)items;
- (BOOL)isValidSectionItem;

@end

NS_ASSUME_NONNULL_END
