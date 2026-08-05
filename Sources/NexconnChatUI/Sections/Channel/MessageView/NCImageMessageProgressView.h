//
//  NCNumberProgressView.h
//  NCChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <UIKit/UIKit.h>

/// View for image message progress
@interface NCImageMessageProgressView : UIView

/// Label displaying the progress
@property (nonatomic, weak) UILabel *label;

/// Activity indicator view for progress
@property (nonatomic, strong) UIActivityIndicatorView *indicatorView;

/*!
 Update progress

 @param progress Progress value, 0 <= progress <= 100
 */
- (void)updateProgress:(NSInteger)progress;

/// Start the animation
- (void)startAnimating;

/// Stop the animation
- (void)stopAnimating;

@end
