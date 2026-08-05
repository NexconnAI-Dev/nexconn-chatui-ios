//
//  NCButtonItemModel.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCButtonItem.h"

@implementation NCButtonItem
+ (instancetype)itemWithTitle:(NSString *)title
                   titleColor:(UIColor *)titleColor
              backgroundColor:(UIColor *)backgroundColor {
    NCButtonItem *item = [NCButtonItem new];
    item.title = title;
    item.titleColor = titleColor;
    item.backgroundColor = backgroundColor;
    return item;
}

@end
