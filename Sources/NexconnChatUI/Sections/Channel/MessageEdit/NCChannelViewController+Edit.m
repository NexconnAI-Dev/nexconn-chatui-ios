//
//  NCChannelViewController+Edit.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCChannelViewController+Edit.h"
#import "NCEditInputBarControl.h"
#import "NCUserListViewController.h"
#import "NCBaseNavigationController.h"
#import "NCAlertView.h"
#import "NCChatUIUtility.h"
#import "NCChatUIConfig.h"
#import "NCUserInfoCacheManager.h"
#import "NCMessageModel.h"
#import "NCChannelVCUtil.h"
#import "NCChatUICommonDefine.h"
#import "NCChannelDataSource.h"
#import "NCChannelDataSource+Edit.h"
#import "NCMessageModel+Edit.h"
#import "NCMessageSelectionUtility.h"
#import "NCMessageEditUtil.h"
#import "NCMessageSenderInfo.h"
#import "NCChatUIErrorCode.h"

static CGFloat NC_KIT_UNREAD_BOTTOM_ICON_WIDTH = 35;
static CGFloat NC_KIT_UNREAD_BOTTOM_ICON_HEIGHT = 35;

@interface NCChannelViewController ()

@property (nonatomic, strong) NCChannelDataSource *dataSource;
@property (nonatomic, assign) BOOL isConversationAppear;
@property (nonatomic, strong) NCChannelVCUtil *util;
@property (nonatomic, strong) NCMessageModel *currentSelectedModel;
// Configuration for the active edit session.
@property (nonatomic, strong) NCEditInputBarConfig *editingInputBarConfig;
// Last bottom-bar state, used to restore the keyboard when the view reappears.
@property (nonatomic, assign) KBottomBarStatus latestInputBottomBarStatus;

- (void)removeReferencingView;

- (BOOL)isRemainMessageExisted;

- (float)getSafeAreaExtraBottomHeight;

- (void)loadRemainMessageAndScrollToBottom:(BOOL)animated;

- (NCChatUIUserInfo *)getSelectingUserInfo:(NSString *)userId;

- (void)getSelectingUserIdList:(void (^)(NSArray<NSString *> *userIdList))completion
                   functionTag:(NSInteger)functionTag;

- (void)onReferenceMessageCellAndEditing:(BOOL)editing;

@end

static NCChannelIdentifier *NCEditConversationChannelIdentifier(NCChannelViewController *chatVC) {
    NSString *channelId = chatVC.channelId ?: @"";
    switch (chatVC.channelType) {
        case NCChannelTypeDirect:
            return [[NCChannelIdentifier alloc] initWithChannelType:NCChannelTypeDirect
                                                          channelId:channelId];
        case NCChannelTypeGroup:
            return [[NCChannelIdentifier alloc] initWithChannelType:NCChannelTypeGroup
                                                          channelId:channelId];
        case NCChannelTypeSystem:
            return [[NCChannelIdentifier alloc] initWithChannelType:NCChannelTypeSystem
                                                          channelId:channelId];
        default:
            return nil;
    }
}

static NCBaseChannel *NCEditConversationChannel(NCChannelViewController *chatVC) {
    NSString *channelId = chatVC.channelId ?: @"";
    switch (chatVC.channelType) {
        case NCChannelTypeDirect:
            return [[NCDirectChannel alloc] initWithChannelId:channelId];
        case NCChannelTypeGroup:
            return [[NCGroupChannel alloc] initWithChannelId:channelId];
        case NCChannelTypeSystem:
            return [[NCSystemChannel alloc] initWithChannelId:channelId];
        default:
            return nil;
    }
}

@implementation NCChannelViewController (Edit)

- (void)edit_viewWillAppear:(BOOL)animated {
    if ([self edit_isMessageEditing]) {
        if (!self.fullScreenEditView) {
            self.editInputBarControl.isVisible = YES;
        }
        return;
    }
}

- (void)edit_viewDidAppear:(BOOL)animated {
    if ([self edit_isMessageEditing]
        && !self.fullScreenEditView
        && self.latestInputBottomBarStatus == KBottomBarKeyboardStatus) {
        [self.editInputBarControl restoreFocus];
    }
}

- (void)edit_viewWillDisappear:(BOOL)animated {
    if (![self edit_isMessageEditing]) {
        return;
    }
    if (self.fullScreenEditView) {
        return;
    }
    self.latestInputBottomBarStatus = self.editInputBarControl.currentBottomBarStatus;
    self.editInputBarControl.isVisible = NO;
}

- (BOOL)edit_isMessageEditing {
    return self.editInputBarControl && self.editingInputBarConfig;
}

#pragma mark - Edit Control Management

- (void)edit_createEditBarControl {
    if (!NCChatUIConfigCenter.message.enableEditMessage) {
        return;
    }
    if (!self.editInputBarControl) {
        CGRect frame = CGRectMake(0, self.view.bounds.size.height - NC_ChatSessionInputBar_Height - [self getSafeAreaExtraBottomHeight], self.view.bounds.size.width, NC_ChatSessionInputBar_Height);
        self.editInputBarControl = [[NCEditInputBarControl alloc] initWithFrame:frame];
        self.editInputBarControl.delegate = self;
        self.editInputBarControl.dataSource = self;
        self.editInputBarControl.channelId = self.channelId;
        self.editInputBarControl.isMentionedEnabled = YES;
        self.editInputBarControl.hidden = YES;
        [self.view addSubview:self.editInputBarControl];
    }
}

- (void)edit_hideEditBottomPanels {
    [self.editInputBarControl hideBottomPanelsWithAnimation:YES completion:nil];
}

