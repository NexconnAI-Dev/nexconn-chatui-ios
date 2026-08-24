//
//  NCCombineMessagePreviewViewController.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCChannelViewController.h"
#import "NCMessageModel.h"
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NCCombineMessagePreviewViewController : NCChannelViewController

- (instancetype)initWithMessageModel:(NCMessageModel *)messageModel navTitle:(NSString *)navTitle;

@end

NS_ASSUME_NONNULL_END
