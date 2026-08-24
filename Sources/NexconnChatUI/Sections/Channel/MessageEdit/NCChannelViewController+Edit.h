//
//  NCChannelViewController+Edit.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCChannelViewController.h"
#import "NCChatUIUserInfo.h"
#import <NexconnChatSDK/NexconnChatSDK.h>

@class NCEditInputBarControl;

NS_ASSUME_NONNULL_BEGIN

/// Editing extension for NCChannelViewController.
/// Contains all methods related to message editing.
@interface NCChannelViewController (Edit)

- (void)edit_viewWillAppear:(BOOL)animated;

- (void)edit_viewDidAppear:(BOOL)animated;

- (void)edit_viewWillDisappear:(BOOL)animated;

/// Whether the controller is currently in editing mode.
- (BOOL)edit_isMessageEditing;

#pragma mark - Edit Control Management

/// Creates the edit control.
- (void)edit_createEditBarControl;

/// Hides the edit input panel.
- (void)edit_hideEditBottomPanels;

#pragma mark - Edit Logic

- (BOOL)edit_updateConversationMessageCollectionView;

/// Handles tapping a reference message from the long-press menu.
/// - Returns Whether the original event should be intercepted.
- (BOOL)edit_onReferenceMessageCell:(id)sender;

/// Starts editing a message from a menu action.
/// - Parameter sender The menu item.
- (void)edit_onEditMessage:(id)sender;

/// Adds an @mentioned user in editing mode, triggered by long-pressing an avatar.
/// - Parameter userId The user ID.
/// - Returns Whether handling succeeded. YES means editing mode handled it; NO means normal mode
/// should handle it.
- (BOOL)edit_addMentionedUserToCurrentInput:(NCChatUIUserInfo *)userInfo;

/// Refreshes the referenced message display in input bars, including normal and edit input bars.
/// This method checks whether the message UId list contains the currently referenced message and
/// updates only when matched. When status is recalled or deleted, pass the corresponding messages.
/// When status is edited, pass the changed message list in messageModels. The implementation checks
/// whether it contains the reference message currently shown in the input bar.
/// - Parameter messageModels The changed message list.
/// - Parameter status                 The referenced message status, such as edited, recalled, or
/// deleted.
- (void)edit_refreshReferenceViewContentIfNeeded:(NSArray<NCMessageModel *> *)messageModels
                                          status:(NCReferenceMessageStatus)status;

/// Refreshes the referenced message display in the edit input bar.
/// This method checks whether the message UId list contains the currently referenced message and
/// updates only when matched. When status is recalled or deleted, pass the corresponding messages.
/// When status is edited, pass the changed message list in messageModels. The implementation checks
/// whether it contains the reference message currently shown in the input bar.
/// - Parameter messageModels The changed message list.
/// - Parameter status                 The referenced message status, such as edited, recalled, or
/// deleted.
- (void)edit_refreshEditInputReferenceViewIfNeeded:(NSArray<NCMessageModel *> *)messageModels
                                            status:(NCReferenceMessageStatus)status;

#pragma mark - Edit State Save and Restore

/// Saves the current edit state if needed.
- (void)edit_saveCurrentEditStateIfNeeded;

/// Shows the editing message.
- (void)edit_showEditingMessage:(NCEditedMessageDraft *)draft;

/// Clears the saved edit state.
- (void)edit_clearSavedEditState;

#pragma mark - Edit Delegate Implementation Methods

/// Handles edit confirmation.
/// - Parameter editInputBarControl The edit control.
/// - Parameter text The edited text.
- (void)edit_editInputBarControl:(NCEditInputBarControl *)editInputBarControl
              didConfirmWithText:(NSString *)text;

/// Handles edit cancellation.
/// - Parameter editInputBarControl The edit control.
- (void)edit_editInputBarControlDidCancel:(NCEditInputBarControl *)editInputBarControl;

/// Handles edit control frame changes.
/// - Parameter editInputBarControl The edit control.
/// - Parameter frame The new frame.
- (void)edit_editInputBarControl:(NCEditInputBarControl *)editInputBarControl
               shouldChangeFrame:(CGRect)frame;

/// Handles displaying the user selector.
/// - Parameter editInputBarControl The edit control.
/// - Parameter selectedBlock The selection completion callback.
/// - Parameter cancelBlock The cancellation callback.
- (void)edit_editInputBarControl:(NCEditInputBarControl *)editInputBarControl
                showUserSelector:(void (^)(NCChatUIUserInfo *selectedUser))selectedBlock
                          cancel:(void (^)(void))cancelBlock;

/// Handles retrieving user information.
/// - Parameter editInputBarControl The edit control.
/// - Parameter userId The user ID.
/// - Returns User information.
- (nullable NCChatUIUserInfo *)edit_editInputBarControl:(NCEditInputBarControl *)editInputBarControl
                                            getUserInfo:(NSString *)userId;

/// Handles a full-screen edit request.
/// - Parameter editInputBarControl The edit control.
- (void)edit_editInputBarControlRequestFullScreenEdit:(NCEditInputBarControl *)editInputBarControl;

/// Handles tapping Cancel in full-screen editing.
- (void)edit_fullScreenEditViewCancel:(NCFullScreenEditView *)fullScreenEditView;

/// Handles tapping the collapse button in full-screen editing.
- (void)edit_fullScreenEditViewCollapse:(NCFullScreenEditView *)fullScreenEditView;

/// Handles selecting an @contact in full-screen editing.
- (void)edit_fullScreenEditView:(NCFullScreenEditView *)fullScreenEditView
               showUserSelector:(void (^)(NCChatUIUserInfo *selectedUser))selectedBlock
                         cancel:(void (^)(void))cancelBlock;
/// Handles tapping Confirm in full-screen editing.
- (void)edit_fullScreenEditView:(NCFullScreenEditView *)fullScreenEditView
             didConfirmWithText:(NSString *)text;

/// Handles tapping the retry button after editing fails.
- (void)edit_didTapEditRetryButton:(NCMessageModel *)model;

@end

NS_ASSUME_NONNULL_END
