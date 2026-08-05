//
//  NCChatUI.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#ifndef NEXCONNCHATUI_NCCHATUI_H
#define NEXCONNCHATUI_NCCHATUI_H

#import <Foundation/Foundation.h>
#import <NexconnChatSDK/NexconnChatSDK.h>
#import <NexconnChatUI/NCChatUISendParams.h>
#import <NexconnChatUI/NCChatUIProtocols.h>

@class NCChatUIUserInfo;
@class NCChatUIGroup;
@class NCMessage;
@class NCError;
@class NCMentionedInfo;
@class NCUploadMediaStatusListener;

NS_ASSUME_NONNULL_BEGIN

/// Posted when the SDK connection status changes.
///
/// The notification `object` is an `NSNumber` wrapping an `NCConnectionStatus` value.
///
/// Any registered connection status delegate added through `-addConnectionStatusDelegate:`
/// also receives this notification.
FOUNDATION_EXPORT NSString *const NCChatUIDispatchConnectionStatusChangedNotification;

/// Posted when channel status synchronization completes.
///
/// The notification `object` is an `NSArray` of `NCConversationStatusInfo` objects; `userInfo` is nil.
///
/// @note Event handling
FOUNDATION_EXPORT NSString *const NCChatUIDispatchConversationStatusChangeNotification;

/// Posted when a channel draft save request finishes.
///
/// userInfo keys: @"channelType" (NCChannelType), @"channelId", @"subChannelId",
/// @"draft", @"updated" (BOOL), @"error" (NSError, optional)
///
/// @note Event handling
FOUNDATION_EXPORT NSString *const NCChatUIChannelDraftSaveResultNotification;

/// Posted when user presence changes.
///
/// The notification `userInfo` contains @{ `NCChatUIUserOnlineStatusChangedUserIdsKey` : changedUserIds }.
///
/// @note Event handling
FOUNDATION_EXPORT NSString *const NCChatUIUserOnlineStatusChangedNotification;

/// The `userInfo` key whose value is the array of user IDs with changed presence.
FOUNDATION_EXPORT NSString *const NCChatUIUserOnlineStatusChangedUserIdsKey;

/// Posted when presence changes for users displayed in the channel list.
///
/// The notification `userInfo` contains @{ `NCChatUIUserOnlineStatusChangedUserIdsKey` : changedUserIds }.
///
/// @note Event handling
FOUNDATION_EXPORT NSString *const NCChatUIConversationCellOnlineStatusUpdateNotification;

/// The main entry point for NexconnChatUI.
///
/// Use the shared instance returned by `+shared` to access all SDK features.
@interface NCChatUI : NSObject

/// Returns the shared instance.
///
/// @return The shared `NCChatUI` instance.
+ (instancetype)shared;

#pragma mark - Initialization

/// Initializes the SDK with the given parameters.
///
/// Call this method before using any SDK feature, including displaying any SDK view.
/// Only one initialization is needed per app lifecycle.
///
/// @param params The initialization parameters.
/// @warning If using Chat UI, call this method. If using Chat SDK directly, use the corresponding method in `NCEngine`.
- (void)initializeWithParams:(NCInitParams *)params;

#pragma mark - Connection

/// Connects to the server with the given parameters.
///
/// @param params The connection parameters.
/// @param databaseOpenedHandler Called when the local message database is opened.
/// @param completionHandler Called when the connection attempt finishes.
- (void)connectWithParams:(NCConnectParams *)params
    databaseOpenedHandler:(nullable void (^)(BOOL isRecreated, NCError * _Nullable error))databaseOpenedHandler
        completionHandler:(nullable void (^)(NSString * _Nullable userId, NCError * _Nullable error))completionHandler;


/// Disconnects from the server.
///
/// The SDK automatically reconnects on foreground/background transitions and network changes.
/// Manually disconnecting is only necessary when the app needs to log out.
///
/// @param disablePush Whether to disable remote push notifications after disconnecting.
/// @warning If using Chat UI, call this method. If using Chat SDK directly, use the corresponding method in `NCEngine`.
- (void)disconnectWithDisablePush:(BOOL)disablePush;

/// Disconnects from the server while keeping remote push notifications enabled.
///
/// The SDK automatically reconnects on foreground/background transitions and network changes.
/// Manually disconnecting is only necessary when the app needs to log out.
///
/// Equivalent to `[NCChatUI.shared disconnectWithDisablePush:NO]`.
- (void)disconnect;

