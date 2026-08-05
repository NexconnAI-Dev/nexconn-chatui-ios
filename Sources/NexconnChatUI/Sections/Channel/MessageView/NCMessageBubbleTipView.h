//
//  NCMessageBubbleTipView.h
//  NCChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <UIKit/UIKit.h>

/// Badge position
typedef NS_ENUM(NSInteger, NCMessageBubbleTipViewAlignment) {
    /// Top-left
    NC_MESSAGE_BUBBLE_TIP_VIEW_ALIGNMENT_TOP_LEFT,
    /// Top-right
    NC_MESSAGE_BUBBLE_TIP_VIEW_ALIGNMENT_TOP_RIGHT,
    /// Top-center
    NC_MESSAGE_BUBBLE_TIP_VIEW_ALIGNMENT_TOP_CENTER,
    /// Center-left
    NC_MESSAGE_BUBBLE_TIP_VIEW_ALIGNMENT_CENTER_LEFT,
    /// Center-right
    NC_MESSAGE_BUBBLE_TIP_VIEW_ALIGNMENT_CENTER_RIGHT,
    /// Bottom-left
    NC_MESSAGE_BUBBLE_TIP_VIEW_ALIGNMENT_BOTTOM_LEFT,
    /// Bottom-right
    NC_MESSAGE_BUBBLE_TIP_VIEW_ALIGNMENT_BOTTOM_RIGHT,
    /// Bottom-center
    NC_MESSAGE_BUBBLE_TIP_VIEW_ALIGNMENT_BOTTOM_CENTER,
    /// Center
    NC_MESSAGE_BUBBLE_TIP_VIEW_ALIGNMENT_CENTER
};

/// View for unread message badge
@interface NCMessageBubbleTipView : UIView

/// Badge display text
@property (nonatomic, copy) NSString *bubbleTipText;

/*!
 Position of the badge

  Defaults to NC_MESSAGE_BUBBLE_TIP_VIEW_ALIGNMENT_TOP_RIGHT (top-right).
 */
@property (nonatomic, assign) NCMessageBubbleTipViewAlignment bubbleTipAlignment;

/// Badge text color
@property (nonatomic, strong) UIColor *bubbleTipTextColor;

/// Badge text shadow offset
@property (nonatomic, assign) CGSize bubbleTipTextShadowOffset;

/// Badge text shadow color
@property (nonatomic, strong) UIColor *bubbleTipTextShadowColor;

/// Badge text font
@property (nonatomic, strong) UIFont *bubbleTipTextFont;

/// Badge background color
@property (nonatomic, strong) UIColor *bubbleTipBackgroundColor;

/// Badge view position offset
@property (nonatomic, assign) CGPoint bubbleTipPositionAdjustment;

/// Frame of the view the badge is attached to
@property (nonatomic, assign) CGRect frameToPositionInRelationWith;

/*!
 Whether the badge shows a number

  If NO, a red dot is shown without a number.
 */
@property (nonatomic) BOOL isShowNotificationNumber;

/*!
 Initialize the badge view

 @param parentView  Parent view the badge is attached to
 @param alignment   Position of the badge
 @return Badge view object
 */
- (instancetype)initWithParentView:(UIView *)parentView alignment:(NCMessageBubbleTipViewAlignment)alignment;

/*!
 Set the badge value

 @param msgCount Badge value
 */
- (void)setBubbleTipNumber:(int)msgCount;

@end
