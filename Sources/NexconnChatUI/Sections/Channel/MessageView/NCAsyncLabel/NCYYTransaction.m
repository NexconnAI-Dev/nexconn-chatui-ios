//
//  YYTransaction.m
//  YYKit <https://github.com/ibireme/YYKit>
//
//  Original copyright (c) 2015 ibireme <ibireme@gmail.com>.
//  Modified by Nexconn in 2026.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "NCYYTransaction.h"

@interface NCYYTransaction ()
@property (nonatomic, strong) id target;
@property (nonatomic, assign) SEL selector;
@end

static NSMutableSet *transactionSet = nil;

static void NCYYRunLoopObserverCallBack(CFRunLoopObserverRef observer, CFRunLoopActivity activity,
                                        void *info) {
    if (transactionSet.count == 0)
        return;
    NSSet *currentSet = transactionSet;
    transactionSet = [NSMutableSet new];
    [currentSet enumerateObjectsUsingBlock:^(NCYYTransaction *transaction, BOOL *stop) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
      [transaction.target performSelector:transaction.selector];
#pragma clang diagnostic pop
    }];
}

static void NCYYTransactionSetup() {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      transactionSet = [NSMutableSet new];
      CFRunLoopRef runloop = CFRunLoopGetMain();
      CFRunLoopObserverRef observer;

      observer =
          CFRunLoopObserverCreate(CFAllocatorGetDefault(), kCFRunLoopBeforeWaiting | kCFRunLoopExit,
                                  true,     // repeat
                                  0xFFFFFF, // after CATransaction(2000000)
                                  NCYYRunLoopObserverCallBack, NULL);
      CFRunLoopAddObserver(runloop, observer, kCFRunLoopCommonModes);
      CFRelease(observer);
    });
}

@implementation NCYYTransaction

+ (NCYYTransaction *)transactionWithTarget:(id)target selector:(SEL)selector {
    if (!target || !selector)
        return nil;
    NCYYTransaction *t = [NCYYTransaction new];
    t.target = target;
    t.selector = selector;
    return t;
}

- (void)commit {
    if (!_target || !_selector)
        return;
    NCYYTransactionSetup();
    [transactionSet addObject:self];
}

- (NSUInteger)hash {
    long v1 = (long)((void *)_selector);
    long v2 = (long)_target;
    return v1 ^ v2;
}

- (BOOL)isEqual:(id)object {
    if (self == object)
        return YES;
    if (![object isMemberOfClass:self.class])
        return NO;
    NCYYTransaction *other = object;
    return other.selector == _selector && other.target == _target;
}

@end
