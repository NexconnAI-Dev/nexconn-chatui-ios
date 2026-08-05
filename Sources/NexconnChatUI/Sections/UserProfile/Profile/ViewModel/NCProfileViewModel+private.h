//
//  NCProfileViewModel+private.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCProfileViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface NCProfileViewModel ()

@property (nonatomic, strong) NSArray <NSArray <NCProfileCellViewModel*> *> *profileList;

- (void)configFooterViewModel:(NCProfileFooterViewModel *)viewModel;

@end

NS_ASSUME_NONNULL_END
