//
//  NCViewModelAdapterCenter.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCViewModelAdapterCenter.h"
#import "NCReadWriteLock.h"
#import "NCBaseViewModel.h"
@interface NCViewModelAdapterCenter()

@property (nonatomic, strong) NSMapTable *delegates;
@property (nonatomic, strong) NCReadWriteLock *lock;

@end

@implementation NCViewModelAdapterCenter
 
+ (instancetype)sharedInstance {
    static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.delegates =  [NSMapTable mapTableWithKeyOptions:NSMapTableStrongMemory
                                                valueOptions:NSMapTableWeakMemory];
        self.lock = [[NCReadWriteLock alloc] init];
    }
    return self;
}

#pragma mark - Private


- (BOOL)registerDelegate:(id)delegate forViewModelClass:(Class)cls {
    if (![cls isSubclassOfClass:[NCBaseViewModel class]]) {
        return NO;
    }
    NSString *identifier = NSStringFromClass(cls);
    if (identifier) {
        [self.lock performWriteLockBlock:^{
            [self.delegates setObject:delegate forKey:identifier];
        }];
        return YES;
    }
    return NO;
}

- (id)delegateForViewModelClass:(Class)cls {
    if (![cls isSubclassOfClass:[NCBaseViewModel class]]) {
        return nil;
    }
    NSString *identifier = NSStringFromClass(cls);
    if (identifier) {
       __block id delegate = nil;
        [self.lock  performReadLockBlock:^{
            delegate = [self.delegates objectForKey:identifier];
        }];
        return delegate;
    }
    return nil;
}

#pragma mark - Public

+ (BOOL)registerDelegate:(id)delegate forViewModelClass:(Class)cls {
    NCViewModelAdapterCenter *instance = [NCViewModelAdapterCenter sharedInstance];
    return [instance registerDelegate:delegate forViewModelClass:cls];
}


+ (id)delegateForViewModelClass:(Class)cls {
    NCViewModelAdapterCenter *instance = [NCViewModelAdapterCenter sharedInstance];
    return [instance delegateForViewModelClass:cls];
}

+ (BOOL)removeDelegateForViewModelClass:(Class)cls {
    return [self registerDelegate:nil forViewModelClass:cls];
}
@end
