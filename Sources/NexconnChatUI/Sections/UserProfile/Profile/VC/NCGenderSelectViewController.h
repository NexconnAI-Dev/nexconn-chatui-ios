//
//  NCGenderSelectViewController.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseViewController.h"
#import "NCProfileGenderViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface NCGenderSelectViewController : NCBaseViewController

- (instancetype)initWithViewModel:(NCProfileGenderViewModel *)viewModel;

@end

NS_ASSUME_NONNULL_END
