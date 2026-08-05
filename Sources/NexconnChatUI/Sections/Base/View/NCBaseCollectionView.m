//
//  NCBaseCollectionView.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseCollectionView.h"
#import "NCSemanticContext.h"
@implementation NCBaseCollectionView
- (instancetype)initWithFrame:(CGRect)frame collectionViewLayout:(UICollectionViewLayout *)layout{
    self = [super initWithFrame:frame collectionViewLayout:layout];
    if(self){
        if ([NCSemanticContext isRTL]) {
            self.semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;
        }else{
            self.semanticContentAttribute = UISemanticContentAttributeForceLeftToRight;
        }
    }
    return self;
}


@end
