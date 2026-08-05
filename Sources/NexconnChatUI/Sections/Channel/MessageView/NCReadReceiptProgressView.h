//
//  NCReadReceiptProgressView.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Circular read receipt progress view for displaying message read progress.
/// Fills clockwise from the 12 o'clock position with padding between the fill area and the border.
@interface NCReadReceiptProgressView : UIView

/// Current progress (0.0 ~ 1.0)
@property (nonatomic, assign) CGFloat progress;

/// Border color (defaults to #16D258 green)
@property (nonatomic, strong) UIColor *borderColor;

/// Fill color (defaults to #16D258, same as the border)
@property (nonatomic, strong) UIColor *fillColor;

/// Inner padding between the fill area and the circular border (defaults to 2.0px)
@property (nonatomic, assign) CGFloat innerPadding;

/// Border line width (defaults to 1.17px)
@property (nonatomic, assign) CGFloat borderWidth;

@end

NS_ASSUME_NONNULL_END