- (BOOL)edit_markEditIsExpired:(NCEditInputBarControl *)inputBar {
    if (!self.editingInputBarConfig
        || ![NCMessageEditUtil isEditTimeValid:self.editingInputBarConfig.sentTime]) {

        [inputBar markEditAsExpired];
        return YES;
    }
    return NO;
}

#pragma mark - Edit Workflow

// Handles the More action while editing.
- (BOOL)edit_updateConversationMessageCollectionView {
    if (![self edit_isMessageEditing]) {
        return NO;
    }
    // Refresh the navigation bar for the edit state.
    [self notifyUpdateUnreadMessageCount];
    
    BOOL multiSelect = [NCMessageSelectionUtility sharedManager].multiSelect;
    if (multiSelect) {
        [[NCMessageSelectionUtility sharedManager] addMessageModel:self.currentSelectedModel];
        [self.view addSubview:self.messageSelectionToolbar];
    } else {
        self.currentSelectedModel = nil;
        [self.messageSelectionToolbar removeFromSuperview];
    }
    [self.editInputBarControl hideEditInputBar:multiSelect];
    
    [self.messageCollectionView reloadData];
    [self.messageCollectionView setNeedsLayout];
    [self.messageCollectionView layoutIfNeeded];
    return YES;
}

- (BOOL)edit_onReferenceMessageCell:(id)sender {
    [self edit_exitEditModeAndRestoreNormalWithAnimation:NO activateNormal:NO completion:^{
        // Switch the regular input bar to reference mode.
        [self onReferenceMessageCellAndEditing:YES];
    }];
    return [self edit_isMessageEditing];
}

// Starts editing the selected message.
- (void)edit_onEditMessage:(id)sender {
    // Ignore repeated edit requests for the active message.
    if ([self.editingInputBarConfig.messageId isEqualToString:self.currentSelectedModel.messageId]) {
        return;
    }
    
    if (self.editingInputBarConfig) {
        [NCAlertView showAlertController:NCUILocalizedString(@"tip") message:NCUILocalizedString(@"message_editing_alert") actionTitles:nil cancelTitle:NCUILocalizedString(@"cancel") confirmTitle:NCUILocalizedString(@"confirm") preferredStyle:(UIAlertControllerStyleAlert) actionsBlock:nil cancelBlock:nil confirmBlock:^{
            self.editingInputBarConfig = nil;
            [self edit_enterEditWithModel:self.currentSelectedModel];
        } inViewController:self];
        return;
    }
    
    // Preserve the current draft before entering edit mode.
    [self.util saveDraftIfNeed];
    
    // Enter edit mode with the selected message.
    [self edit_enterEditWithModel:self.currentSelectedModel];
}

- (void)edit_syncGetReferenceMessageContent:(NCMessageModel *)model
                                 completion:(void(^)(NSString *referMsgUserName, NSString *referContent))completion {
    
    void (^safeCompletion)(NSString *, NSString *) = ^(NSString *referMsgUserName, NSString *referContent){
        if (completion) {
            completion(referMsgUserName, referContent);
        }
    };
    
    if (!model || ![model edit_hasReferenceMessage]) {
        safeCompletion(nil, nil);
        return;
    }
    
    NSString *referMsgUserName;
    NSString *referContent;
    
    NSString *referenceUserId = [model edit_referenceMessageUserId];
    if (referenceUserId) {
        NCMessageSenderInfo *senderInfo = [self edit_senderInfoForReferenceMessageModel:model];
        referMsgUserName = senderInfo.name ?: @"";
    }
    if ([model edit_referenceMessageStatus] == NCReferenceMessageStatusRecalled) {
        referContent = NCUILocalizedString(@"referenced_message_recalled");
    } else if ([model edit_referenceMessageStatus] == NCReferenceMessageStatusDeleted) {
        referContent = NCUILocalizedString(@"referenced_message_deleted");
    } else {
        NSString *referencedText = [model edit_referencedText];
        if (referencedText) {
            referContent = referencedText ?: @"";
        } else {
            NSString *content = [model edit_formattedReferencedMessageContent];
            if (content) {
                referContent = content;
            }
        }
    }
    safeCompletion(referMsgUserName, referContent);
}

- (NCMessageSenderInfo *)edit_senderInfoForReferenceMessageModel:(NCMessageModel *)model {
    if (!model || ![model edit_hasReferenceMessage]) {
        return nil;
    }
    NCReferenceMessage *referenceMessage = [model edit_referenceMessage];
    NCChatUIUserInfo *userInfo = [NCMessageSenderUserInfoResolver userInfoForChannelType:model.channelType
                                                                               channelId:model.channelId
                                                                            senderUserId:referenceMessage.referMsgSenderId
                                                                          senderUserInfo:referenceMessage.referMsg.senderUserInfo];
    return [NCMessageSenderInfo infoWithUserInfo:userInfo];
}

- (void)edit_enterEditWithModel:(NCMessageModel *)model {
    // Read the original editable message content.
    NSString *originalText = @"";
    
    __block NSString *referencedSenderName = nil;
    __block NSString *referencedContent = nil;
    NCReferenceMessageStatus referencedMsgStatus = NCReferenceMessageStatusDefault;
    
    NSString *editableText = [model edit_editableText];
    if (editableText) {
        originalText = editableText ?: @"";
    }
    if ([model edit_hasReferenceMessage]) {
        [self edit_syncGetReferenceMessageContent:model completion:^(NSString *referMsgUserName, NSString *referContent) {
            referencedSenderName = referMsgUserName;
            referencedContent = referContent;
        }];
        referencedMsgStatus = [model edit_referenceMessageStatus];
    }
    
    NCEditInputBarConfig *config = [[NCEditInputBarConfig alloc] init];
    config.messageId = model.messageId;
    config.sentTime = model.sentTime;
    config.textContent = originalText;
    config.referencedSenderName = referencedSenderName;
    config.referencedContent = referencedContent;
    config.referencedMsgStatus = referencedMsgStatus;
    NCMentionedInfo *mentionedInfo = model.content.mentionedInfo;
    config.mentionedRangeInfo = [self edit_toMentionedRangeInfo:mentionedInfo inText:originalText];
    // Populate and present the edit input bar.
    [self edit_showEditBarWithConfig:config becomeFirstResponder:YES];
}

