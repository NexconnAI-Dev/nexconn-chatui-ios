//
//  NCChatUI.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCChatUI.h"
#import "NCChannelNotificationDataContext.h"
#import "NCChatUICommonDefine.h"
#import "NCChatUIConfig.h"
#import "NCChatUIErrorCode.h"
#import "NCChatUIExtensionManager.h"
#import "NCChatUILog.h"
#import "NCChatUINetworkStatusService.h"
#import "NCChatUIUtility.h"
#import "NCEventCenter.h"
#import "NCExtensionKit.h"
#import "NCFileUtility.h"
#import "NCHDVoiceMsgDownloadManager.h"
#import "NCInfoManagement.h"
#import "NCInfoProvider.h"
#import "NCLocalNotification.h"
#import "NCMessageNotificationHelper.h"
#import "NCOldMessageNotificationMessage.h"
#import "NCResendManager.h"
#import "NCSystemSoundPlayer.h"
#import "NCUserInfoCacheManager.h"
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

NSString *const NCUISendingMessageNotification = @"NCUISendingMessageNotification";
NSString *const NCChatUIDispatchConnectionStatusChangedNotification =
    @"NCChatUIDispatchConnectionStatusChangedNotification";

NSString *const NCUIDispatchDownloadMediaNotification = @"NCUIDispatchDownloadMediaNotification";
NSString *const NCChatUIDispatchConversationStatusChangeNotification =
    @"NCChatUIDispatchConversationStatusChangeNotification";
NSString *const NCChatUIChannelDraftSaveResultNotification =
    @"NCChatUIChannelDraftSaveResultNotification";

NSString *const NCChatUIConversationCellOnlineStatusUpdateNotification =
    @"NCChatUIConversationCellOnlineStatusUpdateNotification";
NSString *const NCChatUIUserOnlineStatusChangedNotification =
    @"NCChatUIUserOnlineStatusChangedNotification";
NSString *const NCChatUIUserOnlineStatusChangedUserIdsKey =
    @"NCChatUIUserOnlineStatusChangedUserIdsKey";

@interface NCChatUIMediaDownloadCallback : NSObject
@property (nonatomic, copy) void (^progressBlock)(int progress);
@property (nonatomic, copy) void (^completion)
    (NSString *_Nullable mediaPath, NCError *_Nullable error);
@property (nonatomic, copy) void (^cancelBlock)(void);
@end

@implementation NCChatUIMediaDownloadCallback
@end

@implementation NCChatUISendMessageParams

- (instancetype)initWithContent:(NCMessageContent *)content {
    self = [self init];
    if (self) {
        self.content = content;
    }
    return self;
}

@end

@implementation NCChatUISendMediaMessageParams

- (instancetype)initWithContent:(NCMediaMessageContent *)content {
    self = [self init];
    if (self) {
        self.content = content;
    }
    return self;
}

@end

@interface NCChatUI () <NCMessageHandler, NCConnectionStatusHandler, NCChannelHandler>
@property (nonatomic, copy) NSString *appKey;
@property (nonatomic, copy) NSString *token;
@property (nonatomic, strong) NSMutableArray *downloadingMeidaMessageIds;
@property (nonatomic, strong)
    NSMutableDictionary<NSNumber *, NSMutableArray<NCChatUIMediaDownloadCallback *> *>
        *mediaDownloadCallbacks;
@property (nonatomic, strong) NSHashTable<id<NCChatUIMessageEventObserver>> *messageObservers;
@property (nonatomic, strong, nullable) NSDate *notificationQuietBeginTime;
@property (nonatomic, strong, nullable) NSDate *notificationQuietEndTime;
@property (nonatomic, assign) BOOL hasNotifiedExtensionModuleUserId;
@property (nonatomic, strong) NCChatUINetworkStatusService *networkStatusService;
@property (nonatomic, strong, nullable) NCChatUIUserInfo *cachedCurrentUserInfo;
- (void)p_notifyNetworkStatusChanged:(NCChatUINetworkStatus)status;
@end

static NSString *const NexconnChatUIVersion = @"0.100.2";
static NSString *const NCChatUIMessageHandlerIdentifier = @"NCChatUI.global";
static NSString *const NCChatUIConnectionStatusHandlerIdentifier = @"NCChatUI.connectionStatus";
static NSString *const NCChatUIChannelHandlerIdentifier = @"NCChatUI.channel";

static NSArray<Class> *NCChatUIDefaultCustomMessageClasses(void) {
    return @[
        [NCOldMessageNotificationMessage class], [NCInformationNotificationMessage class],
        [NCGroupNotificationMessage class]
    ];
}

@implementation NCChatUI

- (instancetype)init {
    self = [super init];
    if (self) {
        _currentDataSourceType = NCDataSourceTypeInfoManagement;
    }
    return self;
}

+ (instancetype)shared {
    static NCChatUI *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      if (instance == nil) {
          instance = [[NCChatUI alloc] init];
          instance.userInfoDataSource = nil;
          instance.groupUserInfoDataSource = nil;
          instance.groupInfoDataSource = nil;
          instance.enablePersistentUserInfoCache = NO;
          instance.messageObservers = [NSHashTable weakObjectsHashTable];
          __weak typeof(instance) weakInstance = instance;
          instance.networkStatusService = [[NCChatUINetworkStatusService alloc]
              initWithStatusChangedHandler:^(NCChatUINetworkStatus status) {
                __strong typeof(weakInstance) strongInstance = weakInstance;
                if (!strongInstance) {
                    return;
                }
                [strongInstance p_notifyNetworkStatusChanged:status];
              }];
          [instance.networkStatusService startMonitorIfNeeded];
          [[NCChatUIExtensionManager sharedManager] loadAllExtensionModules];
      }
    });
    return instance;
}

- (void)setCurrentUserInfo:(NCChatUIUserInfo *)currentUserInfo {
    self.cachedCurrentUserInfo = currentUserInfo;
    if (currentUserInfo) {
        [[NCUserInfoCacheManager sharedManager] updateUserInfo:currentUserInfo
                                                     forUserId:currentUserInfo.userId];
        [NCInfoProvider sharedManager].currentUserId = currentUserInfo.userId;
    }
}

- (NCChatUIUserInfo *)currentUserInfo {
    return self.cachedCurrentUserInfo;
}

- (void)setGroupUserInfoDataSource:(id<NCChatUIGroupUserInfoDataSource>)groupUserInfoDataSource {
    _groupUserInfoDataSource = groupUserInfoDataSource;
    if (groupUserInfoDataSource) {
        [NCInfoProvider sharedManager].groupUserInfoEnabled = YES;
    }
}

- (void)initializeWithParams:(NCInitParams *)params {
    if (params.appKey.length == 0) {
        return;
    }
    if ([self.appKey isEqualToString:params.appKey]) {
        NCLogReleaseW(@"Warning: initializeWithParams: must not be called more than once.");
        return;
    }

    self.appKey = params.appKey;
    [NCEngine initializeWithParams:params];
    [NCEngine registerCustomMessages:NCChatUIDefaultCustomMessageClasses()];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(resetNotificationQuietStatus)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(resetNotificationQuietStatus)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    [NCInfoProvider sharedManager].appKey = params.appKey;
    [[NCChatUIExtensionManager sharedManager] initWithAppKey:params.appKey];
    [NCEngine addConnectionStatusHandlerWithIdentifier:NCChatUIConnectionStatusHandlerIdentifier
                                               handler:self];
    [NCEngine addMessageHandlerWithIdentifier:NCChatUIMessageHandlerIdentifier handler:self];
    [NCEngine addChannelHandlerWithIdentifier:NCChatUIChannelHandlerIdentifier handler:self];
}

