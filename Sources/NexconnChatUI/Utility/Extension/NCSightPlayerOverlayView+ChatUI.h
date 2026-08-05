//
//  NCSightPlayerOverlayView+ChatUI.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#ifndef NCSightPlayerOverlayView_ChatUI_h
#define NCSightPlayerOverlayView_ChatUI_h

#if __has_include("NCSightPlayerOverlayView.h")
#import "NCSightPlayerOverlayView.h"
#else
@interface NCSightPlayerOverlayView : UIView
@property (nonatomic, strong) UILabel *currentTimeLab;
@property (nonatomic, strong) UILabel *durationTimeLabel;
@property (nonatomic, strong) UIButton *playBtn;
@property (nonatomic, strong) UISlider *slider;
@property (nonatomic, strong) UIButton *centerPlayBtn;
@end
#endif

#endif /* NCSightPlayerOverlayView_ChatUI_h */
