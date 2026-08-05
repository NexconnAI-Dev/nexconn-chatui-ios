//
//  NCGroupInfoCellViewModel.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCGroupInfoCellViewModel.h"
#import "NCGroupListCell.h"
#import "NCChannelViewController.h"
#import "NCChatUICommonDefine.h"

@interface NCGroupInfoCellViewModel()
@property (nonatomic, copy) NSString *keyword;
@end

@implementation NCGroupInfoCellViewModel

- (instancetype)initWithGroupInfo:(NCGroupInfo *)groupInfo
                          keyword:(NSString *)keyword
{
    self = [super init];
    if (self) {
        self.groupInfo = groupInfo;
        self.keyword = keyword;
    }
    return self;
}

/// Registers the cell class.
+ (void)registerCellForTableView:(UITableView *)tableView {
    [tableView registerClass:[NCGroupListCell class] forCellReuseIdentifier:NCGroupListCellIdentifier];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NCGroupListCell *cell = [tableView dequeueReusableCellWithIdentifier:NCGroupListCellIdentifier
                                                                      forIndexPath:indexPath];
    cell.hideSeparatorLine = self.hideSeparatorLine;
    if (self.groupInfo) {
        [cell showPortrait:self.groupInfo.avatarUrl];
        cell.labName.attributedText =  [self attributedString:self.groupInfo.groupName withKeyword:self.keyword];;
    }
    
    return cell;
}

- (void)itemDidSelectedByViewController:(UIViewController *)vc {
    NCChannelViewController *conversationVC = [[NCChannelViewController alloc] initWithChannelType:NCChannelTypeGroup channelId:self.groupInfo.groupId];
    [vc.navigationController pushViewController:conversationVC animated:YES];
}

-(NSMutableAttributedString*)attributedString:(NSString *)string
                                  withKeyword:(NSString *)keyword
{
    if (string == nil) {
        return [[NSMutableAttributedString alloc] initWithString:@""];
    }
    // Create the cell.
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:string];
   
    if (keyword.length > 0) {
        UIColor *color = NCDynamicColor(@"primary_color");
        NSRange range = [[string uppercaseString] rangeOfString:[keyword uppercaseString]];
        [attributedString addAttribute:NSForegroundColorAttributeName value:color range:range];
    }
  
    return attributedString;
}
@end
