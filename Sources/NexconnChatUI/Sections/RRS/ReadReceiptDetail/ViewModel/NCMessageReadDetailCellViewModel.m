//
//  NCMessageReadDetailCellViewModel.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCMessageReadDetailCellViewModel.h"
#import "NCChatUIUtility.h"
#import "NCChatUIUserInfo.h"

@interface NCMessageReadDetailCellViewModel ()

@property (nonatomic, strong) NCChatUIUserInfo *userInfo;
@property (nonatomic, assign) long long readTime;

@end

@implementation NCMessageReadDetailCellViewModel

- (instancetype)initWithUserInfo:(NCChatUIUserInfo *)userInfo
                        readTime:(long long)readTime {
    self = [super init];
    if (self) {
        _userInfo = userInfo;
        _readTime = readTime;
        _displayReadTime = readTime > 0 ? [NCChatUIUtility convertMessageTime:self.readTime/1000] : @"";
        _cellHeight = 54;
    }
    return self;
}

@end
