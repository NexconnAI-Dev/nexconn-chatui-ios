//
//  NCInputStateManager.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NCChatUIUserInfo.h"

NS_ASSUME_NONNULL_BEGIN

@class NCMentionedInfo;
@class NCMentionedStringRangeInfo;
@class NCInputStateManager;

#pragma mark - Delegate Protocol

@protocol NCInputStateManagerDelegate <NSObject>

@required
/// Displays the user selector.
/// - Parameter manager The manager instance.
/// - Parameter selectedBlock The selection completion callback.
/// - Parameter cancelBlock The cancellation callback.
- (void)inputStateManager:(NCInputStateManager *)manager
         showUserSelector:(void (^)(NCChatUIUserInfo *selectedUser))selectedBlock
                   cancel:(void (^)(void))cancelBlock;

/// Gets user information for @mention restoration.
/// - Parameter manager The state manager instance.
/// - Parameter userId The user ID.
/// - Returns The user information object.
- (nullable NCChatUIUserInfo *)inputStateManager:(NCInputStateManager *)manager getUserInfoForUserId:(NSString *)userId;

@optional
/// Notifies that @mention information changed.
/// - Parameter manager The manager instance.
- (void)inputStateManagerDidUpdateMentions:(NCInputStateManager *)manager;

@end

#pragma mark - Main Interface

/// NCInputStateManager - complete input state manager.
///
/// Main responsibilities:
/// 1. Manage input state saving and restoration (stateData).
/// 2. Handle text changes and cursor management (handleTextChange).
/// 3. Provide @mention support (insertMentionedUser).
/// 4. Coordinate input-related UI interactions.
@interface NCInputStateManager : NSObject

/// Delegate object used to retrieve user information.
@property (nonatomic, weak, nullable) id<NCInputStateManagerDelegate> delegate;

/// Whether @mention functionality is enabled.
@property (nonatomic, assign) BOOL isMentionedEnabled;

/// Gets the current @mention information for sending messages.
@property (nonatomic, strong, readonly, nullable) NCMentionedInfo *mentionedInfo;

/// Gets the current @mention range information.
@property (nonatomic, strong, readonly, nullable) NSArray<NCMentionedStringRangeInfo *> *mentionedRangeInfo;

#pragma mark - Initialization

/// Initializes the input state manager.
/// - Parameter textView The associated text input view.
/// - Parameter delegate The delegate object.
- (instancetype)initWithTextView:(UITextView *)textView
                        delegate:(id<NCInputStateManagerDelegate>)delegate;

/// Handles text changes, called from UITextView's shouldChangeTextInRange.
/// - Parameter text The replacement text.
/// - Parameter range The replacement range.
/// - Returns Whether to use the default text-change handling.
- (BOOL)handleTextChange:(NSString *)text inRange:(NSRange)range;

/// Manually inserts an @mentioned user.
/// - Parameter userInfo The user information.
- (void)insertMentionedUser:(NCChatUIUserInfo *)userInfo;

/// Inserts an @mentioned user, with symbolRequest support.
/// - Parameter userInfo The user information.
/// - Parameter symbolRequest Whether to insert the @ symbol. YES inserts @ plus username; NO inserts only the username, assuming @ already exists.
- (void)insertMentionedUser:(NCChatUIUserInfo *)userInfo symbolRequest:(BOOL)symbolRequest;

/// Sets @mention information.
- (void)setupMentionedRangeInfo:(NSArray<NCMentionedStringRangeInfo *> *)mentionedRangeInfo;

/// Clears all @mention information.
- (void)clearAllMentions;

/// Checks whether the input box has text.
@property (nonatomic, assign, readonly) BOOL hasContent;

/// Clears all states.
- (void)clearAllStates;

@end

NS_ASSUME_NONNULL_END 
