//
//  NCBaseTableViewCell.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseTableViewCell.h"

@implementation NCBaseTableViewCell
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if(self){
        [self setupView];
        [self setupConstraints];
    }
    return self;
}

- (void)setupView {
    
}

- (void)setupConstraints {
    
}

@end
