//
//  NCChatUIConf.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCChatUIThemeDefine.h"
#import <UIKit/UIKit.h>
typedef NS_ENUM(NSInteger, NCChatUIInterfaceLayoutDirection) {
    NCChatUIInterfaceLayoutDirectionUnspecified,
    NCChatUIInterfaceLayoutDirectionLeftToRight,
    NCChatUIInterfaceLayoutDirectionRightToLeft,
};

NS_ASSUME_NONNULL_BEGIN

@interface NCChatUIConf : NSObject
#pragma mark Avatar Display

/// Global navigation bar button tint color for the SDK.
///
/// Default is [UIColor blackColor].
@property (nonatomic, strong) UIColor *globalNavigationBarTintColor;

/// Avatar shape displayed in the SDK channel list, rectangle or circle.
///
/// Default is rectangle, i.e. `NC_USER_AVATAR_RECTANGLE`.
@property (nonatomic, assign) NCUserAvatarStyle globalConversationAvatarStyle;

/// Avatar size displayed in the SDK channel list. Height must be >= 36.
///
/// Default is 46x46.
@property (nonatomic, assign) CGSize globalConversationPortraitSize;

/// Avatar for aggregated channels in the SDK channel list.
///
/// If not set, the built-in default avatar is used.
///
/// Dictionary key-value description:
/// - key:  Aggregated channel type `NCChannelType`
/// - value: Image path (supports local path or remote URL)
@property (nonatomic, strong, nullable)
    NSDictionary<NSNumber *, NSString *> *globalConversationCollectionAvatarDic;

/// Title for aggregated channels in the SDK channel list.
///
/// If not set, the built-in default title is used.
/// key: Aggregated channel type NCChannelType
/// value: Aggregated channel title NSString
@property (nonatomic, strong, nullable)
    NSDictionary<NSNumber *, NSString *> *globalConversationCollectionTitleDic;

/// Avatar shape displayed on the SDK channel page, rectangle or circle.
///
/// Default is rectangle, i.e. NC_USER_AVATAR_RECTANGLE.
@property (nonatomic, assign) NCUserAvatarStyle globalMessageAvatarStyle;

/// Avatar size displayed on the SDK channel page.
///
/// Default is 40x40.
@property (nonatomic, assign) CGSize globalMessagePortraitSize;

/// Corner radius for avatars on the SDK channel list and channel page.
///
/// Default is 4. Only takes effect when the avatar shape is set to rectangle.
/// See globalConversationAvatarStyle and globalMessageAvatarStyle.
@property (nonatomic, assign) CGFloat portraitImageViewCornerRadius;

/// Whether to support dark mode. Default is NO. When enabled, UI supports dark mode and follows
/// system appearance.
@property (nonatomic, assign) BOOL enableDarkMode;

/// SDK UI layout direction.
///
/// Default is NCChatUIInterfaceLayoutDirectionUnspecified.
@property (nonatomic, assign) NCChatUIInterfaceLayoutDirection layoutDirection;

/// File message icon configuration. Key is file suffix (e.g. "png", "pdf"), value is local file
/// path.
@property (nonatomic, copy, readonly) NSDictionary *fileSuffixDictionary;

/// Whether to show online status indicators.
///
/// Default is NO.
/// When enabled, online status indicators are shown in channel list, channel page, and contact
/// list.
@property (nonatomic, assign) BOOL enableUserOnlineStatus;

/// Specifies the display language. Defaults to the system language.
///
/// Built-in languages:
///  - NCChatUILanguageZH_HANS  Simplified Chinese
///  - NCChatUILanguageEN       English
///  - NCChatUILanguageAR       Arabic
///
/// **Supported language formats:**
/// - **Standard BCP-47 format**
///   - `zh-Hans` (Simplified Chinese)
///   - `en` (English)
///   - `ar` (Arabic)
///
/// **The language identifier should match the lproj folder name created in Xcode.**
///
/// **Adding new language support:**
/// 1. Add the corresponding `.lproj` folder to the project (e.g. `ja.lproj`, `zh-Hant.lproj`)
/// 2. Copy `NCChatUI.strings` into the new folder and translate. Path structure: `Project Folder`
/// -> `ja.lproj` -> `NCChatUI.strings`
/// 3. No code changes needed; the system will automatically recognize and support the new language.
///
/// **Example:**
/// ```objc
/// // Set to English
/// [NCChatUIConfig defaultConfig].preferredLanguage = NCChatUILanguageEN;
///
/// // Set to Japanese (requires adding ja.lproj resources first)
/// [NCChatUIConfig defaultConfig].preferredLanguage = @"ja";
/// ```
/// @warning The SDK does not currently support Traditional Chinese; it will automatically fall back
/// to Simplified Chinese. To display Traditional Chinese, add a zh_Hant language file manually.
@property (nonatomic, copy, nullable) NSString *preferredLanguage;

/// Register file message icon configuration. Customize the icon displayed for file messages in
/// channels based on file suffix.
/// @param types File icon dictionary. Key is file suffix (e.g. "png", "pdf"), value is local file
/// path. File suffixes must not contain ".". If the file path is empty or the file does not exist
/// at the path, the default icon from NCChatUI.bundle is used. Image dimensions at the local path
/// should match those in NCChatUI.bundle.
///
- (BOOL)registerFileSuffixTypes:(NSDictionary<NSString *, NSString *> *)types;

@end

NS_ASSUME_NONNULL_END
