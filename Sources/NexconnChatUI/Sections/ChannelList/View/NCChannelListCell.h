//
//  NCChannelListCell.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCChannelListBaseCell.h"
#import "NCChannelListDetailContentView.h"
#import "NCChannelListStatusView.h"
#import "NCChatUIThemeDefine.h"
#import "NCMessageBubbleTipView.h"
#import "NCOnlineStatusView.h"
#import <UIKit/UIKit.h>

#define CONVERSATION_ITEM_HEIGHT 65.0f
@protocol NCChannelListCellDelegate;
@class NCImageView;

/// Channel cell class.
@interface NCChannelListCell : NCChannelListBaseCell

/// Tap delegate for the channel cell.
@property (nonatomic, weak) id<NCChannelListCellDelegate> delegate;

/// Background view for the cell avatar.
@property (nonatomic, strong) UIView *headerImageViewBackgroundView;

/// Cell avatar view.
@property (nonatomic, strong) NCImageView *headerImageView;

/// Channel title.
@property (nonatomic, strong) UILabel *conversationTitle;

/// Tag view to the right of the channel title.
@property (nonatomic, strong) UIView *conversationTagView;

/// Online status indicator (dot displayed before the conversationTitle).
/// Green when online, gray when offline.
@property (nonatomic, strong) NCOnlineStatusView *onlineStatusView;

/// Label displaying the last message content.
@property (nonatomic, strong) UILabel *messageContentLabel;

/// Label displaying the last message send time.
@property (nonatomic, strong) UILabel *messageCreatedTimeLabel;

/// Unread message badge view in the top-right corner of the avatar.
@property (nonatomic, strong) NCMessageBubbleTipView *bubbleTipView;

/// View showing channel do-not-disturb status.
@property (nonatomic, strong) NCBaseImageView *conversationStatusImageView;

/// Avatar shape displayed in the cell.
///
/// Default is the global setting (globalConversationAvatarStyle).
@property (nonatomic, assign) NCUserAvatarStyle portraitStyle;

/// Whether new message notifications are enabled.
///
/// This property is set based on the channel's notification configuration by default.
@property (nonatomic, assign) BOOL enableNotification;

/// Whether to show unread count number in the bubbleTipView when there are unread messages.
///
/// Default is YES.
/// You can configure this in the willDisplayConversationTableCell:atIndexPath: callback of
/// NCChannelListViewController.
@property (nonatomic, assign) BOOL isShowNotificationNumber;

/// Whether to hide the sender name in group channel cells.
@property (nonatomic, assign) BOOL hideSenderName;

/// Background color for non-pinned cells.
@property (nonatomic, strong) UIColor *cellBackgroundColor;

/// Background color for pinned cells.
@property (nonatomic, strong) UIColor *topCellBackgroundColor;

/// View displaying the detail content area.
@property (nonatomic, strong) NCChannelListDetailContentView *detailContentView;

/// View displaying the channel status.
@property (nonatomic, strong) NCChannelListStatusView *statusView;

/// Set the avatar shape for this cell.
///
/// @param portraitStyle The avatar shape.
///
/// This setting only applies to the current channel cell.
- (void)setHeaderImagePortraitStyle:(NCUserAvatarStyle)portraitStyle;

/// Set the data model for the current channel cell.
///
/// @param model The channel cell data model.
- (void)setDataModel:(NCChannelModel *)model;

/// Update the online status indicator.
///
/// @param isOnline Whether the user is online.
///
/// Shows or hides the online status indicator based on the status.
/// Only displayed for direct chat channels.
- (void)updateOnlineStatus:(BOOL)isOnline;

@end

/// Tap delegate for the channel cell.
@protocol NCChannelListCellDelegate <NSObject>

/// Callback when the cell avatar is tapped.
///
/// @param model The channel cell data model.
- (void)didTapCellPortrait:(NCChannelModel *)model;

/// Callback when the cell avatar is long-pressed.
///
/// @param model The channel cell data model.
- (void)didLongPressCellPortrait:(NCChannelModel *)model;

/// Callback when the cell has been updated due to a notification.
- (void)didUpdateCell:(NCChannelListCell *)cell model:(NCChannelModel *)model;

@end
