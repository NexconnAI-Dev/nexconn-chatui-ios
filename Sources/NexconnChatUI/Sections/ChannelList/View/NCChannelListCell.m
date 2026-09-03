//
//  NCChannelListCell.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCChannelListCell.h"
#import "NCChannelListCellUpdateInfo.h"
#import "NCChannelListHeaderView.h"
#import "NCChannelModel+Display.h"
#import "NCChatUI.h"
#import "NCChatUICommonDefine.h"
#import "NCChatUIConfig.h"
#import "NCChatUIUtility.h"
#import "NCInfoUpdateCenter.h"
#import "NCOnlineStatusView.h"
#import "NCSemanticContext.h"
#import "NCUserOnlineStatusUtil.h"
#import <NexconnChatSDK/NexconnChatSDK.h>

@interface NCChannelListCell () <NCInfoUpdateDelegate>

@property (nonatomic, strong) NCChannelListHeaderView *headerView;
// Throttle repeated updates for the same user.
@property (nonatomic, copy) NSString *displayedUserIdentityKey;

// Stack view containing the presence indicator and title so hidden-state layout updates
// automatically.
@property (nonatomic, strong) UIStackView *titleStackView;

@end

@implementation NCChannelListCell

#pragma mark - Initialization
- (instancetype)initWithStyle:(UITableViewCellStyle)style
              reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self initCellLayout];
        [self registerObserver];
    }
    return self;
}

- (void)initCellLayout {
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.selectedBackgroundView = [[UIView alloc] initWithFrame:self.frame];
    self.selectedBackgroundView.backgroundColor = NCDynamicColor(@"highlight_color");

    [self.contentView addSubview:self.headerView];
    [self.contentView
        addSubview:self.titleStackView]; // Group the presence indicator and title in a stack view.
    [self.contentView addSubview:self.conversationTagView];
    [self.contentView addSubview:self.messageCreatedTimeLabel];
    [self.contentView addSubview:self.detailContentView];
    [self.contentView addSubview:self.statusView];
    self.statusView.conversationNotificationStatusView.hidden = YES;
    [self addSubViewConstraints];
}

- (void)registerObserver {
    [NCInfoUpdateCenter addInfoUpdateDelegate:self];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateCellIfNeed:)
                                                 name:NCChatUIChannelListCellUpdateNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter]
        addObserver:self
           selector:@selector(onUserOnlineStatusChanged:)
               name:NCChatUIConversationCellOnlineStatusUpdateNotification
             object:nil];
}

