//
//  NCChatUIExtensionPluginItemInfo.h
//  NCExtensionKit
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCChatSessionInputBarControl.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef void (^NCConversationPluginItemTapBlock)(NCChatSessionInputBarControl *chatSessionInputBar);

/// Plugin board item information
@interface NCChatUIExtensionPluginItemInfo : NSObject

@property (nonatomic, strong) UIImage *normalImage;
@property (nonatomic, strong) UIImage *highlightedImage;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, copy) NCConversationPluginItemTapBlock tapBlock;
@property (nonatomic, assign) NSInteger tag;

@end