- (BOOL)checkNoficationQuietStatus {
    return [self isInQuietTime];
}

- (void)connectWithParams:(NCConnectParams *)params
    databaseOpenedHandler:(void (^)(BOOL isRecreated,
                                    NCError *_Nullable error))databaseOpenedHandler
        completionHandler:
            (void (^)(NSString *_Nullable userId, NCError *_Nullable error))completionHandler {
    [NCEngine connectWithParams:params
          databaseOpenedHandler:databaseOpenedHandler
              completionHandler:^(NSString *_Nullable userId, NCError *_Nullable error) {
                if (!error && userId.length > 0) {
                    [NCInfoProvider sharedManager].currentUserId = userId;
                    [self resetNotificationQuietStatus];
                    [self p_notifyExtensionModulesDidConnectIfNeeded:userId];
                } else {
                    NSString *currentUserId = [[NCEngine getCurrentUserId] copy];
                    if (currentUserId.length > 0) {
                        [NCInfoProvider sharedManager].currentUserId = currentUserId;
                    }
                }
                if (completionHandler) {
                    completionHandler(userId, error);
                }
              }];
    if ([NCEngine getCurrentUserId].length > 0) {
        NCChatUIUserInfo *currentUserInfo = self.currentUserInfo;
        self.currentUserInfo = currentUserInfo;
    }
}

- (void)disconnectWithDisablePush:(BOOL)disablePush {
    self.hasNotifiedExtensionModuleUserId = NO;
    [[NCChatUIExtensionManager sharedManager] didDisconnect];
    [NCEngine disconnect:disablePush];
}

- (void)disconnect {
    [self disconnectWithDisablePush:NO];
}

- (void)postLocalNotificationIfNeed:(NCMessage *)message offline:(BOOL)offline {
    if (![NCChatUIUtility isApplicationInBackground]) {
        return;
    }

    if (offline || message.disableNotification) {
        return;
    }

    if (NCChatUIConfigCenter.message.disableMessageNotificaiton) {
        return;
    }

    NSDictionary *dictionary =
        [NCChatUIUtility getNotificationUserInfoDictionaryWithNCMessage:message];
    [NCMessageNotificationHelper checkNotifyAbilityWith:message
                                             completion:^(BOOL show) {
                                               if (show) {
                                                   [[NCLocalNotification defaultCenter]
                                                       postLocalNotificationWithMessage:message
                                                                               userInfo:dictionary];
                                               }
                                             }];
}

#pragma mark - NCMessageHandler

- (void)onMessageReceived:(NCMessageReceivedEvent *)event {
    NCMessage *message = event.message;
    if (!message) {
        return;
    }

    if ([self p_interceptReceiveMessage:message]) {
        return;
    }

    [self p_updateUserInfoCache:message];

    // Automatically download HD voice messages.
    if ([message.content isKindOfClass:[NCHDVoiceMessage class]] && event.left == 0 &&
        NCChatUIConfigCenter.message.automaticDownloadHQVoiceMsgEnable) {
        dispatch_async(dispatch_get_main_queue(), ^{
          [self downloadMediaMessage:(long)message.clientId progress:nil completion:nil cancel:nil];
        });
    }

    [[NCChatUIExtensionManager sharedManager] forwardMessageToExtensions:message];
    [self p_dispatchMessageToObservers:message left:event.left offline:event.offline];

    if ([self p_disableCustomMessageAlert:message left:event.left]) {
        return;
    }

    [self playSoundByMessageIfNeed:message];
    [self postLocalNotificationIfNeed:message offline:event.offline];
}

- (void)onMessageDeleted:(NCMessageDeletedEvent *)event {
    [self p_dispatchDeletedMessagesForAll:event.messages];
}

- (BOOL)p_interceptReceiveMessage:(NCMessage *)message {
    id<NCChatUIMessagePolicyDelegate> delegate = self.messagePolicyDelegate;
    if ([delegate respondsToSelector:@selector(shouldInterceptMessage:)] &&
        [delegate shouldInterceptMessage:message]) {
        return YES;
    }
    return NO;
}

- (void)p_dispatchMessageToObservers:(NCMessage *)message left:(int)left offline:(BOOL)offline {
    NSArray<id<NCChatUIMessageEventObserver>> *observers = nil;
    @synchronized(self.messageObservers) {
        observers = self.messageObservers.allObjects;
    }
    for (id<NCChatUIMessageEventObserver> observer in observers) {
        if ([observer respondsToSelector:@selector(onReceivedMessage:left:offline:)]) {
            [observer onReceivedMessage:message left:left offline:offline];
        }
    }
}

- (void)p_dispatchDeletedMessagesForAll:(NSArray<NCMessage *> *)messages {
    if (messages.count == 0) {
        return;
    }
    NSMutableArray<NCMessage *> *validMessages = [NSMutableArray array];
    for (NCMessage *message in messages) {
        if (message.clientId > 0) {
            [validMessages addObject:message];
        }
    }
    if (validMessages.count == 0) {
        return;
    }
    NSArray<id<NCChatUIMessageEventObserver>> *observers = nil;
    @synchronized(self.messageObservers) {
        observers = self.messageObservers.allObjects;
    }
    NSArray<NCMessage *> *immutableMessages = [validMessages copy];
    for (id<NCChatUIMessageEventObserver> observer in observers) {
        if ([observer respondsToSelector:@selector(onDeletedMessagesForAll:)]) {
            [observer onDeletedMessagesForAll:immutableMessages];
        }
    }
}

- (void)p_updateUserInfoCache:(NCMessage *)message {
    if ([NCChatUI shared].currentDataSourceType == NCDataSourceTypeInfoManagement) {
        return;
    }
    NCUserInfo *ncSenderUserInfo = message.content.senderUserInfo;
    if (!ncSenderUserInfo) {
        return;
    }
    NCChatUIUserInfo *senderUserInfo = [NCChatUIUserInfo new];
    senderUserInfo.userId = ncSenderUserInfo.userId;
    senderUserInfo.name = ncSenderUserInfo.name;
    senderUserInfo.avatarUrl = ncSenderUserInfo.portraitUri;
    senderUserInfo.alias = ncSenderUserInfo.alias;
    senderUserInfo.extra = ncSenderUserInfo.extra;

    NSString *senderUserId = senderUserInfo.userId;
    if (senderUserId.length > 0 && ![senderUserId isEqualToString:[NCEngine getCurrentUserId]]) {
        if (senderUserInfo.name.length > 0 || senderUserInfo.avatarUrl.length > 0) {
            NCChatUIUserInfo *cachedUserInfo =
                [[NCUserInfoCacheManager sharedManager] getUserInfoFromCacheOnly:senderUserId];
            if (cachedUserInfo) {
                if (0 == senderUserInfo.avatarUrl.length ||
                    [NCFileUtility isLocalPath:senderUserInfo.avatarUrl]) {
                    senderUserInfo.avatarUrl = cachedUserInfo.avatarUrl;
                }
                if (0 == senderUserInfo.alias.length) {
                    senderUserInfo.alias = cachedUserInfo.alias;
                }
                if (0 == senderUserInfo.extra.length) {
                    senderUserInfo.extra = cachedUserInfo.extra;
                }
            }
            [[NCUserInfoCacheManager sharedManager] updateUserInfo:senderUserInfo
                                                         forUserId:senderUserId];
        }
    }
}