- (void)dealloc {
    [NCInfoUpdateCenter removeInfoUpdateDelegate:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)addSubViewConstraints {
    [self.titleStackView setContentCompressionResistancePriority:UILayoutPriorityRequired
                                                         forAxis:UILayoutConstraintAxisHorizontal];
    [self.titleStackView setContentHuggingPriority:UILayoutPriorityRequired
                                           forAxis:UILayoutConstraintAxisHorizontal];

    [self.conversationTitle
        setContentCompressionResistancePriority:UILayoutPriorityDefaultLow
                                        forAxis:UILayoutConstraintAxisHorizontal];
    [self.conversationTitle setContentHuggingPriority:UILayoutPriorityRequired
                                              forAxis:UILayoutConstraintAxisHorizontal];

    [self.messageCreatedTimeLabel
        setContentCompressionResistancePriority:UILayoutPriorityRequired
                                        forAxis:UILayoutConstraintAxisHorizontal];

    // Fix the department label overlapping the timestamp.
    NSDictionary *cellSubViews =
        NSDictionaryOfVariableBindings(_headerView, _titleStackView, _messageCreatedTimeLabel,
                                       _detailContentView, _statusView, _conversationTagView);

    // Horizontal layout: avatar - stack view (presence + title) - tag - time.
    // The stack view removes the hidden presence indicator from layout.
    [self.contentView
        addConstraints:
            [NSLayoutConstraint
                constraintsWithVisualFormat:@"H:|-12-[_headerView(width)]-12-"
                                            @"[_titleStackView]-5-[_conversationTagView(50)]-5-"
                                            @"[_messageCreatedTimeLabel]-12-|"
                                    options:0
                                    metrics:@{
                                        @"width" : @(NCChatUIConfigCenter.ui
                                                         .globalConversationPortraitSize.width)
                                    }
                                      views:cellSubViews]];

    [NSLayoutConstraint activateConstraints:@[
        // Avatar height.
        [self.headerView.heightAnchor
            constraintEqualToConstant:NCChatUIConfigCenter.ui.globalConversationPortraitSize
                                          .height],

        // Stack view height, matching the title height.
        [self.titleStackView.heightAnchor constraintEqualToConstant:21],

        // Tag height.
        [self.conversationTagView.heightAnchor constraintEqualToConstant:21],

        // Time label position.
        [self.messageCreatedTimeLabel.topAnchor constraintEqualToAnchor:self.contentView.topAnchor
                                                               constant:16],

        [self.detailContentView.leadingAnchor constraintEqualToAnchor:self.headerView.trailingAnchor
                                                             constant:12],
        [self.detailContentView.trailingAnchor constraintEqualToAnchor:self.statusView.leadingAnchor
                                                              constant:-8],
        // Keep detailContentView at height 16 to match its messageContentLabel.
        [self.detailContentView.heightAnchor constraintEqualToConstant:16],

        [self.statusView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor
                                                       constant:-5],
        [self.statusView.widthAnchor constraintEqualToConstant:55],
        [self.statusView.centerYAnchor
            constraintEqualToAnchor:self.detailContentView.centerYAnchor],

        // Center the tag vertically in the stack view.
        [self.conversationTagView.centerYAnchor
            constraintEqualToAnchor:self.titleStackView.centerYAnchor],

        // Align the avatar bottom with the detail content.
        [self.detailContentView.bottomAnchor constraintEqualToAnchor:self.headerView.bottomAnchor],

        // Align the stack view top with the time label.
        [self.titleStackView.topAnchor
            constraintEqualToAnchor:self.messageCreatedTimeLabel.topAnchor],

        // Center the avatar vertically.
        [self.headerView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
    ]];

    [self setNeedsUpdateConstraints];
}

#pragma mark - Model Handling and Display
- (void)setDataModel:(NCChannelModel *)model {
    [self resetDefaultLayout:model];
    [super setDataModel:model];
    self.backgroundColor =
        self.model.isTop ? self.topCellBackgroundColor : self.cellBackgroundColor;

    if (model.conversationModelType == NC_CONVERSATION_MODEL_TYPE_NORMAL) {
        [self p_displayNormal:model];
    }

    [self.headerView updateBubbleUnreadNumber:(int)model.unreadMessageCount];
    if (model.sentTime > 0) {
        self.messageCreatedTimeLabel.text =
            [NCChatUIUtility convertConversationTime:model.sentTime / 1000];
    } else if (model.operationTime > 0) {
        self.messageCreatedTimeLabel.text =
            [NCChatUIUtility convertConversationTime:model.operationTime / 1000];
    }
    [self.statusView updateReadStatus:model];
    [self.statusView updateNotificationStatus:model];

    // Update the presence indicator.
    [self updateOnlineStatusDisplay];
}

- (void)p_displaySimaple:(NCChannelModel *)model {
    NSString *title = [model conversationDisplayName];
    NSString *imageUrl = [model conversationPortraitUri];
    if (imageUrl) {
        self.headerView.headerImageView.imageURL = [NSURL URLWithString:imageUrl];
    }
    [self updateConversationTitle:title];
    [self.detailContentView updateContent:model prefixName:nil];
}

- (void)p_displayGroup:(NCChannelModel *)model {
    NSString *title = [model conversationDisplayName];
    NSString *imageUrl = [model conversationPortraitUri];
    if (imageUrl) {
        self.headerView.headerImageView.imageURL = [NSURL URLWithString:imageUrl];
    }
    [self updateConversationTitle:title];

    if (self.hideSenderName) {
        [self.detailContentView updateContent:model prefixName:nil];
        return;
    }
    if ([self updateMessagePrefixNameWithSenderUser]) {
        return;
    }
    [self.detailContentView updateContent:model prefixName:[model senderDisplayNameInGroup]];
}

- (void)p_displayNormal:(NCChannelModel *)model {
    BOOL isSimpleConversation =
        [model isChannelType:NCChannelTypeDirect] || [model isChannelType:NCChannelTypeSystem];
    if (isSimpleConversation) {
        [self p_displaySimaple:model];
        return;
    } else if ([model isChannelType:NCChannelTypeGroup]) {
        [self p_displayGroup:model];
        return;
    }
    [self.detailContentView updateContent:model prefixName:nil];
    [self updateConversationTitle:model.channelId];
}

- (void)resetDefaultLayout:(NCChannelModel *)reuseModel {
    _hideSenderName = [self hideSenderNameForDefault:reuseModel];
    self.topCellBackgroundColor = reuseModel.topCellBackgroundColor;
    self.cellBackgroundColor = reuseModel.cellBackgroundColor;

    [self.headerView resetDefaultLayout:reuseModel];
    self.conversationTitle.text = nil;
    self.messageCreatedTimeLabel.text = nil;
    [self.detailContentView resetDefaultLayout:reuseModel];
    [self.statusView resetDefaultLayout:reuseModel];
    for (UIView *view in [self.conversationTagView subviews]) {
        [view removeFromSuperview];
    }

    // Reset the presence dot. It is hidden by default and occupies no stack-view space.
    self.onlineStatusView.hidden = YES;
    self.onlineStatusView.backgroundColor = nil;
}

- (void)updateConversationTitle:(NSString *)text {
    text = (text.length > 0) ? text : self.model.channelId;
    self.model.conversationTitle = text;
    self.conversationTitle.text = self.model.conversationTitle;
}

- (void)updateOnlineStatus:(BOOL)isOnline {
    if (!self.model.displayOnlineStatus) {
        self.onlineStatusView.hidden = YES;
        return;
    }
    // Show the presence dot using the color for the current status.
    self.onlineStatusView.hidden = NO;
    self.onlineStatusView.online = isOnline;
}

- (void)updateOnlineStatusDisplay {
    NCSubscribeUserOnlineStatus *onlineStatus = self.model.onlineStatus;
    if (!onlineStatus) {
        // Unknown/unloaded status must not be shown as offline.
        self.onlineStatusView.hidden = YES;
        return;
    }
    [self updateOnlineStatus:onlineStatus.isOnline];
}

- (BOOL)hideSenderNameForDefault:(NCChannelModel *)model {
    if ([NCChatUIUtility isUnkownMessage:model.latestMessageClientId content:model.latestMessage] &&
        NCChatUIConfigCenter.message.showUnkownMessage) {
        return YES;
    }
    return NO;
}

- (void)setHideSenderName:(BOOL)hideSenderName {
    if (hideSenderName == _hideSenderName) {
        return;
    }
    _hideSenderName = hideSenderName;

    if (_hideSenderName) {
        [self.detailContentView updateContent:self.model prefixName:nil];
    } else if ([self.model isChannelType:NCChannelTypeGroup]) {
        if ([self updateMessagePrefixNameWithSenderUser]) {
            return;
        }
        [self.detailContentView updateContent:self.model
                                   prefixName:[self.model senderDisplayNameInGroup]];
    }
}

#pragma mark - Notification selector
- (void)onUserInfoUpdate:(NCChatUIUserInfo *)userInfo {
    NSString *updateUserId = userInfo.userId;
    NSString *identityKey = [self userIdentityKeyFromUserInfo:userInfo];
    if ([identityKey isEqualToString:self.displayedUserIdentityKey]) {
        return;
    }
    self.displayedUserIdentityKey = identityKey;

    if (self.model.conversationModelType == NC_CONVERSATION_MODEL_TYPE_NORMAL) {
        if ([updateUserId isEqualToString:self.model.channelId] &&
            ([self.model isChannelType:NCChannelTypeDirect] ||
             [self.model isChannelType:NCChannelTypeSystem])) {
            self.headerView.headerImageView.imageURL =
                [NSURL URLWithString:[self.model conversationPortraitUri]];
            [self updateConversationTitle:[self.model conversationDisplayName]];
        } else if ([updateUserId isEqualToString:self.model.senderUserId] &&
                   [self.model isChannelType:NCChannelTypeGroup]) {
            if (!self.hideSenderName) {
                if ([self updateMessagePrefixNameWithSenderUser]) {
                    return;
                }
                [self.detailContentView updateContent:self.model
                                           prefixName:[self.model senderDisplayNameInGroup]];
            }
        }
    }
}

- (void)onGroupMemberInfoUpdate:(NCChatUIUserInfo *)userInfo groupId:(NSString *)groupId {
    NSString *userId = userInfo.userId;

    if (self.model.conversationModelType == NC_CONVERSATION_MODEL_TYPE_NORMAL &&
        [self.model isChannelType:NCChannelTypeGroup] &&
        [self.model.channelId isEqualToString:groupId] &&
        [self.model.senderUserId isEqualToString:userId]) {
        if (self.hideSenderName) {
            return;
        }
        if ([self updateMessagePrefixNameWithSenderUser]) {
            return;
        }
        [self.detailContentView updateContent:self.model
                                   prefixName:[self.model senderDisplayNameInGroup]];
    }
}

- (void)onGroupInfoUpdate:(NCChatUIGroup *)groupInfo {
    NSString *groupId = groupInfo.groupId;

    if ([self.model isChannelType:NCChannelTypeGroup] &&
        [self.model.channelId isEqualToString:groupId]) {
        if (self.model.dataManagementInfo == nil) {
            self.model.dataManagementInfo = [NCDataManagementInfo new];
        }
        self.model.dataManagementInfo.name = groupInfo.groupName;
        self.model.dataManagementInfo.portraitUri = groupInfo.avatarUrl;
        if (self.model.conversationModelType == NC_CONVERSATION_MODEL_TYPE_NORMAL) {
            self.headerView.headerImageView.imageURL =
                [NSURL URLWithString:[self.model conversationPortraitUri]];
            [self updateConversationTitle:[self.model conversationDisplayName]];
        }
    }
}

- (void)updateCellIfNeed:(NSNotification *)notification {
    NCChannelListCellUpdateInfo *updateInfo = notification.object;

    if ([updateInfo.model isEqual:self.model]) {
        dispatch_main_async_safe(^{
          if (updateInfo.updateType == NCChannelListCellMessageContentUpdate) {
              [self.detailContentView updateContent:self.model];
              [self.statusView updateReadStatus:self.model];
          } else if (updateInfo.updateType == NCChannelListCellSentStatusUpdate) {
              [self.statusView updateReadStatus:self.model];
              [self.detailContentView updateContent:self.model];
          } else if (updateInfo.updateType == NCChannelListCellUnreadCountUpdate) {
              [self.headerView updateBubbleUnreadNumber:(int)self.model.unreadMessageCount];
          }
          [self didUpdateCell];
        });
    }
}

- (void)onUserOnlineStatusChanged:(NSNotification *)notification {
    // Handle presence changes only for direct channels.
    if (![self.model isChannelType:NCChannelTypeDirect]) {
        return;
    }

    // Get the user IDs whose presence changed.
    NSArray<NSString *> *changedUserIds =
        notification.userInfo[NCChatUIUserOnlineStatusChangedUserIdsKey];

    // Check whether the current channel user is in the changed list.
    if ([changedUserIds containsObject:self.model.channelId]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          [self updateOnlineStatusDisplay];
        });
    }
}

