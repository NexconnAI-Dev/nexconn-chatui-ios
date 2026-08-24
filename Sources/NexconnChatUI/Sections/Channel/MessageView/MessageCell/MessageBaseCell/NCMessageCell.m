//
//  NCMessageCell.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCMessageCell.h"
#import "NCChatUICommonDefine.h"
#import "NCChatUIConfig.h"
#import "NCChatUIUserInfo.h"
#import "NCChatUIUtility.h"
#import "NCImageView.h"
#import "NCInfoUpdateCenter.h"
#import "NCMessageCell+Edit.h"
#import "NCMessageCellTool.h"
#import "NCMessageModel+RRS.h"
#import "NCMessageModel+StreamCellVM.h"
#import "NCMessageSenderInfo.h"
#import "NCRRSUtil.h"
#import "NCResendManager.h"

// Avatar.
#define PortraitImageViewTop 0
// Message bubble.
#define ContentViewBottom 14
#define DefaultMessageContentViewWidth 200
#define StatusContentViewWidth 100
#define StatusViewAndContentViewSpace 8

@interface NCMessageCell () <NCInfoUpdateDelegate> {
    BOOL _showPortrait;
}
@property (nonatomic, assign) BOOL showBubbleBackgroundView;
// User information currently displayed by this cell. Messages carrying user information can trigger
// frequent refreshes. When the cell is reused, skip the refresh if the incoming user information
// matches what is already displayed.
// IMSDK-2705
@property (nonatomic, strong) NCChatUIUserInfo *currentDisplayedUserInfo;

@property (nonatomic, weak, readwrite) UICollectionView *hostCollectionView;

/// Message editing state.
@property (nonatomic, assign) NCMessageUpdateStatus editStatus;

@end
@implementation NCMessageCell

#pragma mark - Life Cycle

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self nc_commonInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self nc_commonInit];
    }
    return self;
}

- (void)nc_commonInit {
    _showPortrait = YES;
    [self setupMessageCellView];
    [self registerMessageCellNotification];
}

