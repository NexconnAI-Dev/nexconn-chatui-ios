//
//  NCAttributedLabel+Edit.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCAttributedLabel+Edit.h"
#import "NCChatUIUtility.h"
#import "NCChatUICommonDefine.h"

@interface NCAttributedLabel ()

@property (nonatomic, assign) NSRange nc_editedSuffixRange;

@end

@implementation NCAttributedLabel (Edit)

#pragma mark - Edited State Support

- (void)edit_setTextWithEditedState:(NSString *)text isEdited:(BOOL)isEdited {
    self.nc_editedSuffixRange = NSMakeRange(NSNotFound, 0);
    if (!text || text.length == 0) {
        [self setText:@"" dataDetectorEnabled:YES];
        return;
    }
    
    if (isEdited) {
        // Append the localized edited marker to the display text.
        NSString *displayText = [NCMessageEditUtil displayTextForOriginalText:text isEdited:YES];
        
        NSRange suffixRange = NSMakeRange(text.length, [NCMessageEditUtil editedSuffix].length);
        if (NSMaxRange(suffixRange) <= displayText.length) {
            self.nc_editedSuffixRange = suffixRange;
        }
        [self setText:displayText dataDetectorEnabled:YES];
    } else {
        // Preserve the original text when the message has not been edited.
        [self setText:text dataDetectorEnabled:YES];
    }
}

@end
