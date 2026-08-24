//
//  NCApplyFriendSectionItem.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCApplyFriendSectionItem.h"

@interface NCApplyFriendSectionItem ()
@property (nonatomic, strong) NSMutableArray *items;
@property (nonatomic, copy) NCFriendApplyItemFilterBlock filterBlock;
@property (nonatomic, copy) NCFriedApplyItemCompareBlock compareBlock;
@end

@implementation NCApplyFriendSectionItem

- (instancetype)initWithFilterBlock:(NCFriendApplyItemFilterBlock)filterBlock
                       compareBlock:(NCFriedApplyItemCompareBlock)compareBlock {
    self = [super init];
    if (self) {
        self.filterBlock = filterBlock;
        self.compareBlock = compareBlock;
        self.items = [NSMutableArray array];
    }
    return self;
}

- (NSArray *)filterAndSortItems:(NSArray *)items {
    NSMutableArray *array = [NSMutableArray array];
    if (!self.filterBlock) {
        [array addObjectsFromArray:items];
    } else {
        BOOL stop = NO;
        for (int i = 0; i < [items count]; i++) {
            id obj = items[i];
            if (self.filterBlock) {
                BOOL savable = self.filterBlock(obj, self.timeStart, self.timeEnd, &stop);
                if (savable) {
                    [array addObject:obj];
                }
                if (stop) {
                    break;
                }
            }
        }
    }

    if (array.count > 0 && self.compareBlock) {
        NSArray *sorted = [array sortedArrayUsingComparator:self.compareBlock];
        return sorted;
    } else {
        return array;
    }
}

- (BOOL)isValidSectionItem {
    return (self.title != nil) && self.items.count > 0;
}

- (id)itemAtIndex:(NSInteger)index {
    if (index >= 0 && index < self.items.count) {
        return [self.items objectAtIndex:index];
    }
    return nil;
}
- (void)removeItemAtIndex:(NSInteger)index {
    if (index >= 0 && index < self.items.count) {
        [self.items removeObjectAtIndex:index];
    }
}

- (NSInteger)countOfItems {
    return self.items.count;
}

- (void)clean {
    [self.items removeAllObjects];
}

- (void)appendItems:(NSArray *)items {
    [self.items addObjectsFromArray:items];
}
@end