- (void)dealloc {
    [NCInfoUpdateCenter removeInfoUpdateDelegate:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setShowPortrait:(BOOL)showPortrait {
    if (showPortrait != _showPortrait) {
        _showPortrait = showPortrait;
        [self relayoutViewBy:_showPortrait];
    }
    self.portraitImageView.hidden = !_showPortrait;
}

- (BOOL)showPortrait {
    return _showPortrait;
}
#pragma mark - Super Methods

- (void)setDataModel:(NCMessageModel *)model {
    [super setDataModel:model];
    [self p_showBubbleBackgroundView];
    self.messageFailedStatusView.hidden = YES;
    [self p_setReadStatus];
    [self p_setUserInfo];
    [self setCellAutoLayout];
    [self edit_showEditStatusIfNeeded];
    [self updateReadReceiptView];
}

- (UICollectionView *)hostCollectionView {
    if (!_hostCollectionView) {
        _hostCollectionView = [self parentCollectionView];
    }
    return _hostCollectionView;
}
- (UICollectionView *)parentCollectionView {
    UIView *view = self.superview;
    while (view) {
        if ([view isKindOfClass:[UICollectionView class]]) {
            return (UICollectionView *)view;
        }
        view = view.superview;
    }
    return nil;
}
#pragma mark - Public Methods

- (void)updateStatusContentView:(NCMessageModel *)model {
    dispatch_async(dispatch_get_main_queue(), ^{
      self.messageActivityIndicatorView.hidden = YES;
      if (model.messageDirection == NCMessageDirectionReceive) {
          return;
      }
      switch (model.sentStatus) {
      case NCMessageSentStatusSending:
          [self updateStatusContentViewForSending:model];
          break;
      case NCMessageSentStatusFailed:
          [self updateStatusContentViewForFailed:model];
          break;
      case NCMessageSentStatusCanceled:
          [self updateStatusContentViewForCanceled:model];
          break;
      case NCMessageSentStatusSent:
          [self updateStatusContentViewForSent:model];
          break;
      case NCMessageSentStatusRead:
          [self updateStatusContentViewForRead:model];
          break;
      default:
          break;
      }
    });
}

- (void)updateStatusContentViewForSending:(NCMessageModel *)model {
    self.messageFailedStatusView.hidden = YES;
    if (self.messageActivityIndicatorView) {
        self.messageActivityIndicatorView.hidden = NO;
        if (self.messageActivityIndicatorView.isAnimating == NO) {
            [self.messageActivityIndicatorView startAnimating];
        }
    }
}

- (void)updateStatusContentViewForFailed:(NCMessageModel *)model {
    self.receiptView.hidden = YES;
    self.messageFailedStatusView.hidden = YES;
    if ([[NCResendManager sharedManager] needResend:model.clientId]) {
        if (self.messageActivityIndicatorView) {
            self.messageActivityIndicatorView.hidden = NO;
            if (self.messageActivityIndicatorView.isAnimating == NO) {
                [self.messageActivityIndicatorView startAnimating];
            }
        }
    } else {
        self.messageFailedStatusView.hidden = NO;
        if (self.messageActivityIndicatorView) {
            self.messageActivityIndicatorView.hidden = YES;
            if (self.messageActivityIndicatorView.isAnimating == YES) {
                [self.messageActivityIndicatorView stopAnimating];
            }
        }
    }
}

- (void)updateStatusContentViewForCanceled:(NCMessageModel *)model {
    self.messageFailedStatusView.hidden = YES;
    if (self.messageActivityIndicatorView) {
        self.messageActivityIndicatorView.hidden = YES;
        if (self.messageActivityIndicatorView.isAnimating == YES) {
            [self.messageActivityIndicatorView stopAnimating];
        }
    }
}

- (void)updateStatusContentViewForSent:(NCMessageModel *)model {
    self.messageFailedStatusView.hidden = YES;
    if (self.messageActivityIndicatorView) {
        self.messageActivityIndicatorView.hidden = YES;
        if (self.messageActivityIndicatorView.isAnimating == YES) {
            [self.messageActivityIndicatorView stopAnimating];
        }
    }
    [self updateReadReceiptView];
}

- (void)updateStatusContentViewForRead:(NCMessageModel *)model {
    [self updateReadReceiptView];
    self.messageFailedStatusView.hidden = YES;
    if (self.messageActivityIndicatorView) {
        self.messageActivityIndicatorView.hidden = YES;
        if (self.messageActivityIndicatorView.isAnimating == YES) {
            [self.messageActivityIndicatorView stopAnimating];
        }
    }
}

- (void)updateReadReceiptView {
    if (![self.model rrs_shouldFetchReadReceipt]) {
        return;
    }

    NCMessageReadReceiptInfo *readReceiptInfo = self.model.readReceiptInfo;

    if (readReceiptInfo.readCount == 0) {
        self.receiptView.hidden = NO;
        self.receiptProgressView.hidden = YES;
        self.receiptView.userInteractionEnabled = YES;

        // Show the unread icon when no recipient has read the message.
        UIImage *image = NCDynamicImage(@"channel_msg_rrs_unread_gray_img");
        [self.receiptView setImage:image forState:UIControlStateNormal];
    } else if (readReceiptInfo.readCount > 0 && readReceiptInfo.unreadCount == 0) {
        // Show the read icon when all recipients have read the message.
        self.receiptView.hidden = NO;
        self.receiptProgressView.hidden = YES;
        self.receiptView.userInteractionEnabled = YES;

        UIImage *image = NCDynamicImage(@"channel_msg_rrs_read_img");
        [self.receiptView setImage:image forState:UIControlStateNormal];
    } else {
        // Show progress when only some recipients have read the message.
        self.receiptView.hidden = YES;
        self.receiptProgressView.hidden = NO;
        NSInteger totalCount = readReceiptInfo.readCount + readReceiptInfo.unreadCount;
        CGFloat progress =
            totalCount > 0 ? (CGFloat)readReceiptInfo.readCount / (CGFloat)totalCount : 0;
        self.receiptProgressView.progress = progress;
    }
}

- (void)showBubbleBackgroundView:(BOOL)show {
    self.showBubbleBackgroundView = show;
    self.bubbleBackgroundView.userInteractionEnabled = show;
    if (show) {
        [self.messageContentView sendSubviewToBack:self.bubbleBackgroundView];
    } else {
        self.bubbleBackgroundView = nil;
    }
}

#pragma mark - Private Methods

- (void)setupMessageCellView {
    self.allowsSelection = YES;
    self.delegate = nil;

    [self.baseContentView addSubview:self.portraitImageView];
    [self.baseContentView addSubview:self.nicknameLabel];
    [self.baseContentView addSubview:self.messageContentView];
    [self.baseContentView addSubview:self.statusContentView];

    [self.statusContentView addSubview:self.messageFailedStatusView];
    [self.statusContentView addSubview:self.messageActivityIndicatorView];
    self.messageActivityIndicatorView.hidden = YES;
    [self.statusContentView addSubview:self.receiptView];
    [self.statusContentView addSubview:self.receiptProgressView];

    [self.baseContentView addSubview:self.editStatusContentView];
    [self.editStatusContentView addSubview:self.editStatusLabel];
    [self.editStatusContentView addSubview:self.editRetryButton];
    [self.editStatusContentView addSubview:self.editCircularLoadingView];

    [self setPortraitStyle:NCChatUIConfigCenter.ui.globalMessageAvatarStyle];
}

- (void)registerMessageCellNotification {
    [NCInfoUpdateCenter addInfoUpdateDelegate:self];

    [self registerFrameUpdateLayoutIfNeed];
    [self registerSizeUpdateLayoutIfNeed];
}

- (void)registerFrameUpdateLayoutIfNeed {
    __weak typeof(self) weakSelf = self;
    [self.messageContentView registerFrameChangedEvent:^(CGRect frame) {
      __strong typeof(weakSelf) strongSelf = weakSelf;
      if (strongSelf.model) {
          if ([NCChatUIUtility isRTL]) {
              if (strongSelf.model.messageDirection == NCMessageDirectionSend) {
                  CGRect statusFrame =
                      CGRectMake(CGRectGetMaxX(frame) + StatusViewAndContentViewSpace,
                                 frame.origin.y, StatusContentViewWidth, frame.size.height);
                  strongSelf.statusContentView.frame = statusFrame;
                  [strongSelf setupReceiptViewFrame:statusFrame];

                  strongSelf.messageFailedStatusView.frame =
                      CGRectMake(0, (statusFrame.size.height - 16) / 2, 16, 16);
              } else {
                  CGRect statusFrame = CGRectMake(
                      frame.origin.x - StatusContentViewWidth - StatusViewAndContentViewSpace,
                      frame.origin.y, StatusContentViewWidth, frame.size.height);
                  strongSelf.statusContentView.frame = statusFrame;
                  strongSelf.messageFailedStatusView.frame = CGRectMake(
                      statusFrame.size.width - 16, (statusFrame.size.height - 16) / 2, 16, 16);
              }
              strongSelf.messageActivityIndicatorView.frame =
                  strongSelf.messageFailedStatusView.frame;
          } else {
              if (strongSelf.model.messageDirection == NCMessageDirectionSend) {
                  CGRect statusFrame = CGRectMake(
                      frame.origin.x - StatusContentViewWidth - StatusViewAndContentViewSpace,
                      frame.origin.y, StatusContentViewWidth, frame.size.height);
                  strongSelf.statusContentView.frame = statusFrame;
                  [strongSelf setupReceiptViewFrame:statusFrame];

                  strongSelf.messageFailedStatusView.frame = CGRectMake(
                      statusFrame.size.width - 16, (statusFrame.size.height - 16) / 2, 16, 16);
                  strongSelf.messageActivityIndicatorView.frame =
                      strongSelf.messageFailedStatusView.frame;
              } else {
                  CGRect statusFrame =
                      CGRectMake(CGRectGetMaxX(frame) + StatusViewAndContentViewSpace,
                                 frame.origin.y, StatusContentViewWidth, frame.size.height);
                  strongSelf.statusContentView.frame = statusFrame;
                  strongSelf.messageFailedStatusView.frame =
                      CGRectMake(0, (statusFrame.size.height - 16) / 2, 16, 16);
                  strongSelf.messageActivityIndicatorView.frame =
                      strongSelf.messageFailedStatusView.frame;
              }
          }

          if (strongSelf.showBubbleBackgroundView) {
              strongSelf.bubbleBackgroundView.frame = strongSelf.messageContentView.bounds;
          }
          [strongSelf edit_layoutEditStatusViews];
      }
    }];
}

- (void)registerSizeUpdateLayoutIfNeed {
    __weak typeof(self) weakSelf = self;
    [self.messageContentView registerSizeChangedEvent:^(CGSize size) {
      __strong typeof(weakSelf) strongSelf = weakSelf;
      if (strongSelf.model) {
          CGRect rect = CGRectMake(0, 0, size.width, size.height);
          CGFloat protraitWidth = NCChatUIConfigCenter.ui.globalMessagePortraitSize.width;

          if ([NCChatUIUtility isRTL]) {
              if (strongSelf.model.messageDirection == NCMessageDirectionReceive) {
                  if (strongSelf.showPortrait) {
                      rect.origin.x = strongSelf.baseContentView.bounds.size.width -
                                      (size.width + HeadAndContentSpacing + protraitWidth +
                                       PortraitViewEdgeSpace);
                  } else {
                      rect.origin.x = strongSelf.baseContentView.bounds.size.width -
                                      (size.width + PortraitViewEdgeSpace);
                  }
                  rect.origin.y = PortraitImageViewTop;
                  if (strongSelf.model.isDisplayNickname) {
                      rect.origin.y = PortraitImageViewTop + NameHeight + NameAndContentSpace;
                  }
              } else {
                  if (strongSelf.showPortrait) {
                      rect.origin.x = PortraitViewEdgeSpace + protraitWidth + HeadAndContentSpacing;
                  } else {
                      rect.origin.x = PortraitViewEdgeSpace;
                  }
                  rect.origin.y = PortraitImageViewTop;
              }
          } else {
              if (strongSelf.model.messageDirection == NCMessageDirectionReceive) {
                  if (strongSelf.showPortrait) {
                      rect.origin.x = PortraitViewEdgeSpace + protraitWidth + HeadAndContentSpacing;
                  } else {
                      rect.origin.x = PortraitViewEdgeSpace;
                  }
                  CGFloat messageContentViewY = PortraitImageViewTop;
                  if (strongSelf.model.isDisplayNickname) {
                      messageContentViewY = PortraitImageViewTop + NameHeight + NameAndContentSpace;
                  }
                  rect.origin.y = messageContentViewY;
              } else {
                  if (strongSelf.showPortrait) {
                      rect.origin.x = strongSelf.baseContentView.bounds.size.width -
                                      (size.width + HeadAndContentSpacing + protraitWidth +
                                       PortraitViewEdgeSpace);
                  } else {
                      rect.origin.x = strongSelf.baseContentView.bounds.size.width -
                                      (size.width + PortraitViewEdgeSpace);
                  }

                  rect.origin.y = PortraitImageViewTop;
              }
          }
          strongSelf.messageContentView.frame = rect;
      }
    }];
}

- (void)setupReceiptViewFrame:(CGRect)statusFrame {
    CGFloat size = 12;
    CGFloat y = statusFrame.size.height - size;
    CGFloat x = [NCChatUIUtility isRTL] ? 0 : (StatusContentViewWidth - size);

    self.receiptView.frame = CGRectMake(x, y, size, size);
    self.receiptProgressView.frame = CGRectMake(x, y, size, size);

    // updateReadReceiptView owns read-receipt rendering; this method only sets the frame.
    // Refresh once after the frame changes so cell reuse or asynchronous measurement cannot leave
    // stale receipt state.
    [self updateReadReceiptView];
}

- (void)messageContentViewFrameDidChanged {
}

- (void)setPortraitStyle:(NCUserAvatarStyle)portraitStyle {
    _portraitStyle = portraitStyle;
    if (_portraitStyle == NC_USER_AVATAR_RECTANGLE) {
        self.portraitImageView.layer.cornerRadius =
            NCChatUIConfigCenter.ui.portraitImageViewCornerRadius;
    }
    if (_portraitStyle == NC_USER_AVATAR_CYCLE) {
        self.portraitImageView.layer.cornerRadius =
            [NCChatUIConfigCenter.ui globalMessagePortraitSize].height / 2;
    }
    self.portraitImageView.layer.masksToBounds = YES;
}

- (void)relayoutViewBy:(BOOL)show {
    CGFloat protraitWidth = NCChatUIConfigCenter.ui.globalMessagePortraitSize.width;

    CGRect nicknameFrame = self.nicknameLabel.frame;
    CGRect contentFrame = self.messageContentView.frame;
    CGSize size = contentFrame.size;
    if ([NCChatUIUtility isRTL]) {
        // receiver
        if (NCMessageDirectionReceive == self.model.messageDirection) {
            CGFloat nameOffset_X = 0;
            if (self.showPortrait) {
                contentFrame.origin.x =
                    self.baseContentView.bounds.size.width -
                    (size.width + HeadAndContentSpacing + protraitWidth + PortraitViewEdgeSpace);
                nameOffset_X = self.portraitImageView.frame.origin.x -
                               DefaultMessageContentViewWidth - HeadAndContentSpacing;
            } else {
                nameOffset_X = self.baseContentView.bounds.size.width -
                               (DefaultMessageContentViewWidth + PortraitViewEdgeSpace);
                contentFrame.origin.x =
                    self.baseContentView.bounds.size.width - (size.width + PortraitViewEdgeSpace);
            }
            nicknameFrame.origin.x = nameOffset_X;
        } else { // owner
            if (self.showPortrait) {
                contentFrame.origin.x =
                    PortraitViewEdgeSpace + protraitWidth + HeadAndContentSpacing;
            } else {
                contentFrame.origin.x = PortraitViewEdgeSpace;
            }
        }

    } else {
        // receiver
        if (NCMessageDirectionReceive == self.model.messageDirection) {
            CGFloat nameOffset_X = 0;
            if (self.showPortrait) {
                contentFrame.origin.x =
                    PortraitViewEdgeSpace + protraitWidth + HeadAndContentSpacing;
                nameOffset_X = self.portraitImageView.frame.origin.x +
                               self.portraitImageView.bounds.size.width + HeadAndContentSpacing;
            } else {
                contentFrame.origin.x = PortraitViewEdgeSpace;
                nameOffset_X = self.portraitImageView.frame.origin.x;
            }
            nicknameFrame.origin = CGPointMake(nameOffset_X, PortraitImageViewTop);
            self.nicknameLabel.frame = nicknameFrame;
        } else { // owner
            if (self.showPortrait) {
                contentFrame.origin.x =
                    self.baseContentView.bounds.size.width -
                    (size.width + HeadAndContentSpacing + protraitWidth + PortraitViewEdgeSpace);
            } else {
                contentFrame.origin.x =
                    self.baseContentView.bounds.size.width - (size.width + PortraitViewEdgeSpace);
            }
        }
    }
    self.nicknameLabel.frame = nicknameFrame;
    self.messageContentView.frame = contentFrame;
    [self messageContentViewFrameDidChanged];
}

- (void)setCellAutoLayout {
    CGFloat protraitWidth = NCChatUIConfigCenter.ui.globalMessagePortraitSize.width;
    CGFloat protraitHeight = NCChatUIConfigCenter.ui.globalMessagePortraitSize.height;

    if ([NCChatUIUtility isRTL]) {
        // receiver
        if (NCMessageDirectionReceive == self.model.messageDirection) {
            [self.nicknameLabel setTextAlignment:NSTextAlignmentRight];
            self.nicknameLabel.hidden = !self.model.isDisplayNickname;
            CGFloat portraitImageX =
                self.baseContentView.bounds.size.width - (protraitWidth + PortraitViewEdgeSpace);
            self.portraitImageView.frame =
                CGRectMake(portraitImageX, PortraitImageViewTop, protraitWidth, protraitHeight);
            if (self.showPortrait) {
                self.nicknameLabel.frame = CGRectMake(
                    portraitImageX - DefaultMessageContentViewWidth - HeadAndContentSpacing,
                    PortraitImageViewTop, DefaultMessageContentViewWidth, NameHeight);
            } else {
                self.nicknameLabel.frame =
                    CGRectMake(self.baseContentView.bounds.size.width -
                                   (DefaultMessageContentViewWidth + PortraitViewEdgeSpace),
                               PortraitImageViewTop, DefaultMessageContentViewWidth, NameHeight);
            }
        } else { // owner
            self.nicknameLabel.hidden = YES;
            CGFloat portraitImageX = PortraitViewEdgeSpace;
            self.portraitImageView.frame =
                CGRectMake(portraitImageX, PortraitImageViewTop, protraitWidth, protraitHeight);
        }
        self.messageContentView.contentSize =
            CGSizeMake(DefaultMessageContentViewWidth,
                       self.baseContentView.bounds.size.height - ContentViewBottom);
    } else {
        // receiver
        if (NCMessageDirectionReceive == self.model.messageDirection) {
            [self.nicknameLabel setTextAlignment:NSTextAlignmentLeft];
            self.nicknameLabel.hidden = !self.model.isDisplayNickname;
            CGFloat portraitImageX = PortraitViewEdgeSpace;
            self.portraitImageView.frame =
                CGRectMake(portraitImageX, PortraitImageViewTop, protraitWidth, protraitHeight);
            if (self.showPortrait) {
                self.nicknameLabel.frame =
                    CGRectMake(portraitImageX + self.portraitImageView.bounds.size.width +
                                   HeadAndContentSpacing,
                               PortraitImageViewTop, DefaultMessageContentViewWidth, NameHeight);
            } else {
                self.nicknameLabel.frame = CGRectMake(portraitImageX, PortraitImageViewTop,
                                                      DefaultMessageContentViewWidth, NameHeight);
            }
        } else { // owner
            self.nicknameLabel.hidden = YES;
            CGFloat portraitImageX =
                self.baseContentView.bounds.size.width - (protraitWidth + PortraitViewEdgeSpace);
            self.portraitImageView.frame =
                CGRectMake(portraitImageX, PortraitImageViewTop, protraitWidth, protraitHeight);
        }
        self.messageContentView.contentSize =
            CGSizeMake(DefaultMessageContentViewWidth,
                       self.baseContentView.bounds.size.height - ContentViewBottom);
    }
    [self updateStatusContentView:self.model];
}

- (void)messageCellUpdateSendingStatusEvent:(NSNotification *)notification {
    NCMessageCellNotificationModel *notifyModel = notification.object;
    if (self.model.clientId == notifyModel.clientId) {
        NCLogD(@"messageCellUpdateSendingStatusEvent >%@ ", notifyModel.actionName);
        if ([notifyModel.actionName isEqualToString:CONVERSATION_CELL_STATUS_SEND_BEGIN]) {
            self.model.sentStatus = NCMessageSentStatusSending;
            [self updateStatusContentView:self.model];
        } else if ([notifyModel.actionName isEqualToString:CONVERSATION_CELL_STATUS_SEND_FAILED]) {
            if ([[NCResendManager sharedManager] needResend:self.model.clientId]) {
                self.model.sentStatus = NCMessageSentStatusSending;
            } else {
                self.model.sentStatus = NCMessageSentStatusFailed;
            }
            [self updateStatusContentView:self.model];
        } else if ([notifyModel.actionName
                       isEqualToString:CONVERSATION_CELL_STATUS_SEND_CANCELED]) {
            self.model.sentStatus = NCMessageSentStatusCanceled;
            [self updateStatusContentView:self.model];
        } else if ([notifyModel.actionName isEqualToString:CONVERSATION_CELL_STATUS_SEND_SUCCESS]) {
            if (self.model.sentStatus != NCMessageSentStatusRead) {
                self.model.sentStatus = NCMessageSentStatusSent;
                [self updateStatusContentView:self.model];
            }
        } else if ([notifyModel.actionName
                       isEqualToString:CONVERSATION_CELL_STATUS_SEND_PROGRESS]) {
            self.model.sentStatus = NCMessageSentStatusSending;
            self.messageFailedStatusView.hidden = YES;
        } else if ([notifyModel.actionName
                       isEqualToString:CONVERSATION_CELL_STATUS_SEND_READ_RECEIPT_INFO]) {
            self.model.readReceiptInfo = notifyModel.readReceiptInfo;
            [self updateReadReceiptView];
        }
    }
}

- (void)p_showBubbleBackgroundView {
    if (self.showBubbleBackgroundView) {
        self.bubbleBackgroundView.image = [self getDefaultMessageCellBackgroundImage];
    }
}

- (UIImage *)getDefaultMessageCellBackgroundImage {
    UIImage *bubbleImage;

    // Select the bubble background for the message direction.
    if (NCMessageDirectionReceive == self.model.messageDirection) {
        bubbleImage = NCDynamicImage(@"channel_msg_cell_bg_from_img");
    } else {
        // 根据消息类型判断是否使用白色气泡
        // 合并转发使用 NCMessageType.combine（当前 SDK 为 "RC:CombineV2Msg"），同时兼容旧版
        // "RC:CombineMsg"
        NSArray *whiteBackgroundMessageTypes =
            @[ @"RC:FileMsg", @"RC:CardMsg", @"RC:CombineMsg", NCMessageType.combine ];
        if ([whiteBackgroundMessageTypes containsObject:self.model.objectName]) {
            bubbleImage = NCDynamicImage(@"channel_msg_cell_bg_white_img");
        } else {
            bubbleImage = NCDynamicImage(@"channel_msg_cell_bg_to_img");
        }
    }

    // Resolve the dynamic image for the current trait collection before applying RTL mirroring.
    // imageFlippedForRightToLeftLayoutDirection returns an image whose imageAsset still contains
    // the original variants, so resolving the trait afterward would replace the mirrored image with
    // an unmirrored variant.
    if (bubbleImage.imageAsset) {
        bubbleImage = [bubbleImage.imageAsset imageWithTraitCollection:self.traitCollection];
    }

    // Apply RTL mirroring.
    if ([NCChatUIUtility isRTL]) {
        bubbleImage = [bubbleImage imageFlippedForRightToLeftLayoutDirection];
    }

    // Apply resizable cap insets.
    bubbleImage = [self applyResizableCapInsets:bubbleImage];

    return bubbleImage;
}

#pragma mark - Private Helper Methods

- (UIImage *)applyResizableCapInsets:(UIImage *)image {
    if (!image)
        return nil;

    CGFloat halfWidth = image.size.width * 0.5;
    CGFloat halfHeight = image.size.height * 0.5;
    UIEdgeInsets capInsets = UIEdgeInsetsMake(halfHeight, halfWidth, halfHeight, halfWidth);

    return [image resizableImageWithCapInsets:capInsets];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];

    // Update dynamic colors for appearance changes on iOS 13 and later.
    if (@available(iOS 13.0, *)) {
        if (previousTraitCollection &&
            [previousTraitCollection
                hasDifferentColorAppearanceComparedToTraitCollection:self.traitCollection]) {
            // Refresh the bubble background when the system appearance changes.
            [self p_showBubbleBackgroundView];
        }
    }
}

- (void)p_setReadStatus {
    // Reset the baseline state first, then let updateReadReceiptView render the current receipt
    // state.
    self.receiptView.hidden = YES;
    self.receiptView.userInteractionEnabled = NO;
    self.receiptProgressView.hidden = YES;
}

- (void)p_setUserInfo {
    NCMessageSenderInfo *senderInfo = [self senderInfoForCurrentModel];
    [self renderSenderInfo:senderInfo];
}

#pragma mark - UserInfo Update
- (void)onUserInfoUpdate:(NCChatUIUserInfo *)userInfo {
    if ([self isCurrentMessageSenderUserId:userInfo.userId]) {
        NCMessageSenderInfo *senderInfo = [self senderInfoForCurrentModel];
        [self updateSenderInfoUI:senderInfo];
    }
}

- (void)onGroupMemberInfoUpdate:(NCChatUIUserInfo *)userInfo groupId:(NSString *)groupId {
    if (self.model.channelType == NCChannelTypeGroup) {
        if ([self.model.channelId isEqualToString:groupId] &&
            [self isCurrentMessageSenderUserId:userInfo.userId]) {
            NCMessageSenderInfo *senderInfo = [NCMessageSenderInfo infoWithUserInfo:userInfo];
            [self updateSenderInfoUI:senderInfo];
        }
    }
}

- (void)updateSenderInfoUI:(NCMessageSenderInfo *)senderInfo {
    if ([self isSameUserInfo:self.currentDisplayedUserInfo other:senderInfo.userInfo]) {
        return;
    }
    [self renderSenderInfo:senderInfo];
}

- (void)renderSenderInfo:(NCMessageSenderInfo *)senderInfo {
    self.currentDisplayedUserInfo = [self snapshotUserInfo:senderInfo.userInfo];
    self.model.userInfo = senderInfo.userInfo;
    if (senderInfo.userInfo) {
        [self.portraitImageView setImageURL:[NSURL URLWithString:senderInfo.avatarUrl]];
        [self.nicknameLabel setText:senderInfo.name];
    } else {
        [self.portraitImageView setImageURL:nil];
        [self.nicknameLabel setText:nil];
    }
}

- (BOOL)isCurrentMessageSenderUserId:(NSString *)userId {
    if (userId.length == 0) {
        return NO;
    }
    NSString *senderUserId = [NCMessageSenderUserInfoResolver
        resolvedSenderUserIdWithMessageSenderUserId:self.model.senderUserId
                                     senderUserInfo:self.model.content.senderUserInfo];
    return [senderUserId isEqualToString:userId];
}

- (NCMessageSenderInfo *)senderInfoForCurrentModel {
    NCChatUIUserInfo *userInfo =
        [NCMessageSenderUserInfoResolver userInfoForChannelType:self.model.channelType
                                                      channelId:self.model.channelId
                                                   senderUserId:self.model.senderUserId
                                                 senderUserInfo:self.model.content.senderUserInfo];
    return [NCMessageSenderInfo infoWithUserInfo:userInfo];
}

- (NCChatUIUserInfo *)snapshotUserInfo:(NCChatUIUserInfo *)userInfo {
    if (!userInfo) {
        return nil;
    }
    NCChatUIUserInfo *snapshot = [NCChatUIUserInfo new];
    snapshot.userId = userInfo.userId;
    snapshot.name = userInfo.name;
    snapshot.avatarUrl = userInfo.avatarUrl;
    snapshot.alias = userInfo.alias;
    snapshot.extra = userInfo.extra;
    return snapshot;
}

- (BOOL)isSameUserInfo:(NCChatUIUserInfo *)currentUserInfo other:(NCChatUIUserInfo *)other {
    if (!currentUserInfo || !other) {
        return NO;
    }
    if (![self string:currentUserInfo.userId isEqualToString:other.userId]) {
        return NO;
    }
    if (![self string:currentUserInfo.name isEqualToString:other.name]) {
        return NO;
    }
    if (![self string:currentUserInfo.avatarUrl isEqualToString:other.avatarUrl]) {
        return NO;
    }
    if (![self string:currentUserInfo.alias isEqualToString:other.alias]) {
        return NO;
    }
    return YES;
}

- (BOOL)string:(NSString *)lhs isEqualToString:(NSString *)rhs {
    if (lhs == rhs) {
        return YES;
    }
    if (!lhs || !rhs) {
        return NO;
    }
    return [lhs isEqualToString:rhs];
}

#pragma mark - Target Action
- (void)didClickMsgFailedView:(UIButton *)button {
    self.messageFailedStatusView.hidden = YES;
    self.model.sentStatus = NCMessageSentStatusSending;
    if (self.delegate) {
        if ([self.delegate respondsToSelector:@selector(didTapmessageFailedStatusViewForResend:)]) {
            [self.delegate didTapmessageFailedStatusViewForResend:self.model];
        }
    }
}

- (void)enableShowReceiptView:(UIButton *)sender {
    [self didTapReceiptStatusView:sender];
}

- (void)didTapReceiptStatusView:(id)sender {
    if (self.model.channelType != NCChannelTypeGroup) {
        return;
    }
    if ([self.delegate respondsToSelector:@selector(didTapReceiptStatusView:)]) {
        [self.delegate didTapReceiptStatusView:self.model];
    }
}

- (void)tapUserPortaitEvent:(UIGestureRecognizer *)gestureRecognizer {
    __weak typeof(self) weakSelf = self;
    if ([self.delegate respondsToSelector:@selector(didTapCellPortrait:)]) {
        [self.delegate didTapCellPortrait:weakSelf.model.senderUserId];
    }
}

- (void)longPressUserPortaitEvent:(UIGestureRecognizer *)gestureRecognizer {
    __weak typeof(self) weakSelf = self;
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        if ([self.delegate respondsToSelector:@selector(didLongPressCellPortrait:)]) {
            [self.delegate didLongPressCellPortrait:weakSelf.model.senderUserId];
        }
    }
}