#pragma mark - Notification Settings

/// Refreshes the global do-not-disturb period cached for ChatUI foreground alert sounds.
///
/// Call this after a successful `NCEngine` do-not-disturb setting change.
///
/// @param completion Called after the refresh finishes. Returns an error when the current setting cannot be queried.
- (void)refreshNoDisturbTimeWithCompletion:(nullable void (^)(NCError * _Nullable error))completion;

#pragma mark Connection Status

/// Adds a connection status observer.
///
/// @param delegate The delegate to add.
- (void)addConnectionStatusDelegate:(id<NCChatUIConnectionStatusDelegate>)delegate;

/// Removes a connection status observer.
///
/// @param delegate The delegate to remove.
- (void)removeConnectionStatusDelegate:(id<NCChatUIConnectionStatusDelegate>)delegate;

/// Returns the current connection status of the SDK.
///
/// @return The current connection status.
- (NCConnectionStatus)getConnectionStatus;

#pragma mark Network Status

/// Adds a network status change observer.
///
/// @param delegate The delegate to add.
- (void)addNetworkStatusDelegate:(id<NCChatUINetworkStatusDelegate>)delegate;

/// Removes a network status change observer.
///
/// @param delegate The delegate to remove.
- (void)removeNetworkStatusDelegate:(id<NCChatUINetworkStatusDelegate>)delegate;

/// Returns the current network status.
///
/// @return The current network status.
- (NCChatUINetworkStatus)getCurrentNetworkStatus;

#pragma mark - Message Receiving

/// The delegate that controls message display and handling policy.
@property (nonatomic, weak, nullable) id<NCChatUIMessagePolicyDelegate> messagePolicyDelegate;

/// Adds a message event observer (held as a weak reference).
///
/// @param observer The observer to add.
- (void)addMessageEventObserver:(id<NCChatUIMessageEventObserver>)observer;

/// Removes a message event observer.
///
/// @param observer The observer to remove.
- (void)removeMessageEventObserver:(id<NCChatUIMessageEventObserver>)observer;

#pragma mark - Message Registration & Sending

#pragma mark Message Interception

/// The delegate that intercepts outgoing messages before they are sent.
@property (nonatomic, weak, nullable) id<NCChatUIMessageInterceptor> messageInterceptor;

#pragma mark Sending Messages

/// Sends a standard message and automatically updates the UI.
///
/// @param params The standard message send parameters.
/// @param completion Called when message sending finishes. Returns the sent message on success, or the message with `NCError` on failure.
- (void)sendMessageWithParams:(NCChatUISendMessageParams *)params
                   completion:(nullable void (^)(NCMessage * _Nullable message, NCError * _Nullable error))completion;

/// Sends a media message and automatically updates the UI.
///
/// @param params The media message send parameters.
/// @param progressBlock Called with upload progress updates.
/// @param completion Called when media message sending finishes. Returns the sent message on success, or the message with `NCError` on failure.
/// @param cancelBlock Called when media message sending is cancelled.
- (void)sendMediaMessageWithParams:(NCChatUISendMediaMessageParams *)params
                          progress:(nullable void (^)(int progress, NCMessage *progressMessage))progressBlock
                        completion:(nullable void (^)(NCMessage * _Nullable message, NCError * _Nullable error))completion
                            cancel:(nullable void (^)(NCMessage *cancelMessage))cancelBlock;

/// Cancels a media message that is currently being sent.
///
/// @param clientId The message identifier.
/// @return `YES` if the cancellation succeeded; `NO` if the message was already sent or does not exist.
- (BOOL)cancelSendMediaMessage:(long)clientId;

/// Downloads the media file attached to a message.
///
/// Applicable to image and file messages only.
///
/// @param clientId The message identifier.
/// @param progressBlock Called periodically with download progress (0–100).
/// @param completion Called when the download finishes. Returns the local file path on success, or `NCError` on failure.
/// @param cancelBlock Called if the download is cancelled.
- (void)downloadMediaMessage:(long)clientId
                    progress:(nullable void (^)(int progress))progressBlock
                  completion:(nullable void (^)(NSString * _Nullable mediaPath, NCError * _Nullable error))completion
                      cancel:(nullable void (^)(void))cancelBlock;

