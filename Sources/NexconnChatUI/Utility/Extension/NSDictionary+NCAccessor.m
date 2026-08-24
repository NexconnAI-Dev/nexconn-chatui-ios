#import "NSDictionary+NCAccessor.h"

@implementation NSDictionary (NCAccessor)

- (NSString *)nc_mix_stringForKey:(id)key {
    id value = [self nc_JSONObjectForKey:key];
    if ([value isKindOfClass:[NSString class]]) {
        return value;
    }
    if ([value isKindOfClass:[NSNumber class]]) {
        return [value stringValue];
    }
    if ([value isKindOfClass:[NSDictionary class]] || [value isKindOfClass:[NSArray class]]) {
        NSData *data = [NSJSONSerialization dataWithJSONObject:value options:0 error:nil];
        return data ? [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] : nil;
    }
    return nil;
}

- (NSString *)nc_stringForKey:(id)key {
    id value = [self nc_JSONObjectForKey:key];
    return [value isKindOfClass:[NSString class]] ? value : nil;
}

- (NSDictionary *)nc_dictionaryForKey:(id)key {
    id value = [self nc_JSONObjectForKey:key];
    return [value isKindOfClass:[NSDictionary class]] ? value : nil;
}

- (NSArray *)nc_arrayForKey:(id)key {
    id value = [self nc_JSONObjectForKey:key];
    return [value isKindOfClass:[NSArray class]] ? value : nil;
}

- (NSInteger)nc_integerForKey:(id)key {
    return [self nc_integerForKey:key defaultValue:0];
}

- (NSInteger)nc_integerForKey:(id)key defaultValue:(NSInteger)defaultValue {
    id value = [self nc_JSONObjectForKey:key];
    return [value respondsToSelector:@selector(integerValue)] ? [value integerValue] : defaultValue;
}

- (NSUInteger)nc_unsignedIntegerForKey:(id)key {
    id value = [self nc_JSONObjectForKey:key];
    return [value respondsToSelector:@selector(unsignedIntegerValue)] ? [value unsignedIntegerValue]
                                                                      : 0;
}

- (int)nc_intForKey:(id)key {
    id value = [self nc_JSONObjectForKey:key];
    return [value respondsToSelector:@selector(intValue)] ? [value intValue] : 0;
}

- (unsigned int)nc_unsignedIntForKey:(id)key {
    id value = [self nc_JSONObjectForKey:key];
    return [value respondsToSelector:@selector(unsignedIntValue)] ? [value unsignedIntValue] : 0;
}

- (long)nc_longForKey:(id)key {
    id value = [self nc_JSONObjectForKey:key];
    return [value respondsToSelector:@selector(longValue)] ? [value longValue] : 0;
}

- (unsigned long)nc_unsignedLongForKey:(id)key {
    id value = [self nc_JSONObjectForKey:key];
    return [value respondsToSelector:@selector(unsignedLongValue)] ? [value unsignedLongValue] : 0;
}

- (long long)nc_longLongIntForKey:(id)key {
    id value = [self nc_JSONObjectForKey:key];
    return [value respondsToSelector:@selector(longLongValue)] ? [value longLongValue] : 0;
}

- (unsigned long long)nc_unsignedLongLongIntForKey:(id)key {
    id value = [self nc_JSONObjectForKey:key];
    return [value respondsToSelector:@selector(unsignedLongLongValue)]
               ? [value unsignedLongLongValue]
               : 0;
}

- (BOOL)nc_boolForKey:(id)key {
    id value = [self nc_JSONObjectForKey:key];
    return [value respondsToSelector:@selector(boolValue)] ? [value boolValue] : NO;
}

- (float)nc_floatForKey:(id)key {
    id value = [self nc_JSONObjectForKey:key];
    return [value respondsToSelector:@selector(floatValue)] ? [value floatValue] : 0;
}

- (double)nc_doubleForKey:(id)key {
    id value = [self nc_JSONObjectForKey:key];
    return [value respondsToSelector:@selector(doubleValue)] ? [value doubleValue] : 0;
}

- (id)nc_JSONObjectForKey:(id)key {
    if (!key) {
        return nil;
    }
    id value = self[key];
    return value == [NSNull null] ? nil : value;
}

- (BOOL)nc_objectForKeyIsValid:(id)key {
    return [self nc_JSONObjectForKey:key] != nil;
}

@end

@implementation NSDictionary (NCJson)

+ (NSDictionary *)nc_dictionaryFromJsonString:(NSString *)jsonString {
    if (jsonString.length == 0) {
        return nil;
    }
    return [self nc_dictionaryFromJsonData:[jsonString dataUsingEncoding:NSUTF8StringEncoding]];
}

+ (NSDictionary *)nc_dictionaryFromJsonData:(NSData *)jsonData {
    if (jsonData.length == 0) {
        return nil;
    }
    id object = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:nil];
    return [object isKindOfClass:[NSDictionary class]] ? object : nil;
}

@end
