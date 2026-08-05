//
//  NCPhotoPreviewCollectionViewFlowLayout.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCPhotoPreviewCollectionViewFlowLayout.h"
#import "NCChatUIUtility.h"

@implementation NCPhotoPreviewCollectionViewFlowLayout

- (BOOL)flipsHorizontallyInOppositeLayoutDirection {
    return [NCChatUIUtility isRTL];
}

//- (UIUserInterfaceLayoutDirection)effectiveUserInterfaceLayoutDirection {
//
//    if ([NCChatUIUtility isRTL]) {
//        return UIUserInterfaceLayoutDirectionRightToLeft;
//    }
//    return UIUserInterfaceLayoutDirectionLeftToRight;
//}

@end
