//
//  NCLocalNotification.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCLocalNotification.h"
#import <UIKit/UIKit.h>
#import "NCChatUICommonDefine.h"
#import "NCChatUIUtility.h"
#import "NCChatUI.h"
#import "NCUserInfoCacheManager.h"
#import "NCChatUIUserInfo.h"
#import "NCChatUIGroup.h"
#import "NCChatUIExtensionManager.h"
#import "NCChatUIConfig.h"
#import <NexconnChatSDK/NexconnChatSDK.h>
#if __IPHONE_10_0
#import <UserNotifications/UserNotifications.h>
#endif

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

static NCLocalNotification *sharedLocalNotification = nil;
static NSString *const NCLocalNotificationBundledSoundFileName = @"sms-received.caf";
static NSString *const NCLocalNotificationPreparedSoundFileName = @"nc_sms_received.caf";

@interface NCLocalNotification ()

@property (nonatomic, strong) UILocalNotification *localNotification;

@property (nonatomic, assign) BOOL haveLocationSound;

- (NSString *)notificationRequestIdentifierForMessage:(NCMessage *)message;
@end

@implementation NCLocalNotification

+ (NCLocalNotification *)defaultCenter {
    @synchronized(self) {
        if (nil == sharedLocalNotification) {
            sharedLocalNotification = [[[self class] alloc] init];
            NSString *soundName = [[self class] preparedDefaultNotificationSoundName];
            sharedLocalNotification.haveLocationSound = (soundName.length > 0);
        }
    }

    return sharedLocalNotification;
}

+ (NSString *)preparedDefaultNotificationSoundName {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *bundlePath = [NCChatUIUtility bundlePathWithName:@"NCChatUI"];
    NSString *sourcePath = [bundlePath stringByAppendingPathComponent:NCLocalNotificationBundledSoundFileName];
    if (![fileManager fileExistsAtPath:sourcePath]) {
        return nil;
    }

    NSURL *libraryURL = [fileManager URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask].firstObject;
    if (!libraryURL) {
        return nil;
    }

    NSURL *soundsURL = [libraryURL URLByAppendingPathComponent:@"Sounds" isDirectory:YES];
    NSError *directoryError = nil;
    if (![fileManager createDirectoryAtURL:soundsURL
                withIntermediateDirectories:YES
                                 attributes:nil
                                      error:&directoryError]) {
        NCLogD(@"[NexconnChatUI]: Failed to create local notification Sounds directory: %@", directoryError);
        return nil;
    }

    NSURL *destinationURL = [soundsURL URLByAppendingPathComponent:NCLocalNotificationPreparedSoundFileName];
    NSDictionary<NSFileAttributeKey, id> *sourceAttributes = [fileManager attributesOfItemAtPath:sourcePath error:nil];
    NSDictionary<NSFileAttributeKey, id> *destinationAttributes =
        [fileManager attributesOfItemAtPath:destinationURL.path error:nil];
    if (destinationAttributes && [sourceAttributes[NSFileSize] isEqual:destinationAttributes[NSFileSize]]) {
        return NCLocalNotificationPreparedSoundFileName;
    }

    if (destinationAttributes && ![fileManager removeItemAtURL:destinationURL error:nil]) {
        return nil;
    }

    NSError *copyError = nil;
    if (![fileManager copyItemAtPath:sourcePath toPath:destinationURL.path error:&copyError]) {
        NCLogD(@"[NexconnChatUI]: Failed to prepare local notification sound: %@", copyError);
        return nil;
    }
    return NCLocalNotificationPreparedSoundFileName;
}

- (void)postLocalNotificationWithMessage:(NCMessage *)message userInfo:(NSDictionary *)userInfo {
    [self getNotificationInfo:message result:^(NSString *senderName, NSString *pushContent) {
        if ([[NCChatUIExtensionManager sharedManager] handleNotificationForMessageReceived:message from:senderName userInfo:userInfo]) {
            return;
        }
        if ([self shouldStopLocalNotificationWithMessage:message senderName:senderName]) {
            return;
        }
        [self postLocalNotification:senderName pushContent:pushContent message:message userInfo:userInfo];
    } errorBlock:^(NSString *errorDescription) {
        NCLogE(@"%@", errorDescription);
    }];
}