#pragma mark - Callbacks
- (void)headerImageDidTap {
    if ([self.delegate respondsToSelector:@selector(didTapCellPortrait:)]) {
        [self.delegate didTapCellPortrait:self.model];
    }
}

- (void)headerImageDidLongPress {
    if ([self.delegate respondsToSelector:@selector(didLongPressCellPortrait:)]) {
        [self.delegate didLongPressCellPortrait:self.model];
    }
}

#pragma mark - Getter & Setter
- (NCChannelListHeaderView *)headerView {
    if (!_headerView) {
        _headerView = [[NCChannelListHeaderView alloc]
            initWithFrame:CGRectMake(
                              0, 0, NCChatUIConfigCenter.ui.globalConversationPortraitSize.width,
                              NCChatUIConfigCenter.ui.globalConversationPortraitSize.height)];
        [_headerView addGestureRecognizer:[[UILongPressGestureRecognizer alloc]
                                              initWithTarget:self
                                                      action:@selector(headerImageDidLongPress)]];
        [_headerView addGestureRecognizer:[[UITapGestureRecognizer alloc]
                                              initWithTarget:self
                                                      action:@selector(headerImageDidTap)]];
    }
    return _headerView;
}

- (UIStackView *)titleStackView {
    if (!_titleStackView) {
        _titleStackView = [[UIStackView alloc] init];
        _titleStackView.translatesAutoresizingMaskIntoConstraints = NO;
        _titleStackView.axis = UILayoutConstraintAxisHorizontal;
        _titleStackView.alignment = UIStackViewAlignmentCenter;
        _titleStackView.spacing = 4; // Space between the presence dot and title.

        [self.onlineStatusView
            setContentCompressionResistancePriority:UILayoutPriorityRequired
                                            forAxis:UILayoutConstraintAxisHorizontal];
        [self.onlineStatusView setContentHuggingPriority:UILayoutPriorityRequired
                                                 forAxis:UILayoutConstraintAxisHorizontal];

        // Add the presence dot and title to the stack view.
        [_titleStackView addArrangedSubview:self.onlineStatusView];
        [_titleStackView addArrangedSubview:self.conversationTitle];
    }
    return _titleStackView;
}

