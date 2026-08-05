//
//  NCFileMessageCell.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCFileMessageCell.h"
#import "NCChatUICommonDefine.h"
#import "NCChatUIUtility.h"
#import "NCMessageCellTool.h"
#import "NCChatUIConfig.h"
#import "NCResendManager.h"
extern NSString *const NCUIDispatchDownloadMediaNotification;

#define FILE_CONTENT_HEIGHT 69.f

@interface NCMessageModel (NCFileMessageCell)
- (NSString *)fileMessageName;
- (NSInteger)fileMessageSize;
- (NSString *)fileMessageType;
- (void)setFileMessageLocalPath:(NSString *)localPath;
@end

@interface NCFileMessageCell ()

@property (nonatomic, strong) NSMutableArray *messageContentConstraint;

@end

@implementation NCFileMessageCell

#pragma mark - Life Cycle

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initialize];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initialize];
    }
    return self;
}

#pragma mark - Super Methods

+ (CGSize)sizeForMessageModel:(NCMessageModel *)model
      withCollectionViewWidth:(CGFloat)collectionViewWidth
         referenceExtraHeight:(CGFloat)extraHeight {
    CGFloat __messagecontentview_height = FILE_CONTENT_HEIGHT;

    if (__messagecontentview_height < NCChatUIConfigCenter.ui.globalMessagePortraitSize.height) {
        __messagecontentview_height = NCChatUIConfigCenter.ui.globalMessagePortraitSize.height;
    }
    __messagecontentview_height += extraHeight;
    return CGSizeMake(collectionViewWidth, __messagecontentview_height);
}

- (void)setDataModel:(NCMessageModel *)model {
    [super setDataModel:model];
    self.nameLabel.text = [self.model fileMessageName];
    self.sizeLabel.text = [NCChatUIUtility getReadableStringForFileSize:[self.model fileMessageSize]];
    self.typeIconView.image = [NCChatUIUtility imageWithFileSuffix:[self.model fileMessageType]];
    [self setAutoLayout];
}

- (void)updateStatusContentView:(NCMessageModel *)model {
    if (self.model.sentStatus == NCMessageSentStatusSending) {
        self.messageFailedStatusView.hidden = YES;
        self.progressView.hidden = NO;
        self.cancelSendButton.hidden = NO;
        self.messageActivityIndicatorView.hidden = YES;
    } else {
        [super updateStatusContentView:model];
    }
}

#pragma mark - Target Action
- (void)cancelSend {
    if ([self.delegate respondsToSelector:@selector(didTapCancelUploadButton:)]) {
        [self.delegate didTapCancelUploadButton:self.model];
    }
}

- (void)updateDownloadMediaStatus:(NSNotification *)notify {
    NSDictionary *statusDic = notify.userInfo;
    if (self.model.clientId == [statusDic[@"clientId"] longValue]) {
        if ([statusDic[@"type"] isEqualToString:@"success"]) {
            [self.model setFileMessageLocalPath:statusDic[@"mediaPath"]];
        }
    }
}

- (void)messageCellUpdateSendingStatusEvent:(NSNotification *)notification {
    [super messageCellUpdateSendingStatusEvent:notification];
    NCMessageCellNotificationModel *notifyModel = notification.object;
    NSInteger progress = notifyModel.progress;
    if (self.model.clientId == notifyModel.clientId) {
        NCLogD(@"messageCellUpdateSendingStatusEvent >%@ ", notifyModel.actionName);
        if ([notifyModel.actionName isEqualToString:CONVERSATION_CELL_STATUS_SEND_BEGIN]) {
            self.cancelSendButton.hidden = YES;
            [self updateProgressView:progress];
        } else if ([notifyModel.actionName isEqualToString:CONVERSATION_CELL_STATUS_SEND_FAILED]) {
            self.cancelSendButton.hidden = YES;
            [self updateProgressView:progress];
        } else if ([notifyModel.actionName isEqualToString:CONVERSATION_CELL_STATUS_SEND_SUCCESS]) {
            [self updateProgressView:progress];
            self.cancelSendButton.hidden = YES;
        } else if ([notifyModel.actionName isEqualToString:CONVERSATION_CELL_STATUS_SEND_PROGRESS]) {
            [self updateProgressView:progress];
        } else if ([notifyModel.actionName isEqualToString:CONVERSATION_CELL_STATUS_SEND_CANCELED]) {
            self.cancelSendButton.hidden = YES;
            self.progressView.hidden = YES;
            [self displayCancelLabel];
        }
    }
}

#pragma mark - Private Methods

