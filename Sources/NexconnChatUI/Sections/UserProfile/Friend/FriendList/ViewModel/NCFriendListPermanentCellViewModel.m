//
//  NCFriendListPermanentCellViewModel.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCFriendListPermanentCellViewModel.h"
#import "NCFriendListPermanentCell.h"
#import "NCChatUICommonDefine.h"

@interface NCFriendListPermanentCellViewModel()
@property (nonatomic, copy) NSString *title;
@property (nonatomic, strong) UIImage *portrait;
@property (nonatomic, copy) NCPermanentCellViewModelBlock touchBlock;
@end

@implementation NCFriendListPermanentCellViewModel

- (instancetype)initWithTitle:(NSString *)title 
                     portrait:(UIImage *)portrait
                   touchBlock:(NCPermanentCellViewModelBlock)touchBlock
{
    self = [super init];
    if (self) {
        self.title = title;
        self.portrait = portrait;
        self.touchBlock = touchBlock;
    }
    return self;
}
+ (void)registerCellForTableView:(UITableView *)tableView {
    [tableView registerClass:[NCFriendListPermanentCell class] forCellReuseIdentifier:NCFriendListPermanentCellIdentifier];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NCFriendListPermanentCell *cell = [tableView dequeueReusableCellWithIdentifier:NCFriendListPermanentCellIdentifier
                                                                      forIndexPath:indexPath];
    cell.labName.text = self.title;
    cell.hideSeparatorLine = self.hideSeparatorLine;
    [cell showPortraitByImage:self.portrait];
    return cell;
}

- (void)itemDidSelectedByViewController:(UIViewController *)vc {
    if (self.touchBlock) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.touchBlock(vc);
        });
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 64;
}
@end
