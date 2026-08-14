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
/// 生成链接/电话号码的富文本属性字典，可指定链接颜色对应的主题 token。
/// @param msgDirection 消息收发方向。
/// @param linkColorKey 链接颜色的主题 token（如 @"primary_color"、@"link_color"）。
/// @return 供 NCAttributedLabel 使用的属性字典。
+ (NSDictionary *)getTextLinkOrPhoneNumberAttributeDictionary:(NCMessageDirection)msgDirection
                                                 linkColorKey:(NSString *)linkColorKey;
/// 根据识别到的电话号码构造拨号 URL；输入为空或非法时返回 nil。
/// @param phoneNumber 识别到的电话号码。
/// @return 可直接用于拨号的 tel URL，非法输入返回 nil。
+ (NSString *)phoneURLStringWithPhoneNumber:(NSString *)phoneNumber;
@end
