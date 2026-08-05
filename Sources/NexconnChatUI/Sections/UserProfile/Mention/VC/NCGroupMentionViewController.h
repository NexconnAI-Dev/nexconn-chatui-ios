//
//  NCGroupMentionViewController.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseViewController.h"
#import "NCGroupMentionViewModel.h"
NS_ASSUME_NONNULL_BEGIN

@interface NCGroupMentionViewController : NCBaseViewController

- (instancetype)initWithViewModel:(NCGroupMentionViewModel *)viewModel;
@end

NS_ASSUME_NONNULL_END
