//
//  NCGroupManager.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <NexconnChatSDK/NexconnChatSDK.h>
NS_ASSUME_NONNULL_BEGIN

@interface NCUIPagingQueryOption : NSObject

@property (nonatomic, copy, nullable) NSString *pageToken;
@property (nonatomic, assign) NSInteger count;
@property (nonatomic, assign) BOOL order;

@end

@interface NCUIPagingQueryResult<__covariant ObjectType> : NSObject

@property (nonatomic, copy) NSArray<ObjectType> *data;
@property (nonatomic, copy, nullable) NSString *pageToken;

@end

@interface NCGroupManager : NSObject

+ (void)getGroupMemberInfos:(NSString *)groupId
                     option:(NCUIPagingQueryOption *)option
                       role:(NCGroupMemberRole)role
                   complete:(void (^)(NCUIPagingQueryResult<NCGroupMemberInfo *> * _Nullable result))complete;

+ (void)getGroupMemberInfos:(NSString *)groupId
                    userIds:(NSArray<NSString *> *)userIds
                   complete:(void (^)(NSArray<NCGroupMemberInfo *> * _Nullable members))complete;

+ (void)getJoinedGroupInfosByRole:(NCGroupMemberRole)role
                           option:(NCUIPagingQueryOption *)option
                         complete:(void (^)(NCUIPagingQueryResult<NCGroupInfo *> * _Nullable result))complete;

+ (void)searchJoinedGroupInfos:(NSString *)keyword
                        option:(NCUIPagingQueryOption *)option
                      complete:(void (^)(NCUIPagingQueryResult<NCGroupInfo *> * _Nullable result))complete;

+ (void)fetchFriendInfosWithUserIds:(NSArray<NSString *> *)userIds
                           complete:(void (^)(NSArray<NCFriendInfo *> * _Nullable friendInfos))complete;

+ (void)fetchFriendInfos:(NSArray <NCGroupMemberInfo *> *)members
                complete:(void (^)(NSArray<NCFriendInfo *> * _Nullable friendInfos))complete;

+ (nullable NCFriendInfo *)friendWithUserId:(NSString *)userId
                              inFriendInfos:(NSArray<NCFriendInfo *> *)friendInfos;

@end

NS_ASSUME_NONNULL_END
