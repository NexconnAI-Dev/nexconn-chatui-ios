//
//  NCStreamMessageCell.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCStreamMessageCell.h"
#import "NCMessageModel+StreamCellVM.h"
#import "NCChatUIConfig.h"
#import "NCStreamMessageCellViewModel.h"
#import "NCStreamContentView.h"
#import "NCChatUICommonDefine.h"
#import "NCMessageCellTool.h"
#import "NCStreamMarkdownContentViewModel.h"
#import "NCStreamTextContentViewModel.h"

NSString *const NCStreamMessageCellUpdateEndNotification = @"NCStreamMessageCellUpdateEndNotification";

extern NSString *const NCConversationViewScrollNotification;

@interface NCStreamMessageCell()<NCReferencedContentViewDelegate, NCStreamMessageCellViewModelDelegate, NCStreamContentViewDelegate>
/*!
 Streaming content view.
*/
@property (strong, nonatomic) NCStreamContentView *streamContentView;

/*!
 Button that expands truncated streaming content.
*/
@property (strong, nonatomic) NCButton *unfoldButton;

@property (strong, nonatomic) UIView *lineView;

@property (nonatomic, strong) NCStreamMessageCellViewModel *cellViewModel;

@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, assign) NSInteger dotCount;

@property (nonatomic, assign) BOOL isScrolling;

@property (nonatomic, assign) BOOL needLoad;

@end

@implementation NCStreamMessageCell
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

- (void)layoutSubviews {
    [super layoutSubviews];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.streamContentView.frame = CGRectZero;
    [self.streamContentView cleanView];
    self.referencedContentView.frame = CGRectZero;
    self.unfoldButton.frame = CGRectZero;
    [self.unfoldButton setTitle:@"" forState:(UIControlStateNormal)];
    self.unfoldButton.hidden = YES;
    [self invalidTimer];
}

- (void)dealloc {
    [self invalidTimer];
}

#pragma mark -- over method

+ (CGSize)sizeForMessageModel:(NCMessageModel *)model withCollectionViewWidth:(CGFloat)collectionViewWidth referenceExtraHeight:(CGFloat)extraHeight {
    [self configModelWithCellVM:model];
    NCStreamMessageCellViewModel *cellVM = (NCStreamMessageCellViewModel *)model.cellViewModel;
    CGSize contentSize = [cellVM getMessageContentViewSize];
    return CGSizeMake(collectionViewWidth, contentSize.height + extraHeight);
}

- (void)setDataModel:(NCMessageModel *)model {
    [super setDataModel:model];
    [[self class] configModelWithCellVM:model];
    self.cellViewModel = (NCStreamMessageCellViewModel *)model.cellViewModel;
    self.cellViewModel.delegate = self;
    [self updateContentLayout];
}

#pragma mark -- private

+ (void)configModelWithCellVM:(NCMessageModel *)model {
    if (!model.cellViewModel) {
        model.cellViewModel = [NCStreamMessageCellViewModel viewModelWithModel:model];
    }
}

- (void)initialize {
    [self showBubbleBackgroundView:YES];
    [self.messageContentView addSubview:self.referencedContentView];
    [self.messageContentView addSubview:self.unfoldButton];
    [self.unfoldButton addSubview:self.lineView];
    self.contentView.layer.masksToBounds = YES;
    [self registerNotification];
}


- (void)updateContentLayout {
    self.messageContentView.contentSize = self.cellViewModel.contentViewSize;;

    CGFloat leadingX = ncTextLeadingX;
    CGFloat referTopY = ncContentTop;
    CGFloat streamTopY = ncContentTop;
    if (self.cellViewModel.showReferMessage) {
        CGSize referSize = [self.cellViewModel referViewSize];
        [self.referencedContentView setMessage:self.model contentSize:referSize];
        self.referencedContentView.frame = CGRectMake(leadingX, referTopY, referSize.width, referSize.height);
        streamTopY = CGRectGetMaxY(self.referencedContentView.frame) + ncContentSpace;
    } else {
        self.referencedContentView.frame = CGRectZero;
    }

    CGSize textSize = [self.cellViewModel textViewSize];
    self.streamContentView.frame = CGRectMake(leadingX, streamTopY, textSize.width, textSize.height);
    if (self.cellViewModel.status == NCStreamMessageStatusContentLoading) {
        [self.streamContentView showLoading];
    } else if (self.cellViewModel.status == NCStreamMessageStatusContentFailedWhenLoading) {
        [self.streamContentView showFailed];
    } else if (self.cellViewModel.status != NCStreamMessageStatusNone){
        [self.streamContentView configViewModel:self.cellViewModel.contentViewModel];
        [self updateUnfoldButton];
    }
}

