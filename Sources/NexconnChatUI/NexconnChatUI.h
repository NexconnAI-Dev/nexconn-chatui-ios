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
#import "NCChatUI.h"
#import <NexconnChatUI/NCChatUIErrorCode.h>
#import <NexconnChatUI/NCChatUILog.h>
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
#import <NexconnChatUI/NCComplexTextMessageCell.h>
#import <NexconnChatUI/NCFileMessageCell.h>
#import <NexconnChatUI/NCGIFMessageCell.h>
#import <NexconnChatUI/NCHDVoiceMessageCell.h>
#import <NexconnChatUI/NCImageMessageCell.h>
#import <NexconnChatUI/NCImageMessageProgressView.h>
#import <NexconnChatUI/NCMessageBaseCell.h>
#import <NexconnChatUI/NCMessageCell.h>
#import <NexconnChatUI/NCMessageCellDelegate.h>
#import <NexconnChatUI/NCMessageCellNotificationModel.h>
#import <NexconnChatUI/NCMessageCellTool.h>
#import <NexconnChatUI/NCMessageModel.h>
#import <NexconnChatUI/NCReferenceMessageCell.h>
#import <NexconnChatUI/NCReferencedContentView.h>
#import <NexconnChatUI/NCReferencingView.h>
#import <NexconnChatUI/NCStreamMessageCell.h>
#import <NexconnChatUI/NCTextMessageCell.h>
#import <NexconnChatUI/NCTipMessageCell.h>
#import <NexconnChatUI/NCUnknownMessageCell.h>

/// Utilities
#import <NexconnChatUI/NCChatUICommonDefine.h>
#import <NexconnChatUI/NCChatUIConf.h>
#import <NexconnChatUI/NCChatUIConfig.h>
#import <NexconnChatUI/NCChatUIFontConf.h>
#import <NexconnChatUI/NCChatUIMessageConf.h>
#import <NexconnChatUI/NCChatUIThemeDefine.h>
#import <NexconnChatUI/NCChatUIUtility.h>
/// Others
#import <NexconnChatUI/NCActionSheetView.h>
#import <NexconnChatUI/NCAlertView.h>
#import <NexconnChatUI/NCAttributedLabel.h>
#import <NexconnChatUI/NCBaseViewController.h>
#import <NexconnChatUI/NCChatUISDKExtensionModule.h>
#import <NexconnChatUI/NCContentView.h>
#import <NexconnChatUI/NCEmoticonTabSource.h>
#import <NexconnChatUI/NCMessageBubbleTipView.h>
#import <NexconnChatUI/NCTextView.h>
#import <NexconnChatUI/NCTipLabel.h>

#import <NexconnChatUI/NCBaseButton.h>
#import <NexconnChatUI/NCBaseCollectionView.h>
#import <NexconnChatUI/NCBaseCollectionViewCell.h>
#import <NexconnChatUI/NCBaseImageView.h>
#import <NexconnChatUI/NCBaseLabel.h>
#import <NexconnChatUI/NCBaseNavigationController.h>
#import <NexconnChatUI/NCBaseTableView.h>
#import <NexconnChatUI/NCBaseTableViewCell.h>
#import <NexconnChatUI/NCBaseView.h>

// User and group info
#import <NexconnChatUI/NCChatUIGroup.h>
#import <NexconnChatUI/NCChatUIUserInfo.h>

#import <NexconnChatUI/NCButtonItem.h>
#import <NexconnChatUI/NCCollectionViewModelProtocol.h>
#import <NexconnChatUI/NCGroupMembersCollectionViewModel.h>
#import <NexconnChatUI/NCGroupProfileMembersCellViewModel.h>
#import <NexconnChatUI/NCGroupProfileViewModel.h>
#import <NexconnChatUI/NCMyProfileViewModel.h>
#import <NexconnChatUI/NCProfileCellViewModel.h>
#import <NexconnChatUI/NCProfileCommonCellViewModel.h>
#import <NexconnChatUI/NCProfileFooterViewModel.h>
#import <NexconnChatUI/NCProfileViewController.h>
#import <NexconnChatUI/NCProfileViewModel.h>
#import <NexconnChatUI/NCUserProfileViewModel.h>

