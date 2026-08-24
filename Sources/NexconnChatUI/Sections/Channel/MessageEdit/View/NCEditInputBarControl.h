//
//  NCEditInputBarControl.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCChatUIUserInfo.h"
#import "NCEditInputBarConfig.h"
#import "NCEditInputContainerView.h"
#import "NCEmojiBoardView.h"
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class NCEditInputBarControl;
@class NCMentionedInfo;

@protocol NCEditInputBarControlDelegate <NSObject>

@required
/// Edit confirmed
/// @param editInputBarControl The edit input bar control
/// @param text The edited text
- (void)editInputBarControl:(NCEditInputBarControl *)editInputBarControl
         didConfirmWithText:(NSString *)text;

/// Edit cancelled
/// @param editInputBarControl The edit input bar control
- (void)editInputBarControlDidCancel:(NCEditInputBarControl *)editInputBarControl;

/// Request full-screen edit mode
- (void)editInputBarControlRequestFullScreenEdit:(NCEditInputBarControl *)editInputBarControl;

/// Request collapsing from full-screen edit mode
- (void)editInputBarControlCollapseFromFullScreenEdit:(NCEditInputBarControl *)editInputBarControl;

@optional

/// Request showing user selector (for mention functionality)
/// @param editInputBarControl The edit input bar control
/// @param selectedBlock Callback when a user is selected
/// @param cancelBlock Callback when cancelled
- (void)editInputBarControl:(NCEditInputBarControl *)editInputBarControl
           showUserSelector:(void (^)(NCChatUIUserInfo *selectedUser))selectedBlock
                     cancel:(void (^)(void))cancelBlock;

/// Edit control height changed
/// @param editInputBarControl The edit input bar control
/// @param frame The new frame
- (void)editInputBarControl:(NCEditInputBarControl *)editInputBarControl
          shouldChangeFrame:(CGRect)frame;

@end

@protocol NCEditInputBarControlDataSource <NSObject>

@optional

/// Get user info (for mention functionality)
/// @param editInputBarControl The edit input bar control
/// @param userId The user ID
/// @return The user info
- (nullable NCChatUIUserInfo *)editInputBarControl:(NCEditInputBarControl *)editInputBarControl
                                       getUserInfo:(NSString *)userId;

@end

/// Dedicated edit input bar control
@interface NCEditInputBarControl : UIView <NCEditInputContainerViewDelegate, NCEmojiViewDelegate>

#pragma mark - Properties

/// Delegate of the edit input bar control
@property (nonatomic, weak, nullable) id<NCEditInputBarControlDelegate> delegate;

/// Data source of the edit input bar control
@property (nonatomic, weak, nullable) id<NCEditInputBarControlDataSource> dataSource;

/// Target ID
@property (nonatomic, copy) NSString *channelId;

/// Parent view for the bottom panels. If provided, the bottom panel's origin.x and origin.y are
/// both 0. If not set, the bottom panel is displayed on the parent view of NCEditInputBarControl,
/// laid out at the bottom of the screen.
@property (nonatomic, strong) UIView *bottomPanelsContainerView;

/// Whether the control is visible
@property (nonatomic, assign) BOOL isVisible;

/// Whether in full-screen mode
@property (nonatomic, assign, readonly) BOOL isFullScreen;

/// Whether editing is currently available (business logic state). Defaults to editable.
/// To set as non-editable, call `setEditStatus:reason:`.
@property (nonatomic, assign, readonly) BOOL canEdit;

/// Current mention info for sending messages
@property (nonatomic, strong, readonly, nullable) NCMentionedInfo *mentionedInfo;

/// Whether mention functionality is enabled
@property (nonatomic, assign) BOOL isMentionedEnabled;

/// Current status of the bottom panel
@property (nonatomic, assign, readonly) KBottomBarStatus currentBottomBarStatus;

/// Configuration of the edit input bar
@property (nonatomic, strong) NCEditInputBarConfig *inputBarConfig;

/// Initialization method
- (instancetype)initWithIsFullScreen:(BOOL)isFullScreen;

/// Add a mentioned user
/// @param userInfo The user info
/// @param symbolRequest Whether to insert the @ symbol (YES = insert @ symbol + username, NO =
/// insert username only, assuming @ symbol already exists)
- (void)addMentionedUser:(NCChatUIUserInfo *)userInfo symbolRequest:(BOOL)symbolRequest;

/// Set reference message info, typically used to update the referenced message content display
/// @param senderName Sender name of the referenced message
/// @param content Content of the referenced message
- (void)setReferenceInfo:(NSString *)senderName content:(NSString *)content;

#pragma mark - Core Components

/// Edit input container
@property (nonatomic, strong, readonly) NCEditInputContainerView *editInputContainer;

/// Emoji board view
@property (nonatomic, strong, readonly, nullable) NCEmojiBoardView *emojiBoardView;

#pragma mark - Edit State Management

/// Mark the edit as expired
- (void)markEditAsExpired;

/// Restore edit status
- (void)restoreEditStatus;

#pragma mark - Public Methods

/// Show the edit input bar
- (void)showWithConfig:(NCEditInputBarConfig *)config;

/// Exit the edit input bar
- (void)exitWithAnimation:(BOOL)animated completion:(void (^_Nullable)(void))completion;

/// Get the current edit text
- (NSString *)currentEditText;

/// Set the edit text
/// @param text The text content
- (void)setEditText:(NSString *)text;

/// Restore input focus
- (void)restoreFocus;

/// Hide bottom panels, including the emoji board or keyboard
- (void)hideBottomPanelsWithAnimation:(BOOL)animated completion:(void (^_Nullable)(void))completion;

/// Set the visibility of the edit input bar (without exiting edit mode)
/// @param hidden Whether to hide
- (void)hideEditInputBar:(BOOL)hidden;

/// Reset the edit input bar and clear edit content
- (void)resetEditInputBar;

/// Check whether there is any content
- (BOOL)hasContent;

#pragma mark - Cursor Position

/// Get the current cursor position
- (NSRange)getCurrentCursorPosition;

/// Set the cursor position
/// @param range The cursor position range
- (void)setCursorPosition:(NSRange)range;

@end

NS_ASSUME_NONNULL_END
