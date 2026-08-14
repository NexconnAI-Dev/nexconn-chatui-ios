//
//  NCGIFUtility.h
//  NexconnChatUI
//
//  Adapted from FLAnimatedImage: https://github.com/Flipboard/FLAnimatedImage
//  Original copyright (c) 2014-2016 Flipboard.
//  Modified by Nexconn in 2026.
//

#import <Foundation/Foundation.h>
#import "NCMessageModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface NCGIFUtility : NSObject

+ (CGSize)calculatecollectionViewHeight:(NCMessageModel *)model;

+ (nullable NSString *)downloadFileNameForMessageName:(nullable NSString *)messageName
                                       mediaURLString:(nullable NSString *)mediaUrl;
+ (nullable NSString *)downloadFileNameForMediaURLString:(nullable NSString *)mediaUrl
                                        defaultExtension:(nullable NSString *)defaultExtension;

@end

NS_ASSUME_NONNULL_END
