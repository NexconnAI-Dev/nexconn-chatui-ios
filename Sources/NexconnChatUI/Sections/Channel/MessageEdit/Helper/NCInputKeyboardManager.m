//
//  NCInputKeyboardManager.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCInputKeyboardManager.h"
#import "NCChatUIUtility.h"
#import "NCChatUICommonDefine.h"

// Standard system status bar height.
#define SYS_STATUSBAR_HEIGHT 20
// Additional status bar height while Personal Hotspot is active.
#define HOTSPOT_STATUSBAR_HEIGHT 20
#define APP_STATUSBAR_HEIGHT ([NCChatUIUtility getStatusBarHeightForView:nil])
#define IS_HOTSPOT_CONNECTED (APP_STATUSBAR_HEIGHT == (SYS_STATUSBAR_HEIGHT + HOTSPOT_STATUSBAR_HEIGHT) ? YES : NO)

@interface NCInputKeyboardManager ()

/// Current keyboard height.
@property (nonatomic, assign, readwrite) CGFloat currentKeyboardHeight;

/// Current keyboard frame.
@property (nonatomic, assign, readwrite) CGRect currentKeyboardFrame;

/// Whether the keyboard is visible.
@property (nonatomic, assign, readwrite) BOOL isKeyboardVisible;

/// Whether keyboard notifications are being observed.
@property (nonatomic, assign) BOOL isMonitoring;

@end

@implementation NCInputKeyboardManager

#pragma mark - Lifecycle

- (instancetype)init {
    self = [super init];
    if (self) {
        [self resetKeyboardState];
    }
    return self;
}

- (void)dealloc {
    [self stopMonitoring];
}

#pragma mark - Public Methods

- (void)startMonitoring {
    if (self.isMonitoring) {
        return;
    }
    
    // Observe keyboard presentation changes.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShowNotification:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHideNotification:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    self.isMonitoring = YES;
}

- (void)stopMonitoring {
    if (!self.isMonitoring) {
        return;
    }
    
    // Stop observing keyboard presentation changes.
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    
    self.isMonitoring = NO;
    [self resetKeyboardState];
}

#pragma mark - Private Methods

- (void)resetKeyboardState {
    self.currentKeyboardHeight = 0;
    self.currentKeyboardFrame = CGRectZero;
    self.isKeyboardVisible = NO;
}

#pragma mark - Keyboard Notifications

- (void)keyboardWillShowNotification:(NSNotification *)notification {
    // Allow the delegate to ignore keyboard events for the current state.
    if ([self.delegate respondsToSelector:@selector(keyboardManagerShouldHandleKeyboardEvent:)]) {
        if (![self.delegate keyboardManagerShouldHandleKeyboardEvent:self]) {
            return;
        }
    }
    
    // Read the final keyboard frame.
    NSDictionary *userInfo = notification.userInfo;
    CGRect keyboardEndFrame = [userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    // Read the system keyboard animation parameters.
    UIViewAnimationCurve animationCurve = [userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
    NSTimeInterval animationDuration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    // Store the visible keyboard state.
    self.currentKeyboardFrame = keyboardEndFrame;
    self.currentKeyboardHeight = keyboardEndFrame.size.height;
    self.isKeyboardVisible = YES;
    
    // Notify the delegate before the keyboard appears.
    if ([self.delegate respondsToSelector:@selector(keyboardManager:willShowWithHeight:frame:animationDuration:animationCurve:)]) {
        [self.delegate keyboardManager:self 
                    willShowWithHeight:self.currentKeyboardHeight 
                                 frame:self.currentKeyboardFrame
                     animationDuration:animationDuration 
                        animationCurve:animationCurve];
    }
}

- (void)keyboardWillHideNotification:(NSNotification *)notification {
    // Allow the delegate to ignore keyboard events for the current state.
    if ([self.delegate respondsToSelector:@selector(keyboardManagerShouldHandleKeyboardEvent:)]) {
        if (![self.delegate keyboardManagerShouldHandleKeyboardEvent:self]) {
            return;
        }
    }
    
    // Mark the keyboard as hidden.
    self.isKeyboardVisible = NO;
    // Preserve the last frame and height because the hide animation may still use them.
    
    // Notify the delegate before the keyboard hides.
    if ([self.delegate respondsToSelector:@selector(keyboardManagerWillHide:)]) {
        [self.delegate keyboardManagerWillHide:self];
    }
}

#pragma mark - Utility Methods

+ (CGFloat)screenBottomY {
    CGFloat gap = (NC_IOS_SYSTEM_VERSION_LESS_THAN(@"7.0")) ? 64 : 0;
    CGFloat safeAreaBottom = [NCChatUIUtility getWindowSafeAreaInsets].bottom;
    gap += safeAreaBottom;
    
    if (safeAreaBottom > 0) {
        // On safe-area devices, Personal Hotspot does not change the usable status bar height.
        return [UIScreen mainScreen].bounds.size.height - gap;
    } else {
        return [self isHotspotConnected] ? [UIScreen mainScreen].bounds.size.height - gap - 20
                                         : [UIScreen mainScreen].bounds.size.height - gap;
    }
}

+ (BOOL)isHotspotConnected {
    return IS_HOTSPOT_CONNECTED;
}

- (CGFloat)calculateInputBarYWithInputBarHeight:(CGFloat)inputBarHeight {
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    UIEdgeInsets safeAreaInsets = [NCChatUIUtility getWindowSafeAreaInsets];
    CGFloat screenBottomY = CGRectGetMaxY(screenBounds);
    
    CGFloat result;
    if (self.isKeyboardVisible && !CGRectIsEmpty(self.currentKeyboardFrame)) {
        // Use the tracked frame so positioning matches the notification state.
        result = CGRectGetMinY(self.currentKeyboardFrame) - inputBarHeight;
    } else {
        // With a hardware or hidden keyboard: Y = screen bottom - safe area - input bar height.
        result = screenBottomY - safeAreaInsets.bottom - inputBarHeight;
    }
    return result;
}

@end 