- (void)updateUnfoldButton {
    switch (self.cellViewModel.status) {
        case NCStreamMessageStatusBottomUnfold:{
            self.unfoldButton.hidden = NO;
            self.unfoldButton.enabled = YES;
            self.unfoldButton.frame = CGRectMake(0, self.messageContentView.frame.size.height - ncUnfoldButtonHeight, self.messageContentView.frame.size.width, ncUnfoldButtonHeight);
            [self.unfoldButton setTitle:NCUILocalizedString(@"stream_message_unfold") forState:(UIControlStateNormal)];
            [self.unfoldButton setTitleColor:NCDynamicColor(@"primary_color") forState:UIControlStateNormal];
        } break;
        case NCStreamMessageStatusBottomLoading:{
            self.unfoldButton.hidden = NO;
            self.unfoldButton.enabled = NO;
            self.unfoldButton.frame = CGRectMake(0, self.messageContentView.frame.size.height - ncUnfoldButtonHeight, self.messageContentView.frame.size.width, ncUnfoldButtonHeight);
            [self.unfoldButton setTitle:NCUILocalizedString(@"stream_message_loading") forState:(UIControlStateNormal)];
            [self.unfoldButton setTitleColor:NCDynamicColor(@"primary_color") forState:UIControlStateNormal];
            if (self.timer) {
                return;
            }
            // Initialize the dot counter and timer.
            self.dotCount = 1;
            self.timer = [NSTimer scheduledTimerWithTimeInterval:0.3 target:self selector:@selector(updateLoadingText) userInfo:nil repeats:YES];
        } break;
        case NCStreamMessageStatusBottomFailed:{
            self.unfoldButton.hidden = NO;
            self.unfoldButton.enabled = YES;
            self.unfoldButton.frame = CGRectMake(0, self.messageContentView.frame.size.height - ncUnfoldButtonHeight, self.messageContentView.frame.size.width, ncUnfoldButtonHeight);
            [self.unfoldButton setTitle:NCUILocalizedString(@"stream_message_request_failed") forState:(UIControlStateNormal)];
            [self.unfoldButton setTitleColor:NCDynamicColor(@"primary_color") forState:UIControlStateNormal];
        } break;
        default:{
            if (self.unfoldButton.hidden) {
                return;
            }
            self.unfoldButton.hidden = YES;
            self.unfoldButton.enabled = NO;
            [self.unfoldButton setTitle:@"" forState:(UIControlStateNormal)];
            self.unfoldButton.frame = CGRectZero;
        } break;
    }
    if (self.cellViewModel.status != NCStreamMessageStatusBottomLoading) {
        [self invalidTimer];
    }
}

- (void)updateLoadingText {
    if (self.cellViewModel.status != NCStreamMessageStatusBottomLoading) {
        [self invalidTimer];
        return;
    }
    // Update the number of loading dots.
    NSString *dots = @"";
    for (int i = 0; i < self.dotCount; i++) {
        dots = [dots stringByAppendingString:@"."];
    }
    NSString *loading = [NSString stringWithFormat:@"%@%@", NCUILocalizedString(@"stream_message_loading"), dots];
    [self.unfoldButton setTitle:loading forState:(UIControlStateNormal)];
    // Cycle the loading dot count.
    if (self.dotCount == 6) {
        self.dotCount = 1;
    } else {
        self.dotCount++;
    }
}

- (void)invalidTimer {
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
}

- (void)reloadLayout {
    [UIView animateWithDuration:0.1 animations:^{
        [self updateContentLayout];
    } completion:^(BOOL finished) {
        [self.messageContentView setNeedsLayout]; // Redraw after the animation completes.
        [self.streamContentView setNeedsLayout];
        [self.hostView performBatchUpdates:^{
            [self.hostView.collectionViewLayout invalidateLayout];
        } completion:^(BOOL finished) {
            [[NSNotificationCenter defaultCenter] postNotificationName:NCStreamMessageCellUpdateEndNotification object:self.model.messageId];
        }];
    }];
}

#pragma mark -- NCStreamMessageCellViewModelDelegate

- (void)contentLayoutDidUpdate {
    if (self.isScrolling) {
        self.needLoad = YES;
        return;
    }
    if (!self.cellViewModel.delegate) {
        return;
    }
    [self reloadLayout];
}

#pragma mark -- NCReferencedContentViewDelegate