- (BOOL)p_disableCustomMessageAlert:(NCMessage *)message left:(int)nLeft {
    if (message.direction == NCMessageDirectionSend) {
        return YES;
    }

    if (0 != nLeft) {
        return YES;
    }

    if (!message.isPersisted) {
        return YES;
    }

    if ([self p_isUpdatedMessage:message]) {
        return YES;
    }

    BOOL isUnknownMessage =
        (message.content == nil || [message.content isKindOfClass:[NCUnknownMessage class]]);
    if (!NCChatUIConfigCenter.message.showUnkownMessageNotificaiton && isUnknownMessage) {
        return YES;
    }

    return NO;
}

- (BOOL)p_isUpdatedMessage:(NCMessage *)message {
    return message.hasChanged || message.updateInfo != nil;
}

- (void)playSoundByMessageIfNeed:(NCMessage *)message {
    if ([self p_disableSound:message]) {
        return;
    }

    if (message.content.mentionedInfo.isMentionedMe) {
        [[NCSystemSoundPlayer defaultPlayer] playSoundByMessage:message
                                                  completeBlock:^(BOOL complete) {
                                                    if (complete) {
                                                        [self setExclusiveSoundPlayer];
                                                    }
                                                  }];
    } else {
        NCChannelIdentifier *identifier = message.channelIdentifier;
        if (!identifier.channelId.length) {
            return;
        }
        [NCBaseChannel
            getChannels:@[ identifier ]
             completion:^(NSArray<NCBaseChannel *> *_Nullable channels, NCError *_Nullable error) {
               if (error || channels.count == 0) {
                   return;
               }
               NCChannelNoDisturbLevel level = channels.firstObject.noDisturbLevel;
               if (level == NCChannelNoDisturbLevelMuted) {
                   return;
               }
               [[NCSystemSoundPlayer defaultPlayer] playSoundByMessage:message
                                                         completeBlock:^(BOOL complete) {
                                                           if (complete) {
                                                               [self setExclusiveSoundPlayer];
                                                           }
                                                         }];
             }];
    }
}

- (BOOL)p_disableSound:(NCMessage *)message {
    if ([NCChatUIUtility isApplicationInBackground]) {
        return YES;
    }

    if (NCChatUIConfigCenter.message.disableMessageAlertSound) {
        return YES;
    }

    if (message.disableNotification) {
        return YES;
    }

    if ([self checkNoficationQuietStatus]) {
        return YES;
    }

    if ([[NCChatUIExtensionManager sharedManager] handleAlertForMessageReceived:message]) {
        return YES;
    }

    if ([self p_shouldStopCustomAlertSoundWithMessage:message]) {
        return YES;
    }

    return NO;
}

- (BOOL)p_shouldStopCustomAlertSoundWithMessage:(NCMessage *)message {
    id<NCChatUIMessagePolicyDelegate> delegate = self.messagePolicyDelegate;
    if ([delegate respondsToSelector:@selector(shouldSuppressAlertSoundForMessage:)] &&
        [delegate shouldSuppressAlertSoundForMessage:message]) {
        return YES;
    }
    return NO;
}

- (void)setExclusiveSoundPlayer {
    if (NCChatUIConfigCenter.message.isExclusiveSoundPlayer || [NCChatUIUtility isAudioHolding] ||
        [NCChatUIUtility isCameraHolding]) {
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        [audioSession setCategory:AVAudioSessionCategoryAmbient error:nil];
        [audioSession setActive:YES error:nil];
    } else {
        // Deactivate only when exclusive playback is disabled and neither audio nor camera is being
        // held.
        [[AVAudioSession sharedInstance]
              setActive:NO
            withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation
                  error:nil];
    }
}

- (void)p_handleConnectionStatusChanged:(NCConnectionStatus)status {
    if (status == NCConnectionStatusConnected) {
        [NCChannelNotificationDataContext clean];
    }
    if (status == NCConnectionStatusKickedOfflineByOtherClient ||
        status == NCConnectionStatusSignOut || status == NCConnectionStatusTokenIncorrect) {
        self.hasNotifiedExtensionModuleUserId = NO;
        [[NCChatUIExtensionManager sharedManager] didDisconnect];
    }

    if (NCConnectionStatusNetworkUnavailable != status && NCConnectionStatusUnknown != status &&
        NCConnectionStatusUnconnected != status) {
        [[NSNotificationCenter defaultCenter]
            postNotificationName:NCChatUIDispatchConnectionStatusChangedNotification
                          object:[NSNumber numberWithInteger:status]];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
          [self performSelector:@selector(delayNotifyUnConnectedStatus)
                     withObject:nil
                     afterDelay:5];
        });
    }

    [self p_notifyExtensionModulesDidConnectIfNeeded:[[NCEngine getCurrentUserId] copy]];

    for (id<NCChatUIConnectionStatusDelegate> delegate in
         [[NCEventCenter sharedManager] allConnectionStatusChangeDelegates]) {
        if ([delegate respondsToSelector:@selector(onNCChatUIConnectionStatusChanged:)]) {
            [delegate onNCChatUIConnectionStatusChanged:status];
        }
    }
}

- (void)onConnectionStatusChanged:(NCConnectionStatusChangedEvent *)event {
    [self p_handleConnectionStatusChanged:event.status];
}

- (void)onChannelStatusSyncCompleted:(NCChannelStatusSyncCompletedEvent *)event {
    (void)event;
    [[NSNotificationCenter defaultCenter]
        postNotificationName:NCChatUIDispatchConversationStatusChangeNotification
                      object:nil
                    userInfo:nil];
}

- (void)addConnectionStatusDelegate:(id<NCChatUIConnectionStatusDelegate>)delegate {
    [[NCEventCenter sharedManager] addConnectionStatusChangeDelegate:delegate];
}

- (void)removeConnectionStatusDelegate:(id<NCChatUIConnectionStatusDelegate>)delegate {
    [[NCEventCenter sharedManager] removeConnectionStatusChangeDelegate:delegate];
}

- (void)addNetworkStatusDelegate:(id<NCChatUINetworkStatusDelegate>)delegate {
    [[NCEventCenter sharedManager] addNetworkStatusChangeDelegate:delegate];
}

- (void)removeNetworkStatusDelegate:(id<NCChatUINetworkStatusDelegate>)delegate {
    [[NCEventCenter sharedManager] removeNetworkStatusChangeDelegate:delegate];
}

- (void)addMessageEventObserver:(id<NCChatUIMessageEventObserver>)observer {
    if (!observer) {
        return;
    }
    @synchronized(self.messageObservers) {
        [self.messageObservers addObject:observer];
    }
}