#import <NexconnChatUI/NCFriendListViewController.h>
#import <NexconnChatUI/NCFriendListViewModel.h>
#import <NexconnChatUI/NCNavigationItemsViewModel.h>
#import <NexconnChatUI/NCSearchBarViewModel.h>

#import <NexconnChatUI/NCCellViewModelProtocol.h>
#import <NexconnChatUI/NCListViewModelProtocol.h>

#import <NexconnChatUI/NCFriendListCellViewModel.h>
#import <NexconnChatUI/NCFriendListPermanentCellViewModel.h>

#import <NexconnChatUI/NCGroupCreateViewController.h>
#import <NexconnChatUI/NCGroupCreateViewModel.h>
#import <NexconnChatUI/NCGroupMemberCellViewModel.h>
#import <NexconnChatUI/NCGroupMemberListViewController.h>
#import <NexconnChatUI/NCGroupMemberListViewModel.h>
#import <NexconnChatUI/NCRemoveGroupMemberCellViewModel.h>
#import <NexconnChatUI/NCRemoveGroupMembersViewController.h>
#import <NexconnChatUI/NCRemoveGroupMembersViewModel.h>
#import <NexconnChatUI/NCSelectUserCellViewModel.h>
#import <NexconnChatUI/NCSelectUserViewController.h>
#import <NexconnChatUI/NCSelectUserViewModel.h>

#import <NexconnChatUI/NCBaseCellViewModel.h>
#import <NexconnChatUI/NCBaseViewModel.h>

#import <NexconnChatUI/NCApplyFriendCell.h>
#import <NexconnChatUI/NCApplyFriendCellViewModel.h>
#import <NexconnChatUI/NCApplyFriendListView.h>
#import <NexconnChatUI/NCApplyFriendListViewController.h>
#import <NexconnChatUI/NCApplyFriendListViewModel.h>
#import <NexconnChatUI/NCApplyFriendOperationCell.h>
#import <NexconnChatUI/NCApplyFriendSectionItem.h>
#import <NexconnChatUI/NCApplyNaviItemsViewModel.h>
#import <NexconnChatUI/NCFriendListView.h>

#import <NexconnChatUI/NCUserSearchView.h>

#import <NexconnChatUI/NCApplyFriendAlertView.h>
#import <NexconnChatUI/NCSearchFriendsViewController.h>
#import <NexconnChatUI/NCSearchUserProfileViewModel.h>
#import <NexconnChatUI/NCUserSearchViewController.h>
#import <NexconnChatUI/NCUserSearchViewModel.h>
#import <NexconnChatUI/NCViewModelAdapterCenter.h>

#import <NexconnChatUI/NCProfileSwitchCellViewModel.h>

#import <NexconnChatUI/NCUserProfileDefine.h>

#import <NexconnChatUI/NCGroupNoticeViewController.h>
#import <NexconnChatUI/NCGroupNoticeViewModel.h>

#import <NexconnChatUI/NCFriendListPermanentCell.h>
#import <NexconnChatUI/NCGroupInfoCellViewModel.h>
#import <NexconnChatUI/NCGroupListCell.h>
#import <NexconnChatUI/NCGroupNotificationCell.h>
#import <NexconnChatUI/NCGroupNotificationCellViewModel.h>
#import <NexconnChatUI/NCGroupNotificationViewController.h>
#import <NexconnChatUI/NCGroupNotificationViewModel.h>
#import <NexconnChatUI/NCMyGroupsViewController.h>
#import <NexconnChatUI/NCMyGroupsViewModel.h>

#import <NexconnChatUI/NCGroupFollowsViewController.h>
#import <NexconnChatUI/NCGroupFollowsViewModel.h>
#import <NexconnChatUI/NCGroupManagementViewController.h>
#import <NexconnChatUI/NCGroupManagementViewModel.h>
#import <NexconnChatUI/NCGroupManagerListController.h>
#import <NexconnChatUI/NCGroupManagerListViewModel.h>
#import <NexconnChatUI/NCGroupTransferViewController.h>
#import <NexconnChatUI/NCGroupTransferViewModel.h>
#import <NexconnChatUI/NCMyGroupsView.h>
#import <NexconnChatUI/NCSearchGroupsViewController.h>
#import <NexconnChatUI/NCSearchGroupsViewModel.h>
#import <NexconnChatUI/NCSelectGroupMemberViewController.h>
#import <NexconnChatUI/NCSelectGroupMemberViewModel.h>

