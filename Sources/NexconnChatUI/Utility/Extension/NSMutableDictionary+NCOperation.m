#import "NSMutableDictionary+NCOperation.h"

@implementation NSMutableDictionary (NCOperation)

- (void)nc_setValue:(id)value forKey:(NSString *)key {
    if (key.length > 0 && value) {
        [self setValue:value forKey:key];
    }
}

- (void)nc_setObject:(id)anObject forKey:(id<NSCopying>)aKey {
    if (anObject && aKey) {
        [self setObject:anObject forKey:aKey];
    }
}

- (void)nc_setObject:(id)obj forKeyedSubscript:(id<NSCopying>)key {
    if (obj && key) {
        [self setObject:obj forKeyedSubscript:key];
    }
}

- (void)nc_removeObjectForKey:(id)aKey {
    if (aKey) {
        [self removeObjectForKey:aKey];
    }
}

@end