- (void)removeMessageEventObserver:(id<NCChatUIMessageEventObserver>)observer {
    if (!observer) {
        return;
    }
    @synchronized(self.messageObservers) {
        [self.messageObservers removeObject:observer];
    }
}

- (NCConnectionStatus)getConnectionStatus {
    return [NCEngine getConnectionStatus];
}

- (NCChatUINetworkStatus)getCurrentNetworkStatus {
    [self.networkStatusService refreshCurrentStatusAndNotify:NO];
    return self.networkStatusService.currentNetworkStatus;
}

- (BOOL)isInQuietTime {
    if (!self.notificationQuietBeginTime || !self.notificationQuietEndTime) {
        return NO;
    }
    NSDateFormatter *dateFormatter = [self dateFormatter];
    NSString *nowDateString = [dateFormatter stringFromDate:[NSDate date]];
    NSDate *nowDate = [dateFormatter dateFromString:nowDateString];
    long long beginTime = self.notificationQuietBeginTime.timeIntervalSince1970;
    long long nowTime = nowDate.timeIntervalSince1970;
    long long endTime = self.notificationQuietEndTime.timeIntervalSince1970;
    if (nowTime < beginTime) {
        nowTime = nowTime + 24 * 60 * 60;
    }
    return (nowTime > beginTime && nowTime < endTime);
}

#pragma mark - UserInfo&GroupInfo&GroupUserInfo
- (void)setEnablePersistentUserInfoCache:(BOOL)enablePersistentUserInfoCache {
    _enablePersistentUserInfoCache = enablePersistentUserInfoCache;
    NSString *userId = [[NCEngine getCurrentUserId] copy];
    if (enablePersistentUserInfoCache && userId) {
        [NCInfoProvider sharedManager].currentUserId = userId;
    }
}

- (NCChatUIUserInfo *)getUserInfoCache:(NSString *)userId {
    return [[NCUserInfoCacheManager sharedManager] getUserInfo:userId];
}
// Resolve user information from the cache or the configured provider.
- (void)getUserInfo:(NSString *)userId
           complete:(void (^)(NCChatUIUserInfo *userInfo))completeBlock {
    NCChatUIUserInfo *user =
        [[NCUserInfoCacheManager sharedManager] getUserInfoFromCacheOnly:userId];
    if (user) {
        if (completeBlock) {
            completeBlock(user);
        }
    } else {
        [[NCUserInfoCacheManager sharedManager] getUserInfo:userId complete:completeBlock];
    }
}

- (void)refreshUserInfoCache:(NCChatUIUserInfo *)userInfo withUserId:(NSString *)userId {
    [[NCUserInfoCacheManager sharedManager] updateUserInfo:userInfo forUserId:userId];
}

- (void)clearUserInfoCache {
    [[NCUserInfoCacheManager sharedManager] clearAllUserInfo];
}

- (NCChatUIGroup *)getGroupInfoCache:(NSString *)groupId {
    return [[NCUserInfoCacheManager sharedManager] getGroupInfo:groupId];
}

- (void)refreshGroupInfoCache:(NCChatUIGroup *)groupInfo {
    [[NCUserInfoCacheManager sharedManager] updateGroupInfo:groupInfo];
}

- (void)clearGroupInfoCache {
    [[NCUserInfoCacheManager sharedManager] clearAllGroupInfo];
}

- (void)clearGroupInfoCacheForGroupId:(NSString *)groupId {
    [[NCUserInfoCacheManager sharedManager] clearGroupInfo:groupId];
}

- (NCChatUIUserInfo *)getGroupUserInfoCache:(NSString *)userId withGroupId:(NSString *)groupId {
    return [[NCUserInfoCacheManager sharedManager] getUserInfo:userId inGroupId:groupId];
}

- (void)refreshGroupUserInfoCache:(NCChatUIUserInfo *)userInfo
                       withUserId:(NSString *)userId
                      withGroupId:(NSString *)groupId {
    [[NCUserInfoCacheManager sharedManager] updateUserInfo:userInfo
                                                 forUserId:userId
                                                   inGroup:groupId];
}

- (void)clearGroupUserInfoCache {
    [[NCUserInfoCacheManager sharedManager] clearAllGroupUserInfo];
}

- (void)updateMyUserProfile:(NCUserProfile *)profile
                 completion:(nullable void (^)(NSArray<NSString *> *_Nullable errorKeys,
                                               NCError *_Nullable error))completion {
    [[NCInfoManagement sharedInstance] updateMyUserProfile:profile
        successBlock:^{
          if (completion) {
              completion(nil, nil);
          }
        }
        errorBlock:^(NSInteger errorCode, NSArray<NSString *> *_Nullable errorKeys) {
          if (completion) {
              completion(errorKeys, [NCError errorWithCode:errorCode]);
          }
        }];
}

- (void)setFriendInfo:(NSString *)userId
               remark:(nullable NSString *)remark
           extProfile:(nullable NSDictionary<NSString *, NSString *> *)extProfile
           completion:(nullable void (^)(NSArray<NSString *> *_Nullable errorKeys,
                                         NCError *_Nullable error))completion {
    [[NCInfoManagement sharedInstance] setFriendInfo:userId
        remark:remark
        extProfile:extProfile
        successBlock:^{
          if (completion) {
              completion(nil, nil);
          }
        }
        errorBlock:^(NSInteger errorCode, NSArray<NSString *> *_Nullable errorKeys) {
          if (completion) {
              completion(errorKeys, [NCError errorWithCode:errorCode]);
          }
        }];
}

- (void)updateGroupInfo:(NCGroupInfo *)groupInfo
             completion:(nullable void (^)(NSArray<NSString *> *_Nullable errorKeys,
                                           NCError *_Nullable error))completion {
    [[NCInfoManagement sharedInstance] updateGroupInfo:groupInfo
        successBlock:^{
          if (completion) {
              completion(nil, nil);
          }
        }
        errorBlock:^(NSInteger errorCode, NSArray<NSString *> *_Nullable errorKeys) {
          if (completion) {
              completion(errorKeys, [NCError errorWithCode:errorCode]);
          }
        }];
}

- (void)setGroupMemberInfo:(NSString *)groupId
                    userId:(NSString *)userId
                  nickname:(nullable NSString *)nickname
                     extra:(nullable NSString *)extra
                completion:(nullable void (^)(NSArray<NSString *> *_Nullable errorKeys,
                                              NCError *_Nullable error))completion {
    [[NCInfoManagement sharedInstance] setGroupMemberInfo:groupId
        userId:userId
        nickname:nickname
        extra:extra
        successBlock:^{
          if (completion) {
              completion(nil, nil);
          }
        }
        errorBlock:^(NSInteger errorCode, NSArray<NSString *> *_Nullable errorKeys) {
          if (completion) {
              completion(errorKeys, [NCError errorWithCode:errorCode]);
          }
        }];
}

