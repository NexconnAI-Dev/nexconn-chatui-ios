//
//  NCGroupProfileMembersCell.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCGroupMembersCollectionView.h"
#import "NCPaddingTableViewCell.h"

UIKIT_EXTERN NSString *_Nonnull const NCGroupProfileMembersCellIdentifier;

#define NCGroupProfileMembersCellTextTopSpace 9
#define NCGroupProfileMembersCellTextBottomSpace (NCGroupProfileMembersCellTextTopSpace * 2)

NS_ASSUME_NONNULL_BEGIN

@interface NCGroupProfileMembersCell : NCPaddingTableViewCell

@property (nonatomic, strong) NCGroupMembersCollectionView *membersView;

@end

NS_ASSUME_NONNULL_END
