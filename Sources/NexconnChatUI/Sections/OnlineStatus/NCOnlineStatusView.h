//
//  NCOnlineStatusView.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseView.h"

NS_ASSUME_NONNULL_BEGIN

/// Online status indicator view.
///
/// @note
///     - Displays as a 6x6 circular indicator.
///     - Online: green dot.
///     - Offline: gray dot.
///     - Hidden by default.
///
@interface NCOnlineStatusView : NCBaseView

// isOnline: YES = online (green), NO = offline (gray)
@property (nonatomic, assign, getter=isOnline) BOOL online;

/// Reset the status (hide and clear color).
- (void)reset;

@end

NS_ASSUME_NONNULL_END
