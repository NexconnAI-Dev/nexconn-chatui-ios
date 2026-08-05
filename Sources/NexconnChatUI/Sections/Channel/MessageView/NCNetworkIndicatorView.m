//
//  NCNetworkIndicatorView.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCNetworkIndicatorView.h"
#import "NCChatUICommonDefine.h"
#import "NCChatUIConfig.h"
@interface NCNetworkIndicatorView ()
@property (nonatomic, strong) UILabel *networkUnreachableDescriptionLabel;
@end

@implementation NCNetworkIndicatorView
- (instancetype)initWithText:(NSString *)text {
    self = [super init];
    if (self) {
        self.networkUnreachableImageView = [[NCBaseImageView alloc] init];
        self.networkUnreachableImageView.image = NCDynamicImage(@"network_unreachable_img");
        self.networkUnreachableDescriptionLabel = [[UILabel alloc] init];
        self.networkUnreachableDescriptionLabel.textColor = NCDynamicColor(@"text_primary_color");
        self.networkUnreachableDescriptionLabel.font = [[NCChatUIConfig defaultConfig].font fontOfFourthLevel];
        self.networkUnreachableDescriptionLabel.text = text;
        self.networkUnreachableDescriptionLabel.backgroundColor = [UIColor clearColor];

        [self addSubview:self.networkUnreachableImageView];
        [self addSubview:self.networkUnreachableDescriptionLabel];

        // self.translatesAutoresizingMaskIntoConstraints = NO;
        self.networkUnreachableImageView.translatesAutoresizingMaskIntoConstraints = NO;
        self.networkUnreachableDescriptionLabel.translatesAutoresizingMaskIntoConstraints = NO;

        // set autoLayout
        NSDictionary *bindingViews = NSDictionaryOfVariableBindings(_networkUnreachableImageView,
                                                                    _networkUnreachableDescriptionLabel);

        [self addConstraints:[NSLayoutConstraint
                                 constraintsWithVisualFormat:@"H:|-19-[_networkUnreachableImageView(24)]-12-[_"
                                                             @"networkUnreachableDescriptionLabel]"
                                                     options:0
                                                     metrics:nil
                                                       views:bindingViews]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_networkUnreachableImageView(24)]"
                                                                     options:0
                                                                     metrics:nil
                                                                       views:bindingViews]];

        [self addConstraint:[NSLayoutConstraint constraintWithItem:_networkUnreachableDescriptionLabel
                                                         attribute:NSLayoutAttributeCenterY
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self
                                                         attribute:NSLayoutAttributeCenterY
                                                        multiplier:1.0f
                                                          constant:0]];

        [self addConstraint:[NSLayoutConstraint constraintWithItem:_networkUnreachableImageView
                                                         attribute:NSLayoutAttributeCenterY
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self
                                                         attribute:NSLayoutAttributeCenterY
                                                        multiplier:1.0f
                                                          constant:0]];
    }
    return self;
}

- (void)setText:(NSString *)text{
    self.networkUnreachableDescriptionLabel.text = text;
}
@end
