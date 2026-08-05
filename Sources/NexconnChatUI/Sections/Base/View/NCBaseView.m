//
//  NCBaseView.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseView.h"
#import "NCSemanticContext.h"

NSInteger NCUserManagementViewPadding = 16;
@implementation NCBaseView
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self updateRTLUI];
        [self setupView];
        [self setupConstraints];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder{
    self = [super initWithCoder:coder];
    if(self){
        [self updateRTLUI];
        [self setupView];
        [self setupConstraints];
    }
    return self;
}

- (void)updateRTLUI{
    if ([NCSemanticContext isRTL]) {
        self.semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;
    }else{
        self.semanticContentAttribute = UISemanticContentAttributeForceLeftToRight;
    }
}

- (void)setupView {
    
}

- (void)setupConstraints {
    
}
@end
