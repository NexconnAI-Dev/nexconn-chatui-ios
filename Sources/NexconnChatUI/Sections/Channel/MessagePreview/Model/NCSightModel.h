//
//  NCSightModel.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NexconnChatUI.h"

@class NCMessageModel;

@interface NCSightModel : NSObject

@property (nonatomic, strong) NCMessageModel *messageModel;

- (instancetype)initWithMessageModel:(NCMessageModel *)messageModel;
@end
