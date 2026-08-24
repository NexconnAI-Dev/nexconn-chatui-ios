//
//  NCFriendListCell.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCFriendListCell.h"
#import "NCChatUICommonDefine.h"
#import "NCImageView.h"
NSString *const NCFriendListCellIdentifier = @"NCFriendListCellIdentifier";

@interface NCFriendListCell ()
@property (nonatomic, strong) UIView *line;
@end

@implementation NCFriendListCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setupView {
    [super setupView];
    self.line = [UIView new];
    self.line.backgroundColor = NCDynamicColor(@"line_background_color");
    ;
    //    [self.contentView addSubview:self.line];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat width = self.contentView.bounds.size.width;
    CGFloat height = self.contentView.bounds.size.height;
    self.line.frame = CGRectMake(CGRectGetMaxX(self.portraitImageView.frame), height - 1,
                                 width - CGRectGetMaxX(self.portraitImageView.frame), 1);
}

- (void)showPortrait:(NSString *)url {
    if (url.length) {
        [self.portraitImageView setImageURL:[NSURL URLWithString:url]];
    } else {
        [self.portraitImageView setImage:NCDynamicImage(@"channel-list_cell_portrait_msg_img")];
    }
}

@end