- (BOOL)shouldStopLocalNotificationWithMessage:(NCMessage *)message senderName:(NSString *)senderName {
    id<NCChatUIMessagePolicyDelegate> delegate = [NCChatUI shared].messagePolicyDelegate;
    if ([delegate respondsToSelector:@selector(shouldSuppressLocalNotificationForMessage:senderName:)] &&
        [delegate shouldSuppressLocalNotificationForMessage:message senderName:senderName]) {
        return YES;
    }
    return NO;
}

- (void)postLocalNotification:(NSString *)formatMessage userInfo:(NSDictionary *)userInfo {
    if (nil == _localNotification) {
        _localNotification = [[UILocalNotification alloc] init];
    }

    _localNotification.alertAction = NCUILocalizedString(@"local_notification_show");
    formatMessage = [formatMessage stringByReplacingOccurrencesOfString:@"%" withString:@"%%"];
    _localNotification.alertBody = formatMessage;
    _localNotification.userInfo = userInfo;

    NSString *soundName = [[self class] preparedDefaultNotificationSoundName];
    _haveLocationSound = (soundName.length > 0);
    if (_haveLocationSound) {
        [_localNotification setSoundName:soundName];
    } else {
        [_localNotification setSoundName:UILocalNotificationDefaultSoundName];
    }
    // NSDictionary *dict = @{@"key1": [NSString stringWithFormat:@"%d", NC_LOCAL_NOTIFICATION_TAG]};
    //[localNotify setUserInfo:dict];
    dispatch_async(dispatch_get_main_queue(), ^{
        [[UIApplication sharedApplication] presentLocalNotificationNow:_localNotification];
    });
}

#pragma mark - Private Method
- (void)postLocalNotification:(NSString *)senderName pushContent:(NSString *)pushContent message:(NCMessage *)message userInfo:(NSDictionary *)userInfo {
    NCMessagePushConfig *pushConfig = message.pushConfig;
    NSString *title = @"";
    NSString *soundName = [[self class] preparedDefaultNotificationSoundName];
    _haveLocationSound = (soundName.length > 0);
    if (pushConfig && [self pushTitleEffectived:pushConfig.pushTitle]) {
        title = pushConfig.pushTitle;
    } else {
        title = senderName;
    }
    if (pushConfig && pushConfig.pushContent && pushConfig.pushContent.length > 0) {
        pushContent = pushConfig.pushContent;
    } else {
        pushContent = [pushContent stringByReplacingOccurrencesOfString:@"%" withString:@"%%"];
    }
    
    if (@available(iOS 10.0, *)) {
        UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
        if (!message.pushConfig.disablePushTitle) {
            content.title = title;
        }
        content.body = pushContent;
        content.userInfo = userInfo;
        if (_haveLocationSound) {
            content.sound = [UNNotificationSound soundNamed:soundName];
        } else {
            content.sound = [UNNotificationSound defaultSound];
        }
        NSString *requestWithIdentifier = [self notificationRequestIdentifierForMessage:message];
        if (pushConfig) {
            if (pushConfig.threadId) {
                content.threadIdentifier = pushConfig.threadId;
            }
        }
        UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:requestWithIdentifier content:content trigger:nil];
        [[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
        }];
    } else {
        if (nil == _localNotification) {
            _localNotification = [[UILocalNotification alloc] init];
        }
        _localNotification.alertAction = NCUILocalizedString(@"local_notification_show");
        if (@available(iOS 8.2, *)) {
            if (!message.pushConfig.disablePushTitle) {
                _localNotification.alertTitle = title;
            }
        }
        _localNotification.alertBody = pushContent;
        _localNotification.userInfo = userInfo;

        if (_haveLocationSound) {
            [_localNotification setSoundName:soundName];
        } else {
            [_localNotification setSoundName:UILocalNotificationDefaultSoundName];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [[UIApplication sharedApplication] presentLocalNotificationNow:_localNotification];
        });
    }
}

- (NSString *)notificationRequestIdentifierForMessage:(NCMessage *)message {
    NCMessagePushConfig *pushConfig = message.pushConfig;
    if (pushConfig.apnsCollapseId.length > 0) {
        return pushConfig.apnsCollapseId;
    }
    if (message.messageId.length > 0) {
        return message.messageId;
    }

    NCChannelIdentifier *channelIdentifier = message.channelIdentifier;
    NSString *channelId = channelIdentifier.channelId ?: @"";
    NSString *senderUserId = message.senderUserId ?: @"";
    long long clientId = message.clientId;
    long long sentTime = message.sentTime;
    if (channelId.length > 0 || senderUserId.length > 0 || clientId > 0 || sentTime > 0) {
        return [NSString stringWithFormat:@"nc-local-%ld-%@-%@-%lld-%lld",
                                          (long)channelIdentifier.channelType,
                                          channelId,
                                          senderUserId,
                                          clientId,
                                          sentTime];
    }
    return [[NSUUID UUID] UUIDString];
}

