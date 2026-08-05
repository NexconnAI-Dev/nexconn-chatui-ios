//
//  NCProfileCommonSwitchCell.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCProfileCommonSwitchCell.h"
#import "NCChatUICommonDefine.h"


NSString  * const NCProfileCommonSwitchCellIdentifier = @"NCProfileCommonSwitchCellIdentifier";

@implementation NCProfileCommonSwitchCell

- (void)setupView {
    [super setupView];
    [self.contentStackView addArrangedSubview:self.titleLabel];
    [self.contentStackView addArrangedSubview:self.switchView];
    [self.contentStackView addArrangedSubview:self.arrowView];
}

- (void)switchValueChanged:(UISwitch *)sender {
    [self.delegate switchValueChanged:self.switchView];
}

#pragma mark - getter

- (UISwitch *)switchView {
    if (!_switchView) {
        _switchView = [[UISwitch alloc] init];
        _switchView.onTintColor = NCDynamicColor(@"success_color");
        [_switchView addTarget:self action:@selector(switchValueChanged:) forControlEvents:UIControlEventValueChanged];
        _switchView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _switchView;
}
@end