- (void)initialize {
    self.messageContentConstraint = [[NSMutableArray alloc] init];

    [self showBubbleBackgroundView:YES];
    [self.messageContentView addSubview:self.nameLabel];
    [self.messageContentView addSubview:self.sizeLabel];
    [self.messageContentView addSubview:self.typeIconView];
    [self.typeIconView addSubview:self.progressView];
    [self.messageContentView addSubview:self.cancelLabel];

    [self updateBubbleBackgroundViewConstraints];
    self.messageActivityIndicatorView.hidden = YES;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateDownloadMediaStatus:)
                                                 name:NCUIDispatchDownloadMediaNotification
                                               object:nil];
}

- (void)setAutoLayout {
    self.cancelSendButton.hidden = YES;
    self.cancelLabel.hidden = YES;
    self.messageContentView.contentSize = CGSizeMake([NCMessageCellTool getMessageContentViewMaxWidth], FILE_CONTENT_HEIGHT);
    if (NCMessageDirectionReceive == self.messageDirection) {
        self.progressView.hidden = YES;
    } else {
        self.progressView.hidden = YES;
        if (self.model.sentStatus == NCMessageSentStatusCanceled) {
            [self displayCancelLabel];
        }else if (self.model.sentStatus == NCMessageSentStatusSending) {
            self.progressView.hidden = NO;
            [self updateProgressView:self.progressView.progress];
        }else if (self.model.sentStatus == NCMessageSentStatusSent || self.model.sentStatus == NCMessageSentStatusReceived) {
            self.progressView.hidden = YES;
            self.messageActivityIndicatorView.hidden = YES;
        } else if (self.model.sentStatus == NCMessageSentStatusFailed) {
            self.cancelSendButton.hidden = YES;
            if ([[NCResendManager sharedManager] needResend:self.model.clientId]) {
                self.messageActivityIndicatorView.hidden = NO;
                [self.messageActivityIndicatorView startAnimating];
                self.progressView.hidden = NO;
            } else {
                self.progressView.hidden = YES;
                self.messageActivityIndicatorView.hidden = YES;
            }
        }
    }
}

- (void)updateProgressView:(NSUInteger)progress {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ((self.model.sentStatus == NCMessageSentStatusSending && progress != 100) || [[NCResendManager sharedManager] needResend:self.model.clientId]) {
            self.progressView.hidden = NO;
            self.progressView.progress = (float)progress / 100.f;
            // A failed send reports progress = 0 and shows the activity indicator; positive progress shows the cancel button.
            if ([[NCResendManager sharedManager] needResend:self.model.clientId] && progress == 0) {
                self.cancelSendButton.hidden = YES;
                self.messageActivityIndicatorView.hidden = NO;
                [self.messageActivityIndicatorView startAnimating];
            } else {
                self.cancelSendButton.hidden = NO;
                self.messageActivityIndicatorView.hidden = YES;
            }
        } else {
            self.progressView.hidden = YES;
        }
    });
}

- (void)updateBubbleBackgroundViewConstraints{
    self.nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.sizeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.typeIconView.translatesAutoresizingMaskIntoConstraints = NO;
    self.cancelSendButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.cancelLabel.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self displayCancelButton];
    
    
    NSDictionary *views = NSDictionaryOfVariableBindings(_nameLabel, _sizeLabel, _typeIconView);
    [self.messageContentView
     addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-10-[_typeIconView(48)]"
                                                            options:0
                                                            metrics:nil
                                                              views:views]];
    [self.messageContentView
     addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-12-[_typeIconView(48)]-10-[_nameLabel]-12-|"
                                                            options:0
                                                            metrics:nil
                                                              views:views]];
    [self.messageContentView
     
     addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-10-[_typeIconView(48)]"
                                                            options:0
                                                            metrics:nil
                                                              views:views]];
 
    [self.messageContentView
     
     addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-12-[_typeIconView(48)]-10-[_nameLabel]-12-|"
                                                            options:0
                                                            metrics:nil
                                                              views:views]];
    [self.messageContentView
     addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-10-[_nameLabel]-(>=0)-[_sizeLabel(13)]-10-|"
                                                            options:0
                                                            metrics:nil
                                                              views:views]];
    [self.messageContentView
     addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[_typeIconView]-12-[_sizeLabel]"
                                                            options:0
                                                            metrics:nil
                                                              views:views]];
}

