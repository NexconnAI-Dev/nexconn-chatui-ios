//
//  NCMentionedStringRangeInfo.h
//  NCExtensionKit
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NCMentionedStringRangeInfo : NSObject <NSCoding>

/// Mentioned user ID
@property (nonatomic, strong) NSString *userId;

/// Text content of the mention
@property (nonatomic, strong) NSString *content;

/// Range of the mentioned text
@property (nonatomic, assign) NSRange range;

- (NSString *)encodeToString;

- (instancetype)initWithDecodeString:(NSString *)mentionedInfoString;

@end
