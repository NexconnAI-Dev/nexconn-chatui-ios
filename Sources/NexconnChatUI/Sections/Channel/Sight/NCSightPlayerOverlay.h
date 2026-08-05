//
//  NCSightPlayerOverlay.h
//  NCChatUIExtension
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@protocol NCSightPlayerOverlay <NSObject>

/**
 Bottom play button.
 */
@property (nonatomic, strong, readonly) UIButton *playBtn;

/**
 Top-left close button.
 */
@property (nonatomic, strong, readonly) UIButton *closeBtn;

/**
 Center play button.
 */
@property (nonatomic, strong, readonly) UIButton *centerPlayBtn;

/**
 Top-right extra action button.
 */
@property (nonatomic, strong, readonly) UIButton *extraButton;
@end
NS_ASSUME_NONNULL_END
