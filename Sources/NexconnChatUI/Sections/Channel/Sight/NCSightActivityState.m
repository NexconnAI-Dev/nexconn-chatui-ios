//
//  NCSightActivityState.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 21/7/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCSightActivityState.h"

@implementation NCSightActivityState

+ (instancetype)sharedState {
    static NCSightActivityState *state = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      state = [[NCSightActivityState alloc] init];
    });
    return state;
}

@end
