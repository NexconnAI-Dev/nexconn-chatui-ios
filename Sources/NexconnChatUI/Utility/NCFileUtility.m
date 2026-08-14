//
//  NCFileUtility.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCFileUtility.h"
#import <CommonCrypto/CommonDigest.h>

static NSString *const NCFileCacheRootDirectoryName = @"NexconnChatUI";
static NSString *const NCFileLocalPathMapDefaultsKey = @"NCFileUtilityLocalPathMap";

static NSString *NCFileMD5(NSString *value) {
    if (value.length == 0) {
        return nil;
    }
    const char *bytes = value.UTF8String;
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5(bytes, (CC_LONG)strlen(bytes), digest);
    NSMutableString *result = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (NSUInteger index = 0; index < CC_MD5_DIGEST_LENGTH; index++) {
        [result appendFormat:@"%02x", digest[index]];
    }
    return result;
}

static NSString *NCFileEnsureDirectory(NSString *path) {
    if (path.length > 0) {
        [[NSFileManager defaultManager] createDirectoryAtPath:path
                                 withIntermediateDirectories:YES
                                                  attributes:nil
                                                       error:nil];
    }
    return path;
}

@implementation NCFileUtility

+ (NSData *)decodeBase64String:(NSString *)string {
    if (string.length == 0) {
        return nil;
    }
    return [[NSData alloc] initWithBase64EncodedString:string options:NSDataBase64DecodingIgnoreUnknownCharacters];
}

+ (BOOL)isLocalPath:(NSString *)path {
    if (path.length == 0) {
        return NO;
    }
    NSURL *URL = [NSURL URLWithString:path];
    return [path hasPrefix:@"/"] || URL.isFileURL;
}

+ (BOOL)isRemoteURL:(NSString *)url {
    NSURLComponents *components = [NSURLComponents componentsWithString:url];
    NSString *scheme = components.scheme.lowercaseString;
    return [scheme isEqualToString:@"http"] || [scheme isEqualToString:@"https"];
}

+ (NSString *)correctedFilePath:(NSString *)localPath {
    if (localPath.length == 0) {
        return nil;
    }
    NSString *path = [localPath hasPrefix:@"file://"] ? [NSURL URLWithString:localPath].path : localPath;
    NSArray<NSString *> *sandboxComponents = @[@"/Documents/", @"/Library/", @"/tmp/"];
    for (NSString *component in sandboxComponents) {
        NSRange range = [path rangeOfString:component];
        if (range.location != NSNotFound) {
            return [NSHomeDirectory() stringByAppendingString:[path substringFromIndex:range.location]];
        }
    }
    return path;
}

+ (NSString *)imageCacheRootDirectory {
    NSString *cacheRoot = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
    return NCFileEnsureDirectory([cacheRoot stringByAppendingPathComponent:NCFileCacheRootDirectoryName]);
}

+ (UIImage *)imageByScalingAndCropSize:(UIImage *)image targetSize:(CGSize)targetSize {
    if (!image || targetSize.width <= 0 || targetSize.height <= 0) {
        return nil;
    }

    CGSize imageSize = image.size;
    if (imageSize.width <= 0 || imageSize.height <= 0) {
        return nil;
    }
    CGFloat widthFactor = targetSize.width / imageSize.width;
    CGFloat heightFactor = targetSize.height / imageSize.height;
    CGFloat scaleFactor = MAX(widthFactor, heightFactor);
    CGSize scaledSize = CGSizeMake(imageSize.width * scaleFactor, imageSize.height * scaleFactor);
    CGRect drawRect = CGRectMake((targetSize.width - scaledSize.width) * 0.5,
                                 (targetSize.height - scaledSize.height) * 0.5,
                                 scaledSize.width,
                                 scaledSize.height);

    UIGraphicsBeginImageContextWithOptions(targetSize, NO, image.scale);
    [image drawInRect:drawRect];
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return scaledImage;
}

+ (NSString *)fileKeyForURL:(NSString *)fileURL {
    return NCFileMD5(fileURL);
}

+ (BOOL)isFileExist:(NSString *)path {
    NSString *correctedPath = [self correctedFilePath:path];
    return correctedPath.length > 0 && [[NSFileManager defaultManager] fileExistsAtPath:correctedPath];
}

+ (NSString *)fileLocalPathForRemoteURL:(NSString *)remoteURL {
    NSString *fileKey = [self fileKeyForURL:remoteURL];
    if (fileKey.length == 0) {
        return nil;
    }
    NSDictionary *pathMap = [[NSUserDefaults standardUserDefaults] dictionaryForKey:NCFileLocalPathMapDefaultsKey];
    NSString *localPath = [self correctedFilePath:pathMap[fileKey]];
    if (localPath.length > 0 && [[NSFileManager defaultManager] fileExistsAtPath:localPath]) {
        return localPath;
    }
    return nil;
}

+ (void)setFileLocalPath:(NSString *)localPath forRemoteURL:(NSString *)remoteURL {
    NSString *fileKey = [self fileKeyForURL:remoteURL];
    if (fileKey.length == 0) {
        return;
    }
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *pathMap = [[defaults dictionaryForKey:NCFileLocalPathMapDefaultsKey] mutableCopy] ?: [NSMutableDictionary dictionary];
    if (localPath.length > 0) {
        pathMap[fileKey] = localPath;
    } else {
        [pathMap removeObjectForKey:fileKey];
    }
    [defaults setObject:pathMap forKey:NCFileLocalPathMapDefaultsKey];
}

+ (NSString *)recheckedFileName:(NSString *)fileName {
    if (fileName.length == 0) {
        return fileName;
    }
    NSString *name = fileName.lastPathComponent;
    while ([name hasPrefix:@"."]) {
        name = [name substringFromIndex:1];
    }
    return name;
}

+ (NSString *)fileNameFromRemoteURL:(NSString *)remoteURL {
    if (remoteURL.length == 0) {
        return nil;
    }
    NSURLComponents *components = [NSURLComponents componentsWithString:remoteURL];
    NSString *fileName;
    for (NSURLQueryItem *item in components.queryItems) {
        if ([item.name isEqualToString:@"attname"] && item.value.length > 0) {
            fileName = item.value;
            break;
        }
    }
    if (fileName.length == 0) {
        fileName = components.path.lastPathComponent;
    }
    if (fileName.length == 0) {
        fileName = [self fileKeyForURL:remoteURL];
    }
    fileName = [fileName stringByRemovingPercentEncoding] ?: fileName;
    return [self recheckedFileName:fileName];
}

@end
