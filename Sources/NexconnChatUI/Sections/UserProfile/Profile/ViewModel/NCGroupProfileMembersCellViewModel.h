//
//  NCGroupProfileMembersCellViewModel.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCGroupMembersCollectionViewModel.h"
#import "NCProfileCellViewModel.h"
NS_ASSUME_NONNULL_BEGIN
/// Group profile members cell view model
@interface NCGroupProfileMembersCellViewModel : NCProfileCellViewModel

/// Delegate
@property (nonatomic, weak) id<NCGroupMembersCollectionViewModelDelegate> delegate;

/// Creates an `NCGroupProfileMembersCellViewModel` instance
///
/// @param showItemCount The number of items to display
- (instancetype)initWithItemCount:(NSInteger)showItemCount;

// Configure member display viewModel
- (void)configViewModel:(NCGroupMembersCollectionViewModel *)viewModel;

@end

NS_ASSUME_NONNULL_END
