//
//  NCMessageCell+Edit.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCChatUICommonDefine.h"
#import "NCChatUIConfig.h"
#import "NCChatUIUtility.h"
#import "NCMessageCell+Edit.h"
#import "NCMessageModel+Edit.h"

@interface NCMessageCell ()

@property (nonatomic, assign) NCMessageUpdateStatus editStatus;

@end

@implementation NCMessageCell (Edit)

#pragma mark - Edit Status Management

- (void)edit_showEditStatusIfNeeded {
    if (!NCChatUIConfigCenter.message.enableEditMessage) {
        return;
    }
    NCMessageUpdateInfo *updateInfo = self.model.updateInfo;
    if (updateInfo && updateInfo.status != NCMessageUpdateStatusSuccess) {
        [self edit_updateEditStatus:updateInfo.status];
    } else {
        [self edit_hideAllEditStatusViews];
    }
}

- (void)edit_updateEditStatus:(NCMessageUpdateStatus)editStatus {
    [self edit_hideAllEditStatusViews];
    self.editStatus = editStatus;
    self.editStatusContentView.hidden = editStatus == NCMessageUpdateStatusSuccess;

    if (self.editStatusContentView.hidden) {
        return;
    }
    switch (editStatus) {
    case NCMessageUpdateStatusSuccess:
        [self edit_showEditStatusSuccess];
        break;
    case NCMessageUpdateStatusUpdating:
        [self edit_showEditStatusUpdating];
        break;
    case NCMessageUpdateStatusFailed:
        [self edit_showEditStatusFailed];
        break;
    }

    // Refresh the edit status layout.
    [self edit_layoutEditStatusViews];
}

- (void)edit_hideEditStatus {
    [self edit_updateEditStatus:NCMessageUpdateStatusSuccess];
}

+ (CGFloat)edit_editStatusBarHeightWithModel:(NCMessageModel *)model {
    if (NCChatUIConfigCenter.message.enableEditMessage && model.updateInfo &&
        model.updateInfo.status != NCMessageUpdateStatusSuccess) {
        return 30.0; // Fixed height for the edit status row.
    }
    return 0.0;
}

#pragma mark - Private Status Display

/// Shows the updating state.
- (void)edit_showEditStatusUpdating {
    self.editStatusLabel.text = NCUILocalizedString(@"message_edit_updating");
    self.editStatusLabel.hidden = NO;
    self.editCircularLoadingView.hidden = NO;
    [self.editCircularLoadingView startAnimating];
}

/// Shows the successful edit state.
- (void)edit_showEditStatusSuccess {
    [self edit_hideAllEditStatusViews];
}

/// Shows the failed edit state.
- (void)edit_showEditStatusFailed {
    self.editRetryButton.hidden = NO;
}

/// Hides all edit status views.
- (void)edit_hideAllEditStatusViews {
    self.editStatusContentView.hidden = YES;
    self.editStatusLabel.hidden = YES;
    self.editRetryButton.hidden = YES;
    self.editCircularLoadingView.hidden = YES;
    [self.editCircularLoadingView stopAnimating];
}

#pragma mark - Layout

- (void)edit_layoutEditStatusViews {
    // Edit status is displayed only for outgoing messages.
    if (self.model.messageDirection != NCMessageDirectionSend) {
        [self edit_hideAllEditStatusViews];
        return;
    }
    CGRect statusFrame = self.baseContentView.bounds;
    statusFrame.size.width = CGRectGetMaxX(self.messageContentView.frame);
    statusFrame.size.height = [[self class] edit_editStatusBarHeightWithModel:self.model];
    statusFrame.origin.y = CGRectGetMaxY(self.messageContentView.frame);
    self.editStatusContentView.frame = statusFrame;
    [self.editStatusContentView removeConstraints:self.editStatusContentView.constraints];

    self.editStatusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.editRetryButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.editCircularLoadingView.translatesAutoresizingMaskIntoConstraints = NO;

    // Prevent the status label from being compressed unnecessarily.
    [self.editStatusLabel setContentHuggingPriority:UILayoutPriorityDefaultHigh
                                            forAxis:UILayoutConstraintAxisHorizontal];
    [self.editStatusLabel setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh
                                                          forAxis:UILayoutConstraintAxisHorizontal];

    NSMutableArray *constraints = [NSMutableArray array];
    [constraints addObjectsFromArray:@[
        [self.editStatusLabel.centerYAnchor
            constraintEqualToAnchor:self.editStatusContentView.centerYAnchor],
        [self.editStatusLabel.trailingAnchor
            constraintEqualToAnchor:self.editStatusContentView.trailingAnchor],

        [self.editCircularLoadingView.centerYAnchor
            constraintEqualToAnchor:self.editStatusLabel.centerYAnchor],
        [self.editCircularLoadingView.trailingAnchor
            constraintEqualToAnchor:self.editStatusLabel.leadingAnchor
                           constant:-5],
        [self.editCircularLoadingView.widthAnchor constraintEqualToConstant:12],
        [self.editCircularLoadingView.heightAnchor constraintEqualToConstant:12],

        [self.editRetryButton.trailingAnchor
            constraintEqualToAnchor:self.editStatusContentView.trailingAnchor
                           constant:0],
        [self.editRetryButton.centerYAnchor
            constraintEqualToAnchor:self.editStatusContentView.centerYAnchor],
    ]];

    [self.editStatusContentView addConstraints:constraints];

    // Apply the new constraints immediately.
    [self setNeedsUpdateConstraints];
    [self updateConstraintsIfNeeded];
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

#pragma mark - Event Handling

/// Handles a tap on the edit retry button.
/// @param sender The retry button.
- (void)edit_didTapEditRetryButton:(UIButton *)sender {
    // Return to the updating state while the retry is processed.
    [self edit_updateEditStatus:NCMessageUpdateStatusUpdating];
    // Forward the retry action to the cell delegate.
    if ([self.delegate respondsToSelector:@selector(edit_didTapEditRetryButton:)]) {
        [self.delegate didTapEditRetryButton:self.model];
    }
}

@end
