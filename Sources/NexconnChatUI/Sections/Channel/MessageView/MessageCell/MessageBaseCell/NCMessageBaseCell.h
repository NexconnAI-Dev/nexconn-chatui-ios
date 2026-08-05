//
//  NCMessageBaseCell.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCMessageCellDelegate.h"
#import "NCMessageCellNotificationModel.h"
#import "NCMessageModel.h"
#import "NCTipLabel.h"
#import <UIKit/UIKit.h>
#import "NCBaseCollectionViewCell.h"

/*!
 Notification for message send status updates
 */
UIKIT_EXTERN NSString *const KNotificationMessageBaseCellUpdateSendingStatus;

#define TIME_LABEL_HEIGHT 16
#define TIME_LABEL_AND_BASE_CONTENT_VIEW_SPACE 12
#define TIME_LABEL_TOP 8
#define BASE_CONTENT_VIEW_BOTTOM 20 //20pt padding at the bottom of each cell

/*!
 Base class for message cells

  The base message cell class contains all essential information for message cells.
 Message cell subclasses fall into two categories based on avatar visibility:
 tip cells that hide user info (e.g. NCTipMessageCell, NCUnknownMessageCell),
 and content cells that show user info (e.g. NCMessageCell and its subclasses).
 */
@interface NCMessageBaseCell : NCBaseCollectionViewCell

#pragma mark - overwrite

/*!
 Custom message cell size

 @param model               Message model to display
 @param collectionViewWidth Width of the collection view containing the cell
 @param extraHeight         Height outside the cell content area

 @return Custom message cell size

  When using custom messages, this method must be implemented to return the cell size.
 Here extraHeight is the additional height the cell needs based on UI context (e.g. timestamp, username).
 Typically the cell height should be the content height plus extraHeight.
 */
+ (CGSize)sizeForMessageModel:(NCMessageModel *)model
      withCollectionViewWidth:(CGFloat)collectionViewWidth
         referenceExtraHeight:(CGFloat)extraHeight;

/*!
 Message cell tap callback
 */
@property (nonatomic, weak) id<NCMessageCellDelegate> delegate;

/*!
 Label for displaying the timestamp
 */
@property (strong, nonatomic) NCTipLabel *messageTimeLabel;

/*!
 Data model of the message cell
 */
@property (strong, nonatomic) NCMessageModel *model;

/*!
 View displayed in the cell
 */
@property (strong, nonatomic) UIView *baseContentView;

/*!
 Direction of the message
 */
@property (nonatomic) NCMessageDirection messageDirection;

/*!
 Whether the timestamp label is visible
 */
@property (nonatomic, readonly) BOOL isDisplayMessageTime;

/*!
 Whether selection is allowed
 */
@property (nonatomic) BOOL allowsSelection;

/*!
 Initialize message cell

 @param frame Display frame
 @return Base message cell object
 */
- (instancetype)initWithFrame:(CGRect)frame;

/*!
 Set the data model of the current message cell

 @param model Data model of the message cell
 */
- (void)setDataModel:(NCMessageModel *)model;

/*!
 Listener callback for message send status updates

 @param notification Notification for message send status updates
 */
- (void)messageCellUpdateSendingStatusEvent:(NSNotification *)notification;

@end
