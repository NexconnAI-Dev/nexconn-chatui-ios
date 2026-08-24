//
//  NCSelectFilesTableViewCell.m
//  NCChatUIExtension
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCSelectFilesTableViewCell.h"
#import "NCChatUICommonDefine.h"
#import "NCChatUIConfig.h"
#import "NCSemanticContext.h"
@implementation NCSelectFilesTableViewCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupSelectFilesCellView];
        self.contentView.backgroundColor = NCDynamicColor(@"common_background_color");
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    if (selected) {
        _selectedImageView.image = NCDynamicImage(@"channel_msg_cell_select_img");
    } else {
        _selectedImageView.image = NCDynamicImage(@"channel_msg_cell_unselect_img");
    }
}

- (void)setupSelectFilesCellView {
    // Create the three UI elements.
    _selectedImageView = [NCBaseImageView new];
    _selectedImageView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:_selectedImageView];

    _fileIconImageView = [NCBaseImageView new];
    _fileIconImageView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:_fileIconImageView];

    _fileNameLabel = [NCBaseLabel new];
    _fileNameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _fileNameLabel.font = [[NCChatUIConfig defaultConfig].font fontOfSecondLevel];
    _fileNameLabel.textColor = NCDynamicColor(@"text_primary_color");
    _fileNameLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    [self.contentView addSubview:_fileNameLabel];

    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_selectedImageView
                                                                 attribute:NSLayoutAttributeCenterY
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.contentView
                                                                 attribute:NSLayoutAttributeCenterY
                                                                multiplier:1.0f
                                                                  constant:0]];

    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_fileIconImageView
                                                                 attribute:NSLayoutAttributeCenterY
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.contentView
                                                                 attribute:NSLayoutAttributeCenterY
                                                                multiplier:1.0f
                                                                  constant:0]];

    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_fileNameLabel
                                                                 attribute:NSLayoutAttributeCenterY
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.contentView
                                                                 attribute:NSLayoutAttributeCenterY
                                                                multiplier:1.0f
                                                                  constant:0]];

    NSDictionary *views =
        NSDictionaryOfVariableBindings(_selectedImageView, _fileNameLabel, _fileIconImageView);

    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:
                                                 @"H:|-10-[_selectedImageView(20)]-17-[_"
                                                 @"fileIconImageView(36)]-10-[_fileNameLabel]-10-|"
                                                                 options:kNilOptions
                                                                 metrics:nil
                                                                   views:views]];

    [self
        addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_selectedImageView(20)]"
                                                               options:kNilOptions
                                                               metrics:nil
                                                                 views:views]];

    [self
        addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_fileIconImageView(36)]"
                                                               options:kNilOptions
                                                               metrics:nil
                                                                 views:views]];

    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_fileNameLabel(21)]"
                                                                 options:kNilOptions
                                                                 metrics:nil
                                                                   views:views]];
}

@end
