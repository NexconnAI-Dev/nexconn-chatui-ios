//
//  NCBaseLabel.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseLabel.h"
#import "NCSemanticContext.h"

@implementation NCBaseLabel
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

- (instancetype)initWithCoder:(NSCoder *)coder{
    self = [super initWithCoder:coder];
    if(self){
        [self updateRTLUI];
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
@end
