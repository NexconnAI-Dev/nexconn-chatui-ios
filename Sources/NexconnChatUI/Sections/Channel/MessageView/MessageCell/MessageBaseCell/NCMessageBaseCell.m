//
//  NCMessageBaseCell.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCMessageBaseCell.h"
#import "NCAlertView.h"
#import "NCBaseButton.h"
#import "NCChatUICommonDefine.h"
#import "NCChatUIConfig.h"
#import "NCChatUIUtility.h"
#import "NCMessageSelectionUtility.h"
NSString *const KNotificationMessageBaseCellUpdateSendingStatus =
    @"KNotificationMessageBaseCellUpdateSendingStatus";
#define SelectButtonSize CGSizeMake(20, 20)
#define SelectButtonSpaceLeft 8 // Left inset for the selection button.

@interface NCMessageBaseCell () {
    __weak id<NCMessageCellDelegate> _delegate;
}
@property (nonatomic, strong) UITapGestureRecognizer *multiSelectTap;
@property (nonatomic, strong) NCBaseButton *selectButton;

@end

@implementation NCMessageBaseCell

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setupMessageBaseCellView];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupMessageBaseCellView];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setDelegate:(id<NCMessageCellDelegate>)delegate {
    _delegate = delegate;
}

- (id<NCMessageCellDelegate>)delegate {
    return _delegate;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self setBaseAutoLayout];
    [self updateUIForMultiSelect];
}

#pragma mark - Public Methods

+ (CGSize)sizeForMessageModel:(NCMessageModel *)model
      withCollectionViewWidth:(CGFloat)collectionViewWidth
         referenceExtraHeight:(CGFloat)extraHeight {
    NCLogReleaseW(@"Warning, you not implement "
                  @"sizeForMessageModel:withCollectionViewWidth:referenceExtraHeight: method for "
                  @"you custom cell %@",
                  NSStringFromClass(self));
    return CGSizeMake(0, 0);
}

- (void)setDataModel:(NCMessageModel *)model {
    self.model = model;
    self.messageDirection = model.messageDirection;
    _isDisplayMessageTime = model.isDisplayMessageTime;
    if (self.isDisplayMessageTime) {
        [self.messageTimeLabel setText:[NCChatUIUtility convertMessageTime:model.sentTime / 1000]
                   dataDetectorEnabled:NO];
    }

    [self setBaseAutoLayout];
    [self updateUIForMultiSelect];
}

#pragma mark - Private Methods

- (void)setupMessageBaseCellView {
    [[NSNotificationCenter defaultCenter]
        addObserver:self
           selector:@selector(messageCellUpdateSendingStatusEvent:)
               name:KNotificationMessageBaseCellUpdateSendingStatus
             object:nil];
    self.model = nil;
    self.baseContentView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.contentView addSubview:_baseContentView];
}

- (void)setBaseAutoLayout {
    if (self.isDisplayMessageTime) {
        CGSize timeTextSize_ = [NCChatUIUtility
            getTextDrawingSize:self.messageTimeLabel.text
                          font:[[NCChatUIConfig defaultConfig].font fontOfAnnotationLevel]
               constrainedSize:CGSizeMake(self.bounds.size.width, TIME_LABEL_HEIGHT)];
        timeTextSize_ = CGSizeMake(ceilf(timeTextSize_.width + 10), ceilf(timeTextSize_.height));

        self.messageTimeLabel.hidden = NO;
        [self.messageTimeLabel
            setFrame:CGRectMake((self.bounds.size.width - timeTextSize_.width) / 2, TIME_LABEL_TOP,
                                timeTextSize_.width, TIME_LABEL_HEIGHT)];
        [self.baseContentView setFrame:CGRectMake(0,
                                                  CGRectGetMaxY(self.messageTimeLabel.frame) +
                                                      TIME_LABEL_AND_BASE_CONTENT_VIEW_SPACE,
                                                  self.bounds.size.width,
                                                  self.bounds.size.height -
                                                      CGRectGetMaxY(self.messageTimeLabel.frame) -
                                                      TIME_LABEL_AND_BASE_CONTENT_VIEW_SPACE -
                                                      BASE_CONTENT_VIEW_BOTTOM)];
    } else {
        if (self.messageTimeLabel) {
            self.messageTimeLabel.hidden = YES;
        }
        [self.baseContentView
            setFrame:CGRectMake(0, 0, self.bounds.size.width,
                                self.bounds.size.height - (BASE_CONTENT_VIEW_BOTTOM))];
    }
}

- (void)messageCellUpdateSendingStatusEvent:(NSNotification *)notification {
    NCLogD(@"%s", __FUNCTION__);
}

#pragma mark - Multi select
- (void)onChangedMessageMultiSelectStatus:(NSNotification *)notification {
    [self setDataModel:self.model];
}