- (NCOnlineStatusView *)onlineStatusView {
    if (!_onlineStatusView) {
        _onlineStatusView = [[NCOnlineStatusView alloc] init];
    }
    return _onlineStatusView;
}

- (UILabel *)conversationTitle {
    if (!_conversationTitle) {
        _conversationTitle = [[UILabel alloc] init];
        _conversationTitle.translatesAutoresizingMaskIntoConstraints = NO;
        _conversationTitle.backgroundColor = [UIColor clearColor];
        _conversationTitle.font = [[NCChatUIConfig defaultConfig].font fontOfSecondLevel];
        _conversationTitle.textColor = NCDynamicColor(@"text_primary_color");
    }
    return _conversationTitle;
}

- (UIView *)conversationTagView {
    if (!_conversationTagView) {
        _conversationTagView = [[UIView alloc] init];
        _conversationTagView.translatesAutoresizingMaskIntoConstraints = NO;
        _conversationTagView.clipsToBounds = YES;
    }
    return _conversationTagView;
}

- (UILabel *)messageCreatedTimeLabel {
    if (!_messageCreatedTimeLabel) {
        _messageCreatedTimeLabel = [[UILabel alloc] init];
        _messageCreatedTimeLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _messageCreatedTimeLabel.backgroundColor = [UIColor clearColor];
        _messageCreatedTimeLabel.font = [[NCChatUIConfig defaultConfig].font fontOfGuideLevel];
        _messageCreatedTimeLabel.textColor = NCDynamicColor(@"text_secondary_color");
        BOOL isRTL = [NCSemanticContext isRTL];
        _messageCreatedTimeLabel.textAlignment = isRTL ? NSTextAlignmentLeft : NSTextAlignmentRight;
        _messageCreatedTimeLabel.accessibilityLabel = @"messageCreatedTimeLabel";
    }
    return _messageCreatedTimeLabel;
}