- (void)getNotificationInfo:(NCMessage *)message
                     result:(void (^)(NSString *senderName, NSString *pushContent))resultBlock
                 errorBlock:(void (^)(NSString *errorDescription))errorBlock {
    __block NSString *showMessage = nil;
    BOOL isUnknown = (!message.content || [message.content isKindOfClass:[NCUnknownMessage class]]);
    if (NCChatUIConfigCenter.message.showUnkownMessageNotificaiton && message.messageType && isUnknown) {
        showMessage = NCUILocalizedString(@"unknown_message_notification_tip");
    } else if (message.content.mentionedInfo.isMentionedMe) {
        if (!message.content.mentionedInfo.mentionedContent) {
            showMessage = [NCChatUIUtility formatLocalNotificationWithNCMessage:message];
        } else {
            showMessage = message.content.mentionedInfo.mentionedContent;
        }
    } else {
        showMessage = [NCChatUIUtility formatLocalNotificationWithNCMessage:message];
    }

    if ((NCChannelTypeGroup == message.channelIdentifier.channelType)) {
        [self p_getGroupNotificationInfo:message originalShowMessage:showMessage result:resultBlock errorBlock:errorBlock];
    } else if (NCChannelTypeSystem == message.channelIdentifier.channelType) {
        [self p_getSystemNotificationInfo:message originalShowMessage:showMessage result:resultBlock errorBlock:errorBlock];
    } else {
        [self p_getOthersNotificationInfo:message originalShowMessage:showMessage result:resultBlock errorBlock:errorBlock];
    }
}

- (NSString *)formatGroupNotification:(NCMessage *)message
                                group:(NCChatUIGroup *)groupInfo
                                 user:(NCChatUIUserInfo *)userInfo
                          showMessage:(NSString *)showMessage {
    if (@available(iOS 8.2, *)) {
        if (message.content.mentionedInfo.isMentionedMe) {
            if (!message.content.mentionedInfo.mentionedContent) {
                showMessage = [NSString
                    stringWithFormat:@"%@%@:%@",
                               NCUILocalizedString(@"have_mentioned_for_notification"),
                                     [NCChatUIUtility getDisplayName:userInfo], showMessage];
            }
        } else {
            showMessage = [NSString stringWithFormat:@"%@:%@", [NCChatUIUtility getDisplayName:userInfo], showMessage];
        }
    } else {
        if (message.content.mentionedInfo.isMentionedMe) {
            if (!message.content.mentionedInfo.mentionedContent) {
                showMessage = [NSString
                    stringWithFormat:@"%@%@(%@):%@",
                               NCUILocalizedString(@"have_mentioned_for_notification"),
                               [NCChatUIUtility getDisplayName:userInfo], groupInfo.groupName, showMessage];
            }
        } else {
            showMessage = [NSString stringWithFormat:@"%@(%@):%@", [NCChatUIUtility getDisplayName:userInfo], groupInfo.groupName, showMessage];
        }
    }
    
    return showMessage;
}

- (NSString *)formatOtherNotification:(NCMessage *)message name:(NSString *)name showMessage:(NSString *)showMessage {
    if (@available(iOS 8.2, *)) {
        showMessage = [NSString stringWithFormat:@"%@", showMessage];
    } else {
        showMessage = [NSString stringWithFormat:@"%@:%@", name, showMessage];
    }
    return showMessage;
}