// RRS
#import <NexconnChatUI/NCMessageReadDetailCellViewModel.h>
#import <NexconnChatUI/NCMessageReadDetailDefine.h>
#import <NexconnChatUI/NCMessageReadDetailTabView.h>
#import <NexconnChatUI/NCMessageReadDetailView.h>
#import <NexconnChatUI/NCMessageReadDetailViewConfig.h>
#import <NexconnChatUI/NCMessageReadDetailViewController.h>
#import <NexconnChatUI/NCMessageReadDetailViewModel.h>

// New Skin
#import <NexconnChatUI/NCChatUITheme.h>
#import <NexconnChatUI/NCChatUIThemeManager.h>
#import <NexconnChatUI/NCMenuItem.h>

#import <NexconnChatUI/NCOnlineStatusView.h>

#import <NexconnChatUI/NCGroupMemberAdditionalCell.h>
#import <NexconnChatUI/NCGroupMemberAdditionalCellViewModel.h>
#import <NexconnChatUI/NCGroupMentionViewController.h>
#import <NexconnChatUI/NCGroupMentionViewModel.h>
#import <NexconnChatUI/NCPaddingTableViewCell.h>
#import <NexconnChatUI/NCSearchBarListView.h>
#import <NexconnChatUI/NCSelectUserView.h>
#import <NexconnChatUI/NCSizeCalculateLabel.h>
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
#import "NCComplexTextMessageCell.h"
#import "NCFileMessageCell.h"
#import "NCGIFMessageCell.h"
#import "NCHDVoiceMessageCell.h"
#import "NCImageMessageCell.h"
#import "NCImageMessageProgressView.h"
#import "NCMessageBaseCell.h"
#import "NCMessageCell.h"
#import "NCMessageCellDelegate.h"
#import "NCMessageCellNotificationModel.h"
#import "NCMessageCellTool.h"
#import "NCMessageModel.h"
#import "NCReferenceMessageCell.h"
#import "NCReferencedContentView.h"
#import "NCReferencingView.h"
#import "NCStreamMessageCell.h"
#import "NCTextMessageCell.h"
#import "NCTipMessageCell.h"
#import "NCUnknownMessageCell.h"

/// Utilities
#import "NCChatUICommonDefine.h"
#import "NCChatUIConf.h"
#import "NCChatUIConfig.h"
#import "NCChatUIFontConf.h"
#import "NCChatUIMessageConf.h"
#import "NCChatUIThemeDefine.h"
#import "NCChatUIUtility.h"
/// Others
#import "NCActionSheetView.h"
#import "NCAlertView.h"
#import "NCAttributedLabel.h"
#import "NCBaseViewController.h"
#import "NCChatUISDKExtensionModule.h"
#import "NCContentView.h"
#import "NCEmoticonTabSource.h"
#import "NCMessageBubbleTipView.h"
#import "NCTextView.h"
#import "NCTipLabel.h"

// View base classes
#import "NCBaseButton.h"
#import "NCBaseCollectionView.h"
#import "NCBaseCollectionViewCell.h"
#import "NCBaseImageView.h"
#import "NCBaseLabel.h"
#import "NCBaseNavigationController.h"
#import "NCBaseTableView.h"
#import "NCBaseTableViewCell.h"
#import "NCBaseView.h"

// User and group info
#import "NCChatUIGroup.h"
#import "NCChatUIUserInfo.h"

#import "NCButtonItem.h"
#import "NCCollectionViewModelProtocol.h"
#import "NCGroupMembersCollectionViewModel.h"
#import "NCGroupProfileMembersCellViewModel.h"
#import "NCGroupProfileViewModel.h"
#import "NCMyProfileViewModel.h"
#import "NCProfileCellViewModel.h"
#import "NCProfileCommonCellViewModel.h"
#import "NCProfileFooterViewModel.h"
#import "NCProfileViewController.h"
#import "NCProfileViewModel.h"
#import "NCUserProfileViewModel.h"

