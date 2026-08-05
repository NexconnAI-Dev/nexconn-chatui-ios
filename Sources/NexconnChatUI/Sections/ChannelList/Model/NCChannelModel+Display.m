//
//  NCChannelModel+Display.m
//  NexconnChatUI
//
//  Created on 2026/4/3.
//

#import "NCChannelModel+Display.h"
#import "NCChatUIConfig.h"
#import "NCChatUIUtility.h"
#import "NCChatUICommonDefine.h"
#import "NCUserInfoCacheManager.h"
#import "NCChatUIUserInfo.h"

@implementation NCChannelModel (Display)

#pragma mark - Channel Display Information

- (NSString *)conversationDisplayName {
    if (self.dataManagementInfo && self.dataManagementInfo.name.length > 0) {
        return self.dataManagementInfo.name;
    }
    if ([self isChannelType:NCChannelTypeGroup]) {
        NCChatUIGroup *groupInfo = [[NCUserInfoCacheManager sharedManager] getGroupInfo:self.channelId];
        return groupInfo.groupName;
    }
    NCChatUIUserInfo *userInfo = [self nc_displayManagedUserInfo:self.channelId];
    if (userInfo) {
        return [NCChatUIUtility getDisplayName:userInfo];
    }
    return nil;
}

- (NSString *)conversationPortraitUri {
    if (self.dataManagementInfo && self.dataManagementInfo.name.length > 0) {
        return self.dataManagementInfo.portraitUri;
    }
    return [self conversationCachedPortraitUri];
}

- (NSString *)conversationCachedPortraitUri {
    if ([self isChannelType:NCChannelTypeGroup]) {
        NCChatUIGroup *groupInfo = [[NCUserInfoCacheManager sharedManager] getGroupInfo:self.channelId];
        return groupInfo.avatarUrl;
    }
    NCChatUIUserInfo *userInfo = [self nc_displayManagedUserInfo:self.channelId];
    return userInfo.avatarUrl;
}

- (NSString *)senderDisplayNameInGroup {
    if (![self isChannelType:NCChannelTypeGroup]) {
        return nil;
    }
    NCChatUIUserInfo *groupMemberUserInfo = [self nc_displayManagedGroupMemberInfo:self.senderUserId
                                                                            groupId:self.channelId];
    NCChatUIUserInfo *baseUserInfo = [self nc_displayManagedUserInfo:self.senderUserId];
    NCGroupMemberInfo *groupMemberInfo = groupMemberUserInfo.memberInfo;
    NSString *memberNickname = groupMemberInfo.nickname;
    if (memberNickname.length > 0) {
        return memberNickname;
    }
    if (groupMemberUserInfo.name.length > 0) {
        return groupMemberUserInfo.name;
    }
    if (baseUserInfo.alias.length > 0) {
        return baseUserInfo.alias;
    }
    return baseUserInfo.name;
}

#pragma mark - Message Formatting

- (NSString *)formattedLastMessageContent {
    NSInteger channelType = [self nc_displayConversationTypeValue];
    if ([NCChatUIUtility isUnkownMessage:self.latestMessageClientId content:self.latestMessage] &&
        NCChatUIConfigCenter.message.showUnkownMessage) {
        return NCUILocalizedString(@"unknown_message_cell_tip");
    }
    return [NCChatUIUtility formatMessage:self.latestMessage
                              channelId:self.channelId
                      channelType:channelType];
}

#pragma mark - Configuration Lookup

- (BOOL)isReadReceiptEnabledForCurrentChannelType {
    NSInteger channelType = [self nc_displayConversationTypeValue];
    return [NCChatUIConfigCenter.message.enabledReadReceiptConversationTypeList containsObject:@(channelType)];
}

#pragma mark - Private Methods

- (NSInteger)nc_displayConversationTypeValue {
    switch (self.channelType) {
        case NCChannelTypeDirect:
        case NCChannelTypeGroup:
        case NCChannelTypeSystem:
        case NCChannelTypeCommunity:
            return (NSInteger)self.channelType;
        case NCChannelTypeOpen:
        default:
            // Open and unknown channel types have no equivalent; preserve the invalid value used by the existing behavior.
            return -1;
    }
}

- (NCChatUIUserInfo *)nc_displayManagedUserInfo:(NSString *)userId {
    if (userId.length == 0) {
        return nil;
    }
    return [[NCUserInfoCacheManager sharedManager] getUserInfo:userId];
}

- (NCChatUIUserInfo *)nc_displayManagedGroupMemberInfo:(NSString *)userId
                                               groupId:(NSString *)groupId {
    if (userId.length == 0 || groupId.length == 0) {
        return nil;
    }
    NCChatUIUserInfo *groupMemberUserInfo = [[NCUserInfoCacheManager sharedManager] getUserInfo:userId inGroupId:groupId];
    return groupMemberUserInfo ?: [self nc_displayManagedUserInfo:userId];
}

@end
