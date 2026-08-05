//
//  NCMessageCellDelegate.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCMessageModel.h"
#import <UIKit/UIKit.h>

/*!
 Callback for message cell taps
 */
@protocol NCMessageCellDelegate <NSObject>
@optional

/*!
 Callback for tapping cell content

 @param model Data model of the message cell
 */
- (void)didTapMessageCell:(NCMessageModel *)model;

/*!
 Callback for tapping a URL in the cell

 @param url   Tapped URL
 @param model Data model of the message cell

  Tapping a URL in the cell triggers this callback instead of didTapMessageCell:.
 */
- (void)didTapUrlInMessageCell:(NSString *)url model:(NCMessageModel *)model;

/*!
 Callback for tapping a phone number in the cell

 @param phoneNumber Tapped phone number
 @param model       Data model of the message cell

  Tapping a phone number in the cell triggers this callback instead of didTapMessageCell:.
 */
- (void)didTapPhoneNumberInMessageCell:(NSString *)phoneNumber model:(NCMessageModel *)model;

/*!
 Callback for tapping a user avatar in the cell

 @param userId User ID of the avatar
 */
- (void)didTapCellPortrait:(NSString *)userId;

/*!
 Callback for long-pressing a user avatar in the cell

 @param userId User ID of the avatar
 */
- (void)didLongPressCellPortrait:(NSString *)userId;

/*!
 Callback for long-pressing cell content

 @param model Data model of the message cell
 @param view  View in the long-pressed area
 */
- (void)didLongTouchMessageCell:(NCMessageModel *)model inView:(UIView *)view;

/*!
 Callback for tapping the send failure indicator

 @param model Data model of the message cell
 */
- (void)didTapmessageFailedStatusViewForResend:(NCMessageModel *)model;

/// Callback when the read receipt status view is tapped
/// @param model The message cell data model
/// @note Only supported in group channels
- (void)didTapReceiptStatusView:(NCMessageModel *)model;

/*!
 Callback for tapping the cancel-send button on a media message

 @param model Data model of the media message cell

  Only supports canceling file message sends
 */
- (void)didTapCancelUploadButton:(NCMessageModel *)model;

/*!
 Callback for tapping the quoted content preview in a reference message

 @param model Data model of the reference message cell
*/
- (void)didTapReferencedContentView:(NCMessageModel *)model;

/// Callback when the retry button is tapped after a message edit failure
/// @param model The message cell data model
- (void)didTapEditRetryButton:(NCMessageModel *)model;

@end
