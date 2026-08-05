//
//  NCGroupListCell.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCFriendListPermanentCell.h"

NS_ASSUME_NONNULL_BEGIN
UIKIT_EXTERN NSString  * const NCGroupListCellIdentifier;

@interface NCGroupListCell : NCFriendListPermanentCell
- (void)showPortrait:(NSString *)url;
@end

NS_ASSUME_NONNULL_END
