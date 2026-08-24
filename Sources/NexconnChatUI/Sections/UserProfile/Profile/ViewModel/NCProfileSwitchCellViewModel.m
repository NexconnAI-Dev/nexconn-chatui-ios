//
//  NCProfileSwitchCellViewModel.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCProfileSwitchCellViewModel.h"
#import "NCProfileCommonSwitchCell.h"

@interface NCProfileSwitchCellViewModel () <NCProfileCommonSwitchCellDelegate>

@end

@implementation NCProfileSwitchCellViewModel

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NCProfileCommonSwitchCell *cell =
        [tableView dequeueReusableCellWithIdentifier:NCProfileCommonSwitchCellIdentifier
                                        forIndexPath:indexPath];
    cell.titleLabel.text = self.title;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.arrowView.hidden = YES;
    cell.switchView.on = self.switchOn;
    cell.delegate = self;
    cell.hideSeparatorLine = self.hideSeparatorLine;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return NCUserManagementCellHeight;
}

#pragma mark-- NCProfileCommonSwitchCellDelegate

- (void)switchValueChanged:(nonnull UISwitch *)switchView {
    if (self.switchValueChanged) {
        self.switchValueChanged(switchView.on);
    }
}

@end
