//
//  NCMessageCell+Edit.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCMessageCell.h"
#import "NCCircularLoadingView.h"

NS_ASSUME_NONNULL_BEGIN

/// Editing-state extension for NCMessageCell.
/// Handles state display and management related to message editing.
@interface NCMessageCell (Edit)

#pragma mark - Edit State Management

- (void)edit_showEditStatusIfNeeded;

/// Updates the edit status display.
/// - Parameter editStatus The edit status.
- (void)edit_updateEditStatus:(NCMessageUpdateStatus)editStatus;

/// Hides the edit status.
- (void)edit_hideEditStatus;

/// Updates the edit status bar layout based on the current bubble frame.
- (void)edit_layoutEditStatusViews;

/// The edit status bar height.
+ (CGFloat)edit_editStatusBarHeightWithModel:(NCMessageModel *)model;

@end

NS_ASSUME_NONNULL_END 
