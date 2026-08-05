//
//  NCMessageReadDetailCellViewModel.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NCChatUIUserInfo;

NS_ASSUME_NONNULL_BEGIN

/// Read receipt detail user cell view model
@interface NCMessageReadDetailCellViewModel : NSObject

/// User info
@property (nonatomic, strong, readonly) NCChatUIUserInfo *userInfo;

/// Read timestamp (0 indicates no time displayed)
@property (nonatomic, assign, readonly) long long readTime;

/// Formatted read time string
@property (nonatomic, copy, readonly) NSString *displayReadTime;

/// Cell height
@property (nonatomic, assign, readonly) CGFloat cellHeight;

/// Initializes the view model
/// @param userInfo The user info
/// @param readTime The read timestamp
- (instancetype)initWithUserInfo:(NCChatUIUserInfo *)userInfo
                        readTime:(long long)readTime;

@end

NS_ASSUME_NONNULL_END
