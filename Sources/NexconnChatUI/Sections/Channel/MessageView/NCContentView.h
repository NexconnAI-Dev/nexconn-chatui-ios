//
//  NCContentView.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseView.h"
#import <UIKit/UIKit.h>
/// View for message content
@interface NCContentView : NCBaseView

@property (nonatomic, assign) CGSize contentSize;

/*!
 Register a callback for frame changes

 @param eventBlock Callback for frame changes
 */
- (void)registerFrameChangedEvent:(void (^)(CGRect frame))eventBlock;

/*!
 Register a callback for size changes

 @param eventBlock Callback for size changes
 */
- (void)registerSizeChangedEvent:(void (^)(CGSize contentSize))eventBlock;
@end
