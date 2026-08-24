//
//  NCChatUIConfig.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCChatUIConfig.h"

@interface NCChatUIFontConf ()

@end

@implementation NCChatUIConfig
+ (instancetype)defaultConfig {
    static NCChatUIConfig *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      instance = [[[self class] alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.message = [[NCChatUIMessageConf alloc] init];
        self.ui = [[NCChatUIConf alloc] init];
        self.font = [[NCChatUIFontConf alloc] init];
    }
    return self;
}
@end
