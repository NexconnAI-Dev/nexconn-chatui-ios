//
//  NCPageControl.m
//  NCChatUIExtension
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCPageControl.h"
#import "NCChatUICommonDefine.h"

@interface NCPageControl ()
@property (nonatomic) CGSize size;
@end
@implementation NCPageControl
#pragma mark - Super Methods
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.currentPageIndicatorTintColor = NCDynamicColor(@"text_secondary_color");
        self.pageIndicatorTintColor = NCDynamicColor(@"auxiliary_background_1_color");
        self.hidesForSinglePage = YES;
        self.enabled = NO;
        self.currentPage = 0;
        if([NCChatUIUtility isRTL]) {
            self.semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;
        } else {
            self.semanticContentAttribute = UISemanticContentAttributeForceLeftToRight;
        }
        
    }
    return self;
}
@end
