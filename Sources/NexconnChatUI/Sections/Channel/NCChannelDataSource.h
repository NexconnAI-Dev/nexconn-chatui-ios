//
//  NCChannelDataSource.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol NCMessagesLoadProtocol <NSObject>
- (void)noMoreMessageToFetch;
@end

@class NCChannelViewController, NCMessageModel, NCChannelViewLayout, NCMessageResult, NCMessage,
    NCBaseChannel;

@interface NCChannelDataSource : NSObject

@property (nonatomic, weak) id<NCMessagesLoadProtocol> loadDelegate;
- (instancetype)init:(NCChannelViewController *)chatVC;
// Whether all messages have finished loading.
@property (nonatomic, assign, readonly) BOOL allMessagesAreLoaded;
// The collection layout.
@property (nonatomic, strong, readonly) NCChannelViewLayout *customFlowLayout;
// The message ID used for showing unread messages.
@property (nonatomic, assign, readonly) long long showUnreadViewMessageId;
// YES while the channel page is showing the loading indicator for more messages; reset to NO when
// loading completes to avoid repeated fast loads.
@property (nonatomic, assign, readonly) BOOL isIndicatorLoading;
// Whether historical messages are being loaded.
@property (nonatomic, assign, readonly) BOOL isLoadingHistoryMessage;
// Tracks the lower-right unread count while staying on the current page.
@property (nonatomic, strong) NSMutableArray *unreadNewMsgArr;

@property (nonatomic, strong) NSMutableArray *unreadMentionedMessages;

@property (nonatomic, strong) NSMutableArray *cachedReloadMessages;

@property (nonatomic, assign, readonly) BOOL isMentionedEnabled;

// Loads the initial messages when entering the channel page.
- (void)getInitialMessage:(NCBaseChannel *)channel;

- (void)loadLatestHistoryMessage;

// Loads more historical messages when the channel page scrolls to the top.
- (void)loadMoreHistoryMessageIfNeed;
// Sets whether the message should display the user name.
- (NCMessageModel *)setModelIsDisplayNickName:(NCMessageModel *)model;
// Adds an outgoing message to the data source.
- (void)appendSendOutMessage:(NCMessage *)message;

- (void)appendAndDisplayMessage:(NCMessage *)message;
// Deletes a message for everyone.
- (void)didDeleteMessageForAll:(NCMessage *)deletedMessage;
// Refreshes the UI for a message deleted for everyone.
- (void)didReloadDeletedMessageForAllWithClientId:(long)deletedMessageClientId;

// Loads more historical messages while scrolling the channel page.
- (void)scrollToLoadMoreHistoryMessage;
// Loads more newer messages while scrolling the channel page.
- (void)scrollToLoadMoreNewerMessage;
// Scrolls the channel page to the suitable position, such as the first unread mentioned message or
// a message at the user-specified time.
- (void)scrollToSuitablePosition;
// Cancels all queued data-source message append operations when the channel page disappears.
- (void)cancelAppendMessageQueue;
// Handles tapping the lower-right unread message count button.
- (void)tapRightBottomMsgCountIcon:(UIGestureRecognizer *)gesture;
// Handles tapping the upper-right unread message count button.
- (void)tapRightTopMsgUnreadButton;
- (void)tapRightTopUnReadMentionedButton:(UIButton *)sender;

- (void)setupUnReadMentionedButton;

- (void)removeMentionedMessage:(long)curMessageId;

- (void)scrollDidEnd;
#pragma mark - Notification
// Handles messages received by the channel page.

- (BOOL)isAtTheBottomOfTableView;
@end