- (void)edit_showEditBarWithConfig:(NCEditInputBarConfig *)config
              becomeFirstResponder:(BOOL)becomeFirstResponder {
    // Clear stale cached edit state when starting a new edit.
    [self edit_clearSavedEditState];
    
    // Save the input configuration only for a new edit or after leaving edit mode, so returning from full screen does not reset it.
    if (!self.editingInputBarConfig) {
        self.editingInputBarConfig = config;
    }
    
    if (!self.chatSessionInputBarControl.hidden) {
        if (self.chatSessionInputBarControl.currentBottomBarStatus != KBottomBarDefaultStatus) {
            [self.chatSessionInputBarControl updateStatus:KBottomBarDefaultStatus animated:NO];
        }
        self.chatSessionInputBarControl.hidden = YES;
    }
    if (self.referencingView) {
        [self removeReferencingView];
    }
    [self.editInputBarControl showWithConfig:config];
    [self edit_markEditIsExpired:self.editInputBarControl];
    if (becomeFirstResponder) {
        [self.editInputBarControl restoreFocus];
    }
}

- (void)edit_checkConfirmData:(NCEditInputBarControl *)editInputBarControl
                         text:(NSString *)text
                   completion:(void (^)(NCMessageModel * _Nullable message, BOOL shouldExitEditing))completion {
    
    void (^safeCompletion)(NCMessageModel * _Nullable, BOOL) = ^(NCMessageModel * _Nullable model, BOOL shouldExitEditing){
        if (completion) {
            [self performOnMainThread:^{
                completion(model, shouldExitEditing);
            }];
        }
    };
    
    NSString *trimmedText = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (trimmedText.length == 0) {
        safeCompletion(nil, NO);
        return;
    }
    if ([self edit_markEditIsExpired:editInputBarControl]) {
        safeCompletion(nil, NO);
        return;
    }
    NCGetMessageByIdParams *params = [[NCGetMessageByIdParams alloc] initWithMessageId:self.editingInputBarConfig.messageId];
    [NCBaseChannel getMessageByIdWithParams:params completion:^(NCMessage * _Nullable message, NCError * _Nullable error) {
        (void)error;
        NCMessageModel *model = message ? [NCMessageModel modelWithNCMessage:message] : nil;
        if (!model) {
            [editInputBarControl.editInputContainer resignInputViewFirstResponder];
            [self edit_showAlert:NCUILocalizedString(@"message_edit_deleted_alert") confirmBlock:^{
                safeCompletion(nil, YES);
            }];
            return;
        }
        safeCompletion(model, NO);
    }];
}

- (void)edit_didUpdateMessageWithText:(NSString *)text
                        mentionedInfo:(nullable NCMentionedInfo *)mentionedInfo
                         messageModel:(NCMessageModel *)messageModel {
    // Do not submit empty edited text.
    NSString *trimmedText = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (trimmedText.length == 0 || !messageModel) {
        return;
    }
    [self edit_editMessageModel:messageModel editContent:text mentionedInfo:mentionedInfo isRetry:NO];
}

// Update a message using a copy of its original content.
// A nil editContent is a retry and reuses the pending content stored in updateInfo.
- (void)edit_editMessageModel:(NCMessageModel *)model
                  editContent:(NSString *)editContent
                mentionedInfo:(nullable NCMentionedInfo *)mentionedInfo
                      isRetry:(BOOL)isRetry {
    if (!model || !model.content) {
        return;
    }
    NCMessageContent *oldContent = model.content;
    NCMessageContent *newContent = nil;
    if (editContent.length == 0) {
        // Retry with the saved pending content instead of the reverted UI content.
        if (model.updateInfo && model.updateInfo.content) {
            newContent = model.updateInfo.content;
        } else {
            return;
        }
    } else {
        newContent = [self edit_newContentFrom:oldContent text:editContent mentionedInfo:mentionedInfo];
    }
    if (!newContent) {
        return;
    }

    // Optimistically store the new content and updating state before reloading so layout measures the latest text.
    long long updateTimestamp = model.updateInfo ? model.updateInfo.timestamp
                                                 : (long long)([[NSDate date] timeIntervalSince1970] * 1000);
    model.updateInfo = [[NCMessageUpdateInfo alloc] initWithTimestamp:updateTimestamp
                                                             content:newContent
                                                              status:NCMessageUpdateStatusUpdating];
    model.content = newContent;
    [self.dataSource edit_refreshUIMessagesEditedStatus:@[model]];

    NCUpdateMessageParams *updateParams = [[NCUpdateMessageParams alloc] initWithMessageId:model.messageId
                                                                                    content:newContent];
    [NCBaseChannel updateMessageWithParams:updateParams completion:^(NCMessage * _Nullable updatedMessage,
                                                                    NCError * _Nullable error) {
        [self performOnMainThread:^{
            if (error) {
                [self edit_showEditErrorAlert:(NCChatUIErrorCode)error.code isRetry:isRetry];
                // On failure, including offline errors, restore the original display content and hide the edited marker.
                // Keep the pending content in updateInfo for retry.
                NCMessageUpdateInfo *info = model.updateInfo;
                long long failedTimestamp = info ? info.timestamp
                                                 : (long long)([[NSDate date] timeIntervalSince1970] * 1000);
                NCMessageContent *retryContent = info.content ?: newContent;
                model.content = oldContent;
                model.updateInfo = [[NCMessageUpdateInfo alloc] initWithTimestamp:failedTimestamp
                                                                         content:retryContent
                                                                          status:NCMessageUpdateStatusFailed];
                [self.dataSource edit_refreshUIMessagesEditedStatus:@[model]];
                return;
            }
            // On success, refresh from the server response and display the new content with the edited marker.
            if (updatedMessage) {
                NCMessageModel *updatedModel = [NCMessageModel modelWithNCMessage:updatedMessage];
                [self.dataSource edit_refreshUIMessagesEditedStatus:@[updatedModel]];
            }
        }];
    }];
}

