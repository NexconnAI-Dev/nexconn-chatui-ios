//
//  NCSelectDirectoryTableViewCell.m
//  NCChatUIExtension
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCSelectDirectoryTableViewCell.h"
#import "NCChatUICommonDefine.h"
#import "NCChatUIConfig.h"
#import "NCSemanticContext.h"
@implementation NCSelectDirectoryTableViewCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupSelectDirectoryCellView];
        self.contentView.backgroundColor = NCDynamicColor(@"common_background_color");
    }
    return self;
}

- (void)setupSelectDirectoryCellView {
    // Create the two UI elements.

    _directoryImageView = [NCBaseImageView new];
    _directoryImageView.translatesAutoresizingMaskIntoConstraints = NO;
    _directoryImageView.image = NCDynamicImage(@"file_list_folder_img");
    [self.contentView addSubview:_directoryImageView];

    _directoryNameLabel = [NCBaseLabel new];
    _directoryNameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _directoryNameLabel.font = [[NCChatUIConfig defaultConfig].font fontOfSecondLevel];
    _directoryNameLabel.textColor = NCDynamicColor(@"text_primary_color");

    [self.contentView addSubview:_directoryNameLabel];

    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_directoryImageView
                                                                 attribute:NSLayoutAttributeCenterY
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.contentView
                                                                 attribute:NSLayoutAttributeCenterY
                                                                multiplier:1.0f
                                                                  constant:0]];

    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_directoryNameLabel
                                                                 attribute:NSLayoutAttributeCenterY
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.contentView
                                                                 attribute:NSLayoutAttributeCenterY
                                                                multiplier:1.0f
                                                                  constant:0]];

    NSDictionary *views = NSDictionaryOfVariableBindings(_directoryImageView, _directoryNameLabel);

    [self addConstraints:[NSLayoutConstraint
                             constraintsWithVisualFormat:
                                 @"H:|-49-[_directoryImageView(36)]-9-[_directoryNameLabel]-10-|"
                                                 options:kNilOptions
                                                 metrics:nil
                                                   views:views]];

    [self addConstraints:[NSLayoutConstraint
                             constraintsWithVisualFormat:@"V:[_directoryImageView(36)]"
                                                 options:kNilOptions
                                                 metrics:nil
                                                   views:views]];

    [self addConstraints:[NSLayoutConstraint
                             constraintsWithVisualFormat:@"V:[_directoryNameLabel(21)]"
                                                 options:kNilOptions
                                                 metrics:nil
                                                   views:views]];
}
@end
