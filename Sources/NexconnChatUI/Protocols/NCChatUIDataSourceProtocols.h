//
//  NCChatUIDataSourceProtocols.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#ifndef NEXCONNCHATUI_NCCHATUIDATASOURCEPROTOCOLS_H
#define NEXCONNCHATUI_NCCHATUIDATASOURCEPROTOCOLS_H

#import <Foundation/Foundation.h>

@class NCChatUIUserInfo;
@class NCChatUIGroup;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, NCDataSourceType) {
    /// Info provider
    NCDataSourceTypeInfoProvider = 0,
    /// Info management
    NCDataSourceTypeInfoManagement,
};

/// User info data source.
///
/// The SDK obtains user information through your implementation of this data source and displays it.
@protocol NCChatUIUserInfoDataSource <NSObject>

/// Called by the SDK to request user information from the app.
///
/// @param userId      The user ID.
/// @param completion  Block to execute after obtaining the user info. Pass the corresponding user info object.
///
/// The SDK calls this method to obtain and display user info.
/// After you set the user info data source, the SDK invokes this method whenever it needs to display user information.
- (void)getUserInfoWithUserId:(NSString *)userId completion:(void (^)(NCChatUIUserInfo *_Nullable userInfo))completion;

@end

/// Group info data source.
///
/// The SDK obtains group information through your implementation of this data source and displays it.
@protocol NCChatUIGroupInfoDataSource <NSObject>

/// Called by the SDK to request group information from the app.
///
/// @param groupId     The group ID.
/// @param completion  Block to execute after obtaining the group info. Pass the corresponding group info object.
///
/// The SDK calls this method to obtain and display group info.
/// After you set the group info data source, the SDK invokes this method whenever it needs to display group information.
- (void)getGroupInfoWithGroupId:(NSString *)groupId completion:(void (^)(NCChatUIGroup *_Nullable groupInfo))completion;

@end

/// Group member nickname data source.
///
/// If you use the group nickname feature, the SDK obtains user nickname information within a group through your implementation of this data source.
@protocol NCChatUIGroupUserInfoDataSource <NSObject>

/// Called by the SDK to request a user's nickname within a specific group.
///
/// @param userId          The user ID.
/// @param groupId         The group ID.
/// @param completion      Block to execute after obtaining the group nickname info. Pass the corresponding user info object.
///
/// If you use the group nickname feature, the SDK obtains and displays the user's nickname within the group through this method.
- (void)getUserInfoWithUserId:(NSString *)userId
                      inGroup:(NSString *)groupId
                   completion:(void (^)(NCChatUIUserInfo *_Nullable userInfo))completion;

@end

/// Group member list data source.
@protocol NCChatUIGroupMemberDataSource <NSObject>
@optional

/// Called by the SDK to request the member list of the current group (requires NCChatUIUserInfoDataSource to be implemented).
///
/// @param groupId     The group ID.
/// @param resultBlock Block to execute after obtaining the member list. Pass the list of member user IDs.
///
/// The SDK calls this method to obtain the member list of the group. Return the member user ID list in the resultBlock.
/// After you set the group member data source, the SDK invokes this method whenever it needs the group member list.
- (void)getAllMembersOfGroup:(NSString *)groupId result:(void (^)(NSArray<NSString *> *_Nullable userIdList))resultBlock;

@end

NS_ASSUME_NONNULL_END

#endif /* NEXCONNCHATUI_NCCHATUIDATASOURCEPROTOCOLS_H */