// Copy editable content while preserving mentions, extra data, sender information, and other shared fields.
// This avoids mutating the content object currently displayed by the UI.
- (nullable NCMessageContent *)edit_newContentFrom:(NCMessageContent *)oldContent
                                              text:(NSString *)text
                                     mentionedInfo:(nullable NCMentionedInfo *)mentionedInfo {
    if ([oldContent isMemberOfClass:[NCTextMessage class]]) {
        NCTextMessage *newText = [[NCTextMessage alloc] initWithText:text];
        newText.mentionedInfo = mentionedInfo;
        newText.extra = oldContent.extra;
        newText.senderUserInfo = oldContent.senderUserInfo;
        return newText;
    }
    if ([oldContent isMemberOfClass:[NCReferenceMessage class]]) {
        NCReferenceMessage *oldRef = (NCReferenceMessage *)oldContent;
        NCReferenceMessage *newRef = [[NCReferenceMessage alloc] init];
        newRef.content = text;
        newRef.mentionedInfo = mentionedInfo;
        newRef.extra = oldRef.extra;
        newRef.senderUserInfo = oldRef.senderUserInfo;
        newRef.referMsgSenderId = oldRef.referMsgSenderId;
        newRef.referMsg = oldRef.referMsg;
        newRef.referMsgId = oldRef.referMsgId;
        newRef.referMsgStatus = oldRef.referMsgStatus;
        return newRef;
    }
    return nil;
}

- (void)edit_showAlert:(NSString *)alertMessage confirmBlock:(void (^)(void))confirmBlock {
    [NCAlertView showAlertController:NCUILocalizedString(@"tip") message:alertMessage actionTitles:nil cancelTitle:nil confirmTitle:NCUILocalizedString(@"confirm") preferredStyle:(UIAlertControllerStyleAlert) actionsBlock:nil cancelBlock:nil confirmBlock:^{
        if (confirmBlock) {
            confirmBlock();
        }
    } inViewController:self];
}

- (void)edit_showEditErrorAlert:(NCChatUIErrorCode)code isRetry:(BOOL)isRetry {
    if (code == NCChatUIErrorCodeSuccess) {
        return;
    }
    NSString *alertContent = @"";
    switch (code) {
        case NCChatUIErrorCodeOriginalMessageNotExist:
            alertContent = NCUILocalizedString(@"message_edit_not_exist");
            break;
        case NCChatUIErrorCodeDangerousContent:
        case NCChatUIErrorCodeContentReviewRejected:
            alertContent = NCUILocalizedString(@"message_edit_content_sensitive");
            break;
        case NCChatUIErrorCodeMessageOverModifyTimeFail:
        case NCChatUIErrorCodeModifiedMessageTimeout:
            alertContent = NCUILocalizedString(@"message_edit_expired_toast");
            break;
        default:
        {
            if (isRetry) {
                alertContent = NCUILocalizedString(@"message_edit_retry_failed");
            } else {
                alertContent = NCUILocalizedString(@"message_edit_failed");
            }
        }
            break;
    }
    if (alertContent.length > 0) {
        [NCAlertView showAlertController:nil message:alertContent hiddenAfterDelay:2];
    }
}

#pragma mark - Mention Handling

- (BOOL)edit_addMentionedUserToCurrentInput:(NCChatUIUserInfo *)userInfo {
    // Mention changes apply only in edit mode.
    if (![self edit_isMessageEditing]) {
        return NO;
    }
    
    if (!self.editInputBarControl.isMentionedEnabled) {
        return NO;
    }
    
    if (userInfo) {
        [self.editInputBarControl addMentionedUser:userInfo symbolRequest:YES];
        [self.editInputBarControl restoreFocus];
        return YES;
    }
    return NO;
}