- (void)sendMessageWithParams:(NCChatUISendMessageParams *)params
                   completion:(void (^)(NCMessage *_Nullable message,
                                        NCError *_Nullable error))completion {
    if (!params || params.channelId.length == 0 || params.content == nil) {
        if (completion) {
            completion(nil, [NCError errorWithCode:NCChatUIErrorCodeInvalidParameterMessage]);
        }
        return;
    }
    NCMessageContent *sendingContent = params.content;
    if (!sendingContent) {
        return;
    }
    [self attachCurrentUserInfoToMessageContent:sendingContent];
    if ([self beforeInterceptSendMessageWithParams:params]) {
        return;
    }
    sendingContent = params.content;
    if (!sendingContent) {
        if (completion) {
            completion(nil,
                       [NCError errorWithCode:NCChatUIErrorCodeInvalidParameterMessageContent]);
        }
        return;
    }
    NCBaseChannel *channel = [self sendingChannelWithType:params.channelType
                                                channelId:params.channelId
                                             subChannelId:params.subChannelId];
    if (!channel) {
        if (completion) {
            completion(nil, [NCError errorWithCode:NCChatUIErrorCodeInvalidParameterTargetId]);
        }
        return;
    }
    NCSendMessageParams *sendParams = [[NCSendMessageParams alloc] initWithContent:sendingContent];
    sendParams.needReceipt =
        params.needReceipt || [self shouldNeedReadReceiptForChannelType:params.channelType];
    sendParams.directedUserIds = params.directedUserIds;
    sendParams.disableNotification = params.disableNotification;
    sendParams.metadata = params.metadata;
    sendParams.pushConfig = params.pushConfig;
    [channel sendMessageWithParams:sendParams
        attachedHandler:^(NCMessage *_Nullable attachedMessage) {
          if (!attachedMessage) {
              return;
          }
          [[NSNotificationCenter defaultCenter] postNotificationName:NCUISendingMessageNotification
                                                              object:attachedMessage
                                                            userInfo:nil];
        }
        completionHandler:^(NCMessage *_Nullable sentMessage, NCError *_Nullable error) {
          BOOL isSensitiveWordReplaced =
              (error.code == NCChatUIErrorCodeMessageReplacedSensitiveWord);
          if (!error || isSensitiveWordReplaced) {
              [self postSendMessageSentNotificationWithNCMessage:sentMessage];
              [self sendMessageComplete:sentMessage error:nil];
              if (completion) {
                  completion(sentMessage, nil);
              }
              return;
          }
          [self postSendMessageErrorNotificationWithNCMessage:sentMessage error:error];
          [self sendMessageComplete:sentMessage error:error];
          if (completion) {
              completion(sentMessage, error);
          }
        }];
}

- (void)downloadMediaMessage:(long)clientId
                    progress:(void (^)(int progress))progressBlock
                  completion:(void (^)(NSString *_Nullable mediaPath,
                                       NCError *_Nullable error))completion
                      cancel:(void (^)(void))cancelBlock {
    NSNumber *messageNumber = @(clientId);
    NCChatUIMediaDownloadCallback *callback = [self mediaDownloadCallbackWithProgress:progressBlock
                                                                           completion:completion
                                                                               cancel:cancelBlock];
    [self addMediaDownloadCallback:callback clientId:messageNumber];

    if ([self.downloadingMeidaMessageIds containsObject:messageNumber]) {
        return;
    }

    [self addMeidaMessageId:messageNumber];

    NCGetMessageByIdParams *params =
        [[NCGetMessageByIdParams alloc] initWithMessageClientId:clientId];
    [NCBaseChannel
        getMessageByIdWithParams:params
                      completion:^(NCMessage *_Nullable message, NCError *_Nullable error) {
                        if (!message || error) {
                            [self removeMeidaMessageId:messageNumber];
                            NSInteger errorCode = error ? error.code : NCChatUIErrorCodeUnknown;
                            NCError *resolvedError =
                                error ?: [NCError errorWithCode:NCChatUIErrorCodeUnknown];
                            NSDictionary *statusDic = @{
                                @"clientId" : @(clientId),
                                @"type" : @"error",
                                @"errorCode" : @(errorCode)
                            };
                            [[NSNotificationCenter defaultCenter]
                                postNotificationName:NCUIDispatchDownloadMediaNotification
                                              object:nil
                                            userInfo:statusDic];
                            [self notifyMediaDownloadCompletionForClientId:messageNumber
                                                                 mediaPath:nil
                                                                     error:resolvedError];
                            return;
                        }
                        [message
                            downloadMediaWithProgressHandler:^(NSInteger progress) {
                              NSDictionary *statusDic = @{
                                  @"clientId" : @(clientId),
                                  @"type" : @"progress",
                                  @"progress" : @(progress)
                              };
                              [[NSNotificationCenter defaultCenter]
                                  postNotificationName:NCUIDispatchDownloadMediaNotification
                                                object:nil
                                              userInfo:statusDic];
                              [self notifyMediaDownloadProgressForClientId:messageNumber
                                                                  progress:(int)progress];
                            }
                            successHandler:^(NSString *_Nullable mediaPath) {
                              [self removeMeidaMessageId:messageNumber];
                              NSDictionary *statusDic = @{
                                  @"clientId" : @(clientId),
                                  @"type" : @"success",
                                  @"mediaPath" : mediaPath ?: @""
                              };
                              [[NSNotificationCenter defaultCenter]
                                  postNotificationName:NCUIDispatchDownloadMediaNotification
                                                object:nil
                                              userInfo:statusDic];
                              NCError *resolvedError =
                                  mediaPath.length > 0
                                      ? nil
                                      : [NCError errorWithCode:NCChatUIErrorCodeUnknown];
                              [self notifyMediaDownloadCompletionForClientId:messageNumber
                                                                   mediaPath:mediaPath
                                                                       error:resolvedError];
                            }
                            errorHandler:^(NCError *_Nullable error) {
                              [self removeMeidaMessageId:messageNumber];
                              NSInteger errorCode = error ? error.code : NCChatUIErrorCodeUnknown;
                              NCError *resolvedError =
                                  error ?: [NCError errorWithCode:NCChatUIErrorCodeUnknown];
                              NSDictionary *statusDic = @{
                                  @"clientId" : @(clientId),
                                  @"type" : @"error",
                                  @"errorCode" : @(errorCode)
                              };
                              [[NSNotificationCenter defaultCenter]
                                  postNotificationName:NCUIDispatchDownloadMediaNotification
                                                object:nil
                                              userInfo:statusDic];
                              [self notifyMediaDownloadCompletionForClientId:messageNumber
                                                                   mediaPath:nil
                                                                       error:resolvedError];
                            }
                            cancelHandler:^{
                              [self removeMeidaMessageId:messageNumber];
                              NSDictionary *statusDic =
                                  @{@"clientId" : @(clientId),
                                    @"type" : @"cancel"};
                              [[NSNotificationCenter defaultCenter]
                                  postNotificationName:NCUIDispatchDownloadMediaNotification
                                                object:nil
                                              userInfo:statusDic];
                              [self notifyMediaDownloadCancelForClientId:messageNumber];
                            }];
                      }];
}

