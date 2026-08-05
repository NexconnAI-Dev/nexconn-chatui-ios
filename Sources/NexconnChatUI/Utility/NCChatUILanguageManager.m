//
//  NCChatUILanguageManager.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCChatUILanguageManager.h"
#import "NCChatUIConfig.h"
#import "NCChatUIUtility.h"

@interface NCChatUILanguageManager ()

/// Cached lproj candidates.
@property (nonatomic, copy) NSArray<NSString *> *cachedLprojCandidates;

/// Cached bundles keyed by table name.
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSBundle *> *cachedBundles;

/// Serial synchronization queue.
@property (nonatomic, strong) dispatch_queue_t syncQueue;

/// Active language identifier used to detect context changes.
/// Stores the resolved language: explicit user preference first, then the system preference.
/// When no language is explicitly configured, this stores the resolved system language rather than an empty string.
@property (nonatomic, copy) NSString *lastPreferredLanguage;

@end

@implementation NCChatUILanguageManager

#pragma mark - Lifecycle

+ (instancetype)sharedManager {
    static NCChatUILanguageManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        _syncQueue = dispatch_queue_create("ai.nexconn.imkit.languageManager", DISPATCH_QUEUE_SERIAL);
        _cachedBundles = [NSMutableDictionary dictionary];
        
        // Initialize the language context synchronously to avoid races on first access.
        // Store the resolved language identifier rather than the raw preferredLanguage value.
        _lastPreferredLanguage = [self p_languageIdentifier];
        _cachedLprojCandidates = [self p_generateLprojCandidates];
        
        // Initialization reads the current system preference when no explicit language is configured.
        // Call reloadLanguageContext after a relevant preference change to rebuild candidates and clear cached bundles.
    }
    return self;
}

#pragma mark - Public Methods

- (NSString *)localizedStringForKey:(NSString *)key table:(NSString *)table {
    if (!key || !table) {
        return key ?: @"";
    }
    
    __block NSBundle *bundle = nil;
    
    // Read the bundle cache on the synchronization queue.
    dispatch_sync(self.syncQueue, ^{
        bundle = self.cachedBundles[table];
        
        // Resolve and cache the bundle on first access to this table.
        if (!bundle) {
            bundle = [self p_findBundleForTable:table];
            if (bundle) {
                self.cachedBundles[table] = bundle;
            }
        }
    });
    
    // Resolve the localized string from the selected bundle.
    if (bundle) {
        NSString *localizedString = [bundle localizedStringForKey:key value:nil table:table];
        if (localizedString && ![localizedString isEqualToString:key]) {
            return localizedString;
        }
    }
    
    // Fall back to the key.
    return key;
}

- (void)reloadLanguageContext {
    dispatch_async(self.syncQueue, ^{
        // Resolve the currently active language identifier.
        NSString *currentLanguageId = [self p_languageIdentifier];
        
        // Compare the resolved language, including the system preference when no explicit language is set.
        if ([currentLanguageId isEqualToString:self.lastPreferredLanguage]) {
            return; // Skip when the resolved language is unchanged.
        }
        
        self.lastPreferredLanguage = currentLanguageId;
        
        // Rebuild the localization fallback candidates.
        self.cachedLprojCandidates = [self p_generateLprojCandidates];
        
        // Clear cached bundles because their paths may change with the language.
        [self.cachedBundles removeAllObjects];
    });
}

#pragma mark - Private Methods

/// Builds the complete list of lproj candidates.
- (NSArray<NSString *> *)p_generateLprojCandidates {
    NSString *languageId = [self p_languageIdentifier];
    if (!languageId) {
        return @[@"en"];
    }
    
    NSMutableOrderedSet *candidates = [NSMutableOrderedSet orderedSet];
    
    // Build the language-specific fallback chain.
    NSArray *chain = [self p_fallbackChainForLanguage:languageId];
    NSArray *withChineseFallback = [self p_chineseFallbackForChain:chain];
    [candidates addObjectsFromArray:withChineseFallback];
    
    // Append the common fallback.
    [candidates addObject:@"en"];
    
    return [candidates array];
}

/// Resolves the language identifier from the explicit preference or the first system preference.
- (NSString *)p_languageIdentifier {
    NSString *preferred = [NCChatUIConfig defaultConfig].ui.preferredLanguage;
    
    // Prefer the explicitly configured language.
    if (preferred.length > 0) {
        return [self p_normalizeLanguageIdentifier:preferred];
    }
    
    // Fall back to the first system-preferred language.
    NSArray *systemLanguages = [NSLocale preferredLanguages];
    if (systemLanguages.count > 0) {
        return [self p_normalizeLanguageIdentifier:systemLanguages.firstObject];
    }
    
    return nil;
}

/// Normalizes language identifiers by replacing underscores with hyphens.
- (NSString *)p_normalizeLanguageIdentifier:(NSString *)identifier {
    return [identifier stringByReplacingOccurrencesOfString:@"_" withString:@"-"];
}

/// Builds a language fallback chain, for example zh-Hans-CN -> zh-Hans -> zh.
- (NSArray<NSString *> *)p_fallbackChainForLanguage:(NSString *)langId {
    NSMutableArray *chain = [NSMutableArray arrayWithObject:langId];
    NSArray *components = [langId componentsSeparatedByString:@"-"];
    
    if (components.count > 1) {
        for (NSInteger i = components.count - 1; i > 0; i--) {
            NSString *parent = [[components subarrayWithRange:NSMakeRange(0, i)] componentsJoinedByString:@"-"];
            [chain addObject:parent];
        }
    }
    
    return chain;
}

/// Adds Simplified Chinese as a fallback when Traditional Chinese resources are unavailable.
- (NSArray<NSString *> *)p_chineseFallbackForChain:(NSArray<NSString *> *)chain {
    // Insert Simplified Chinese after Traditional Chinese when it is not already present.
    if ([chain containsObject:@"zh-Hant"] && ![chain containsObject:@"zh-Hans"]) {
        NSMutableArray *result = [chain mutableCopy];
        NSUInteger hantIndex = [result indexOfObject:@"zh-Hant"];
        [result insertObject:@"zh-Hans" atIndex:hantIndex + 1];
        return result;
    }
    
    return chain;
}

/// Finds the first bundle containing the requested table.strings file.
- (NSBundle *)p_findBundleForTable:(NSString *)table {
    NSArray *bundles = @[
        [NSBundle mainBundle],
        [NSBundle bundleForClass:[NCChatUIUtility class]]
    ];
    
    NSString *tablePath = [NSString stringWithFormat:@"%@.strings", table];
    NSArray<NSString *> *candidates = self.cachedLprojCandidates;
    
    // Use the default fallback when the candidate list is unexpectedly empty.
    if (candidates.count == 0) {
        candidates = @[@"en"];
    }
    
    for (NSString *lprojName in candidates) {
        for (NSBundle *searchBundle in bundles) {
            NSString *lprojPath = [searchBundle pathForResource:lprojName ofType:@"lproj"];
            if (lprojPath) {
                NSString *fullPath = [lprojPath stringByAppendingPathComponent:tablePath];
                if ([[NSFileManager defaultManager] fileExistsAtPath:fullPath]) {
                    return [NSBundle bundleWithPath:lprojPath];
                }
            }
        }
    }
    
    return nil;
}

@end
