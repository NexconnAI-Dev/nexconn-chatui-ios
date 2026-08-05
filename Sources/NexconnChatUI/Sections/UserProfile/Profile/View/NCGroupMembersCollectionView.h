//
//  NCGroupMembersCollectionView.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseCollectionView.h"
#import "NCGroupMembersCollectionViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface NCGroupMembersCollectionView : NCBaseCollectionView

- (void)configViewModel:(NCGroupMembersCollectionViewModel *)viewModel;

@end

NS_ASSUME_NONNULL_END