- (void)didTapReferencedContentView:(NCMessageModel *)message {
    NCStreamMessage *streamMessage = (NCStreamMessage *)message.content;
    NCMessageContent *referContent = streamMessage.referenceInfo.content;
    if ([referContent isKindOfClass:[NCFileMessage class]] ||
        [referContent isKindOfClass:[NCImageMessage class]]  ||
        [referContent isKindOfClass:[NCTextMessage class]]) {
        if ([self.delegate respondsToSelector:@selector(didTapReferencedContentView:)]) {
            [self.delegate didTapReferencedContentView:message];
        }
    } else {
        if ([self.delegate respondsToSelector:@selector(didTapMessageCell:)]) {
            [self.delegate didTapMessageCell:self.model];
        }
    }
}

#pragma mark -- NCStreamContentViewDelegate

- (void)streamContentViewDidLongPress {
    [self longPressedStreamContentView:nil];
}

- (void)streamContentViewDidClickUrl:(NSString *)url {
    if ([self.delegate respondsToSelector:@selector(didTapUrlInMessageCell:model:)]) {
        [self.delegate didTapUrlInMessageCell:url model:self.model];
    }
}

#pragma mark -- notification

- (void)registerNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(conversationViewScrollDidChange:) name:NCConversationViewScrollNotification object:nil];
}

- (void)conversationViewScrollDidChange:(NSNotification *)notifi {
    self.isScrolling = [notifi.object boolValue];
    if (!self.isScrolling && self.needLoad) {
        self.needLoad = NO;
        [self reloadLayout];
    }
}


#pragma mark -- action

- (void)longPressedStreamContentView:(id)sender {
    UILongPressGestureRecognizer *press = (UILongPressGestureRecognizer *)sender;
    if (press.state == UIGestureRecognizerStateEnded) {
        return;
    } else if (press.state == UIGestureRecognizerStateBegan) {
        [self.delegate didLongTouchMessageCell:self.model inView:self.messageContentView];
    }
}

- (void)didTapStreamContentView{
    NCLogD(@"%s", __FUNCTION__);
    if ([self.delegate respondsToSelector:@selector(didTapMessageCell:)]) {
        [self.delegate didTapMessageCell:self.model];
    }
}

- (void)unfoldButtonDidClick {
    [self.cellViewModel reloadStreamContent:(NCStreamMessageStatusBottomLoading)];
    [self.cellViewModel requestStreamMessage];
}

#pragma mark -- getter

- (NCReferencedContentView *)referencedContentView{
    if (!_referencedContentView) {
        _referencedContentView = [[NCReferencedContentView alloc] init];
        _referencedContentView.delegate = self;
    }
    return _referencedContentView;
}

- (NCStreamContentView *)streamContentView {
    if (!_streamContentView) {
        _streamContentView = [self.cellViewModel.contentViewModel streamContentView];
        _streamContentView.delegate = self;
        [self.messageContentView addSubview:_streamContentView];
        [self.messageContentView bringSubviewToFront:self.unfoldButton];
        UILongPressGestureRecognizer *longPress =
        [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressedStreamContentView:)];
        [self.messageContentView addGestureRecognizer:longPress];

        UITapGestureRecognizer *tap =
            [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapStreamContentView)];
        tap.numberOfTapsRequired = 1;
        tap.numberOfTouchesRequired = 1;
        [self.messageContentView addGestureRecognizer:tap];
    }
    return _streamContentView;
}

- (NCButton *)unfoldButton {
    if (!_unfoldButton) {
        _unfoldButton = [NCButton new];
        _unfoldButton.titleLabel.font = [[NCChatUIConfig defaultConfig].font fontOfThirdLevel];
        [_unfoldButton addTarget:self action:@selector(unfoldButtonDidClick) forControlEvents:(UIControlEventTouchUpInside)];
        CAGradientLayer *gradientLayer = [CAGradientLayer layer];
        gradientLayer.frame = CGRectMake(0, -50, [NCMessageCellTool getMessageContentViewMaxWidth], 50);
        UIColor *color = NCDynamicColor(@"common_background_color");
        if (color) {
            gradientLayer.colors = @[
                (id)[UIColor clearColor].CGColor,
                (id)color.CGColor];
        } else {
            gradientLayer.colors = @[
                (id)[NCDYCOLOR(0xffffff, 0x111111) colorWithAlphaComponent:0.0].CGColor,
                (id)NCDYCOLOR(0xffffff, 0x111111).CGColor];
        }
      
        gradientLayer.locations = @[@0, @1];
        // Add the fade gradient.
        [_unfoldButton.layer addSublayer:gradientLayer];
        _unfoldButton.hidden = YES;
    }
    return _unfoldButton;
}

- (UIView *)lineView {
    if (!_lineView) {
        _lineView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [NCMessageCellTool getMessageContentViewMaxWidth], 0.5)];
        _lineView.backgroundColor = NCDynamicColor(@"line_background_color");
    }
    return _lineView;
}
@end
