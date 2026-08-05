//
//  NCMenuItem.m
//  PopMenu
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCMenuItem.h"

@implementation NCMenuItem

- (instancetype)initWithTitle:(NSString *)title image:(UIImage *)image action:(SEL)action {
    self = [super initWithTitle:title action:action];
    if (self) {
        _image = image;
    }
    return self;
}

+ (instancetype)menuItemWithItem:(UIMenuItem *)item {
    return [[self alloc] initWithTitle:item.title image:nil action:item.action];
}
@end

