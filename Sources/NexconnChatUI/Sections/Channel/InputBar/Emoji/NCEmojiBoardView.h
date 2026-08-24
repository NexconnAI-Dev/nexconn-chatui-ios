//
//  NCEmojiBoardView.h
//  NCExtensionKit
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCEmoticonTabSource.h"
#import <NexconnChatSDK/NexconnChatSDK.h>
#import <UIKit/UIKit.h>

@class NCPageControl;
@class NCEmojiBoardView;

/*!
 Callback for emoji input
 */
@protocol NCEmojiViewDelegate <NSObject>
@optional

/*!
 Callback for tapping an emoji

 @param emojiView Emoji input view
 @param string    String encoding of the tapped emoji
 */
- (void)didTouchEmojiView:(NCEmojiBoardView *)emojiView touchedEmoji:(NSString *)string;

/*!
 Callback for tapping the send button

 @param emojiView  Emoji input view
 @param sendButton Send button
 */
- (void)didSendButtonEvent:(NCEmojiBoardView *)emojiView sendButton:(UIButton *)sendButton;

@end

/*!
 Emoji input view
 */
@interface NCEmojiBoardView : UIView <UIScrollViewDelegate>

/*!
 Current conversation type
 */
@property (nonatomic, assign) NCChannelType channelType;

/*!
 Current conversation ID
 */
@property (nonatomic, strong) NSString *channelId;

/*!
 Background view for the emoji board
 */
@property (nonatomic, strong) UIScrollView *emojiBackgroundView;

/*!
 Callback for emoji input
 */
@property (nonatomic, weak) id<NCEmojiViewDelegate> delegate;

/*!
 Size of the emoji area
 */
@property (nonatomic, assign, readonly) CGSize contentViewSize;

// Disable system emojis
@property (nonatomic, assign, readonly, getter=isSystemEmojiDisable) BOOL disableDefaultEmoji;
/**
 *  init
 *
 *  @param frame            frame
 *  @param delegate         Entity implementing NCEmojiViewDelegate
 */
- (instancetype)initWithFrame:(CGRect)frame delegate:(id<NCEmojiViewDelegate>)delegate;
/*!
 Load emoji label
 */
- (void)loadLabelView;

/*!
Whether the send button is enabled
 */
- (void)enableSendButton:(BOOL)enableSend;
/**
 *  Add a sticker pack (for standard developer use)
 *
 *  @param viewDataSource Data source delegate for each emoji page; called when swiping requires
 * loading an emoji page — return the page view
 */
- (void)addEmojiTab:(id<NCEmoticonTabSource>)viewDataSource;
/**
 *  Add an extension sticker pack (for third-party sticker vendors)
 *
 *  @param viewDataSource Data source delegate for each emoji page; called when swiping requires
 * loading an emoji page — return the page view
 */
- (void)addExtensionEmojiTab:(id<NCEmoticonTabSource>)viewDataSource;

/**
 *  Reload sticker packs loaded via extensions (this triggers the NCChatUIExtensionModule protocol
 * callback for addEmojiTab; packs added this way will not be reloaded)
 */
- (void)reloadExtensionEmoticonTabSource;

// Disable system emojis
- (void)disableSystemDefaultEmoji;
@end