/// Downloads a file by URL.
///
/// Returns the cached file if available locally; otherwise downloads from the server.
///
/// @param fileName The destination file name including extension (e.g., "video.mov").
/// @param mediaUrl The remote URL of the file.
/// @param progressBlock Called periodically with download progress (0–100).
/// @param completion Called when the download finishes. Returns the local file path on success, or `NCError` on failure.
/// @param cancelBlock Called if the download is cancelled.
/// @warning This is a file downloader only and does not modify the message object.
///
/// @note Media download
- (void)downloadMediaFile:(NSString *_Nonnull)fileName
                 mediaUrl:(NSString *_Nonnull)mediaUrl
                 progress:(nullable void (^)(int progress))progressBlock
               completion:(nullable void (^)(NSString * _Nullable mediaPath, NCError * _Nullable error))completion
                   cancel:(nullable void (^)(void))cancelBlock;

/// Cancels an in-progress media download.
///
/// @param clientId The message identifier.
/// @return `YES` if the cancellation succeeded; `NO` if the download already completed or the message does not exist.
- (BOOL)cancelDownloadMediaMessage:(long)clientId;

#pragma mark - User & Group Info

/// The current logged-in user's info.
///
/// Set this after connecting to the server. The SDK uses it for display and message sending.
///
/// @warning If the user ID in the provided info does not match the logged-in user, it is ignored.
@property (nonatomic, strong, nullable) NCChatUIUserInfo *currentUserInfo;

/// Whether to persist user and group info to local storage. Defaults to `NO`.
///
/// When `NO`, user info is fetched from the data source and cached in memory only; the cache
/// is cleared when the app terminates. When `YES`, the cache persists across app launches.
@property (nonatomic, assign) BOOL enablePersistentUserInfoCache;

/// The data source type for user info. Defaults to `NCDataSourceTypeInfoManagement`.
@property (nonatomic, assign) NCDataSourceType currentDataSourceType;

#pragma mark User Info

/// The data source that provides user info to the SDK for display.
@property (nonatomic, weak, nullable) id<NCChatUIUserInfoDataSource> userInfoDataSource;

/// Updates the cached user info for the specified user.
///
/// The change takes effect the next time a view displaying this user reloads.
/// To refresh immediately, call `reloadData` on the relevant view controller.
///
/// @param userInfo The updated user info.
/// @param userId The user identifier.
- (void)refreshUserInfoCache:(NCChatUIUserInfo *)userInfo withUserId:(NSString *)userId;

/// Returns the cached user info for the specified user.
///
/// @param userId The user identifier.
/// @return The cached user info, or nil if not cached.
- (nullable NCChatUIUserInfo *)getUserInfoCache:(NSString *)userId;

/// Retrieves user info from cache first, then from the remote server if not cached.
///
/// @param userId The user identifier.
/// @param completeBlock Called with the resolved user info.
- (void)getUserInfo:(NSString *)userId complete:(void (^)(NCChatUIUserInfo *userInfo))completeBlock;

/// Clears all cached user info.
///
/// The change takes effect the next time a view displaying user info reloads.
/// To refresh immediately, call `reloadData` on the relevant view controller.
- (void)clearUserInfoCache;

/// Updates the current user's profile.
///
/// @param profile The user profile to update.
/// @param completion Called when the update finishes. Returns `(nil, nil)` on success, or `(errorKeys, error)` on failure.
- (void)updateMyUserProfile:(NCUserProfile *)profile
                 completion:(nullable void (^)(NSArray<NSString *> * _Nullable errorKeys, NCError * _Nullable error))completion;

/// Sets friend info for the specified user.
///
/// @param userId The user identifier.
/// @param remark The friend remark (max 64 characters). Pass nil or empty string to clear.
/// @param extProfile Extended profile information.
/// @param completion Called when the update finishes. Returns `(nil, nil)` on success, or `(errorKeys, error)` on failure.
- (void)setFriendInfo:(NSString *)userId
               remark:(nullable NSString *)remark
           extProfile:(nullable NSDictionary<NSString *, NSString*> *)extProfile
           completion:(nullable void (^)(NSArray<NSString *> * _Nullable errorKeys, NCError * _Nullable error))completion;


#pragma mark Group Info

/// The data source that provides group info to the SDK for display.
@property (nonatomic, weak, nullable) id<NCChatUIGroupInfoDataSource> groupInfoDataSource;

