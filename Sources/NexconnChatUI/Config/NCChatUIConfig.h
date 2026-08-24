//
//  NCChatUIConfig.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCChatUIConf.h"
#import "NCChatUIFontConf.h"
#import "NCChatUIMessageConf.h"
#import <Foundation/Foundation.h>

#define NCChatUIConfigCenter [NCChatUIConfig defaultConfig]

/// Global configuration for ChatUI, organized by module.
@interface NCChatUIConfig : NSObject

+ (instancetype)defaultConfig;

/// Message configuration.
@property (nonatomic, strong) NCChatUIMessageConf *message;

/// UI configuration.
@property (nonatomic, strong) NCChatUIConf *ui;

/// Font configuration.
@property (nonatomic, strong) NCChatUIFontConf *font;
@end
