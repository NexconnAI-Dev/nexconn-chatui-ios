//
//  NCTextPreviewView.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCTextPreviewView.h"
#import "NCChatUI.h"
#import "NCChatUICommonDefine.h"
#import "NCChatUIUtility.h"
#import "NCMessageCellTool.h"
#import "NCAlertView.h"
#import "NCTextPreviewView+Edit.h"
#import "NCMenuItem.h"

@interface NCTextPreviewView()<NCAttributedLabelDelegate, NCChatUIMessageEventObserver>
@property (nonatomic, strong) NCAttributedLabel *label;
@property (nonatomic, weak) id<NCTextPreviewViewDelegate> textPreviewDelegate;
@property (nonatomic, assign) long clientId;
@property (nonatomic, copy) NSString *originalText;
@end
@implementation NCTextPreviewView
+ (void)showText:(NSString *)text clientId:(long)clientId delegate:(nonnull id<NCTextPreviewViewDelegate>)delegate{
    NCTextPreviewView *textPreviewView = [[NCTextPreviewView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT) text:text clientId:clientId];
    textPreviewView.textPreviewDelegate = delegate;
    [textPreviewView showTextPreviewView];
}

- (instancetype)initWithFrame:(CGRect)frame text:(NSString *)text  clientId:(long)clientId {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = NCDynamicColor(@"common_background_color");
        CGFloat textHeight = [NCChatUIUtility getTextDrawingSize:text font:[UIFont systemFontOfSize:20] constrainedSize:CGSizeMake(SCREEN_WIDTH-20, MAXFLOAT)].height;
        textHeight = ceilf(textHeight)+20;
        self.contentSize = CGSizeMake(SCREEN_WIDTH, textHeight);
        if (textHeight <= SCREEN_HEIGHT) {
            self.scrollEnabled = NO;
        }else{
            self.scrollEnabled = YES;
        }
        
        self.label.text = text;
        [self addSubview:self.label];
        
        self.clientId = clientId;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapCurrentView)];
        [self addGestureRecognizer:tap];
        
        UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
        [self.label addGestureRecognizer:longPressGesture];
        
        [self registerNotificationCenter];
    }
    return self;
}

- (void)dealloc {
    [[NCChatUI shared] removeMessageEventObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Notification
- (void)registerNotificationCenter {
    [[NCChatUI shared] addMessageEventObserver:self];
}

- (void)onDeletedMessagesForAll:(NSArray<NCMessage *> *)messages {
    if (messages.count == 0) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        BOOL isCurrentMessageDeletedForAll = NO;
        for (NCMessage *message in messages) {
            if (message.clientId == self.clientId) {
                isCurrentMessageDeletedForAll = YES;
                break;
            }
        }
        // Dismiss the preview when the referenced text being viewed is deleted for everyone.
        if (isCurrentMessageDeletedForAll) {
            [NCAlertView showAlertController:nil message:NCUILocalizedString(@"message_delete_for_all_alert") actionTitles:nil cancelTitle:NCUILocalizedString(@"confirm") confirmTitle:nil preferredStyle:UIAlertControllerStyleAlert actionsBlock:nil cancelBlock:^{
                [self didTapCurrentView];
            } confirmBlock:nil inViewController:nil];
        }
    });
}

#pragma mark - NCAttributedLabelDelegate
- (void)attributedLabel:(NCAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url {
    [self didTapCurrentView];
    if ([self.textPreviewDelegate respondsToSelector:@selector(didTapUrlInMessageCell:model:)]) {
        [self.textPreviewDelegate didTapUrlInMessageCell:url.absoluteString model:nil];
    }
}

- (void)attributedLabel:(NCAttributedLabel *)label didSelectLinkWithPhoneNumber:(NSString *)phoneNumber {
    [self didTapCurrentView];
    NSString *number = [NCMessageCellTool phoneURLStringWithPhoneNumber:phoneNumber];
    if (!number) {
        return;
    }
    if ([self.textPreviewDelegate respondsToSelector:@selector(didTapPhoneNumberInMessageCell:model:)]) {
        [self.textPreviewDelegate didTapPhoneNumberInMessageCell:number model:nil];
    }
}

- (void)attributedLabel:(NCAttributedLabel *)label didTapLabel:(NSString *)content {
    [self didTapCurrentView];
}

#pragma mark - Privite

- (void)showTextPreviewView {
    UIWindow *window = self.window ?: [NCChatUIUtility getWindowForView:nil];
    [window addSubview:self];
}

- (void)didTapCurrentView{
    [self removeFromSuperview];
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) { // Handle the gesture only when it begins.
        UILabel *label = (UILabel *)gestureRecognizer.view;
        if (label && [label isKindOfClass:[UILabel class]]) {
            // Make the label the first responder.
            [label becomeFirstResponder];
            
            // Create and display the menu.
            UIMenuItem *copyItem = [[UIMenuItem alloc] initWithTitle:NCUILocalizedString(@"copy")
                                                              action:@selector(copyAction)];
            [[UIMenuController sharedMenuController] setMenuItems:[NSArray arrayWithObject:copyItem]];
            // Set the target frame and host view.
            [[UIMenuController sharedMenuController] setTargetRect:label.frame inView:self];
            // Show the menu.
            [[UIMenuController sharedMenuController] setMenuVisible:YES animated:YES];
        }
    }
}

// Handles the Copy menu action.
- (void)copyAction {
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    NSString *labelText = self.label.text;
    NSString *copyText = [self edit_copyText];
    if (copyText.length > 0 && ![copyText isEqualToString:labelText]) {
        pasteboard.string = copyText;
    } else {
        pasteboard.string = labelText;
    }
    [self.label resignFirstResponder];
}

- (UILabel *)label{
    if (!_label) {
        CGFloat textY = self.contentSize.height < SCREEN_HEIGHT ? (SCREEN_HEIGHT - self.contentSize.height )/2 : 0;
        _label = [[NCAttributedLabel alloc] initWithFrame:CGRectMake(10, textY, SCREEN_WIDTH-20, self.contentSize.height)];
        _label.numberOfLines = 0;
        _label.textColor = NCDynamicColor(@"text_primary_color");
        _label.font = [UIFont systemFontOfSize:20];
        _label.textAlignment = NSTextAlignmentCenter;
        _label.attributeDictionary = [NCMessageCellTool getTextLinkOrPhoneNumberAttributeDictionary:NCMessageDirectionReceive
                                                                                     linkColorKey:@"primary_color"];
        _label.highlightedAttributeDictionary = [NCMessageCellTool getTextLinkOrPhoneNumberAttributeDictionary:NCMessageDirectionReceive
                                                                                                  linkColorKey:@"primary_color"];
        _label.delegate = self;
        _label.userInteractionEnabled = YES;
    }
    return _label;
}
@end
