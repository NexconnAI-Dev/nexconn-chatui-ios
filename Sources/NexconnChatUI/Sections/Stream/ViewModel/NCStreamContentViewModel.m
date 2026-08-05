//
//  NCStreamContentViewModel.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCStreamContentViewModel.h"
#import "NCStreamContentView.h"
#import "NCChatUICommonDefine.h"
#import "NCMessageCellTool.h"
extern CGFloat const ncTextLeadingX;
@implementation NCStreamContentViewModel

+ (NSString *)failedInfo {
    return NCUILocalizedString(@"stream_failed_with_auto_request");
}

- (instancetype)init {
    if (self = [super init]) {

    }
    return self;
}

- (NCStreamContentView *)streamContentView {
    return nil;
}

- (CGFloat)contentMaxWidth {
    return [NCMessageCellTool getMessageContentViewMaxWidth] - ncTextLeadingX*2;
}

#pragma mark -- NCStreamViewModelProtocol

- (CGSize)calculateContentSize {
    return CGSizeMake(0, 0);
}

- (void)streamContentDidUpdate:(nonnull NSString *)content {
    if ([self.content isEqualToString:content]) {
        return;
    }
    self.content = content;
}

@end
