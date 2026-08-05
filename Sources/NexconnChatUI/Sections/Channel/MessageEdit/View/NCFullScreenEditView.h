//
//  NCFullScreenEditView.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NCChatUIUserInfo.h"
#import "NCEditInputBarControl.h"

NS_ASSUME_NONNULL_BEGIN

@class NCFullScreenEditView;

@protocol NCFullScreenEditViewDelegate <NSObject>

/// Collapse from full-screen edit mode
- (void)fullScreenEditViewCollapse:(NCFullScreenEditView *)fullScreenEditView;

/// Edit confirmed
/// @param fullScreenEditView The full-screen edit view
/// @param text The text in the edit input bar
- (void)fullScreenEditView:(NCFullScreenEditView *)fullScreenEditView didConfirmWithText:(NSString *)text;

/// Edit cancelled
- (void)fullScreenEditViewCancel:(NCFullScreenEditView *)fullScreenEditView;

/// Show user selector for the edit input control
- (void)fullScreenEditView:(NCFullScreenEditView *)fullScreenEditView
          showUserSelector:(void (^)(NCChatUIUserInfo *selectedUser))selectedBlock
                    cancel:(void (^)(void))cancelBlock;

@end

@interface NCFullScreenEditView : UIView

/// Target ID
@property (nonatomic, copy) NSString *channelId;

/// Delegate
@property (nonatomic, weak) id<NCFullScreenEditViewDelegate> delegate;

/// Edit input bar control
@property (nonatomic, strong) NCEditInputBarControl *editInputBarControl;

/// Whether mention functionality is enabled
@property (nonatomic, assign) BOOL isMentionedEnabled;

/// Show the full-screen edit view
/// @param config The edit configuration
/// @param animated Whether to animate
- (void)showWithConfig:(NCEditInputBarConfig *)config animation:(BOOL)animated;

/// Hide the full-screen edit view
/// @param animated Whether to animate
/// @param completion Completion callback
- (void)hideWithAnimation:(BOOL)animated completion:(void(^_Nullable)(void))completion;

@end

NS_ASSUME_NONNULL_END