- (void)downloadMediaFile:(NSString *)fileName
                 mediaUrl:(NSString *)mediaUrl
                 progress:(void (^)(int))progressBlock
               completion:(void (^)(NSString *_Nullable mediaPath,
                                    NCError *_Nullable error))completion
                   cancel:(void (^)(void))cancelBlock {
    [NCBaseChannel downloadMediaUrl:mediaUrl
        fileName:fileName
        progressHandler:^(NSInteger progress) {
          NSDictionary *statusDic =
              @{@"mediaUrl" : mediaUrl ?: @"",
                @"type" : @"progress",
                @"progress" : @(progress)};
          [[NSNotificationCenter defaultCenter]
              postNotificationName:NCUIDispatchDownloadMediaNotification
                            object:nil
                          userInfo:statusDic];
          if (progressBlock) {
              progressBlock((int)progress);
          }
        }
        completionHandler:^(NSString *_Nullable mediaPath, NCError *_Nullable error) {
          if (error || mediaPath.length == 0) {
              NSInteger errorCode = error ? error.code : NCChatUIErrorCodeUnknown;
              NCError *resolvedError = error ?: [NCError errorWithCode:NCChatUIErrorCodeUnknown];
              NSDictionary *statusDic =
                  @{@"mediaUrl" : mediaUrl ?: @"",
                    @"type" : @"error",
                    @"errorCode" : @(errorCode)};
              [[NSNotificationCenter defaultCenter]
                  postNotificationName:NCUIDispatchDownloadMediaNotification
                                object:nil
                              userInfo:statusDic];
              if (completion) {
                  completion(nil, resolvedError);
              }
              return;
          }
          NSDictionary *statusDic = @{
              @"mediaUrl" : mediaUrl ?: @"",
              @"type" : @"success",
              @"mediaPath" : mediaPath ?: @""
          };
          [[NSNotificationCenter defaultCenter]
              postNotificationName:NCUIDispatchDownloadMediaNotification
                            object:nil
                          userInfo:statusDic];
          if (completion) {
              completion(mediaPath, nil);
          }
        }
        cancelHandler:^{
          NSDictionary *statusDic = @{@"mediaUrl" : mediaUrl ?: @"", @"type" : @"cancel"};
          [[NSNotificationCenter defaultCenter]
              postNotificationName:NCUIDispatchDownloadMediaNotification
                            object:nil
                          userInfo:statusDic];
          if (cancelBlock) {
              cancelBlock();
          }
        }];
}

- (void)addMeidaMessageId:(NSNumber *)clientId {
    if (self.downloadingMeidaMessageIds.count <= 0) {
        self.downloadingMeidaMessageIds = [@[ clientId ] mutableCopy];
        return;
    }

    NSMutableArray *msgIds = [NSMutableArray arrayWithArray:self.downloadingMeidaMessageIds];
    [msgIds addObject:clientId];
    self.downloadingMeidaMessageIds = [msgIds copy];
}

- (void)removeMeidaMessageId:(NSNumber *)clientId {
    if (self.downloadingMeidaMessageIds.count <= 0) {
        return;
    }

    NSMutableArray *msgIds = [NSMutableArray arrayWithArray:self.downloadingMeidaMessageIds];
    [msgIds enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
      if ([obj isEqualToNumber:clientId]) {
          [msgIds removeObject:obj];
          *stop = YES;
      }
    }];
    self.downloadingMeidaMessageIds = [msgIds copy];
}

- (NCChatUIMediaDownloadCallback *)
    mediaDownloadCallbackWithProgress:(void (^)(int progress))progressBlock
                           completion:(void (^)(NSString *_Nullable mediaPath,
                                                NCError *_Nullable error))completion
                               cancel:(void (^)(void))cancelBlock {
    NCChatUIMediaDownloadCallback *callback = [[NCChatUIMediaDownloadCallback alloc] init];
    callback.progressBlock = progressBlock;
    callback.completion = completion;
    callback.cancelBlock = cancelBlock;
    return callback;
}

- (void)addMediaDownloadCallback:(NCChatUIMediaDownloadCallback *)callback
                        clientId:(NSNumber *)clientId {
    if (!callback || !clientId) {
        return;
    }
    if (!self.mediaDownloadCallbacks) {
        self.mediaDownloadCallbacks = [NSMutableDictionary dictionary];
    }
    NSMutableArray<NCChatUIMediaDownloadCallback *> *callbacks =
        self.mediaDownloadCallbacks[clientId];
    if (!callbacks) {
        callbacks = [NSMutableArray array];
        self.mediaDownloadCallbacks[clientId] = callbacks;
    }
    [callbacks addObject:callback];
}

- (NSArray<NCChatUIMediaDownloadCallback *> *)mediaDownloadCallbacksForClientId:(NSNumber *)clientId
                                                                         remove:(BOOL)remove {
    NSArray<NCChatUIMediaDownloadCallback *> *callbacks =
        [self.mediaDownloadCallbacks[clientId] copy] ?: @[];
    if (remove) {
        [self.mediaDownloadCallbacks removeObjectForKey:clientId];
    }
    return callbacks;
}

- (void)notifyMediaDownloadProgressForClientId:(NSNumber *)clientId progress:(int)progress {
    NSArray<NCChatUIMediaDownloadCallback *> *callbacks =
        [self mediaDownloadCallbacksForClientId:clientId remove:NO];
    for (NCChatUIMediaDownloadCallback *callback in callbacks) {
        if (callback.progressBlock) {
            callback.progressBlock(progress);
        }
    }
}

- (void)notifyMediaDownloadCompletionForClientId:(NSNumber *)clientId
                                       mediaPath:(NSString *_Nullable)mediaPath
                                           error:(NCError *_Nullable)error {
    NSArray<NCChatUIMediaDownloadCallback *> *callbacks =
        [self mediaDownloadCallbacksForClientId:clientId remove:YES];
    for (NCChatUIMediaDownloadCallback *callback in callbacks) {
        if (callback.completion) {
            callback.completion(error ? nil : mediaPath, error);
        }
    }
}

- (void)notifyMediaDownloadCancelForClientId:(NSNumber *)clientId {
    NSArray<NCChatUIMediaDownloadCallback *> *callbacks =
        [self mediaDownloadCallbacksForClientId:clientId remove:YES];
    for (NCChatUIMediaDownloadCallback *callback in callbacks) {
        if (callback.cancelBlock) {
            callback.cancelBlock();
        }
    }
}

- (BOOL)cancelDownloadMediaMessage:(long)clientId {
    NSNumber *messageNumber = @(clientId);
    if (![self.downloadingMeidaMessageIds containsObject:messageNumber]) {
        return NO;
    }

    NCGetMessageByIdParams *params =
        [[NCGetMessageByIdParams alloc] initWithMessageClientId:clientId];
    [NCBaseChannel
        getMessageByIdWithParams:params
                      completion:^(NCMessage *_Nullable message, NCError *_Nullable error) {
                        if (!message || error) {
                            return;
                        }
                        [message cancelDownloadingMediaWithCompletion:nil];
                      }];
    return YES;
}

