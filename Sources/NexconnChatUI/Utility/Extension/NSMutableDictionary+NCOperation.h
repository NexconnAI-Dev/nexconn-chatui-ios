//
//  NSMutableDictionary+NCOperation.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSMutableDictionary (NCOperation)

- (void)nc_setValue:(nullable id)value forKey:(NSString *)key;

- (void)nc_setObject:(id)anObject forKey:(id<NSCopying>)aKey;

- (void)nc_setObject:(id)obj forKeyedSubscript:(id<NSCopying>)key;

- (void)nc_removeObjectForKey:(id)aKey;

@end

NS_ASSUME_NONNULL_END