- (BOOL)pushTitleEffectived:(NSString *)pushTitle {
    // Treat a whitespace-only pushTitle as unset.
    if (pushTitle && pushTitle.length > 0 && [[pushTitle stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length] > 0) {
        return YES;
    }
    return NO;
}

#pragma clang diagnostic pop

#pragma -mark private method
- (void)p_getGroupNotificationInfo:(NCMessage *)message
               originalShowMessage:(NSString *)originalShowMessage
                            result:(void (^)(NSString *senderName, NSString *pushContent))resultBlock
                        errorBlock:(void (^)(NSString *errorDescription))errorBlock {
    __block NSString *showMessage = [originalShowMessage copy];
    [[NCUserInfoCacheManager sharedManager] getGroupInfo:message.channelIdentifier.channelId
                                                complete:^(NCChatUIGroup *groupInfo) {
        if (nil == groupInfo) {
            if (errorBlock) {
                NSString *errorDes = @"...................postLocalNotification failed, groupInfo is NULL, please call [[NCChatUI shared] refreshGroupInfoCache:(NCChatUIGroup *)groupInfo] ...................";
                errorBlock(errorDes);
            }
            // 群信息缓存缺失时兜底展示：仍使用原始消息内容生成通知，避免直接丢弃。
            if (resultBlock) {
                resultBlock(@"", showMessage);
            }
            return;
        }
        [[NCUserInfoCacheManager sharedManager]
            getUserInfo:message.senderUserId
               complete:^(NCChatUIUserInfo *userInfo) {

                   if (userInfo) {
                       showMessage =
                           [self formatGroupNotification:message
                                                   group:groupInfo
                                                    user:userInfo
                                             showMessage:showMessage];
                       resultBlock(groupInfo.groupName, showMessage);
                   }else {
                       if (errorBlock) {
                           NSString *errorDes = @"...................postLocalNotification failed, groupUserInfo is NULL, please call  [[NCChatUI shared] refreshGroupUserInfoCache:(NCChatUIUserInfo *)userInfo withUserId:(NSString *)userId withGroupId:(NSString *)groupId] ...................";
                           errorBlock(errorDes);
                       }
                       // 群成员信息缓存缺失时兜底展示：以群名称作为标题，展示原始消息内容。
                       if (resultBlock) {
                           resultBlock(groupInfo.groupName ?: @"", showMessage);
                       }
                   }
               }];
    }];
}

- (void)p_getSystemNotificationInfo:(NCMessage *)message
                originalShowMessage:(NSString *)originalShowMessage
                             result:(void (^)(NSString *senderName, NSString *pushContent))resultBlock
                         errorBlock:(void (^)(NSString *errorDescription))errorBlock {
    __block NSString *showMessage = [originalShowMessage copy];
    [[NCUserInfoCacheManager sharedManager] getUserInfo:message.channelIdentifier.channelId complete:^(NCChatUIUserInfo *userInfo) {
        if (nil == userInfo) {
            if (errorBlock) {
                NSString *errorDes = @"...................postLocalNotification failed, userInfo is NULL, please call  [[NCChatUI shared] refreshUserInfoCache:(NCChatUIUserInfo *)userInfo withUserId:(NSString *)userId] ...................";
                errorBlock(errorDes);
            }
            // 用户信息缓存缺失时兜底展示：仍使用原始消息内容生成通知，避免直接丢弃。
            if (resultBlock) {
                resultBlock(@"", showMessage);
            }
            return;
        }
        NSString *dispalyName = [NCChatUIUtility getDisplayName:userInfo];
        showMessage = [self formatOtherNotification:message name:dispalyName showMessage:showMessage];
        if (resultBlock) {
            resultBlock(dispalyName, showMessage);
        }
    }];
}

- (void)p_getOthersNotificationInfo:(NCMessage *)message
                originalShowMessage:(NSString *)originalShowMessage
                             result:(void (^)(NSString *senderName, NSString *pushContent))resultBlock
                         errorBlock:(void (^)(NSString *errorDescription))errorBlock {
    __block NSString *showMessage = [originalShowMessage copy];
    [[NCUserInfoCacheManager sharedManager] getUserInfo:message.channelIdentifier.channelId complete:^(NCChatUIUserInfo *userInfo) {
        if (nil == userInfo) {
            if (errorBlock) {
                NSString *errorDes = @"...................postLocalNotification failed, userInfo is NULL, please call  [[NCChatUI shared] refreshUserInfoCache:(NCChatUIUserInfo *)userInfo withUserId:(NSString *)userId] ...................";
                errorBlock(errorDes);
            }
            // 用户信息缓存缺失时兜底展示：仍使用原始消息内容生成通知，避免直接丢弃。
            if (resultBlock) {
                resultBlock(@"", showMessage);
            }
            return;
        }
        NSString *dispalyName = [NCChatUIUtility getDisplayName:userInfo];
        showMessage = [self formatOtherNotification:message name:dispalyName showMessage:showMessage];
        if (resultBlock) {
            resultBlock(dispalyName, showMessage);
        }
    }];
}
@end
