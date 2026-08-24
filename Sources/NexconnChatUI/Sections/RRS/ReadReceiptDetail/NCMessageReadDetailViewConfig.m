//
//  NCMessageReadDetailViewConfig.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCMessageReadDetailViewConfig.h"
#import "NCChatUICommonDefine.h"

@implementation NCMessageReadDetailViewConfig

- (instancetype)init {
    self = [super init];
    if (self) {
        // Apply default values.
        _tabHeight = 42.0;
        _pageSize = 100;
    }
    return self;
}

- (void)setPageSize:(NSInteger)pageSize {
    _pageSize = MIN(MAX(pageSize, 1), 100);
}

@end