- (void)longPressedMessageContentView:(id)sender {
    UILongPressGestureRecognizer *press = (UILongPressGestureRecognizer *)sender;
    if (press.state == UIGestureRecognizerStateEnded) {
        return;
    } else if (press.state == UIGestureRecognizerStateBegan) {
        [self.delegate didLongTouchMessageCell:self.model inView:self.messageContentView];
    }
}

- (void)didTapMessageContentView {
    NCLogD(@"%s", __FUNCTION__);
    if ([self.delegate respondsToSelector:@selector(didTapMessageCell:)]) {
        [self.delegate didTapMessageCell:self.model];
    }
}

#pragma mark - Getter && Setter
- (NCBaseButton *)receiptView {
    if (!_receiptView) {
        _receiptView = [[NCBaseButton alloc] init];
        [_receiptView setImage:NCDynamicImage(@"channel_msg_cell_msg_read_img")
                      forState:UIControlStateNormal];
        [_receiptView addTarget:self
                         action:@selector(enableShowReceiptView:)
               forControlEvents:UIControlEventTouchUpInside];
        _receiptView.userInteractionEnabled = NO;
        _receiptView.hidden = YES;
    }
    return _receiptView;
}

- (UIActivityIndicatorView *)messageActivityIndicatorView {
    if (!_messageActivityIndicatorView) {
        if (@available(iOS 13.0, *)) {
            _messageActivityIndicatorView = [[UIActivityIndicatorView alloc]
                initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
        } else {
            _messageActivityIndicatorView = [[UIActivityIndicatorView alloc]
                initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        }
        _messageActivityIndicatorView.hidden = YES;
    }
    return _messageActivityIndicatorView;
}

- (NCButton *)messageFailedStatusView {
    if (!_messageFailedStatusView) {
        _messageFailedStatusView = [[NCButton alloc] init];
        [_messageFailedStatusView setImage:NCDynamicImage(@"channel_msg_cell_msg_fail_img")
                                  forState:UIControlStateNormal];
        _messageFailedStatusView.hidden = YES;
        [_messageFailedStatusView addTarget:self
                                     action:@selector(didClickMsgFailedView:)
                           forControlEvents:UIControlEventTouchUpInside];
    }
    return _messageFailedStatusView;
}

- (NCImageView *)portraitImageView {
    if (!_portraitImageView) {
        _portraitImageView = [[NCImageView alloc]
            initWithPlaceholderImage:NCDynamicImage(@"channel-list_cell_portrait_msg_img")];
        // Handle avatar taps.
        UITapGestureRecognizer *portraitTap =
            [[UITapGestureRecognizer alloc] initWithTarget:self
                                                    action:@selector(tapUserPortaitEvent:)];
        portraitTap.numberOfTapsRequired = 1;
        portraitTap.numberOfTouchesRequired = 1;
        [_portraitImageView addGestureRecognizer:portraitTap];

        UILongPressGestureRecognizer *portraitLongPress = [[UILongPressGestureRecognizer alloc]
            initWithTarget:self
                    action:@selector(longPressUserPortaitEvent:)];
        [_portraitImageView addGestureRecognizer:portraitLongPress];

        _portraitImageView.userInteractionEnabled = YES;
    }
    return _portraitImageView;
}

- (UILabel *)nicknameLabel {
    if (!_nicknameLabel) {
        _nicknameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _nicknameLabel.backgroundColor = [UIColor clearColor];
        [_nicknameLabel setFont:[[NCChatUIConfig defaultConfig].font fontOfAnnotationLevel]];
        [_nicknameLabel setTextColor:NCDynamicColor(@"text_secondary_color")];
    }
    return _nicknameLabel;
}

- (UIView *)statusContentView {
    if (!_statusContentView) {
        _statusContentView = [[UIView alloc]
            initWithFrame:CGRectMake(0, 0, StatusContentViewWidth, StatusContentViewWidth)];
        _statusContentView.backgroundColor = [UIColor clearColor];
    }
    return _statusContentView;
}

- (NCContentView *)messageContentView {
    if (!_messageContentView) {
        _messageContentView = [[NCContentView alloc] init];
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc]
            initWithTarget:self
                    action:@selector(longPressedMessageContentView:)];
        [_messageContentView addGestureRecognizer:longPress];

        UITapGestureRecognizer *tap =
            [[UITapGestureRecognizer alloc] initWithTarget:self
                                                    action:@selector(didTapMessageContentView)];
        tap.numberOfTapsRequired = 1;
        tap.numberOfTouchesRequired = 1;
        [_messageContentView addGestureRecognizer:tap];
        _messageContentView.userInteractionEnabled = YES;
    }
    return _messageContentView;
}

