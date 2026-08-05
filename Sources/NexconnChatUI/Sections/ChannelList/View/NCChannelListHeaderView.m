//
//  NCChannelListHeaderView.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCChannelListHeaderView.h"
#import "NCChatUICommonDefine.h"
#import "NCChatUIUtility.h"
#import "NCChatUIConfig.h"
#import "NCChannelModel+Display.h"

@implementation NCChannelListHeaderView
#pragma mark - Life Cycle
- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initSubviewsLayout];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initSubviewsLayout];
    }
    return self;
}

- (void)initSubviewsLayout {
    self.translatesAutoresizingMaskIntoConstraints = NO;
    self.backgroundColor = [UIColor clearColor];

    [self addSubview:self.backgroundView];
    [self.backgroundView addSubview:self.headerImageView];
    self.headerImageStyle = NCChatUIConfigCenter.ui.globalConversationAvatarStyle;

    
    if ([NCChatUIUtility isRTL]) {
        self.bubbleView =
        [[NCMessageBubbleTipView alloc] initWithParentView:self
                                                 alignment:NC_MESSAGE_BUBBLE_TIP_VIEW_ALIGNMENT_TOP_LEFT];
    } else {
        self.bubbleView =
        [[NCMessageBubbleTipView alloc] initWithParentView:self
                                                 alignment:NC_MESSAGE_BUBBLE_TIP_VIEW_ALIGNMENT_TOP_RIGHT];
    }
    self.bubbleView.bubbleTipBackgroundColor =  NCDynamicColor(@"hint_color");
    
    [self addSubviewConstraints];
}

- (void)setHeaderImageStyle:(NCUserAvatarStyle)headerImageStyle {
    _headerImageStyle = headerImageStyle;
    if (_headerImageStyle == NC_USER_AVATAR_RECTANGLE) {
        self.headerImageView.layer.cornerRadius = [NCChatUIConfigCenter.ui portraitImageViewCornerRadius];
    } else if (_headerImageStyle == NC_USER_AVATAR_CYCLE) {
        self.headerImageView.layer.cornerRadius = [NCChatUIConfigCenter.ui globalConversationPortraitSize].height / 2;
    }
}

- (void)updateBubbleUnreadNumber:(int)unreadNumber {
    [self.bubbleView setBubbleTipNumber:unreadNumber];
}

- (void)resetDefaultLayout:(NCChannelModel *)reuseModel {
    UIImage *placeholderImage = nil;
    UIImage *cachedImage = [self getCachedImage:reuseModel];
    if (cachedImage) {
        placeholderImage = cachedImage;
    } else {
        placeholderImage = [NCChatUIUtility defaultConversationHeaderImage:reuseModel];
    }
    [self.headerImageView setPlaceholderImage:placeholderImage];
    self.bubbleView.isShowNotificationNumber = YES;
}

- (UIImage *)getCachedImage:(NCChannelModel *)reuseModel {
    NSString *portraitUri = [reuseModel conversationCachedPortraitUri];

    if (portraitUri.length > 0) {
        NSData *cachedImageData =
            [[NCImageLoader sharedImageLoader] getImageDataForURL:[NSURL URLWithString:portraitUri]];
        if (cachedImageData) {
            return [UIImage imageWithData:cachedImageData];
            ;
        }
    }
    return nil;
}

#pragma mark - Constraints
- (void)addSubviewConstraints {
    [self addConstraints:[NSLayoutConstraint
                             constraintsWithVisualFormat:@"V:|[_backgroundView]|"
                                                 options:0
                                                 metrics:nil
                                                   views:NSDictionaryOfVariableBindings(_backgroundView)]];
    [self addConstraints:[NSLayoutConstraint
                             constraintsWithVisualFormat:@"H:|[_backgroundView]|"
                                                 options:0
                                                 metrics:nil
                                                   views:NSDictionaryOfVariableBindings(_backgroundView)]];

    [self.backgroundView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_headerImageView]|"
                                                                                options:0
                                                                                metrics:nil
                                                                                  views:NSDictionaryOfVariableBindings(
                                                                                            _headerImageView)]];
    [self.backgroundView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_headerImageView]|"
                                                                                options:0
                                                                                metrics:nil
                                                                                  views:NSDictionaryOfVariableBindings(
                                                                                            _headerImageView)]];
}

#pragma mark - Getter & Setter
- (UIView *)backgroundView {
    if(!_backgroundView) {
        _backgroundView = [[NCImageView alloc] initWithFrame:self.frame];
        _backgroundView.translatesAutoresizingMaskIntoConstraints = NO;
        _backgroundView.backgroundColor = [UIColor clearColor];
    }
    return _backgroundView;
}

- (NCImageView *)headerImageView {
    if(!_headerImageView) {
        _headerImageView = [[NCImageView alloc] initWithFrame:self.frame];
        _headerImageView.translatesAutoresizingMaskIntoConstraints = NO;
        _headerImageView.layer.cornerRadius = 4;
        _headerImageView.layer.masksToBounds = YES;
        _headerImageView.image = nil;
        _headerImageView.placeholderImage = NCDynamicImage(@"channel-list_cell_portrait_img");
        _headerImageView.userInteractionEnabled = YES;
    }
    return _headerImageView;
}
@end
