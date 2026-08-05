#import "NSMutableArray+NCOperation.h"

@implementation NSMutableArray (NCOperation)

- (void)nc_addObject:(id)anObject {
    if (anObject) {
        [self addObject:anObject];
    }
}

- (void)nc_insertObject:(id)anObject atIndex:(NSUInteger)index {
    if (anObject && index <= self.count) {
        [self insertObject:anObject atIndex:index];
    }
}

- (void)nc_removeObjectAtIndex:(NSUInteger)index {
    if (index < self.count) {
        [self removeObjectAtIndex:index];
    }
}

- (void)nc_replaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject {
    if (anObject && index < self.count) {
        [self replaceObjectAtIndex:index withObject:anObject];
    }
}

@end

@implementation NSArray (NCJson)

+ (NSArray *)nc_arrayFromJsonString:(NSString *)jsonString {
    if (jsonString.length == 0) {
        return nil;
    }
    return [self nc_arrayFromJsonData:[jsonString dataUsingEncoding:NSUTF8StringEncoding]];
}

+ (NSArray *)nc_arrayFromJsonData:(NSData *)jsonData {
    if (jsonData.length == 0) {
        return nil;
    }
    id object = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:nil];
    return [object isKindOfClass:[NSArray class]] ? object : nil;
}

@end
