//
//  NCTipLabel.h
//  iOS-IMKit
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCAttributedLabel.h"
#import <UIKit/UIKit.h>

/*!
 Gray tip label
 */
@interface NCTipLabel : NCAttributedLabel

/*!
 Edge insets
 */
@property (nonatomic, assign) UIEdgeInsets marginInsets;

/*!
 Initialize a gray tip label object

 @return Gray tip label object
 */
+ (instancetype)greyTipLabel;

@end