- (void)displayCancelLabel {
    [self.messageContentView addSubview:self.cancelLabel];
    [self.messageContentConstraint
        addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[_cancelLabel]-16.5-|"
                                                                    options:0
                                                                    metrics:nil
                                                                      views:NSDictionaryOfVariableBindings(
                                                                                _nameLabel, _sizeLabel, _typeIconView, _cancelLabel)]];
    [self.messageContentView addConstraint:[NSLayoutConstraint constraintWithItem:_cancelLabel
                                                                          attribute:NSLayoutAttributeCenterY
                                                                          relatedBy:NSLayoutRelationEqual
                                                                             toItem:self.sizeLabel
                                                                          attribute:NSLayoutAttributeCenterY
                                                                         multiplier:1
                                                                           constant:0]];
    [self.messageContentView addConstraints:self.messageContentConstraint];
    self.cancelLabel.hidden = NO;
}

- (void)displayCancelButton {
    dispatch_async(dispatch_get_main_queue(), ^{
        if([NCChatUIUtility isRTL]){
            self.baseContentView.semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;
        }else{
            self.baseContentView.semanticContentAttribute = UISemanticContentAttributeForceLeftToRight;
        }
        [self.baseContentView addSubview:self.cancelSendButton];
        NCContentView *messageContentView = self.messageContentView;
        [self.baseContentView
            addConstraints:[NSLayoutConstraint
                               constraintsWithVisualFormat:@"V:[_cancelSendButton(20)]"
                                                   options:0
                                                   metrics:nil
                                                     views:NSDictionaryOfVariableBindings(_cancelSendButton)]];

        [self.baseContentView
            addConstraints:[NSLayoutConstraint
                               constraintsWithVisualFormat:@"H:[_cancelSendButton(20)]-13-[messageContentView]"
                                                   options:0
                                                   metrics:nil
                                                     views:NSDictionaryOfVariableBindings(messageContentView,
                                                                                          _cancelSendButton)]];

        [self.baseContentView addConstraint:[NSLayoutConstraint constraintWithItem:_cancelSendButton
                                                                         attribute:NSLayoutAttributeCenterY
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:self.messageContentView
                                                                         attribute:NSLayoutAttributeCenterY
                                                                        multiplier:1
                                                                          constant:0]];

    });
}

#pragma mark - Getter
- (UILabel *)nameLabel{
    if(!_nameLabel){
        _nameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        [_nameLabel setFont:[[NCChatUIConfig defaultConfig].font fontOfGuideLevel]];
        _nameLabel.numberOfLines = 2;
        _nameLabel.textColor = NCDynamicColor(@"text_primary_color");
        _nameLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
        if([NCChatUIUtility isRTL]){
            _nameLabel.textAlignment = NSTextAlignmentRight;
        }else{
            _nameLabel.textAlignment = NSTextAlignmentLeft;
        }
    }
    return _nameLabel;
}

- (UILabel *)sizeLabel{
    if (!_sizeLabel) {
        _sizeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        [_sizeLabel setFont:[[NCChatUIConfig defaultConfig].font fontOfAnnotationLevel]];
        _sizeLabel.textColor = NCDynamicColor(@"text_secondary_color");
    }
    return _sizeLabel;
}

- (NCBaseImageView *)typeIconView{
    if (!_typeIconView) {
        _typeIconView = [[NCBaseImageView alloc] initWithFrame:CGRectMake(0, 0, 48, 48)];
        _typeIconView.clipsToBounds = YES;
    }
    return _typeIconView;
}

- (NCProgressView *)progressView{
    if (!_progressView) {
        _progressView = [[NCProgressView alloc] initWithFrame:CGRectMake(-10, -10, self.typeIconView.frame.size.width+20, self.typeIconView.frame.size.height+20)];
        [_progressView setHidden:YES];
    }
    return _progressView;
}

- (NCBaseButton *)cancelSendButton{
    if (!_cancelSendButton) {
        _cancelSendButton = [[NCBaseButton alloc] initWithFrame:CGRectZero];
        [_cancelSendButton setImage:NCDynamicImage(@"channel_msg_cell_cancel_img") forState:UIControlStateNormal];
        [_cancelSendButton addTarget:self action:@selector(cancelSend) forControlEvents:UIControlEventTouchUpInside];
        _cancelSendButton.hidden = YES;
    }
    return _cancelSendButton;
}

- (UILabel *)cancelLabel{
    if (!_cancelLabel) {
        _cancelLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _cancelLabel.text = NCUILocalizedString(@"cancel_send_file");
        _cancelLabel.textColor = NCDynamicColor(@"text_secondary_color");
        _cancelLabel.font = [[NCChatUIConfig defaultConfig].font fontOfAnnotationLevel];
        _cancelLabel.hidden = YES;
    }
    return _cancelLabel;
}
@end
