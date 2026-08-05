//
//  NCSightCollectionView.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCSightCollectionView.h"

@implementation NCSightCollectionView

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    CGPoint point = [gestureRecognizer locationInView:self];
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    CGRect rect = CGRectMake(0, screenSize.height - 54, self.contentSize.width, 54);
    if (CGRectContainsPoint(rect, point)) {
        return NO;
    }
    return YES;
}

@end
