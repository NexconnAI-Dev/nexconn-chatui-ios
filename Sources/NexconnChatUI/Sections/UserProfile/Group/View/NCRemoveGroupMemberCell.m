//
//  NCRemoveGroupMemberCell.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCRemoveGroupMemberCell.h"
#import "NCChatUICommonDefine.h"
NSString *const NCRemoveGroupMemberCellIdentifier = @"NCRemoveGroupMemberCellIdentifier";

#define NCSelectUserCellRoleTrailingSpace 16

@implementation NCRemoveGroupMemberCell

- (void)setupView {
    [super setupView];
    [self.paddingContainerView addSubview:self.roleLabel];
}

- (void)setupConstraints {
    [super setupConstraints];
    [self appendViewAtEnd:self.roleLabel];
}

- (UILabel *)roleLabel {
    if (!_roleLabel) {
        _roleLabel = [[UILabel alloc] init];
        _roleLabel.font = [UIFont systemFontOfSize:14];
        _roleLabel.textColor = NCDynamicColor(@"text_secondary_color");
        _roleLabel.textAlignment = NSTextAlignmentRight;
        _roleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [_roleLabel setContentHuggingPriority:UILayoutPriorityRequired
                                      forAxis:UILayoutConstraintAxisHorizontal];
    }
    return _roleLabel;
}
@end
