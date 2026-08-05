#import <Foundation/Foundation.h>
#import <NexconnChatSDK/NexconnChatSDK.h>

NS_ASSUME_NONNULL_BEGIN

@interface NCChatUIUserInfo : NSObject

@property (nonatomic, copy, nullable) NSString *userId;
@property (nonatomic, copy, nullable) NSString *name;
@property (nonatomic, copy, nullable) NSString *avatarUrl;
@property (nonatomic, copy, nullable) NSString *alias;
@property (nonatomic, copy, nullable) NSString *extra;

@property (nonatomic, strong, nullable) NCUserProfile *profile;
@property (nonatomic, strong, nullable) NCFriendInfo *friendInfo;
@property (nonatomic, strong, nullable) NCGroupMemberInfo *memberInfo;

+ (instancetype)userInfoWithProfile:(NCUserProfile *)profile;
+ (instancetype)userInfoWithFriendInfo:(NCFriendInfo *)friendInfo;
+ (instancetype)userInfoWithMemberInfo:(NCGroupMemberInfo *)memberInfo;

@end

NS_ASSUME_NONNULL_END