- (NSArray <NCMentionedStringRangeInfo *> *)edit_toMentionedRangeInfo:(NCMentionedInfo *)mentionedInfo
                                                               inText:(NSString *)text {
    if (!mentionedInfo || mentionedInfo.userIdList.count == 0) {
        return nil;
    }
    if (!text || text.length == 0) {
        return nil;
    }
    
    NSMutableArray<NCMentionedStringRangeInfo *> *rangeInfoList = [NSMutableArray array];
    
    // Resolve all candidate user display information first.
    NSMutableDictionary *userDisplayNames = [NSMutableDictionary dictionary];
    for (NSString *userId in mentionedInfo.userIdList) {
        NCChatUIUserInfo *userInfo = [self getSelectingUserInfo:userId];
        if (userInfo) {
            userDisplayNames[userId] = userInfo.name ?: userId;
        }
    }
    
    // Scan the text for matching mention tokens.
    NSRange searchRange = NSMakeRange(0, text.length);
    
    while (searchRange.location < text.length) {
        NSRange atRange = [text rangeOfString:@"@" options:0 range:searchRange];
        if (atRange.location == NSNotFound) {
            break; // No more @ symbols.
        }
        // Match this @ position against known user names.
        for (NSString *userId in mentionedInfo.userIdList) {
            NSString *displayName = userDisplayNames[userId];
            if (!displayName) continue;
            
            NSString *pattern = [NSString stringWithFormat:@"@%@ ", displayName];
            if ([self text:text hasPrefix:pattern atIndex:atRange.location]) {
                NSRange matchRange = NSMakeRange(atRange.location, pattern.length);
                // Avoid recording the same range more than once.
                if (![self isRangeAlreadyInMatches:matchRange matches:rangeInfoList]) {
                    // Store metadata for the matched mention range.
                    NCMentionedStringRangeInfo *rangeInfo = [[NCMentionedStringRangeInfo alloc] init];
                    rangeInfo.range = matchRange;
                    rangeInfo.userId = userId;
                    rangeInfo.content = pattern;
                    [rangeInfoList addObject:rangeInfo];
                    break; // Stop after the first matching user name.
                }
            }
        }
        // Continue scanning after this character.
        searchRange.location = atRange.location + 1;
        searchRange.length = text.length - searchRange.location;
    }
    return [rangeInfoList copy];
}

#pragma mark - Referenced Message Handling

- (void)edit_refreshReferenceViewContentIfNeeded:(NSArray<NCMessageModel *> *)messageModels
                                          status:(NCReferenceMessageStatus)status {
    if (messageModels.count == 0) {
        return;
    }
    [self edit_refreshNormalInputReferenceViewIfNeeded:messageModels];
    [self edit_refreshEditInputReferenceViewIfNeeded:messageModels status:status];
}

// Updates the referenced-message preview above the regular input bar.
- (void)edit_refreshNormalInputReferenceViewIfNeeded:(NSArray<NCMessageModel *> *)messageModels {
    NSMutableDictionary<NSString *, NCMessageModel *> *messageModelDict = [NSMutableDictionary dictionary];
    for (NCMessageModel *model in messageModels) {
        if (model.messageId.length > 0) {
            messageModelDict[model.messageId] = model;
        }
    }
    if (messageModelDict.count == 0 || !self.referencingView || !self.referencingView.referModel) {
        return;
    }
    NSString *referencedMessageUId = self.referencingView.referModel.messageId;
    if (referencedMessageUId.length == 0) {
        return;
    }
    if (![messageModelDict.allKeys containsObject:referencedMessageUId]) {
        return;
    }
    NCMessageModel *model = messageModelDict[referencedMessageUId];
    if (!model) {
        return;
    }
    if (!self.currentSelectedModel) {
        self.currentSelectedModel = model;
    }
    [self performOnMainThread: ^{
        self.referencingView.referModel = model;
        self.referencingView.textLabel.text = [NCChatUIUtility formatMessage:model.content
                                                                 channelId:model.channelId
                                                         channelType:model.channelType
                                                             isAllMessage:YES];
    }];
}

// Updates the referenced-message preview above the edit input bar.
- (void)edit_refreshEditInputReferenceViewIfNeeded:(NSArray<NCMessageModel *> *)messageModels
                                            status:(NCReferenceMessageStatus)status {
    if (![self edit_isMessageEditing]) {
        return;
    }
    NSMutableDictionary<NSString *, NCMessageModel *> *messageModelDict = [NSMutableDictionary dictionary];
    for (NCMessageModel *model in messageModels) {
        if (model.messageId.length > 0) {
            messageModelDict[model.messageId] = model;
        }
    }
    if (messageModelDict.count == 0) {
        return;
    }
    NCGetMessageByIdParams *params = [[NCGetMessageByIdParams alloc] initWithMessageId:self.editingInputBarConfig.messageId];
    [NCBaseChannel getMessageByIdWithParams:params completion:^(NCMessage * _Nullable message, NCError * _Nullable error) {
        (void)error;
        NCMessageModel *messageModel = message ? [NCMessageModel modelWithNCMessage:message] : nil;
        if (![messageModel edit_hasReferenceMessage]) {
            return;
        }
        
        // Resolve the referenced message model.
        NCMessageModel *referMessageModel = messageModelDict[[messageModel edit_referenceMessageUId]];
        if (!referMessageModel) {
            return;
        }
        
        NCEditInputBarControl *editInputBarControl = [self edit_currentActiveEditInputBarControl];
        if (editInputBarControl) {
            // Replace content only for an edited message; deleted or recalled references retain their status placeholder.
            if (status == NCReferenceMessageStatusUpdated) {
                [messageModel edit_updateReferencedMessageContentFromModel:referMessageModel];
            }
            [messageModel edit_setReferenceMessageStatus:status];
            
            [self edit_syncGetReferenceMessageContent:messageModel completion:^(NSString *referMsgUserName, NSString *referContent) {
                self.editingInputBarConfig.referencedSenderName = referMsgUserName;
                self.editingInputBarConfig.referencedContent = referContent;
                
                [self performOnMainThread:^{
                    [editInputBarControl setReferenceInfo:referMsgUserName content:referContent];
                }];
            }];
            if ([messageModel edit_hasReferenceMessage]) {
                self.editingInputBarConfig.referencedMsgStatus = [messageModel edit_referenceMessageStatus];
            }
        }
    }];
}

#pragma mark - Edit State Persistence

