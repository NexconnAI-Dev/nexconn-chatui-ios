//
//  NCRemoveGroupMemberCell.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCSelectUserCell.h"

UIKIT_EXTERN NSString  * _Nonnull const NCRemoveGroupMemberCellIdentifier;


NS_ASSUME_NONNULL_BEGIN

@interface NCRemoveGroupMemberCell : NCSelectUserCell

@property (nonatomic, strong) UILabel *roleLabel;

@end

NS_ASSUME_NONNULL_END
