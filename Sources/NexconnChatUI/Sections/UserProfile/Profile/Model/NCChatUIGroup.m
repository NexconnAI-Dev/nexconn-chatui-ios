#import "NCChatUIGroup.h"

@implementation NCChatUIGroup

+ (instancetype)groupWithGroupInfo:(NCGroupInfo *)groupInfo {
    if (!groupInfo) {
        return nil;
    }
    NCChatUIGroup *managedGroup = [NCChatUIGroup new];
    managedGroup.groupInfo = groupInfo;
    return managedGroup;
}

- (void)setGroupInfo:(NCGroupInfo *)groupInfo {
    _groupInfo = groupInfo;
    if (!groupInfo) {
        return;
    }
    self.groupId = groupInfo.groupId;
    self.groupName = groupInfo.groupName;
    self.avatarUrl = groupInfo.avatarUrl;
    self.notice = groupInfo.notice;
}

@end
