//
//  NCGIFUtility.m
//  NexconnChatUI
//
//  Adapted from FLAnimatedImage: https://github.com/Flipboard/FLAnimatedImage
//  Original copyright (c) 2014-2016 Flipboard.
//  Modified by Nexconn in 2026.
//

#import "NCGIFUtility.h"
#import "NCFileUtility.h"

#define MAXHEIGHT 120.f
#define MINHEIGHT 79.f

@implementation NCGIFUtility
#pragma mark - Public Methods
+ (CGSize)calculatecollectionViewHeight:(NCMessageModel *)model {
    NCGIFMessage *gifMessage = (NCGIFMessage *)model.content;
    CGFloat gifHeight = gifMessage.height / 2;
    CGFloat gifWidth = gifMessage.width / 2;
    if (gifHeight <= 1) {
        gifHeight = 1;
    }
    if (gifWidth <= 1) {
        gifWidth = 1;
    }
    if (gifHeight <= MAXHEIGHT && gifWidth <= MAXHEIGHT) {
        float scale = gifWidth / gifHeight;
        gifHeight = [self caculateHeight:gifHeight];
        gifWidth = gifHeight * scale;
        return CGSizeMake(gifWidth, gifHeight);
    }
    if (gifHeight > MAXHEIGHT && gifWidth <= MAXHEIGHT) {
        CGFloat height = MAXHEIGHT;
        CGFloat width = MAXHEIGHT * gifWidth / gifHeight;
        height = [self caculateHeight:height];
        return CGSizeMake(width, height);
    }
    if (gifHeight <= MAXHEIGHT && gifWidth > MAXHEIGHT) {
        CGFloat width = MAXHEIGHT;
        CGFloat height = MAXHEIGHT * gifHeight / gifWidth;
        height = [self caculateHeight:height];
        return CGSizeMake(width, height);
    }
    if (gifHeight > MAXHEIGHT && gifWidth > MAXHEIGHT) {
        if (gifHeight > gifWidth) {
            CGFloat height = MAXHEIGHT;
            CGFloat width = MAXHEIGHT * gifWidth / gifHeight;
            height = [self caculateHeight:height];
            return CGSizeMake(width, height);
        } else {
            CGFloat width = MAXHEIGHT;
            CGFloat height = MAXHEIGHT * gifHeight / gifWidth;
            height = [self caculateHeight:height];
            return CGSizeMake(width, height);
        }
    }
    return CGSizeMake(MINHEIGHT, [self caculateHeight:0]);
}

+ (NSString *)downloadFileNameForMessageName:(NSString *)messageName mediaURLString:(NSString *)mediaUrl {
    NSString *decodedName = [messageName stringByRemovingPercentEncoding] ?: messageName;
    NSString *fileName = [NCFileUtility recheckedFileName:decodedName];
    if ([fileName.pathExtension caseInsensitiveCompare:@"gif"] == NSOrderedSame) {
        return fileName;
    }

    NSString *fileKey = [NCFileUtility fileKeyForURL:mediaUrl];
    return fileKey.length > 0 ? [NSString stringWithFormat:@"Image_%@.gif", fileKey] : nil;
}

+ (NSString *)downloadFileNameForMediaURLString:(NSString *)mediaUrl defaultExtension:(NSString *)defaultExtension {
    NSString *fileName = @"";
    NSURLComponents *components = [NSURLComponents componentsWithString:mediaUrl];
    if (components.URL.lastPathComponent.length > 0) {
        fileName = components.URL.lastPathComponent;
    }

    if (fileName.length == 0) {
        NSString *pathWithoutQuery = [[mediaUrl componentsSeparatedByString:@"?"] firstObject] ?: @"";
        fileName = pathWithoutQuery.lastPathComponent ?: @"";
    }

    NSString *decodedFileName = [fileName stringByRemovingPercentEncoding];
    if (decodedFileName.length > 0) {
        fileName = decodedFileName;
    }

    if (fileName.pathExtension.length == 0 && defaultExtension.length > 0) {
        fileName = [fileName stringByAppendingPathExtension:defaultExtension];
    }

    NSString *safeFileName = [NCFileUtility recheckedFileName:fileName];
    return safeFileName.length > 0 ? safeFileName : fileName;
}

#pragma mark - Private Methods

+ (CGFloat)caculateHeight:(CGFloat)height {
    CGFloat currentHeight = height;
    if (height < MINHEIGHT) {
        currentHeight = MINHEIGHT;
    }
    return currentHeight;
}

@end
