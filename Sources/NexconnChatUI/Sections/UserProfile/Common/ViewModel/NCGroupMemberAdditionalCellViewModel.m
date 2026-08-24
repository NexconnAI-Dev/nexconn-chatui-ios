//
//  NCGroupMemberAdditionalCellViewModel.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCGroupMemberAdditionalCellViewModel.h"
#import "NCGroupMemberAdditionalCell.h"

@interface NCGroupMemberAdditionalCellViewModel ()

@end

@implementation NCGroupMemberAdditionalCellViewModel

- (instancetype)initWithTitle:(NSString *)title portrait:(UIImage *)portrait {
    self = [super init];
    if (self) {
        self.title = title;
        self.portrait = portrait;
    }
    return self;
}

+ (void)registerCellForTableView:(UITableView *)tableView {
    [tableView registerClass:[NCGroupMemberAdditionalCell class]
        forCellReuseIdentifier:NCGroupMemberAdditionalCellIdentifier];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NCGroupMemberAdditionalCell *cell =
        [tableView dequeueReusableCellWithIdentifier:NCGroupMemberAdditionalCellIdentifier
                                        forIndexPath:indexPath];
    cell.labName.text = self.title;
    cell.portraitImageView.image = self.portrait;
    cell.hideSeparatorLine = self.hideSeparatorLine;
    return cell;
}

- (void)itemDidSelectedByViewController:(UIViewController *)vc {
}

@end