- (void)edit_showEditingMessage:(NCEditedMessageDraft *)draft {
    if (!NCChatUIConfigCenter.message.enableEditMessage) {
        return;
    }
    if (!draft || draft.content.length == 0) {
        return;
    }
    // Do not reload cached state while an edit session is already active.
    if ([self edit_isMessageEditing]) {
        return;
    }
    NCEditInputBarConfig *editConfig = [[NCEditInputBarConfig alloc] initWithData:draft.content];
    
    void (^showBlock)(NCEditInputBarConfig *) = ^(NCEditInputBarConfig *config){
        [self performOnMainThread:^{
            [self edit_showEditBarWithConfig:editConfig becomeFirstResponder:NO];
            // Restore the keyboard bottom-bar state so viewDidAppear can reopen the keyboard.
            self.latestInputBottomBarStatus = KBottomBarKeyboardStatus;
        }];
    };
    
    // Refresh the cached referenced-message content.
    if (editConfig.messageId.length > 0
        && editConfig.referencedContent.length > 0
        && editConfig.referencedMsgStatus != NCReferenceMessageStatusDeleted
        && editConfig.referencedMsgStatus != NCReferenceMessageStatusRecalled) {
        
        NCChannelIdentifier *channelIdentifier = NCEditConversationChannelIdentifier(self);
        if (!channelIdentifier) {
            showBlock(editConfig);
            return;
        }
        NCRefreshReferenceMessageParams *params =
            [[NCRefreshReferenceMessageParams alloc] initWithChannelIdentifier:channelIdentifier
                                                                    messageIds:@[editConfig.messageId]];
        
        void (^resultsBlock)(NSArray<NCMessageResult *> *)  = ^(NSArray<NCMessageResult *> *results){
            if (results.count == 1) {
                NCMessageModel *model = results[0].message ? [NCMessageModel modelWithNCMessage:results[0].message] : nil;
                if (model) {
                    [self edit_syncGetReferenceMessageContent:model completion:^(NSString *referMsgUserName, NSString *referContent) {
                        editConfig.referencedSenderName = referMsgUserName;
                        editConfig.referencedContent = referContent;
                    }];
                    
                    if ([model edit_hasReferenceMessage]) {
                        editConfig.referencedMsgStatus = [model edit_referenceMessageStatus];
                    }
                    showBlock(editConfig);
                }
            }
        };
        
        [NCBaseChannel refreshReferenceMessageWithParams:params
                                      localMessageHandler:resultsBlock
                                     remoteMessageHandler:resultsBlock
                                            errorHandler:^(NCError * _Nullable error) {
            (void)error;
            showBlock(editConfig);
        }];
    } else {
        showBlock(editConfig);
    }
}

- (void)edit_saveCurrentEditStateIfNeeded {
    if (![self edit_isMessageEditing]) {
        return;
    }
    
    NCEditInputBarControl *editInputBar = [self edit_currentActiveEditInputBarControl];
    if (![editInputBar hasContent]) {
        return;
    }
    NCEditedMessageDraft *draft = [[NCEditedMessageDraft alloc] init];
    draft.messageId = editInputBar.inputBarConfig.messageId;
    draft.content = [editInputBar.inputBarConfig encode];

    NCBaseChannel *channel = NCEditConversationChannel(self);
    if (!channel) {
        return;
    }
    [channel saveEditedMessageDraft:draft completion:^(BOOL isSaved, NCError * _Nullable error) {
        (void)isSaved;
        (void)error;
    }];
}

- (void)edit_clearSavedEditState {
    NCBaseChannel *channel = NCEditConversationChannel(self);
    if (!channel) {
        return;
    }
    [channel clearEditedMessageDraftWithCompletion:^(BOOL isCleared, NCError * _Nullable error) {
        (void)isCleared;
        (void)error;
    }];
}

/// Exits edit mode and restores the regular input bar.
- (void)edit_exitEditModeAndRestoreNormalWithAnimation:(BOOL)animated
                                        activateNormal:(BOOL)activate
                                            completion:(void (^ _Nullable)())completion {
    if (![self edit_isMessageEditing]) {
        return;
    }
    [self performOnMainThread:^{
         [self edit_exitEditModeWithAnimation:animated completion:^{
             [self edit_restoreNormalInputWithActivate:activate completion:completion];
        }];
    }];
}

/// Exits edit mode.
- (void)edit_exitEditModeWithAnimation:(BOOL)animated completion:(void (^ _Nullable)())completion {
    [self.editInputBarControl exitWithAnimation:animated completion:^{
        self.editingInputBarConfig = nil;
        [self.editInputBarControl resetEditInputBar];
        [self edit_clearSavedEditState];
        if (completion) {
            completion();
        }
    }];
}

/// Restores the regular input bar.
- (void)edit_restoreNormalInputWithActivate:(BOOL)activate completion:(void (^ _Nullable)())completion {
    self.chatSessionInputBarControl.hidden = NO;
    // Restore the draft, including any referenced-message preview it contains.
    NCBaseChannel *channel = NCEditConversationChannel(self);
    if (!channel) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.chatSessionInputBarControl.draft = nil;
            if (activate) {
                [self.chatSessionInputBarControl.inputTextView becomeFirstResponder];
            }
            if (completion) {
                completion();
            }
        });
        return;
    }
    [channel reloadWithCompletion:^(NCBaseChannel * _Nullable latestChannel, NSError * _Nullable error) {
        (void)error;
        dispatch_async(dispatch_get_main_queue(), ^{
            NCBaseChannel *activeChannel = latestChannel ?: channel;
            self.chatSessionInputBarControl.draft = activeChannel.draft;
            if (activate) {
                [self.chatSessionInputBarControl.inputTextView becomeFirstResponder];
            }
            if (completion) {
                completion();
            }
        });
    }];
}

