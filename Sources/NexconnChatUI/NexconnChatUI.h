//
//  NexconnChatUI.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <UIKit/UIKit.h>

#if __has_include(<NexconnChatUI/NexconnChatUI.h>)

/// Core classes
#import <NexconnChatUI/NCChatUIErrorCode.h>
#import <NexconnChatUI/NCChatUILog.h>
#import "NCChatUI.h"
#import <NexconnChatUI/NCChatUISendParams.h>

/// Channel list
#import <NexconnChatUI/NCChannelListViewController.h>

/// Channel page
#import <NexconnChatUI/NCChannelViewController.h>
#import <NexconnChatUI/NCImageSlideController.h>

/// Channel list cells
#import <NexconnChatUI/NCChannelListBaseCell.h>
#import <NexconnChatUI/NCChannelListCell.h>
#import <NexconnChatUI/NCChannelModel.h>

/// Message cells
#import <NexconnChatUI/NCFileMessageCell.h>
#import <NexconnChatUI/NCImageMessageCell.h>
#import <NexconnChatUI/NCGIFMessageCell.h>
#import <NexconnChatUI/NCImageMessageProgressView.h>
#import <NexconnChatUI/NCMessageBaseCell.h>
#import <NexconnChatUI/NCMessageCell.h>
#import <NexconnChatUI/NCMessageCellDelegate.h>
#import <NexconnChatUI/NCMessageCellNotificationModel.h>
#import <NexconnChatUI/NCMessageModel.h>
#import <NexconnChatUI/NCTextMessageCell.h>
#import <NexconnChatUI/NCTipMessageCell.h>
#import <NexconnChatUI/NCUnknownMessageCell.h>
#import <NexconnChatUI/NCReferenceMessageCell.h>
#import <NexconnChatUI/NCReferencedContentView.h>
#import <NexconnChatUI/NCReferencingView.h>
#import <NexconnChatUI/NCMessageCellTool.h>
#import <NexconnChatUI/NCHDVoiceMessageCell.h>
#import <NexconnChatUI/NCComplexTextMessageCell.h>
#import <NexconnChatUI/NCStreamMessageCell.h>

/// Utilities
#import <NexconnChatUI/NCChatUIUtility.h>
#import <NexconnChatUI/NCChatUIThemeDefine.h>
#import <NexconnChatUI/NCChatUICommonDefine.h>
#import <NexconnChatUI/NCChatUIConfig.h>
#import <NexconnChatUI/NCChatUIFontConf.h>
#import <NexconnChatUI/NCChatUIMessageConf.h>
#import <NexconnChatUI/NCChatUIConf.h>
/// Others
#import <NexconnChatUI/NCAttributedLabel.h>
#import <NexconnChatUI/NCBaseViewController.h>
#import <NexconnChatUI/NCContentView.h>
#import <NexconnChatUI/NCEmoticonTabSource.h>
#import <NexconnChatUI/NCMessageBubbleTipView.h>
#import <NexconnChatUI/NCTextView.h>
#import <NexconnChatUI/NCTipLabel.h>
#import <NexconnChatUI/NCChatUISDKExtensionModule.h>
#import <NexconnChatUI/NCAlertView.h>
#import <NexconnChatUI/NCActionSheetView.h>

#import <NexconnChatUI/NCBaseTableView.h>
#import <NexconnChatUI/NCBaseTableViewCell.h>
#import <NexconnChatUI/NCBaseCollectionView.h>
#import <NexconnChatUI/NCBaseCollectionViewCell.h>
#import <NexconnChatUI/NCBaseButton.h>
#import <NexconnChatUI/NCBaseImageView.h>
#import <NexconnChatUI/NCBaseNavigationController.h>
#import <NexconnChatUI/NCBaseView.h>
#import <NexconnChatUI/NCBaseLabel.h>

// User and group info
#import <NexconnChatUI/NCChatUIUserInfo.h>
#import <NexconnChatUI/NCChatUIGroup.h>

#import <NexconnChatUI/NCProfileViewController.h>
#import <NexconnChatUI/NCUserProfileViewModel.h>
#import <NexconnChatUI/NCProfileViewModel.h>
#import <NexconnChatUI/NCMyProfileViewModel.h>
#import <NexconnChatUI/NCProfileFooterViewModel.h>
#import <NexconnChatUI/NCGroupProfileViewModel.h>
#import <NexconnChatUI/NCButtonItem.h>
#import <NexconnChatUI/NCProfileCellViewModel.h>
#import <NexconnChatUI/NCProfileCommonCellViewModel.h>
#import <NexconnChatUI/NCGroupProfileMembersCellViewModel.h>
#import <NexconnChatUI/NCGroupMembersCollectionViewModel.h>
#import <NexconnChatUI/NCCollectionViewModelProtocol.h>