- (void)updateUIForMultiSelect {
    [self.contentView removeGestureRecognizer:self.multiSelectTap];
    if ([NCMessageSelectionUtility sharedManager].multiSelect) {
        self.baseContentView.userInteractionEnabled = NO;
        if (self.allowsSelection) {
            self.selectButton.hidden = NO;
            [self.contentView addGestureRecognizer:self.multiSelectTap];
        } else {
            self.selectButton.hidden = YES;
        }
    } else {
        self.baseContentView.userInteractionEnabled = YES;
        self.selectButton.hidden = YES;
        CGRect frame = self.baseContentView.frame;
        frame.origin.x = 0;
        self.baseContentView.frame = frame;
        return;
    }
    [self updateSelectButtonStatus];

    CGRect frame = self.baseContentView.frame;
    CGFloat selectButtonY =
        frame.origin.y +
        (NCChatUIConfigCenter.ui.globalMessagePortraitSize.height - SelectButtonSize.height) /
            2; // Vertically center the selection button relative to the message avatar.
    if (NCMessageDirectionReceive == self.model.messageDirection) {
        if (frame.origin.x <
            3) { // Offset only when the cell has not already been shifted from the leading edge.
            if ([NCChatUIUtility isRTL]) {
                frame.origin.x = frame.origin.x - 12 - SelectButtonSpaceLeft;
            } else {
                frame.origin.x = SelectButtonSpaceLeft + 12;
            }
        }
        self.baseContentView.frame = frame;
    }
    CGRect selectButtonFrame = CGRectMake(SelectButtonSpaceLeft, selectButtonY, 20, 20);
    if ([NCChatUIUtility isRTL]) {
        if (NCMessageDirectionReceive == self.model.messageDirection) {
            selectButtonFrame.origin.x = frame.origin.x + frame.size.width - SelectButtonSpaceLeft;
        } else {

            selectButtonFrame.origin.x = CGRectGetMaxX(frame) - SelectButtonSpaceLeft - 20;
        }
    }
    self.selectButton.frame = selectButtonFrame;
}

- (void)setAllowsSelection:(BOOL)allowsSelection {
    _allowsSelection = allowsSelection;
    if (self.model) {
        [self updateUIForMultiSelect];
    }
}

- (void)onSelectMessageEvent {
    if ([[NCMessageSelectionUtility sharedManager] isContainMessage:self.model]) {
        [[NCMessageSelectionUtility sharedManager] removeMessageModel:self.model];
        [self updateSelectButtonStatus];
    } else {
        if ([NCMessageSelectionUtility sharedManager].selectedMessages.count >= 100) {
            [NCAlertView showAlertController:nil
                                     message:NCUILocalizedString(@"chat_transcripts")
                                 cancelTitle:NCUILocalizedString(@"ok")];
        } else {
            [[NCMessageSelectionUtility sharedManager] addMessageModel:self.model];
            [self updateSelectButtonStatus];
        }
    }
}

- (void)updateSelectButtonStatus {
    NSString *imgName = [[NCMessageSelectionUtility sharedManager] isContainMessage:self.model]
                            ? @"message_cell_select"
                            : @"message_cell_unselect";
    NSString *imgNameKey = [[NCMessageSelectionUtility sharedManager] isContainMessage:self.model]
                               ? @"channel_msg_cell_select_img"
                               : @"channel_msg_cell_unselect_img";
    UIImage *image = NCDynamicImage(imgNameKey);
    [self.selectButton setImage:image forState:UIControlStateNormal];
}

#pragma mark - Getters and Setters

- (NCBaseButton *)selectButton {
    if (!_selectButton) {
        _selectButton = [[NCBaseButton alloc] initWithFrame:CGRectZero];
        [_selectButton setImage:NCDynamicImage(@"channel_msg_cell_unselect_img")
                       forState:UIControlStateNormal];
        [_selectButton addTarget:self
                          action:@selector(onSelectMessageEvent)
                forControlEvents:UIControlEventTouchUpInside];
        _selectButton.hidden = YES;
        [self.contentView addSubview:_selectButton];
        CGRect selectButtonFrame = CGRectMake(SelectButtonSpaceLeft, 0, 20, 20);
        _selectButton.frame = selectButtonFrame;
    }
    return _selectButton;
}

- (UITapGestureRecognizer *)multiSelectTap {
    if (!_multiSelectTap) {
        _multiSelectTap =
            [[UITapGestureRecognizer alloc] initWithTarget:self
                                                    action:@selector(onSelectMessageEvent)];
        _multiSelectTap.numberOfTapsRequired = 1;
        _multiSelectTap.numberOfTouchesRequired = 1;
    }
    return _multiSelectTap;
}

// Defer loading because most cells do not display a timestamp.
- (NCTipLabel *)messageTimeLabel {
    if (!_messageTimeLabel) {
        _messageTimeLabel = [NCTipLabel greyTipLabel];
        _messageTimeLabel.backgroundColor = [UIColor clearColor];
        _messageTimeLabel.textColor = NCDynamicColor(@"text_secondary_color");
        _messageTimeLabel.font = [[NCChatUIConfig defaultConfig].font fontOfAnnotationLevel];
        [self.contentView addSubview:_messageTimeLabel];
    }
    return _messageTimeLabel;
}
@end
