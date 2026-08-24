//
//  NCGroupListCell.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCGroupListCell.h"
#import "NCChatUICommonDefine.h"
#import "NCImageView.h"
NSString *const NCGroupListCellIdentifier = @"NCGroupListCellIdentifier";

@implementation NCGroupListCell

- (void)showPortrait:(NSString *)url {
    if (url.length) {
        [self.portraitImageView setImageURL:[NSURL URLWithString:url]];
    } else {
        [self.portraitImageView setImage:NCDynamicImage(@"channel-list_cell_group_portrait_img")];
    }
}
@end
