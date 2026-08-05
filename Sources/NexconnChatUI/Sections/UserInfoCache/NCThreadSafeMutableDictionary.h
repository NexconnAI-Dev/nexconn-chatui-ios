//
//  NCThreadSafeMutableDictionary.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NCThreadSafeMutableDictionary : NSMutableDictionary <NSLocking>

@end
