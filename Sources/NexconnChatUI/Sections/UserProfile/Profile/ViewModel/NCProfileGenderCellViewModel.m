//
//  NCProfileGenderCellViewModel.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCProfileGenderCellViewModel.h"
#import "NCProfileGenderCell.h"
#import "NCChatUICommonDefine.h"

@interface NCProfileGenderCellViewModel ()
@property (nonatomic, weak) UITableView *tableView;
@property (nonatomic, strong) NSIndexPath *indexPath;
@end

@implementation NCProfileGenderCellViewModel
+ (instancetype)cellViewModel:(NCChatUIUserGender)gender {
    NCProfileGenderCellViewModel *viewModel = [NCProfileGenderCellViewModel new];
    viewModel.gender = gender;
    return viewModel;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    self.tableView = tableView;
    self.indexPath = indexPath;
    NCProfileGenderCell *cell = [tableView dequeueReusableCellWithIdentifier:NCProfileGenderCellIdentifier forIndexPath:indexPath];
    cell.titleLabel.text = [self getGenderString:self.gender];
    cell.selectView.hidden = !self.isSelect;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.hideSeparatorLine = self.hideSeparatorLine;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return NCUserManagementCellHeight;
}

- (void)reloadData {
    NCProfileGenderCell *cell = [self.tableView cellForRowAtIndexPath:self.indexPath];
    if ([cell isKindOfClass:[NCProfileGenderCell class]]) {
        cell.selectView.hidden = !self.isSelect;
    }
}

#pragma mark -- getter

- (NSString *)getGenderString:(NCChatUIUserGender)gender {
    switch (gender) {
        case NCChatUIUserGenderMale:
            return NCUILocalizedString(@"male");
        case NCChatUIUserGenderFemale:
            return NCUILocalizedString(@"female");
        default:
            break;
    }
    return NCUILocalizedString(@"unknown");
}

@end
