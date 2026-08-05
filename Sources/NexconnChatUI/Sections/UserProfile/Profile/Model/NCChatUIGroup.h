#import <Foundation/Foundation.h>
#import <NexconnChatSDK/NexconnChatSDK.h>

NS_ASSUME_NONNULL_BEGIN

/// ChatUI display/cache model for group identity shown in conversation list, messages, notifications, and group UI.
///
/// `groupInfo` is kept as a temporary compatibility bridge for callers that still receive SDK group details.
/// New ChatUI cache/display code should read the flat fields on this object. SDK update/detail paths should use
/// `NCGroupInfo` or explicit update params instead of treating this object as a backing SDK model.
@interface NCChatUIGroup : NSObject

/// The unique group identifier.
@property (nonatomic, copy, nullable) NSString *groupId;

/// The group display name used by ChatUI surfaces.
@property (nonatomic, copy, nullable) NSString *groupName;

/// The group avatar URL used by conversation lists, notifications, and profile UI.
@property (nonatomic, copy, nullable) NSString *avatarUrl;

/// Custom display extension data provided by the ChatUI data source or cache.
@property (nonatomic, copy, nullable) NSString *extra;

/// The group notice text used by group profile and related ChatUI views.
@property (nonatomic, copy, nullable) NSString *notice;

/// Temporary compatibility bridge to SDK group details. Do not use as the ChatUI cache truth source.
@property (nonatomic, strong, nullable) NCGroupInfo *groupInfo;

/// Creates a ChatUI group display model from SDK group details.
///
/// The returned object copies display fields from `groupInfo` and keeps `groupInfo` as a temporary compatibility bridge.
+ (instancetype)groupWithGroupInfo:(NCGroupInfo *)groupInfo;

@end

NS_ASSUME_NONNULL_END