- (NCEditInputBarControl *)edit_currentActiveEditInputBarControl {
    // Prefer the full-screen editor because it overlays the regular edit control.
    return self.fullScreenEditView ?
    self.fullScreenEditView.editInputBarControl :
    self.editInputBarControl;
}

#pragma mark - Edit Delegates

- (void)edit_editInputBarControl:(NCEditInputBarControl *)editInputBarControl didConfirmWithText:(NSString *)text {
    if (self.editingInputBarConfig) {
        [self edit_checkConfirmData:editInputBarControl text:text completion:^(NCMessageModel *model, BOOL shouldExitEditing) {
            if (model) {
                [self edit_didUpdateMessageWithText:text mentionedInfo:editInputBarControl.mentionedInfo messageModel:model];
                // Exit edit mode after confirmation.
                [self edit_exitEditModeAndRestoreNormalWithAnimation:YES activateNormal:YES completion:nil];
            } else if (shouldExitEditing) {
                [self edit_exitEditModeAndRestoreNormalWithAnimation:YES activateNormal:YES completion:nil];
            }
        }];
    }
}

- (void)edit_editInputBarControlDidCancel:(NCEditInputBarControl *)editInputBarControl {
    [self edit_exitEditModeAndRestoreNormalWithAnimation:YES activateNormal:YES completion:nil];
}

- (void)edit_editInputBarControl:(NCEditInputBarControl *)editInputBarControl shouldChangeFrame:(CGRect)frame {
    if (![self edit_isMessageEditing]) {
        return;
    }
    // Subtract the multi-select toolbar height because it hides the edit input bar.
    BOOL multiSelect = [NCMessageSelectionUtility sharedManager].multiSelect;
    CGFloat extraHeight = multiSelect ? self.messageSelectionToolbar.bounds.size.height : 0;
    
    CGRect collectionViewRect = self.messageCollectionView.frame;
    collectionViewRect.size.height = CGRectGetMinY(frame) - collectionViewRect.origin.y - extraHeight;
    [self.messageCollectionView setFrame:collectionViewRect];
    
    CGFloat width = NC_KIT_UNREAD_BOTTOM_ICON_WIDTH;
    CGFloat height = NC_KIT_UNREAD_BOTTOM_ICON_HEIGHT;
    CGFloat rightOrLeftPadding = 5.5;
    CGFloat bottom = 12;
    CGFloat editInputBarControlY = editInputBarControl.frame.origin.y;
    CGFloat x = self.view.frame.size.width - rightOrLeftPadding - width;
    CGFloat y = editInputBarControlY - bottom - height;
    
    if ([NCChatUIUtility isRTL]) {
        x = rightOrLeftPadding;
    }
    [self.unreadRightBottomIcon setFrame:CGRectMake(x, y, width, height)];
    
    if (self.locatedMessageSentTime == 0) {
        // Do not scroll to the bottom before viewWillAppear/viewDidLoad when a message location is forced.
        if (self.dataSource.isLoadingHistoryMessage || [self isRemainMessageExisted]) {
            [self loadRemainMessageAndScrollToBottom:YES];
        } else if (self.isConversationAppear) {
            [self scrollToBottomAnimated:NO];
        }
    }
}

- (void)edit_editInputBarControl:(NCEditInputBarControl *)editInputBarControl
           showUserSelector:(void (^)(NCChatUIUserInfo *selectedUser))selectedBlock
                     cancel:(void (^)(void))cancelBlock {
    void (^restoreFocus)(void) = ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [editInputBarControl restoreFocus];
        });
    };
    // Wrap the callback so focus returns after user selection.
    void (^wrappedCompletion)(NCChatUIUserInfo *) = ^(NCChatUIUserInfo *selectedUser) {
        if (selectedBlock) {
            selectedBlock(selectedUser);
        }
        restoreFocus();
    };
    
    void (^wrappedCancelBlock)(void) = ^{
        if (cancelBlock) {
            cancelBlock();
        }
        restoreFocus();
    };
    
    if ([self respondsToSelector:@selector(showChooseUserViewController:cancel:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showChooseUserViewController:wrappedCompletion cancel:wrappedCancelBlock];
        });
    }
}

- (nullable NCChatUIUserInfo *)edit_editInputBarControl:(NCEditInputBarControl *)editInputBarControl getUserInfo:(NSString *)userId {
    // Reuse the regular chat input bar's user lookup path.
    return [self getSelectingUserInfo:userId];
}

- (void)edit_editInputBarControlRequestFullScreenEdit:(NCEditInputBarControl *)editInputBarControl {
    // Save the current cursor location.
    NSRange currentCursorPosition = [editInputBarControl getCurrentCursorPosition];
    
    [editInputBarControl hideBottomPanelsWithAnimation:YES completion:^{
        // Hide the regular edit control while full-screen editing is active.
        editInputBarControl.isVisible = NO;
        
        [self edit_setupFullScreenEditView];
        
        if (self.navigationController) {
            [self.navigationController.view addSubview:self.fullScreenEditView];
        } else {
            // Fall back to the key window when no navigation controller is available.
            UIWindow *keyWindow = [self edit_keyWindow];
            [keyWindow addSubview:self.fullScreenEditView];
        }
        
        [self.fullScreenEditView showWithConfig:editInputBarControl.inputBarConfig animation:YES];
        
        // Restore the cursor in the full-screen editor.
        if (currentCursorPosition.location != NSNotFound) {
            [self.fullScreenEditView.editInputBarControl setCursorPosition:currentCursorPosition];
        }
        
        [self edit_markEditIsExpired:self.fullScreenEditView.editInputBarControl];
    }];
}

