//
//  NCProfileSwitchCellViewModel.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCProfileCellViewModel.h"

NS_ASSUME_NONNULL_BEGIN
/// Profile switch cell view model
@interface NCProfileSwitchCellViewModel : NCProfileCellViewModel

/// Name
@property (nonatomic, copy) NSString *title;

/// Whether enabled
@property (nonatomic, assign) BOOL switchOn;

/// Tap callback
@property (nonatomic, copy) void (^switchValueChanged)(BOOL on);

@end

NS_ASSUME_NONNULL_END
