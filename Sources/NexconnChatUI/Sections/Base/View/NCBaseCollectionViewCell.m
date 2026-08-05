//
//  NCBaseCollectionViewCell.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseCollectionViewCell.h"
#import "NCSemanticContext.h"
@implementation NCBaseCollectionViewCell
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self updateRTLUI];
    }
    return self;
}

- (instancetype)init{
    self = [super init];
    if(self){
        [self updateRTLUI];
    }
    return self;
}

- (void)updateRTLUI{
    if ([NCSemanticContext isRTL]) {
        self.contentView.semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;
    }else{
        self.contentView.semanticContentAttribute = UISemanticContentAttributeForceLeftToRight;
    }
}
@end