#pragma mark - Full-Screen Editing

- (void)edit_fullScreenEditViewCollapse:(NCFullScreenEditView *)fullScreenEditView {
    // Save the full-screen editor cursor location.
    NSRange currentCursorPosition = [fullScreenEditView.editInputBarControl getCurrentCursorPosition];
    
    // Capture the full-screen edit state.
    NCEditInputBarConfig *config = fullScreenEditView.editInputBarControl.inputBarConfig;
    
    // Restore the regular edit mode.
    [self edit_showEditBarWithConfig:config becomeFirstResponder:NO];
    
    [self edit_exitFullScreenEditView:^{
        // Restore the cursor in the regular editor.
        if (currentCursorPosition.location != NSNotFound) {
            [self.editInputBarControl setCursorPosition:currentCursorPosition];
        }
        
        // Restore focus asynchronously after the regular editor state is applied.
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.editInputBarControl restoreFocus];
        });
    }];
}

- (void)edit_fullScreenEditViewCancel:(NCFullScreenEditView *)fullScreenEditView {
    [self edit_exitFullScreenEditView:^{
        // Exit the regular edit mode.
        [self edit_exitEditModeAndRestoreNormalWithAnimation:YES activateNormal:YES completion:nil];
    }];
}

- (void)edit_fullScreenEditView:(NCFullScreenEditView *)fullScreenEditView
               showUserSelector:(void (^)(NCChatUIUserInfo * _Nonnull))selectedBlock
                         cancel:(void (^)(void))cancelBlock {
    [self edit_editInputBarControl:fullScreenEditView.editInputBarControl showUserSelector:selectedBlock cancel:cancelBlock];
}

- (void)edit_fullScreenEditView:(NCFullScreenEditView *)fullScreenEditView didConfirmWithText:(NSString *)text {
    [self edit_checkConfirmData:fullScreenEditView.editInputBarControl text:text completion:^(NCMessageModel *model, BOOL shouldExitEditing) {
        if (model) {
            [self edit_exitFullScreenEditView:^{
                [self edit_didUpdateMessageWithText:text
                                      mentionedInfo:fullScreenEditView.editInputBarControl.mentionedInfo
                                       messageModel:model];
                [self edit_exitEditModeAndRestoreNormalWithAnimation:YES activateNormal:YES completion:nil];
            }];
        } else if (shouldExitEditing) {
            [self edit_exitFullScreenEditView:^{
                [self edit_exitEditModeAndRestoreNormalWithAnimation:YES activateNormal:YES completion:nil];
            }];
        }
    }];
    
}

- (void)edit_exitFullScreenEditView:(void(^)(void))completion {
    [self.fullScreenEditView hideWithAnimation:YES completion:^{
        if (completion) {
            completion();
        }
        self.fullScreenEditView = nil;
    }];
}

- (void)edit_didTapEditRetryButton:(NCMessageModel *)model {
    if (!model) {
        return;
    }
    if (!model.updateInfo || !model.updateInfo.content) {
        return;
    }
    // Retry through the shared update entry; nil editContent reuses the pending content in updateInfo.
    [self edit_editMessageModel:model editContent:@"" mentionedInfo:nil isRetry:YES];
}

- (void)edit_setupFullScreenEditView {
    if (!self.fullScreenEditView) {
        self.fullScreenEditView = [[NCFullScreenEditView alloc] initWithFrame:self.view.bounds];
        self.fullScreenEditView.channelId = self.channelId;
        self.fullScreenEditView.delegate = self;
        self.fullScreenEditView.isMentionedEnabled = self.dataSource.isMentionedEnabled;
    }
}

- (UIWindow *)edit_keyWindow {
    if (@available(iOS 13.0, *)) {
        NSSet<UIScene *> *connectedScenes = [UIApplication sharedApplication].connectedScenes;
        for (UIScene *scene in connectedScenes) {
            if ([scene isKindOfClass:[UIWindowScene class]]) {
                UIWindowScene *windowScene = (UIWindowScene *)scene;
                for (UIWindow *window in windowScene.windows) {
                    if (window.isKeyWindow) {
                        return window;
                    }
                }
            }
        }
    }
    return [UIApplication sharedApplication].keyWindow;
}

// Executes a block on the main thread.
- (void)performOnMainThread:(dispatch_block_t)block {
    if (!block) {
        return;
    }
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

/// Checks whether text starts with a prefix at a specific index.
/// @param text The source text.
/// @param prefix The prefix to match.
/// @param index The starting index.
/// @return YES when the prefix matches; otherwise NO.
- (BOOL)text:(NSString *)text hasPrefix:(NSString *)prefix atIndex:(NSInteger)index {
    if (!text || !prefix || index < 0 || index >= text.length) {
        return NO;
    }
    
    NSInteger remainingLength = text.length - index;
    if (remainingLength < prefix.length) {
        return NO; // The remaining text is shorter than the prefix.
    }
    
    NSRange checkRange = NSMakeRange(index, prefix.length);
    NSString *substring = [text substringWithRange:checkRange];
    return [substring isEqualToString:prefix];
}

/// Checks whether a range is already present in the match list.
/// @param range The range to find.
/// @param matches The existing matches.
/// @return YES when the range is already present; otherwise NO.
- (BOOL)isRangeAlreadyInMatches:(NSRange)range matches:(NSArray<NCMentionedStringRangeInfo *> *)matches {
    for (NCMentionedStringRangeInfo *match in matches) {
        if (NSEqualRanges(range, match.range)) {
            return YES;
        }
    }
    return NO;
}

@end
