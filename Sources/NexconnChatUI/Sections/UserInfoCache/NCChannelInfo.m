//
//  NCChannelInfo.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCChannelInfo.h"
#import "NCChatUIGroup.h"

static BOOL NCChannelInfoNullableStringEqual(NSString *lhs, NSString *rhs) {
    return lhs == rhs || [lhs isEqualToString:rhs];
}

static BOOL NCChannelInfoChatUIGroupEqual(NCChatUIGroup *lhs, NCChatUIGroup *rhs) {
    return lhs == rhs ||
           (NCChannelInfoNullableStringEqual(lhs.groupId, rhs.groupId) &&
            NCChannelInfoNullableStringEqual(lhs.groupName, rhs.groupName) &&
            NCChannelInfoNullableStringEqual(lhs.avatarUrl, rhs.avatarUrl) &&
            NCChannelInfoNullableStringEqual(lhs.extra, rhs.extra) &&
            NCChannelInfoNullableStringEqual(lhs.notice, rhs.notice));
}

@implementation NCChannelInfo

- (instancetype)initWithConversationId:(NSString *)channelId
                      channelType:(NCChannelType)channelType
                                  name:(NSString *)name
                           avatarUrl:(NSString *)avatarUrl
                                 extra:(NSString *)extra{
    self = [super init];

    if (self) {
        _channelId = channelId;
        _channelType = channelType;
        _name = name;
        _avatarUrl = avatarUrl;
        _extra = extra;
    }

    return self;
}

- (instancetype)initWithGroupInfo:(NCChatUIGroup *)groupInfo {
    self = [self initWithConversationId:groupInfo.groupId
                       channelType:NCChannelTypeGroup
                                   name:groupInfo.groupName
                            avatarUrl:groupInfo.avatarUrl
                                  extra:groupInfo.extra];
    if (self) {
        _groupInfo = groupInfo;
    }
    return self;
}

- (NCChatUIGroup *)translateToGroupInfo {
    if (self.channelType != NCChannelTypeGroup) {
        return nil;
    }
    if (self.groupInfo) {
        return self.groupInfo;
    }
    NCChatUIGroup *groupInfo = [NCChatUIGroup new];
    groupInfo.groupId = self.channelId;
    groupInfo.groupName = self.name;
    groupInfo.avatarUrl = self.avatarUrl;
    groupInfo.extra = self.extra;
    return groupInfo;
}

+ (NSString *)getConversationGUID:(NCChannelType)channelType channelId:(NSString *)channelId {
    if (channelId) {
        return [NSString stringWithFormat:@"%lu;;;%@", (unsigned long)channelType, channelId];
    } else {
        return nil;
    }
}
- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[self class]]) {
        NCChannelInfo *o = (NCChannelInfo *)object;
        return [_channelId isEqualToString:o.channelId] && (_channelType == o.channelType) &&
               (_avatarUrl == o.avatarUrl || [_avatarUrl isEqualToString:o.avatarUrl]) &&
               (_name == o.name || [_name isEqualToString:o.name]) &&
               (_extra == o.extra || [_extra isEqualToString:o.extra]) &&
               NCChannelInfoChatUIGroupEqual(self.groupInfo, o.groupInfo);
    }
    return NO;
}
@end