#import <NexconnChatUI/NCFriendListViewController.h>
#import <NexconnChatUI/NCFriendListViewModel.h>
#import <NexconnChatUI/NCNavigationItemsViewModel.h>
#import <NexconnChatUI/NCSearchBarViewModel.h>

#import <NexconnChatUI/NCListViewModelProtocol.h>
#import <NexconnChatUI/NCCellViewModelProtocol.h>

#import <NexconnChatUI/NCFriendListCellViewModel.h>
#import <NexconnChatUI/NCFriendListPermanentCellViewModel.h>

#import <NexconnChatUI/NCGroupCreateViewController.h>
#import <NexconnChatUI/NCGroupCreateViewModel.h>
#import <NexconnChatUI/NCSelectUserViewModel.h>
#import <NexconnChatUI/NCSelectUserCellViewModel.h>
#import <NexconnChatUI/NCSelectUserViewController.h>
#import <NexconnChatUI/NCGroupMemberListViewModel.h>
#import <NexconnChatUI/NCGroupMemberCellViewModel.h>
#import <NexconnChatUI/NCRemoveGroupMembersViewModel.h>
#import <NexconnChatUI/NCRemoveGroupMemberCellViewModel.h>
#import <NexconnChatUI/NCGroupMemberListViewController.h>
#import <NexconnChatUI/NCRemoveGroupMembersViewController.h>

#import <NexconnChatUI/NCBaseViewModel.h>
#import <NexconnChatUI/NCBaseCellViewModel.h>

#import <NexconnChatUI/NCApplyFriendListViewModel.h>
#import <NexconnChatUI/NCApplyFriendCellViewModel.h>
#import <NexconnChatUI/NCApplyFriendListViewController.h>
#import <NexconnChatUI/NCApplyFriendOperationCell.h>
#import <NexconnChatUI/NCApplyFriendCell.h>
#import <NexconnChatUI/NCApplyFriendListView.h>
#import <NexconnChatUI/NCApplyFriendSectionItem.h>
#import <NexconnChatUI/NCApplyNaviItemsViewModel.h>
#import <NexconnChatUI/NCFriendListView.h>

#import <NexconnChatUI/NCUserSearchView.h>

#import <NexconnChatUI/NCSearchUserProfileViewModel.h>
#import <NexconnChatUI/NCUserSearchViewModel.h>
#import <NexconnChatUI/NCUserSearchViewController.h>
#import <NexconnChatUI/NCApplyFriendAlertView.h>
#import <NexconnChatUI/NCViewModelAdapterCenter.h>
#import <NexconnChatUI/NCSearchFriendsViewController.h>

#import <NexconnChatUI/NCProfileSwitchCellViewModel.h>

#import <NexconnChatUI/NCUserProfileDefine.h>

#import <NexconnChatUI/NCGroupNoticeViewController.h>
#import <NexconnChatUI/NCGroupNoticeViewModel.h>

#import <NexconnChatUI/NCGroupNotificationViewModel.h>
#import <NexconnChatUI/NCGroupNotificationViewController.h>
#import <NexconnChatUI/NCGroupNotificationCell.h>
#import <NexconnChatUI/NCGroupNotificationCellViewModel.h>
#import <NexconnChatUI/NCMyGroupsViewController.h>
#import <NexconnChatUI/NCMyGroupsViewModel.h>
#import <NexconnChatUI/NCGroupInfoCellViewModel.h>
#import <NexconnChatUI/NCGroupListCell.h>
#import <NexconnChatUI/NCFriendListPermanentCell.h>

#import <NexconnChatUI/NCGroupFollowsViewController.h>
#import <NexconnChatUI/NCGroupFollowsViewModel.h>
#import <NexconnChatUI/NCSelectGroupMemberViewController.h>
#import <NexconnChatUI/NCSelectGroupMemberViewModel.h>
#import <NexconnChatUI/NCGroupManagementViewController.h>
#import <NexconnChatUI/NCGroupManagementViewModel.h>
#import <NexconnChatUI/NCGroupManagerListController.h>
#import <NexconnChatUI/NCGroupManagerListViewModel.h>
#import <NexconnChatUI/NCGroupTransferViewController.h>
#import <NexconnChatUI/NCGroupTransferViewModel.h>
#import <NexconnChatUI/NCSearchGroupsViewModel.h>
#import <NexconnChatUI/NCSearchGroupsViewController.h>
#import <NexconnChatUI/NCMyGroupsView.h>

