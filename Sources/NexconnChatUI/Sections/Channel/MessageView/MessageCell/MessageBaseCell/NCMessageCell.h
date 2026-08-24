//
//  NCMessageCell.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseButton.h"
#import "NCBaseImageView.h"
#import "NCButton.h"
#import "NCChatUIThemeDefine.h"
#import "NCContentView.h"
#import "NCMessageBaseCell.h"
#import "NCMessageCellDelegate.h"
#import "NCReadReceiptProgressView.h"
#define HeadAndContentSpacing 8
#define PortraitViewEdgeSpace 12 // Distance between avatar and screen edge
#define NameAndContentSpace 2
#define NameHeight 14
@class NCImageView;
@class NCCircularLoadingView;

/*!
 Message cell class for display

  Message cells that need to display user info and content can inherit from this class.
 For example: NCTextMessageCell, NCImageMessageCell, etc.
 Inherit from this class if you need to display custom messages.
 */
@interface NCMessageCell : NCMessageBaseCell

/*!
Avatar of the message sender
*/
@property (nonatomic, strong) NCImageView *portraitImageView;

/*!
 Username of the message sender
 */
@property (nonatomic, strong) UILabel *nicknameLabel;

/*!
 View for message content
 */
@property (nonatomic, strong) NCContentView *messageContentView;

/*!
 Background view of the message
 */
@property (nonatomic, strong) NCBaseImageView *bubbleBackgroundView;

/*!
 View for displaying send status

  Contains the messageFailedStatusView subview.
 */
@property (nonatomic, strong) UIView *statusContentView;

/*!
 View for displaying send failure status
 */
@property (nonatomic, strong) NCButton *messageFailedStatusView;

/// View for displaying the message edit status, including updating and update-failed states
@property (nonatomic, strong) UIView *editStatusContentView;

/// Label for message edit status
@property (nonatomic, strong) UILabel *editStatusLabel;

/// Button displayed when message edit fails
@property (nonatomic, strong) UIButton *editRetryButton;

@property (nonatomic, strong) NCCircularLoadingView *editCircularLoadingView;

/*!
 Message sending indicator view
 */
@property (nonatomic, strong) UIActivityIndicatorView *messageActivityIndicatorView;

/*!
 Shape of the displayed user avatar
 */
@property (nonatomic, assign, setter=setPortraitStyle:) NCUserAvatarStyle portraitStyle;

/*!
 Button indicating read receipt status

  Only displayed in group conversations
 */
@property (nonatomic, strong) NCBaseButton *receiptView;

/*!
 Read receipt progress view (V5)
 Displays group message read progress
 */
@property (strong, nonatomic) NCReadReceiptProgressView *receiptProgressView;

/*!
 Whether to display the avatar

 */
@property (nonatomic, assign) BOOL showPortrait;

@property (nonatomic, weak, readonly) UICollectionView *hostCollectionView;
/*!
 Set the data model of the current message cell

 @param model Data model of the message cell
 */
- (void)setDataModel:(NCMessageModel *)model;

/*!
 Update message send status

 @param model Data model of the message cell
 */
- (void)updateStatusContentView:(NCMessageModel *)model;

/*!
 Whether to show the message bubble background view

@param show Data model of the message cell
*/
- (void)showBubbleBackgroundView:(BOOL)show;

/*!
 Get the default message bubble background image

 @return Message bubble background image
 */
- (UIImage *)getDefaultMessageCellBackgroundImage;

/*!
Callback for tapping the messageContentView
*/
- (void)didTapMessageContentView;

@end
