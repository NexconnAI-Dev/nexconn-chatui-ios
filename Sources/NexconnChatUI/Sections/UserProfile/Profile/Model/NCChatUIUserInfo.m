#import "NCChatUIUserInfo.h"

static NSString *NCChatUIJSONStringFromDictionary(NSDictionary *dictionary) {
    if (dictionary.count == 0) {
        return nil;
    }
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dictionary options:NSJSONWritingPrettyPrinted error:&error];
    if (!jsonData) {
        return nil;
    }
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

@implementation NCChatUIUserInfo

+ (instancetype)userInfoWithProfile:(NCUserProfile *)profile {
    if (!profile) {
        return nil;
    }
    NCChatUIUserInfo *managedUserInfo = [NCChatUIUserInfo new];
    managedUserInfo.profile = profile;
    return managedUserInfo;
}

+ (instancetype)userInfoWithFriendInfo:(NCFriendInfo *)friendInfo {
    if (!friendInfo) {
        return nil;
    }
    NCChatUIUserInfo *managedUserInfo = [NCChatUIUserInfo new];
    managedUserInfo.friendInfo = friendInfo;
    return managedUserInfo;
}

+ (instancetype)userInfoWithMemberInfo:(NCGroupMemberInfo *)memberInfo {
    if (!memberInfo) {
        return nil;
    }
    NCChatUIUserInfo *managedUserInfo = [NCChatUIUserInfo new];
    managedUserInfo.memberInfo = memberInfo;
    return managedUserInfo;
}

- (void)setProfile:(NCUserProfile *)profile {
    _profile = profile;
    if (!profile) {
        return;
    }
    self.userId = profile.userId;
    self.name = profile.name;
    self.avatarUrl = profile.avatarUrl;
    if (profile.extProfile.count > 0) {
        self.extra = NCChatUIJSONStringFromDictionary(profile.extProfile);
    }
}

- (void)setFriendInfo:(NCFriendInfo *)friendInfo {
    _friendInfo = friendInfo;
    if (!friendInfo) {
        return;
    }
    self.userId = friendInfo.userId;
    self.name = friendInfo.name;
    self.alias = friendInfo.remark;
    self.avatarUrl = friendInfo.avatarUrl;
    if (friendInfo.extProfile.count > 0) {
        self.extra = NCChatUIJSONStringFromDictionary(friendInfo.extProfile);
    }
}

- (void)setMemberInfo:(NCGroupMemberInfo *)memberInfo {
    _memberInfo = memberInfo;
    if (!memberInfo) {
        return;
    }
    self.userId = memberInfo.userId;
    self.name = memberInfo.name;
    self.avatarUrl = memberInfo.avatarUrl;
    self.extra = memberInfo.extra;
}

@end