#import "NCFriendListViewController.h"
#import "NCFriendListViewModel.h"
#import "NCNavigationItemsViewModel.h"
#import "NCSearchBarViewModel.h"

#import "NCCellViewModelProtocol.h"
#import "NCListViewModelProtocol.h"

#import "NCFriendListCellViewModel.h"
#import "NCFriendListPermanentCellViewModel.h"

#import "NCGroupCreateViewController.h"
#import "NCGroupCreateViewModel.h"
#import "NCGroupMemberCellViewModel.h"
#import "NCGroupMemberListViewController.h"
#import "NCGroupMemberListViewModel.h"
#import "NCRemoveGroupMemberCellViewModel.h"
#import "NCRemoveGroupMembersViewController.h"
#import "NCRemoveGroupMembersViewModel.h"
#import "NCSelectUserCellViewModel.h"
#import "NCSelectUserViewController.h"
#import "NCSelectUserViewModel.h"

#import "NCBaseCellViewModel.h"
#import "NCBaseViewModel.h"

#import "NCApplyFriendCell.h"
#import "NCApplyFriendCellViewModel.h"
#import "NCApplyFriendListView.h"
#import "NCApplyFriendListViewController.h"
#import "NCApplyFriendListViewModel.h"
#import "NCApplyFriendOperationCell.h"
#import "NCApplyFriendSectionItem.h"
#import "NCApplyNaviItemsViewModel.h"
#import "NCFriendListView.h"

#import "NCUserSearchView.h"

#import "NCApplyFriendAlertView.h"
#import "NCSearchFriendsViewController.h"
#import "NCSearchUserProfileViewModel.h"
#import "NCUserSearchViewController.h"
#import "NCUserSearchViewModel.h"
#import "NCViewModelAdapterCenter.h"

#import "NCProfileSwitchCellViewModel.h"

#import "NCUserProfileDefine.h"

#import "NCGroupNoticeViewController.h"
#import "NCGroupNoticeViewModel.h"

// 2024-11-14
#import "NCGroupInfoCellViewModel.h"
#import "NCGroupNotificationCell.h"
#import "NCGroupNotificationCellViewModel.h"
#import "NCGroupNotificationViewController.h"
#import "NCGroupNotificationViewModel.h"
#import "NCMyGroupsViewController.h"
#import "NCMyGroupsViewModel.h"

#import "NCFriendListPermanentCell.h"
#import "NCGroupListCell.h"

#import "NCGroupFollowsViewController.h"
#import "NCGroupFollowsViewModel.h"
#import "NCGroupManagementViewController.h"
#import "NCGroupManagementViewModel.h"
#import "NCGroupManagerListController.h"
#import "NCGroupManagerListViewModel.h"
#import "NCGroupTransferViewController.h"
#import "NCGroupTransferViewModel.h"
#import "NCMyGroupsView.h"
#import "NCSearchGroupsViewController.h"
#import "NCSearchGroupsViewModel.h"
#import "NCSelectGroupMemberViewController.h"
#import "NCSelectGroupMemberViewModel.h"

// RRS
#import "NCMessageReadDetailCellViewModel.h"
#import "NCMessageReadDetailDefine.h"
#import "NCMessageReadDetailTabView.h"
#import "NCMessageReadDetailView.h"
#import "NCMessageReadDetailViewConfig.h"
#import "NCMessageReadDetailViewController.h"
#import "NCMessageReadDetailViewModel.h"

// New Skin
#import "NCChatUIBuiltInThemes.h"
#import "NCChatUITheme.h"
#import "NCChatUIThemeManager.h"
#import "NCMenuItem.h"

#import "NCOnlineStatusView.h"

#import "NCGroupMemberAdditionalCell.h"
#import "NCGroupMemberAdditionalCellViewModel.h"
#import "NCGroupMentionViewController.h"
#import "NCGroupMentionViewModel.h"
#import "NCPaddingTableViewCell.h"
#import "NCSearchBarListView.h"
#import "NCSelectUserView.h"
#import "NCSizeCalculateLabel.h"
#import "NCStackTableViewCell.h"
#endif
