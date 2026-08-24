//
//  NCChatUIConf.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCChatUIConf.h"
#import "NCChatUILanguageManager.h"

@interface NCChatUIConf ()

@property (nonatomic, copy) NSDictionary *fileSuffixDictionary;

@end

@implementation NCChatUIConf
- (instancetype)init {
    self = [super init];
    if (self) {
        self.globalNavigationBarTintColor = [UIColor blackColor];
        self.globalConversationAvatarStyle = NC_USER_AVATAR_RECTANGLE;
        self.globalConversationPortraitSize = CGSizeMake(46, 46);
        self.globalMessageAvatarStyle = NC_USER_AVATAR_RECTANGLE;
        self.globalMessagePortraitSize = CGSizeMake(40, 40);
        self.portraitImageViewCornerRadius = 5;
        self.fileSuffixDictionary = [NSDictionary dictionary];
    }
    return self;
}

- (void)setGlobalConversationPortraitSize:(CGSize)globalConversationPortraitSize {
    CGFloat width = globalConversationPortraitSize.width;
    CGFloat height = globalConversationPortraitSize.height;

    if (height < 36.0f) {
        height = 36.0f;
    }

    _globalConversationPortraitSize.width = width;
    _globalConversationPortraitSize.height = height;
}

- (void)setGlobalMessagePortraitSize:(CGSize)globalMessagePortraitSize {
    CGFloat width = globalMessagePortraitSize.width;
    CGFloat height = globalMessagePortraitSize.height;

    _globalMessagePortraitSize.width = width;
    _globalMessagePortraitSize.height = height;
}

- (void)setPreferredLanguage:(NSString *)preferredLanguage {
    if (![_preferredLanguage isEqualToString:preferredLanguage]) {
        _preferredLanguage = [preferredLanguage copy];
        // Ask the language manager to reload its context.
        [[NCChatUILanguageManager sharedManager] reloadLanguageContext];
    }
}

- (BOOL)registerFileSuffixTypes:(NSDictionary<NSString *, NSString *> *)types {
    for (NSString *key in types) {
        if (![key isKindOfClass:[NSString class]]) {
            return NO;
        }
        if (![types[key] isKindOfClass:[NSString class]]) {
            return NO;
        }
    }
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict addEntriesFromDictionary:types ?: @{}];
    self.fileSuffixDictionary = [dict copy];
    return YES;
}

@end
