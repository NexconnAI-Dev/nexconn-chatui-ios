//
//  NCChatUILanguageManager.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Language manager.
 
/// Finds and caches language resources to improve localized string lookup performance.
@interface NCChatUILanguageManager : NSObject

/// Gets the shared instance.
+ (instancetype)sharedManager;

/// Gets a localized string.
/// @param key String key.
/// @param table String table name, such as "NCChatUI".
/// @return The localized string, or key if no localized value is found.
- (NSString *)localizedStringForKey:(NSString *)key table:(NSString *)table;

/// Reloads the language context when the language changes.
///
/// **Note:**
/// This method is triggered automatically when `[NCChatUIConfig defaultConfig].ui.preferredLanguage`
/// changes, so manual calls are usually unnecessary.
- (void)reloadLanguageContext;

@end

NS_ASSUME_NONNULL_END
