//
//  NCMessageTool.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "NCMessageModel.h"

@interface NCMessageCellTool : NSObject
+ (UIImage *)getDefaultMessageCellBackgroundImage:(NCMessageModel *)model;
+ (CGFloat)getMessageContentViewMaxWidth;
+ (CGSize)getThumbnailImageSize:(UIImage *)image;
+ (NSDictionary *)getTextLinkOrPhoneNumberAttributeDictionary:(NCMessageDirection)msgDirection;
@end