- (NCBaseImageView *)bubbleBackgroundView {
    if (!_bubbleBackgroundView) {
        _bubbleBackgroundView = [[NCBaseImageView alloc] initWithFrame:CGRectZero];
        [self.messageContentView addSubview:self.bubbleBackgroundView];
    }
    return _bubbleBackgroundView;
}

#pragma mark - Edit

- (UIView *)editStatusContentView {
    if (!_editStatusContentView) {
        _editStatusContentView = [[UIView alloc] init];
        _editStatusContentView.hidden = YES;
    }
    return _editStatusContentView;
}

- (NCCircularLoadingView *)editCircularLoadingView {
    if (!_editCircularLoadingView) {
        _editCircularLoadingView = [[NCCircularLoadingView alloc] init];
        _editCircularLoadingView.hidden = YES;
    }
    return _editCircularLoadingView;
}

- (UILabel *)editStatusLabel {
    if (!_editStatusLabel) {
        _editStatusLabel = [[UILabel alloc] init];
        _editStatusLabel.font = [[NCChatUIConfig defaultConfig].font fontOfAnnotationLevel];
        _editStatusLabel.textColor = NCDynamicColor(@"primary_color");
        _editStatusLabel.textAlignment = NSTextAlignmentRight;
        _editStatusLabel.hidden = YES;
        _editStatusLabel.numberOfLines = 1;
        _editStatusLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    }
    return _editStatusLabel;
}

