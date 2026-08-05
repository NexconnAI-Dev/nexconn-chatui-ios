//
//  UIImage+NCDynamicImage.h
//  NCChatUIExtension
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (NCDynamicImage)

@property (nonatomic, copy) NSString *nc_imageLocalPath;

+ (UIImage *)nc_imageWithLocalPath:(NSString *)path;

- (BOOL)nc_needReloadImage;
@end

NS_ASSUME_NONNULL_END
