//
//  NSMutableArray+NCOperation.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSMutableArray (NCOperation)

- (void)nc_addObject:(id)anObject;

- (void)nc_insertObject:(id)anObject atIndex:(NSUInteger)index;

- (void)nc_removeObjectAtIndex:(NSUInteger)index;

- (void)nc_replaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject;

@end

@interface NSArray (NCJson)

+ (nullable NSArray *)nc_arrayFromJsonString:(NSString *)jsonString;
+ (nullable NSArray *)nc_arrayFromJsonData:(NSData *)jsonData;

@end

NS_ASSUME_NONNULL_END
