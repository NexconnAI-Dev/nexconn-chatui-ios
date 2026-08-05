//
//  NCFriendApplyAlertView.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseView.h"
#import "NCTextView.h"
NS_ASSUME_NONNULL_BEGIN

typedef void(^NCApplyFriendAlertBlock)(NSString *);
/// Friend request alert view
@interface NCApplyFriendAlertView : NCBaseView

/// Displays the friend request alert
/// @param title The title
/// @param placeholder The placeholder text
/// @param completion The completion callback
+ (void)showAlert:(NSString *)title
      placeholder:(NSString *)placeholder
       completion:(NCApplyFriendAlertBlock)completion;

/// Displays the friend request alert
/// @param title The title
/// @param placeholder The placeholder text
/// @param limit The character length limit
/// @param completion The completion callback
+ (void)showAlert:(NSString *)title
      placeholder:(NSString *)placeholder
      lengthLimit:(NSInteger)limit
       completion:(NCApplyFriendAlertBlock)completion;
@end

NS_ASSUME_NONNULL_END