- (void)sendMediaMessageWithParams:(NCChatUISendMediaMessageParams *)params
                          progress:(void (^)(int progress, NCMessage *progressMessage))progressBlock
                        completion:(void (^)(NCMessage *_Nullable message,
                                             NCError *_Nullable error))completion
                            cancel:(void (^)(NCMessage *cancelMessage))cancelBlock {
    if (!params || params.channelId.length == 0 || params.content == nil) {
        if (completion) {
            completion(nil, [NCError errorWithCode:NCChatUIErrorCodeInvalidParameterMessage]);
        }
        return;
    }
    NCMessageContent *sendingContent = params.content;
    if (!sendingContent) {
        return;
    }
    if (![sendingContent isKindOfClass:[NCMediaMessageContent class]]) {
        if (completion) {
            completion(nil,
                       [NCError errorWithCode:NCChatUIErrorCodeInvalidParameterMessageContent]);
        }
        return;
    }
    [self attachCurrentUserInfoToMessageContent:sendingContent];
    if ([self beforeInterceptSendMediaMessageWithParams:params]) {
        return;
    }
    sendingContent = params.content;
    if (![sendingContent isKindOfClass:[NCMediaMessageContent class]]) {
        if (completion) {
            completion(nil,
                       [NCError errorWithCode:NCChatUIErrorCodeInvalidParameterMessageContent]);
        }
        return;
    }
    NCBaseChannel *channel = [self sendingChannelWithType:params.channelType
                                                channelId:params.channelId
                                             subChannelId:params.subChannelId];
    if (!channel) {
        if (completion) {
            completion(nil, [NCError errorWithCode:NCChatUIErrorCodeInvalidParameterTargetId]);
        }
        return;
    }
    NCSendMediaMessageParams *sendParams =
        [[NCSendMediaMessageParams alloc] initWithContent:(NCMediaMessageContent *)sendingContent];
    sendParams.needReceipt =
        params.needReceipt || [self shouldNeedReadReceiptForChannelType:params.channelType];
    sendParams.directedUserIds = params.directedUserIds;
    sendParams.disableNotification = params.disableNotification;
    sendParams.metadata = params.metadata;
    sendParams.pushConfig = params.pushConfig;
    [channel sendMediaMessageWithParams:sendParams
        attachedHandler:^(NCMessage *_Nullable attachedMessage) {
          if (!attachedMessage) {
              return;
          }
          [[NSNotificationCenter defaultCenter] postNotificationName:NCUISendingMessageNotification
                                                              object:attachedMessage
                                                            userInfo:nil];
        }
        progressHandler:^(NSInteger progress, NCMessage *_Nullable progressMessage) {
          [self postSendMessageProgressNotificationWithNCMessage:progressMessage
                                                        progress:(int)progress];
          if (progressBlock) {
              progressBlock((int)progress, progressMessage);
          }
        }
        completionHandler:^(NCMessage *_Nullable sentMessage, NCError *_Nullable error) {
          BOOL isSensitiveWordReplaced =
              (error.code == NCChatUIErrorCodeMessageReplacedSensitiveWord);
          if (!error || isSensitiveWordReplaced) {
              [self postSendMessageSentNotificationWithNCMessage:sentMessage];
              [self sendMessageComplete:sentMessage error:nil];
              if (completion) {
                  completion(sentMessage, nil);
              }
              return;
          }
          [self postSendMessageErrorNotificationWithNCMessage:sentMessage error:error];
          [self sendMessageComplete:sentMessage error:error];
          if (completion) {
              completion(sentMessage, error);
          }
        }
        cancelHandler:^(NCMessage *_Nullable cancelMessage) {
          [self postSendMessageCancelNotificationWithNCMessage:cancelMessage];
          if (cancelBlock) {
              cancelBlock(cancelMessage);
          }
        }];
}

- (BOOL)cancelSendMediaMessage:(long)clientId {
    if ([[NCResendManager sharedManager] needResend:clientId]) {
        [[NCResendManager sharedManager] removeResendMessage:clientId];
        return YES;
    }
    return [NCBaseChannel cancelSendMediaMessageWithClientId:clientId];
}

- (BOOL)beforeInterceptSendMessageWithParams:(NCChatUISendMessageParams *)params {
    if ([self.messageInterceptor
            respondsToSelector:@selector(interceptWillSendMessageWithParams:)]) {
        return [self.messageInterceptor interceptWillSendMessageWithParams:params];
    }
    return NO;
}

- (BOOL)beforeInterceptSendMediaMessageWithParams:(NCChatUISendMediaMessageParams *)params {
    if ([self.messageInterceptor
            respondsToSelector:@selector(interceptWillSendMediaMessageWithParams:)]) {
        return [self.messageInterceptor interceptWillSendMediaMessageWithParams:params];
    }
    return NO;
}

- (NCBaseChannel *)sendingChannelWithType:(NCChannelType)channelType
                                channelId:(NSString *)channelId
                             subChannelId:(NSString *)subChannelId {
    switch (channelType) {
    case NCChannelTypeDirect:
        return [[NCDirectChannel alloc] initWithChannelId:channelId];
    case NCChannelTypeGroup:
        return [[NCGroupChannel alloc] initWithChannelId:channelId];
    case NCChannelTypeCommunity:
        return [[NCCommunitySubChannel alloc] initWithChannelId:channelId
                                                   subChannelId:(subChannelId ?: @"")];
    default:
        return nil;
    }
}

- (BOOL)shouldNeedReadReceiptForChannelType:(NCChannelType)channelType {
    return channelType == NCChannelTypeDirect || channelType == NCChannelTypeGroup;
}

- (NCPushConfig *)pushConfigWithPushContent:(NSString *)pushContent pushData:(NSString *)pushData {
    if (pushContent.length == 0 && pushData.length == 0) {
        return nil;
    }
    NCPushConfig *pushConfig = [NCPushConfig new];
    pushConfig.pushContent = pushContent;
    pushConfig.pushData = pushData;
    return pushConfig;
}

- (void)postSendMessageProgressNotificationWithNCMessage:(NCMessage *)message
                                                progress:(int)progress {
    if (!message) {
        return;
    }
    NSDictionary *statusDic = @{
        @"channelType" : @(message.channelIdentifier.channelType),
        @"channelId" : message.channelIdentifier.channelId ?: @"",
        @"subChannelId" :
                [message.channelIdentifier isKindOfClass:[NCCommunitySubChannelIdentifier class]]
            ? ((NCCommunitySubChannelIdentifier *)message.channelIdentifier).subChannelId ?: @""
            : @"",
        @"channelId" : message.channelIdentifier.channelId ?: @"",
        @"channelType" : @(message.channelIdentifier.channelType),
        @"clientId" : @(message.clientId),
        @"sentStatus" : @(NCMessageSentStatusSending),
        @"progress" : @(progress),
        @"message" : message
    };
    [[NSNotificationCenter defaultCenter] postNotificationName:NCUISendingMessageNotification
                                                        object:message
                                                      userInfo:statusDic];
}

- (void)postSendMessageSentNotificationWithNCMessage:(NCMessage *)message {
    if (!message) {
        return;
    }
    NSDictionary *statusDic = @{
        @"channelType" : @(message.channelIdentifier.channelType),
        @"channelId" : message.channelIdentifier.channelId ?: @"",
        @"subChannelId" :
                [message.channelIdentifier isKindOfClass:[NCCommunitySubChannelIdentifier class]]
            ? ((NCCommunitySubChannelIdentifier *)message.channelIdentifier).subChannelId ?: @""
            : @"",
        @"channelId" : message.channelIdentifier.channelId ?: @"",
        @"channelType" : @(message.channelIdentifier.channelType),
        @"clientId" : @(message.clientId),
        @"sentStatus" : @(NCMessageSentStatusSent),
        @"content" : message.content ?: [NSNull null],
        @"message" : message
    };
    [[NSNotificationCenter defaultCenter] postNotificationName:NCUISendingMessageNotification
                                                        object:message
                                                      userInfo:statusDic];
}

