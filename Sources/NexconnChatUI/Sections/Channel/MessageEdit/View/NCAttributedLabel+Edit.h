//
//  NCAttributedLabel+Edit.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCAttributedLabel.h"
#import "NCMessageEditUtil.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Edited-state extension for NCAttributedLabel.
 * Adds unified edited-state display support to NCAttributedLabel.
 */
@interface NCAttributedLabel (Edit)

#pragma mark - Edited State Support

/// Sets text content with edited-state display.
/// @param text Original text content.
/// @param isEdited Whether the text is in the edited state.
- (void)edit_setTextWithEditedState:(NSString *)text isEdited:(BOOL)isEdited;

@end

NS_ASSUME_NONNULL_END 
