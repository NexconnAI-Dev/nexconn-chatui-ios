//
//  NSDictionary+NCAccessor.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSDictionary (NCAccessor)

/// Use with care. This method is retained only for legacy parsing of strings, maps, arrays, and
/// NSNumber values. Use nc_stringForKey for normal string parsing.
/// - Parameter key: key
- (nullable NSString *)nc_mix_stringForKey:(id)key;

- (nullable NSString *)nc_stringForKey:(id)key;
- (nullable NSDictionary *)nc_dictionaryForKey:(id)key;
- (nullable NSArray *)nc_arrayForKey:(id)key;

- (NSInteger)nc_integerForKey:(id)key;
- (NSInteger)nc_integerForKey:(id)key defaultValue:(NSInteger)defaultValue;
- (NSUInteger)nc_unsignedIntegerForKey:(id)key;

- (int)nc_intForKey:(id)key;
- (unsigned int)nc_unsignedIntForKey:(id)key;

- (long)nc_longForKey:(id)key;
- (unsigned long)nc_unsignedLongForKey:(id)key;

- (long long int)nc_longLongIntForKey:(id)key;
- (unsigned long long int)nc_unsignedLongLongIntForKey:(id)key;

- (BOOL)nc_boolForKey:(id)key;

- (float)nc_floatForKey:(id)key;

- (double)nc_doubleForKey:(id)key;

- (nullable id)nc_JSONObjectForKey:(id)key;

- (BOOL)nc_objectForKeyIsValid:(id)key;

@end

@interface NSDictionary (NCJson)

+ (nullable NSDictionary *)nc_dictionaryFromJsonString:(NSString *)jsonString;
+ (nullable NSDictionary *)nc_dictionaryFromJsonData:(NSData *)jsonData;

@end

NS_ASSUME_NONNULL_END
