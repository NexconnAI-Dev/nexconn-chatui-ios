//
//  NCReferencingView.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseButton.h"
#import "NCBaseLabel.h"
#import "NCBaseView.h"
#import "NCMessageModel.h"
#import <UIKit/UIKit.h>
@class NCReferencingView;

@protocol NCReferencingViewDelegate <NSObject>
@optional
- (void)didTapReferencingView:(NCMessageModel *)messageModel;

- (void)dismissReferencingView:(NCReferencingView *)referencingView;

@end

@interface NCReferencingView : NCBaseView

/// Close reference button
@property (nonatomic, strong) NCBaseButton *dismissButton;

/// Referenced message sender name label
@property (nonatomic, strong) NCBaseLabel *nameLabel;

/// Referenced message content text label
@property (nonatomic, strong) NCBaseLabel *textLabel;

/// Referenced message model
@property (nonatomic, strong) NCMessageModel *referModel;
/// Reference delegate
@property (nonatomic, weak) id<NCReferencingViewDelegate> delegate;
/// Initializes the referencing view
- (instancetype)initWithModel:(NCMessageModel *)model inView:(UIView *)view;

/// The Y origin of the current view
- (void)setOffsetY:(CGFloat)offsetY;
@end