- (void)postSendMessageErrorNotificationWithNCMessage:(NCMessage *)message error:(NCError *)error {
    if (!message || !error) {
        return;
    }
    [[NCResendManager sharedManager] addResendMessageIfNeed:(long)message.clientId
                                                      error:(NCChatUIErrorCode)error.code];
    NSDictionary *statusDic = @{
        @"channelType" : @(message.channelIdentifier.channelType),
        @"channelId" : message.channelIdentifier.channelId ?: @"",
        @"subChannelId" :
                [message.channelIdentifier isKindOfClass:[NCCommunitySubChannelIdentifier class]]
            ? ((NCCommunitySubChannelIdentifier *)message.channelIdentifier).subChannelId ?: @""
            : @"",
        @"channelId" : message.channelIdentifier.channelId ?: @"",
        @"channelType" : @(message.channelIdentifier.channelType),
        @"clientId" : @(message.clientId),
        @"sentStatus" : @(NCMessageSentStatusFailed),
        @"error" : @(error.code),
        @"content" : message.content ?: [NSNull null],
        @"message" : message
    };
    [[NSNotificationCenter defaultCenter] postNotificationName:NCUISendingMessageNotification
                                                        object:message
                                                      userInfo:statusDic];
}

- (void)postSendMessageCancelNotificationWithNCMessage:(NCMessage *)message {
    if (!message) {
        return;
    }
    NSDictionary *statusDic = @{
        @"channelType" : @(message.channelIdentifier.channelType),
        @"channelId" : message.channelIdentifier.channelId ?: @"",
        @"subChannelId" :
                [message.channelIdentifier isKindOfClass:[NCCommunitySubChannelIdentifier class]]
            ? ((NCCommunitySubChannelIdentifier *)message.channelIdentifier).subChannelId ?: @""
            : @"",
        @"channelId" : message.channelIdentifier.channelId ?: @"",
        @"channelType" : @(message.channelIdentifier.channelType),
        @"clientId" : @(message.clientId),
        @"sentStatus" : @(NCMessageSentStatusCanceled),
        @"content" : message.content ?: [NSNull null],
        @"message" : message
    };
    [[NSNotificationCenter defaultCenter] postNotificationName:NCUISendingMessageNotification
                                                        object:message
                                                      userInfo:statusDic];
}

- (void)sendMessageComplete:(NCMessage *)message error:(NCError *)error {
    if (!message) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
      if (message &&
          [self.messageInterceptor respondsToSelector:@selector(interceptDidSendMessage:)]) {
          [self.messageInterceptor interceptDidSendMessage:message];
      }
    });
}

- (void)setScheme:(NSString *)scheme forExtensionModule:(NSString *)moduleName {
    [[NCChatUIExtensionManager sharedManager] setScheme:scheme forModule:moduleName];
}

- (BOOL)openExtensionModuleUrl:(NSURL *)url {
    return [[NCChatUIExtensionManager sharedManager] onOpenUrl:url];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [NCEngine removeMessageHandlerForIdentifier:NCChatUIMessageHandlerIdentifier];
    [NCEngine removeConnectionStatusHandlerForIdentifier:NCChatUIConnectionStatusHandlerIdentifier];
    [NCEngine removeChannelHandlerForIdentifier:NCChatUIChannelHandlerIdentifier];
    [self.networkStatusService stopMonitor];
}

- (void)attachCurrentUserInfoToMessageContent:(NCMessageContent *)content {
    if (NCChatUIConfigCenter.message.enableMessageAttachUserInfo && !content.senderUserInfo) {
        NCChatUIUserInfo *currentUserInfo = [NCChatUI shared].currentUserInfo;
        if (!currentUserInfo) {
            return;
        }
        NCUserInfo *senderUserInfo = [NCUserInfo new];
        senderUserInfo.userId = currentUserInfo.userId;
        senderUserInfo.name = currentUserInfo.name;
        senderUserInfo.portraitUri = currentUserInfo.avatarUrl;
        senderUserInfo.alias = currentUserInfo.alias;
        senderUserInfo.extra = currentUserInfo.extra;
        content.senderUserInfo = senderUserInfo;
    }
}

- (void)resetNotificationQuietStatus {
    [self refreshNoDisturbTimeWithCompletion:nil];
}

- (void)refreshNoDisturbTimeWithCompletion:(void (^)(NCError *_Nullable error))completion {
    [NCEngine getNoDisturbTimeWithCompletion:^(NCNoDisturbTimeInfo *_Nullable info,
                                               NCError *_Nullable error) {
      if (error) {
          if (completion) {
              completion(error);
          }
          return;
      }
      NSDateFormatter *dateFormatter = [self dateFormatter];
      NSString *startTime = info.startTime ?: @"";
      if (startTime.length > 0) {
          self.notificationQuietBeginTime = [dateFormatter dateFromString:startTime];
          self.notificationQuietEndTime =
              [self.notificationQuietBeginTime dateByAddingTimeInterval:info.spanMinutes * 60];
      } else {
          self.notificationQuietBeginTime = nil;
          self.notificationQuietEndTime = nil;
      }
      if (completion) {
          completion(nil);
      }
    }];
}

- (NSDateFormatter *)dateFormatter {
    static NSDateFormatter *formatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      formatter = [[NSDateFormatter alloc] init];
      [formatter setDateFormat:@"HH:mm:ss"];
    });
    return formatter;
}

- (void)delayNotifyUnConnectedStatus {
    NCConnectionStatus status = [self getConnectionStatus];
    if (NCConnectionStatusNetworkUnavailable == status || NCConnectionStatusUnknown == status ||
        NCConnectionStatusUnconnected == status) {
        [[NSNotificationCenter defaultCenter]
            postNotificationName:NCChatUIDispatchConnectionStatusChangedNotification
                          object:[NSNumber numberWithInteger:status]];
    }
}

- (void)p_notifyExtensionModulesDidConnectIfNeeded:(NSString *)userId {
    dispatch_async(dispatch_get_main_queue(), ^{
      if ([self getConnectionStatus] == NCConnectionStatusConnected &&
          !self.hasNotifiedExtensionModuleUserId) {
          self.hasNotifiedExtensionModuleUserId = YES;
          dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [[NCChatUIExtensionManager sharedManager] didConnect:userId];
          });
      }
    });
}

- (void)p_notifyNetworkStatusChanged:(NCChatUINetworkStatus)status {
    dispatch_async(dispatch_get_main_queue(), ^{
      NSArray<id<NCChatUINetworkStatusDelegate>> *delegates =
          [[NCEventCenter sharedManager] allNetworkStatusChangeDelegates];
      for (id<NCChatUINetworkStatusDelegate> delegate in delegates) {
          if ([delegate respondsToSelector:@selector(onNCChatUINetworkStatusChanged:)]) {
              [delegate onNCChatUINetworkStatusChanged:status];
          }
      }
    });
}

+ (NSString *)getVersion {
    return NexconnChatUIVersion;
}

@end
