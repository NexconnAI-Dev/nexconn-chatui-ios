//
//  YYTransaction.h
//  YYKit <https://github.com/ibireme/YYKit>
//
//  Original copyright (c) 2015 ibireme <ibireme@gmail.com>.
//  Modified by Nexconn in 2026.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 YYTransaction let you perform a selector once before current runloop sleep.
 */
@interface NCYYTransaction : NSObject

/**
 Creates and returns a transaction with a specified target and selector.
 
 - Parameter target:    A specified target, the target is retained until runloop end.
 - Parameter selector:  A selector for target.
 
 - Returns: A new transaction, or nil if an error occurs.
 */
+ (NCYYTransaction *)transactionWithTarget:(id)target selector:(SEL)selector;

/**
 Commit the trancaction to main runloop.
 
  It will perform the selector on the target once before main runloop's
 current loop sleep. If the same transaction (same target and same selector) has 
 already commit to runloop in this loop, this method do nothing.
 */
- (void)commit;

@end

NS_ASSUME_NONNULL_END