- (NCChannelListDetailContentView *)detailContentView {
    if (!_detailContentView) {
        _detailContentView = [[NCChannelListDetailContentView alloc] init];
    }
    return _detailContentView;
}

- (NCChannelListStatusView *)statusView {
    if (!_statusView) {
        _statusView = [[NCChannelListStatusView alloc] init];
    }
    return _statusView;
}
#pragma mark - private method
- (NSString *)userIdentityKeyFromUserInfo:(NCChatUIUserInfo *)userInfo {
    NSString *userId = userInfo.userId ?: @"";
    NSString *name = userInfo.name ?: @"";
    NSString *portrait = userInfo.avatarUrl ?: @"";
    NSString *alias = userInfo.alias ?: @"";
    return [NSString stringWithFormat:@"%@|%@|%@|%@", userId, name, portrait, alias];
}

- (BOOL)updateMessagePrefixNameWithSenderUser {
    NCUserInfo *senderUserInfo = self.model.latestMessage.senderUserInfo;
    if (!self.hideSenderName &&
        [NCChatUI shared].currentDataSourceType == NCDataSourceTypeInfoManagement &&
        senderUserInfo.userId.length > 0 &&
        [senderUserInfo.userId isEqualToString:self.model.senderUserId]) {
        NSString *displayName =
            senderUserInfo.name.length > 0 ? senderUserInfo.name : senderUserInfo.userId;
        [self.detailContentView updateContent:self.model prefixName:displayName];
        return YES;
    }
    return NO;
}

