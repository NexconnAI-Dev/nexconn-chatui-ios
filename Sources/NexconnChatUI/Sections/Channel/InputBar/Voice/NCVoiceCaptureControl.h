//
//  NCVoiceCaptureControl.h
//  NCChatUIExtension
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <NexconnChatSDK/NexconnChatSDK.h>
#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>
@protocol NCVoiceCaptureControlDelegate <NSObject>
- (void)NCVoiceCaptureControlTimeout:(double)duration;

@optional
- (void)NCVoiceCaptureControlTimeUpdate:(double)duration;
@end

@interface NCVoiceCaptureControl : UIView

@property (nonatomic, weak) id<NCVoiceCaptureControlDelegate> delegate;

@property (nonatomic, readonly, copy) NSData *stopRecord;

@property (nonatomic, readonly, assign) double duration;

// Customer service channels do not recognize high-quality voice messages, so NCChannelType is
// needed for the check.
- (instancetype)initWithFrame:(CGRect)frame channelType:(NCChannelType)type;

- (void)startRecord;

- (void)cancelRecord;

- (void)showCancelView;

- (void)hideCancelView;

- (void)showViewWithErrorMsg:(NSString *)errorMsg;

- (void)stopTimer;
@end
