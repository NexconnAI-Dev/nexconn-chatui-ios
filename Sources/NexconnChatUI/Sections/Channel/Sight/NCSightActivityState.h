//
//  NCSightActivityState.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 21/7/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NCSightActivityState : NSObject

@property (nonatomic, assign) BOOL cameraHolding;
@property (nonatomic, assign) BOOL playerHolding;

+ (instancetype)sharedState;

@end
