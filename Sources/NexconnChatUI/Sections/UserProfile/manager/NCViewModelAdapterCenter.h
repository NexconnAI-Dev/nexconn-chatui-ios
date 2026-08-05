//
//  NCAdapterCenter.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// View model adapter center
@interface NCViewModelAdapterCenter : NSObject

/// Registers a delegate for a view model class
/// 
/// @param delegate The delegate object
/// @param cls The view model class
/// @return Whether the operation succeeded
+ (BOOL)registerDelegate:(id _Nullable)delegate forViewModelClass:(Class)cls;

/// Removes the delegate for a view model class
///
/// @param cls The view model class
/// @return Whether the operation succeeded
+ (BOOL)removeDelegateForViewModelClass:(Class)cls;

/// Returns the delegate for a view model class
///
/// @param cls The view model class
+ (id)delegateForViewModelClass:(Class)cls;

@end

NS_ASSUME_NONNULL_END
