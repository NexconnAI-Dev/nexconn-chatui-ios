//
//  NCVoiceRecorder.h
//  NCChatUIExtension
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol NCVoiceRecorderDelegate;

@interface NCVoiceRecorder : NSObject

+ (NCVoiceRecorder *)defaultVoiceRecorder;

+ (NCVoiceRecorder *)hqVoiceRecorder;

@property (nonatomic, readonly) BOOL isRecording;

- (BOOL)startRecordWithObserver:(id<NCVoiceRecorderDelegate>)observer;

- (BOOL)cancelRecord;

- (void)stopRecord:(void (^)(NSData *wavData, NSTimeInterval secs))compeletion;

- (CGFloat)updateMeters;

@end

@protocol NCVoiceRecorderDelegate <NSObject>

- (void)NCVoiceAudioRecorderDidFinishRecording:(BOOL)success;
- (void)NCVoiceAudioRecorderEncodeErrorDidOccur:(NSError *)error;

@end