/// Updates cached group info.
///
/// The change takes effect the next time a view displaying this group reloads.
/// To refresh immediately, call `reloadData` on the relevant view controller.
///
/// @param groupInfo The updated group info.
- (void)refreshGroupInfoCache:(NCChatUIGroup *)groupInfo;

/// Returns the cached group info for the specified group.
///
/// @param groupId The group identifier.
/// @return The cached group info, or nil if not cached.
- (nullable NCChatUIGroup *)getGroupInfoCache:(NSString *)groupId;

/// Clears all cached group info.
///
/// The change takes effect the next time a view displaying group info reloads.
/// To refresh immediately, call `reloadData` on the relevant view controller.
- (void)clearGroupInfoCache;

/// Clears cached group info for the specified group.
///
/// The change takes effect the next time a view displaying group info reloads.
/// To refresh immediately, call `reloadData` on the relevant view controller.
///
/// @param groupId The group identifier.
- (void)clearGroupInfoCacheForGroupId:(NSString *)groupId;

/// Updates group info on the server.
///
/// @param groupInfo The group info to update. `groupId` is required.
/// @param completion Called when the update finishes. Returns `(nil, nil)` on success, or `(errorKeys, error)` on failure.
- (void)updateGroupInfo:(NCGroupInfo *)groupInfo
             completion:(nullable void (^)(NSArray<NSString *> * _Nullable errorKeys, NCError * _Nullable error))completion NS_SWIFT_NAME(updateGroupInfo(_:completion:));


/// Sets a group member's profile.
///
/// @param groupId The group identifier.
/// @param userId The user identifier. The logged-in user's own ID is supported.
/// @param nickname The member nickname (max 64 characters). Pass nil or empty string to clear.
/// @param extra Additional information (max 128 characters).
/// @param completion Called when the update finishes. Returns `(nil, nil)` on success, or `(errorKeys, error)` on failure.
- (void)setGroupMemberInfo:(NSString *)groupId
                    userId:(NSString *)userId
                  nickname:(nullable NSString *)nickname
                     extra:(nullable NSString *)extra
                completion:(nullable void (^)(NSArray<NSString *> * _Nullable errorKeys, NCError * _Nullable error))completion;

#pragma mark Group Member Profile (Optional)

/// The data source that provides group member profiles for display.
@property (nonatomic, weak, nullable) id<NCChatUIGroupUserInfoDataSource> groupUserInfoDataSource;

/// Returns the cached group member profile for the specified user in a group.
///
/// @param userId The user identifier.
/// @param groupId The group identifier.
/// @return The cached group member profile, or nil if not cached.
- (nullable NCChatUIUserInfo *)getGroupUserInfoCache:(NSString *)userId withGroupId:(NSString *)groupId;

/// Updates the cached group member profile.
///
/// The change takes effect the next time a view displaying this member reloads.
/// To refresh immediately, call `reloadData` on the relevant view controller.
///
/// @param userInfo The updated user info.
/// @param userId The user identifier.
/// @param groupId The group identifier.
- (void)refreshGroupUserInfoCache:(NCChatUIUserInfo *)userInfo withUserId:(NSString *)userId withGroupId:(NSString *)groupId;

/// Clears all cached group member profiles.
///
/// The change takes effect the next time a view displaying group member info reloads.
/// To refresh immediately, call `reloadData` on the relevant view controller.
- (void)clearGroupUserInfoCache;

#pragma mark Group Member Data Source

/// The data source that provides the group member list for mention features.
@property (nonatomic, weak, nullable) id<NCChatUIGroupMemberDataSource> groupMemberDataSource;

#pragma mark - Extension Module

/// Sets the URL scheme for an extension module.
///
/// Some third-party extensions open external apps and wait for a return result.
/// Register the URL scheme in `Info.plist` and then pass it to the corresponding module.
///
/// @param scheme The URL scheme.
/// @param moduleName The extension module name.
- (void)setScheme:(NSString *)scheme forExtensionModule:(NSString *)moduleName;

/// Lets extension modules handle an incoming URL.
///
/// @param url The URL to handle.
/// @return `YES` if the URL was handled; `NO` otherwise.
- (BOOL)openExtensionModuleUrl:(NSURL *)url;

/// Returns the SDK version string.
///
/// @return The SDK version.
+ (NSString *)getVersion;

@end

NS_ASSUME_NONNULL_END

#endif /* NEXCONNCHATUI_NCCHATUI_H */
