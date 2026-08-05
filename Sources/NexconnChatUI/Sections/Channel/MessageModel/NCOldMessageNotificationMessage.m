//
//  NCOldMessageNotificationMessage.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCOldMessageNotificationMessage.h"

@implementation NCOldMessageNotificationMessage

- (instancetype)init {
    self = [super init];
    if (self) {
        // self.type = aType;
    }
    return self;
}

- (NSDictionary<NSString *, id> *)encodeFields {
    return @{};
}

- (void)decodeWithFields:(NSDictionary<NSString *,id> *)fields {
    (void)fields;
}

+ (NSString *)messageType {
    return NCOldMessageNotificationMessageTypeIdentifier;
}

+ (NCMessagePersistent)persistentFlag {
    return NCMessagePersistentNone;
}

#if !__has_feature(objc_arc)
- (void)dealloc {
    [super dealloc];
}
#endif //__has_feature(objc_arc)
@end

@implementation NCInformationNotificationMessage

+ (NSString *)messageType {
    return NCInformationNotificationMessageIdentifier;
}

+ (NCMessagePersistent)persistentFlag {
    return NCMessagePersistentPersisted;
}

+ (instancetype)notificationWithMessage:(NSString *)message extra:(NSString *)extra {
    NCInformationNotificationMessage *notif = [[NCInformationNotificationMessage alloc] init];
    notif.message = message ?: @"";
    notif.extra = extra;
    return notif;
}

- (NSDictionary<NSString *,id> *)encodeFields {
    NSMutableDictionary<NSString *, id> *fields = [NSMutableDictionary dictionary];
    if (self.message.length > 0) {
        fields[@"message"] = self.message;
    }
    return fields;
}

- (void)decodeWithFields:(NSDictionary<NSString *,id> *)fields {
    self.message = [fields[@"message"] isKindOfClass:[NSString class]] ? fields[@"message"] : @"";
}

- (NSString *)conversationDigest {
    return self.message ?: @"";
}

@end

@implementation NCGroupNotificationMessage

+ (NSString *)messageType {
    return NCGroupNotificationMessageIdentifier;
}

+ (NCMessagePersistent)persistentFlag {
    return NCMessagePersistentPersisted;
}

+ (instancetype)notificationWithOperation:(NSString *)operation
                           operatorUserId:(NSString *)operatorUserId
                                     data:(NSString *)data
                                  message:(NSString *)message
                                    extra:(NSString *)extra {
    NCGroupNotificationMessage *notif = [[NCGroupNotificationMessage alloc] init];
    notif.operation = operation ?: @"";
    notif.operatorUserId = operatorUserId ?: @"";
    notif.data = data ?: @"";
    notif.message = message ?: @"";
    notif.extra = extra;
    return notif;
}

- (NSDictionary<NSString *,id> *)encodeFields {
    NSMutableDictionary<NSString *, id> *fields = [NSMutableDictionary dictionary];
    if (self.operation.length > 0) {
        fields[@"operation"] = self.operation;
    }
    if (self.operatorUserId.length > 0) {
        fields[@"operatorUserId"] = self.operatorUserId;
    }
    if (self.data.length > 0) {
        fields[@"data"] = self.data;
    }
    if (self.message.length > 0) {
        fields[@"message"] = self.message;
    }
    return fields;
}

- (void)decodeWithFields:(NSDictionary<NSString *,id> *)fields {
    self.operation = [fields[@"operation"] isKindOfClass:[NSString class]] ? fields[@"operation"] : @"";
    self.operatorUserId = [fields[@"operatorUserId"] isKindOfClass:[NSString class]] ? fields[@"operatorUserId"] : @"";
    self.data = [fields[@"data"] isKindOfClass:[NSString class]] ? fields[@"data"] : @"";
    self.message = [fields[@"message"] isKindOfClass:[NSString class]] ? fields[@"message"] : @"";
}

- (NSString *)conversationDigest {
    return self.message ?: @"";
}

@end
