//
//  NCEventCenter.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCChatUIEventProtocols.h"

NS_ASSUME_NONNULL_BEGIN

@interface NCEventCenter : NSObject

/// Returns the shared event center.
///
/// - Returns: The shared event center instance.
+ (instancetype)sharedManager;

#pragma mark - Connection Status Observers

/// Adds a ChatUI connection status observer.
///
/// - Parameter delegate: The observer to add.
- (void)addConnectionStatusChangeDelegate:(id<NCChatUIConnectionStatusDelegate>)delegate;

/// Removes a ChatUI connection status observer.
///
/// - Parameter delegate: The observer to remove.
- (void)removeConnectionStatusChangeDelegate:(id<NCChatUIConnectionStatusDelegate>)delegate;

/// Returns all ChatUI connection status observers.
///
/// - Returns: All registered ChatUI connection status observers.
- (NSArray<id<NCChatUIConnectionStatusDelegate>> *)allConnectionStatusChangeDelegates;

#pragma mark - Network Status Observers

/// Adds a ChatUI network status observer.
///
/// - Parameter delegate: The observer to add.
- (void)addNetworkStatusChangeDelegate:(id<NCChatUINetworkStatusDelegate>)delegate;

/// Removes a ChatUI network status observer.
///
/// - Parameter delegate: The observer to remove.
- (void)removeNetworkStatusChangeDelegate:(id<NCChatUINetworkStatusDelegate>)delegate;

/// Returns all ChatUI network status observers.
///
/// - Returns: All registered ChatUI network status observers.
- (NSArray<id<NCChatUINetworkStatusDelegate>> *)allNetworkStatusChangeDelegates;

@end

NS_ASSUME_NONNULL_END
