//
//  NCBaseTableView.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseTableView.h"
#import "NCSemanticContext.h"

@implementation NCBaseTableView
- (instancetype)initWithFrame:(CGRect)frame style:(UITableViewStyle)style {
    self = [super initWithFrame:frame style:style];
    if (self) {
        if ([NCSemanticContext isRTL]) {
            self.semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;
        } else {
            self.semanticContentAttribute = UISemanticContentAttributeForceLeftToRight;
        }
    }
    return self;
}

@end
