//
//  NCSightPreviewView.h
//  NCChatUIExtension
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

@protocol NCSightPreviewViewDelegate <NSObject>

- (void)tappedToFocusAtPoint:(CGPoint)point;

@end

/**
 Video capture preview view.
 */
@interface NCSightPreviewView : UIView

/**
 Video capture preview layer.
 */
@property (nonatomic, readonly) AVCaptureVideoPreviewLayer *previewLayer;

/**
 Preview view delegate.
 */
@property (nonatomic, weak) id<NCSightPreviewViewDelegate> delegate;

/**
 Shows the focus box animation at the specified point.

 @param point Center point of the focus box.
 */
- (void)showFocusBoxAnimationAtPoint:(CGPoint)point;

@end
