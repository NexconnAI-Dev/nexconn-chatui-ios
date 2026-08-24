//
//  NCTextPreviewView.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCAttributedLabel.h"
#import "NCBaseScrollView.h"
#import "NCMessageModel.h"
#import <UIKit/UIKit.h>
@protocol NCTextPreviewViewDelegate;

@interface NCTextPreviewView : NCBaseScrollView

+ (void)showText:(NSString *)text
        clientId:(long)clientId
        delegate:(id<NCTextPreviewViewDelegate>)delegate;

@end

@protocol NCTextPreviewViewDelegate <NSObject>
@optional
/*!
 Callback for tapping a URL in a cell.

 - Parameter url:   The tapped URL.
 - Parameter model: The message cell data model.

  Tapping a URL in a cell invokes this callback and does not trigger didTapMessageCell:.
 */
- (void)didTapUrlInMessageCell:(NSString *)url model:(NCMessageModel *)model;

/*!
 Callback for tapping a phone number in a cell.

 - Parameter phoneNumber: The tapped phone number.
 - Parameter model:       The message cell data model.

  Tapping a phone number in a cell invokes this callback and does not trigger didTapMessageCell:.
 */
- (void)didTapPhoneNumberInMessageCell:(NSString *)phoneNumber model:(NCMessageModel *)model;
@end
