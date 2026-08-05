//
//  NCForwardManager.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <NexconnChatSDK/NexconnChatSDK.h>

NS_ASSUME_NONNULL_BEGIN

@class NCMessageModel;

@interface NCForwardManager : NSObject

+ (NCForwardManager *)sharedInstance;

- (void)doForwardMessageList:(NSArray<NCMessageModel *> *)messageList
            conversationList:(NSArray<NCBaseChannel *> *)conversationList
                   isCombine:(BOOL)isCombine
     forwardConversationType:(NCChannelType)forwardConversationType
                   completed:(void (^)(BOOL success))completedBlock;

@end

NS_ASSUME_NONNULL_END
