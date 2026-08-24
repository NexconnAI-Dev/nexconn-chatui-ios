//
//  NCTextPreviewView+Edit.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCAttributedLabel+Edit.h"
#import "NCChatUICommonDefine.h"
#import "NCTextPreviewView+Edit.h"

@interface NCTextPreviewView ()

@property (nonatomic, strong) NCAttributedLabel *label;
@property (nonatomic, weak) id<NCTextPreviewViewDelegate> textPreviewDelegate;
@property (nonatomic, copy) NSString *originalText;

- (instancetype)initWithFrame:(CGRect)frame text:(NSString *)text clientId:(long)clientId;
- (void)showTextPreviewView;

@end

@implementation NCTextPreviewView (Edit)

+ (void)edit_showText:(NSString *)text
             clientId:(long)clientId
               edited:(BOOL)edited
             delegate:(id<NCTextPreviewViewDelegate>)delegate {
    NSString *originalText = text;
    NSString *displayText = [NCMessageEditUtil displayTextForOriginalText:originalText
                                                                 isEdited:edited];
    NCTextPreviewView *textPreviewView =
        [[NCTextPreviewView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)
                                            text:displayText
                                        clientId:clientId];
    textPreviewView.originalText = originalText;
    // Append and style the localized edited marker when needed.
    [textPreviewView.label edit_setTextWithEditedState:originalText isEdited:edited];
    textPreviewView.textPreviewDelegate = delegate;
    [textPreviewView showTextPreviewView];
}

- (NSString *)edit_copyText {
    return self.originalText;
}

@end
