//
//  NCFileUtility.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NCFileUtility : NSObject

+ (nullable NSData *)decodeBase64String:(nullable NSString *)string;
+ (BOOL)isLocalPath:(nullable NSString *)path;
+ (BOOL)isRemoteURL:(nullable NSString *)url;
+ (nullable NSString *)correctedFilePath:(nullable NSString *)localPath;
+ (nullable NSString *)imageCacheRootDirectory;
+ (nullable UIImage *)imageByScalingAndCropSize:(nullable UIImage *)image targetSize:(CGSize)targetSize;
+ (nullable NSString *)fileKeyForURL:(nullable NSString *)fileURL;
+ (BOOL)isFileExist:(nullable NSString *)path;
+ (nullable NSString *)recheckedFileName:(nullable NSString *)fileName;
+ (nullable NSString *)fileNameFromRemoteURL:(nullable NSString *)remoteURL;

@end

NS_ASSUME_NONNULL_END
