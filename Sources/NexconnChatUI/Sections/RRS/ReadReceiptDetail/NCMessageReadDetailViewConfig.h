//
//  NCMessageReadDetailViewConfig.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Read receipt detail view configuration
@interface NCMessageReadDetailViewConfig : NSObject

/// Tab height. Defaults to 42.
@property (nonatomic, assign) CGFloat tabHeight;

/// Page size. Defaults to 100, range: [1, 100].
@property (nonatomic, assign) NSInteger pageSize;

@end

NS_ASSUME_NONNULL_END