- (void)didUpdateCell {
    if ([self.delegate respondsToSelector:@selector(didUpdateCell:model:)]) {
        [self.delegate didUpdateCell:self model:self.model];
    }
}

#pragma mark - Backward Compatibility
- (void)setHeaderImageViewBackgroundView:(UIView *)headerImageViewBackgroundView {
    self.headerView.backgroundView = headerImageViewBackgroundView;
}
- (UIView *)headerImageViewBackgroundView {
    return self.headerView.backgroundView;
}
- (void)setHeaderImageView:(NCImageView *)headerImageView {
    self.headerView.headerImageView = headerImageView;
}
- (NCImageView *)headerImageView {
    return self.headerView.headerImageView;
}
- (void)setBubbleTipView:(NCMessageBubbleTipView *)bubbleTipView {
    self.headerView.bubbleView = bubbleTipView;
}
- (NCMessageBubbleTipView *)bubbleTipView {
    return self.headerView.bubbleView;
}
- (void)setConversationStatusImageView:(UIImageView *)conversationStatusImageView {
    self.statusView.conversationNotificationStatusView = conversationStatusImageView;
}
- (UIImageView *)conversationStatusImageView {
    return self.statusView.conversationNotificationStatusView;
}

- (void)setMessageContentLabel:(UILabel *)messageContentLabel {
    self.detailContentView.messageContentLabel = messageContentLabel;
}
- (UILabel *)messageContentLabel {
    return self.detailContentView.messageContentLabel;
}
- (void)setEnableNotification:(BOOL)enableNotification {
    if ([[NSThread currentThread] isMainThread]) {
        self.statusView.conversationNotificationStatusView.hidden = enableNotification;
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
          self.statusView.conversationNotificationStatusView.hidden = enableNotification;
        });
    }
}
- (BOOL)enableNotification {
    return self.statusView.conversationNotificationStatusView.hidden;
}
- (void)setPortraitStyle:(NCUserAvatarStyle)portraitStyle {
    [self setHeaderImagePortraitStyle:portraitStyle];
}
- (void)setHeaderImagePortraitStyle:(NCUserAvatarStyle)portraitStyle {
    _portraitStyle = portraitStyle;
    [self.headerView setHeaderImageStyle:_portraitStyle];
}
- (void)setIsShowNotificationNumber:(BOOL)isShowNotificationNumber {
    self.headerView.bubbleView.isShowNotificationNumber = isShowNotificationNumber;
}
- (BOOL)isShowNotificationNumber {
    return self.headerView.bubbleView.isShowNotificationNumber;
}
@end
