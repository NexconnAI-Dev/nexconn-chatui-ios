//
//  NCInputKeyboardManager.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class NCInputKeyboardManager;

/// Input keyboard manager delegate protocol.
/// Notifies keyboard state changes and decouples UI from keyboard logic.
@protocol NCInputKeyboardManagerDelegate <NSObject>

@required

/// Called before the keyboard is shown.
/// - Parameter manager The keyboard manager instance.
/// - Parameter height The keyboard height.
/// - Parameter frame The keyboard frame.
/// - Parameter duration The animation duration.
/// - Parameter curve The animation curve.
- (void)keyboardManager:(NCInputKeyboardManager *)manager
     willShowWithHeight:(CGFloat)height
                  frame:(CGRect)frame
      animationDuration:(NSTimeInterval)duration
         animationCurve:(UIViewAnimationCurve)curve;

/// Called before the keyboard is hidden.
/// - Parameter manager The keyboard manager instance.
- (void)keyboardManagerWillHide:(NCInputKeyboardManager *)manager;

@optional

/// Asks whether keyboard events should be handled.
/// - Parameter manager The keyboard manager instance.
/// - Returns YES to handle keyboard events, NO to ignore them.
- (BOOL)keyboardManagerShouldHandleKeyboardEvent:(NCInputKeyboardManager *)manager;

@end

/// Input keyboard manager.
///
/// Responsibilities:
/// 1. Observe system keyboard notifications.
/// 2. Parse keyboard parameters, including height, frame, and animation info.
/// 3. Provide keyboard-related calculation utilities.
/// 4. Notify keyboard state changes through the delegate pattern.
@interface NCInputKeyboardManager : NSObject

#pragma mark - Basic Properties

/// Delegate object used to notify keyboard state changes.
@property (nonatomic, weak, nullable) id<NCInputKeyboardManagerDelegate> delegate;

/// Current keyboard height, read-only.
@property (nonatomic, assign, readonly) CGFloat currentKeyboardHeight;

/// Current keyboard frame, read-only.
@property (nonatomic, assign, readonly) CGRect currentKeyboardFrame;

/// Whether the keyboard is visible, read-only.
@property (nonatomic, assign, readonly) BOOL isKeyboardVisible;

#pragma mark - Lifecycle Management

/// Starts observing keyboard notifications.
/// Call this when keyboard monitoring is needed.
///
- (void)startMonitoring;

/// Stops observing keyboard notifications.
/// Call this when keyboard monitoring is no longer needed, usually in dealloc.
- (void)stopMonitoring;

#pragma mark - Utility Methods (Pure Functions)

/// Gets the screen bottom Y coordinate, considering the safe area and hotspot.
/// - Returns The screen bottom Y coordinate.
+ (CGFloat)screenBottomY;

/// Checks whether a hotspot is connected.
/// - Returns Whether a hotspot is connected.
+ (BOOL)isHotspotConnected;

/// Calculates the input bar Y coordinate under the current keyboard state.
/// - Parameter inputBarHeight The input bar height.
/// - Returns The Y coordinate where the input bar should be placed.
- (CGFloat)calculateInputBarYWithInputBarHeight:(CGFloat)inputBarHeight;

@end

NS_ASSUME_NONNULL_END