- (UIButton *)editRetryButton {
    if (!_editRetryButton) {
        NSString *title =
            [NSString stringWithFormat:@" %@", NCUILocalizedString(@"message_edit_failed")];
        _editRetryButton = [[UIButton alloc] init];
        [_editRetryButton setImage:NCDynamicImage(@"channel_msg_edit_retry_img")
                          forState:UIControlStateNormal];
        [_editRetryButton setTitle:title forState:UIControlStateNormal];
        [_editRetryButton setTitleColor:NCDynamicColor(@"hint_color")
                               forState:UIControlStateNormal];
        _editRetryButton.titleLabel.font =
            [[NCChatUIConfig defaultConfig].font fontOfAnnotationLevel];
        [_editRetryButton addTarget:self
                             action:@selector(edit_didTapEditRetryButton:)
                   forControlEvents:UIControlEventTouchUpInside];
        _editRetryButton.hidden = YES;
    }
    return _editRetryButton;
}

- (NCReadReceiptProgressView *)receiptProgressView {
    if (!_receiptProgressView) {
        _receiptProgressView = [[NCReadReceiptProgressView alloc] init];
        _receiptProgressView.hidden = YES;
        _receiptProgressView.userInteractionEnabled = YES;
        UITapGestureRecognizer *tapGesture =
            [[UITapGestureRecognizer alloc] initWithTarget:self
                                                    action:@selector(didTapReceiptStatusView:)];
        [_receiptProgressView addGestureRecognizer:tapGesture];
    }
    return _receiptProgressView;
}

@end