// RRS
#import <NexconnChatUI/NCMessageReadDetailViewController.h>
#import <NexconnChatUI/NCMessageReadDetailViewConfig.h>
#import <NexconnChatUI/NCMessageReadDetailViewModel.h>
#import <NexconnChatUI/NCMessageReadDetailCellViewModel.h>
#import <NexconnChatUI/NCMessageReadDetailView.h>
#import <NexconnChatUI/NCMessageReadDetailTabView.h>
#import <NexconnChatUI/NCMessageReadDetailDefine.h>

//New Skin
#import <NexconnChatUI/NCChatUITheme.h>
#import <NexconnChatUI/NCChatUIThemeManager.h>
#import <NexconnChatUI/NCMenuItem.h>

#import <NexconnChatUI/NCOnlineStatusView.h>

#import <NexconnChatUI/NCGroupMemberAdditionalCellViewModel.h>
#import <NexconnChatUI/NCGroupMemberAdditionalCell.h>
#import <NexconnChatUI/NCPaddingTableViewCell.h>
#import <NexconnChatUI/NCSizeCalculateLabel.h>
#import <NexconnChatUI/NCSearchBarListView.h>
#import <NexconnChatUI/NCSelectUserView.h>
#import <NexconnChatUI/NCGroupMentionViewModel.h>
#import <NexconnChatUI/NCGroupMentionViewController.h>
#import <NexconnChatUI/NCStackTableViewCell.h>
#else
/// Core classes
#import "NCChatUI.h"
#import "NCChatUISendParams.h"

/// Channel list
#import "NCChannelListViewController.h"

/// Channel page
#import "NCChannelViewController.h"
#import "NCImageSlideController.h"

/// Channel list cells
#import "NCChannelListBaseCell.h"
#import "NCChannelListCell.h"
#import "NCChannelModel.h"

/// Message cells
#import "NCFileMessageCell.h"
#import "NCImageMessageCell.h"
#import "NCGIFMessageCell.h"
#import "NCImageMessageProgressView.h"
#import "NCMessageBaseCell.h"
#import "NCMessageCell.h"
#import "NCMessageCellDelegate.h"
#import "NCMessageCellNotificationModel.h"
#import "NCMessageModel.h"
#import "NCTextMessageCell.h"
#import "NCTipMessageCell.h"
#import "NCUnknownMessageCell.h"
#import "NCReferenceMessageCell.h"
#import "NCReferencedContentView.h"
#import "NCReferencingView.h"
#import "NCMessageCellTool.h"
#import "NCHDVoiceMessageCell.h"
#import "NCComplexTextMessageCell.h"
#import "NCStreamMessageCell.h"


/// Utilities
#import "NCChatUIUtility.h"
#import "NCChatUIThemeDefine.h"
#import "NCChatUICommonDefine.h"
#import "NCChatUIConfig.h"
#import "NCChatUIFontConf.h"
#import "NCChatUIMessageConf.h"
#import "NCChatUIConf.h"
/// Others
#import "NCAttributedLabel.h"
#import "NCBaseViewController.h"
#import "NCContentView.h"
#import "NCEmoticonTabSource.h"
#import "NCMessageBubbleTipView.h"
#import "NCTextView.h"
#import "NCTipLabel.h"
#import "NCChatUISDKExtensionModule.h"
#import "NCAlertView.h"
#import "NCActionSheetView.h"

// View base classes
#import "NCBaseTableView.h"
#import "NCBaseTableViewCell.h"
#import "NCBaseCollectionView.h"
#import "NCBaseCollectionViewCell.h"
#import "NCBaseButton.h"
#import "NCBaseImageView.h"
#import "NCBaseNavigationController.h"
#import "NCBaseView.h"
#import "NCBaseLabel.h"

// User and group info
#import "NCChatUIUserInfo.h"
#import "NCChatUIGroup.h"

#import "NCProfileViewController.h"
#import "NCUserProfileViewModel.h"
#import "NCProfileViewModel.h"
#import "NCMyProfileViewModel.h"
#import "NCProfileFooterViewModel.h"
#import "NCGroupProfileViewModel.h"
#import "NCButtonItem.h"
#import "NCProfileCellViewModel.h"
#import "NCProfileCommonCellViewModel.h"
#import "NCGroupProfileMembersCellViewModel.h"
#import "NCGroupMembersCollectionViewModel.h"
#import "NCCollectionViewModelProtocol.h"

#import "NCFriendListViewController.h"
#import "NCFriendListViewModel.h"
#import "NCNavigationItemsViewModel.h"
#import "NCSearchBarViewModel.h"

#import "NCListViewModelProtocol.h"
#import "NCCellViewModelProtocol.h"

#import "NCFriendListCellViewModel.h"
#import "NCFriendListPermanentCellViewModel.h"

#import "NCGroupCreateViewController.h"
#import "NCGroupCreateViewModel.h"
#import "NCSelectUserViewModel.h"
#import "NCSelectUserCellViewModel.h"
#import "NCSelectUserViewController.h"
#import "NCGroupMemberListViewModel.h"
#import "NCGroupMemberCellViewModel.h"
#import "NCRemoveGroupMembersViewModel.h"
#import "NCRemoveGroupMemberCellViewModel.h"
#import "NCGroupMemberListViewController.h"
#import "NCRemoveGroupMembersViewController.h"

#import "NCBaseViewModel.h"
#import "NCBaseCellViewModel.h"

#import "NCApplyFriendListViewModel.h"
#import "NCApplyFriendCellViewModel.h"
#import "NCApplyFriendListViewController.h"
#import "NCApplyFriendOperationCell.h"
#import "NCApplyFriendCell.h"
#import "NCApplyFriendListView.h"
#import "NCApplyFriendSectionItem.h"
#import "NCApplyNaviItemsViewModel.h"
#import "NCFriendListView.h"

#import "NCUserSearchView.h"

#import "NCSearchUserProfileViewModel.h"
#import "NCUserSearchViewModel.h"
#import "NCUserSearchViewController.h"
#import "NCApplyFriendAlertView.h"
#import "NCViewModelAdapterCenter.h"
#import "NCSearchFriendsViewController.h"

#import "NCProfileSwitchCellViewModel.h"

#import "NCUserProfileDefine.h"


#import "NCGroupNoticeViewController.h"
#import "NCGroupNoticeViewModel.h"

//2024-11-14
#import "NCGroupNotificationViewModel.h"
#import "NCGroupNotificationViewController.h"
#import "NCGroupNotificationCell.h"
#import "NCGroupNotificationCellViewModel.h"
#import "NCMyGroupsViewController.h"
#import "NCMyGroupsViewModel.h"
#import "NCGroupInfoCellViewModel.h"

#import "NCGroupListCell.h"
#import "NCFriendListPermanentCell.h"

#import "NCGroupFollowsViewController.h"
#import "NCGroupFollowsViewModel.h"
#import "NCSelectGroupMemberViewController.h"
#import "NCSelectGroupMemberViewModel.h"
#import "NCGroupManagementViewController.h"
#import "NCGroupManagementViewModel.h"
#import "NCGroupManagerListController.h"
#import "NCGroupManagerListViewModel.h"
#import "NCGroupTransferViewController.h"
#import "NCGroupTransferViewModel.h"
#import "NCSearchGroupsViewModel.h"
#import "NCSearchGroupsViewController.h"
#import "NCMyGroupsView.h"

// RRS
#import "NCMessageReadDetailViewController.h"
#import "NCMessageReadDetailViewConfig.h"
#import "NCMessageReadDetailViewModel.h"
#import "NCMessageReadDetailCellViewModel.h"
#import "NCMessageReadDetailView.h"
#import "NCMessageReadDetailTabView.h"
#import "NCMessageReadDetailDefine.h"

// New Skin
#import "NCChatUITheme.h"
#import "NCChatUIThemeManager.h"
#import "NCChatUIBuiltInThemes.h"
#import "NCMenuItem.h"

#import "NCOnlineStatusView.h"

#import "NCGroupMemberAdditionalCellViewModel.h"
#import "NCGroupMemberAdditionalCell.h"
#import "NCPaddingTableViewCell.h"
#import "NCSizeCalculateLabel.h"
#import "NCSearchBarListView.h"
#import "NCSelectUserView.h"
#import "NCGroupMentionViewModel.h"
#import "NCGroupMentionViewController.h"
#import "NCStackTableViewCell.h"
#endif
