//
//  NCChatUIUtility.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCChatUIUtility.h"
#import "NCButton.h"
#import "NCChannelModel.h"
#import "NCChatUI.h"
#import "NCChatUICommonDefine.h"
#import "NCChatUIConfig.h"
#import "NCChatUIExtensionService.h"
#import "NCChatUILanguageManager.h"
#import "NCChatUILog.h"
#import "NCChatUIUserInfo.h"
#import "NCImageLoader.h"
#import "NCMBProgressHUD.h"
#import "NCOldMessageNotificationMessage.h"
#import "NCPinYin.h"
#import "NCRRSUtil.h"
#import "NCSemanticContext.h"
#import "NCSightActivityState.h"
#import "NCStreamUtilities.h"
#import "NCUserInfoCacheManager.h"
#import "NSDictionary+NCAccessor.h"
#import "UIImage+NCDynamicImage.h"
#import <SafariServices/SafariServices.h>
#import <UIKit/UIKit.h>

static NSUInteger const NCMessageTextMaxVisibleCharacterCount = 5000;

static NCBaseChannel *NCSyncReadStatusChannel(NCChannelModel *conversation) {
    if (!conversation) {
        return nil;
    }
    NSString *channelId = conversation.channelId ?: @"";
    switch (conversation.channelType) {
    case NCChannelTypeDirect:
        return [[NCDirectChannel alloc] initWithChannelId:channelId];
    case NCChannelTypeGroup:
        return [[NCGroupChannel alloc] initWithChannelId:channelId];
    case NCChannelTypeSystem:
        return [[NCSystemChannel alloc] initWithChannelId:channelId];
    default:
        return nil;
    }
}

static NSString *NCLocalNotificationTypeForChannelType(NSInteger channelType) {
    if (channelType == NCChannelTypeDirect || channelType == 1) {
        return @"PR";
    }
    if (channelType == NCChannelTypeGroup || channelType == 3) {
        return @"GRP";
    }
    if (channelType == NCChannelTypeSystem || channelType == 6) {
        return @"SYS";
    }
    if (channelType == 9) {
        return @"PH";
    }
    return nil;
}

static BOOL NCRTCBridgeCallBoolSelector(SEL selector) {
    Class bridgeClass = NSClassFromString(@"NCRTCBridge");
    if (!bridgeClass || ![bridgeClass respondsToSelector:selector]) {
        return NO;
    }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    return ((BOOL (*)(id, SEL))[bridgeClass methodForSelector:selector])(bridgeClass, selector);
#pragma clang diagnostic pop
}

static NSArray<NSString *> *NCPreferredScaleSuffixes(void) {
    CGFloat screenScale = [UIScreen mainScreen].scale;
    if (screenScale >= 3.0) {
        return @[ @"@3x", @"@2x", @"" ];
    }
    if (screenScale >= 2.0) {
        return @[ @"@2x", @"@3x", @"" ];
    }
    return @[ @"", @"@2x", @"@3x" ];
}

static NSString *NCResolveImagePath(NSString *bundlePath, NSString *imageName) {
    if (bundlePath.length == 0 || imageName.length == 0) {
        return nil;
    }

    NSString *extension = [imageName pathExtension];
    NSString *baseName =
        extension.length > 0 ? [imageName stringByDeletingPathExtension] : imageName;
    NSString *normalizedExtension =
        extension.length > 0 ? [@"." stringByAppendingString:extension] : @".png";

    NSFileManager *fileManager = [NSFileManager defaultManager];
    for (NSString *suffix in NCPreferredScaleSuffixes()) {
        NSString *fileName =
            [NSString stringWithFormat:@"%@%@%@", baseName, suffix, normalizedExtension];
        NSString *candidatePath = [bundlePath stringByAppendingPathComponent:fileName];
        if ([fileManager fileExistsAtPath:candidatePath]) {
            return candidatePath;
        }
    }
    return nil;
}

@interface NCUIWeakRefObject : NSObject
@property (nonatomic, weak) id weakRefObj;
+ (instancetype)refWithObject:(id)obj;
@end

@implementation NCUIWeakRefObject
+ (instancetype)refWithObject:(id)obj {
    NCUIWeakRefObject *ref = [[NCUIWeakRefObject alloc] init];
    ref.weakRefObj = obj;
    return ref;
}
@end

@implementation NCChatUIUtility
#pragma mark - Public Method

+ (BOOL)isApplicationInBackground {
    return [UIApplication sharedApplication].applicationState == UIApplicationStateBackground;
}

+ (NSString *)convertConversationTime:(long long)secs {
    NSString *timeText = nil;
    NSDate *messageDate = [NSDate dateWithTimeIntervalSince1970:secs];
    NSDateFormatter *formatter = [self getDateFormatter];
    NSString *locale = NCUILocalizedString(@"locale");
    [formatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:locale]];
    if ([self isSameYear:messageDate]) {
        if ([self isSameMonth:messageDate]) {
            NSInteger intervalDays = [self getIntervalDays:messageDate];
            if (intervalDays == 0) {
                NSString *formatStr = [self getDateFormatterString:messageDate];
                [formatter setDateFormat:formatStr];
                return timeText = [formatter stringFromDate:messageDate];
            } else if (intervalDays == 1) {
                return timeText = NCUILocalizedString(@"yesterday");
            } else if (intervalDays < 7 && [self isCurrentWeek:messageDate]) {
                [formatter setDateFormat:@"eeee"];
                return timeText = [formatter stringFromDate:messageDate];
            } else {
                [formatter setDateFormat:NCUILocalizedString(@"same_year_date")];
                return timeText = [formatter stringFromDate:messageDate];
            }
        }
        [formatter setDateFormat:NCUILocalizedString(@"same_year_date")];
        return timeText = [formatter stringFromDate:messageDate];
    }
    [formatter setDateFormat:NCUILocalizedString(@"chat_list_date")];
    return timeText = [formatter stringFromDate:messageDate];
}

+ (NSString *)convertMessageTime:(long long)secs {
    NSString *timeText = nil;
    NSDate *messageDate = [NSDate dateWithTimeIntervalSince1970:secs];
    NSDateFormatter *formatter = [self getDateFormatter];
    [formatter
        setLocale:[[NSLocale alloc] initWithLocaleIdentifier:NCUILocalizedString(@"locale")]];
    if ([self isSameYear:messageDate]) {
        if ([self isSameMonth:messageDate]) {
            NSInteger intervalDays = [self getIntervalDays:messageDate];
            NSString *formatStr = [self getDateFormatterString:messageDate];
            [formatter setDateFormat:formatStr];
            if (intervalDays == 0) {
                return timeText = [formatter stringFromDate:messageDate];
            } else if (intervalDays == 1) {
                return timeText =
                           [NSString stringWithFormat:@"%@ %@", NCUILocalizedString(@"yesterday"),
                                                      [formatter stringFromDate:messageDate]];
            } else if (intervalDays < 7 && [self isCurrentWeek:messageDate]) {
                [formatter setDateFormat:[NSString stringWithFormat:@"eeee %@", formatStr]];
                return timeText = [formatter stringFromDate:messageDate];
            } else {
                [formatter
                    setDateFormat:[NSString
                                      stringWithFormat:@"%@ %@",
                                                       NCUILocalizedString(@"same_year_date"),
                                                       [self getDateFormatterString:messageDate]]];
                return [formatter stringFromDate:messageDate];
            }
        }
        [formatter
            setDateFormat:[NSString stringWithFormat:@"%@ %@",
                                                     NCUILocalizedString(@"same_year_date"),
                                                     [self getDateFormatterString:messageDate]]];
        return [formatter stringFromDate:messageDate];
    }
    return [self getMessageDate:messageDate dateFormat:formatter];
}

+ (UIImage *)imageNamed:(NSString *)name ofBundle:(NSString *)bundleName {
    static NSMutableDictionary *loadedObjectDict = nil;
    if (!loadedObjectDict) {
        loadedObjectDict = [[NSMutableDictionary alloc] init];
    }
    NSString *keyString = [NSString stringWithFormat:@"%@%@", bundleName, name];
    if (@available(iOS 13.0, *)) {
        NSNumber *currentUserInterfaceStyle =
            [[NSUserDefaults standardUserDefaults] objectForKey:@"NCCurrentUserInterfaceStyle"];
        keyString =
            [NSString stringWithFormat:@"%@%@%@", bundleName, name, currentUserInterfaceStyle];
    }
    NCUIWeakRefObject *ref = loadedObjectDict[keyString];
    if (ref.weakRefObj) {
        return ref.weakRefObj;
    }

    UIImage *image = nil;
    NSString *image_name = name;
    if (![image_name hasSuffix:@".png"]) {
        image_name = [NSString stringWithFormat:@"%@.png", name];
    }

    NSString *bundlePath = nil;
    NSMutableArray<NSString *> *candidateBundleNames = [NSMutableArray array];
    if (bundleName.length > 0) {
        [candidateBundleNames addObject:bundleName];
    }

    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSBundle *innerBundle = [NSBundle bundleForClass:[self class]];
    for (NSString *candidateBundleName in candidateBundleNames) {
        NSString *bundleNameString = [candidateBundleName stringByDeletingPathExtension];
        NSURL *rootBundleURL = [[NSBundle mainBundle] URLForResource:bundleNameString
                                                       withExtension:@"bundle"];
        if (rootBundleURL) {
            NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
            NSString *candidatePath =
                [resourcePath stringByAppendingPathComponent:candidateBundleName];
            if ([fileManager fileExistsAtPath:candidatePath]) {
                bundlePath = candidatePath;
                break;
            }
        }

        NSString *innerBundlePath =
            [[innerBundle resourcePath] stringByAppendingPathComponent:candidateBundleName];
        if ([fileManager fileExistsAtPath:innerBundlePath]) {
            bundlePath = innerBundlePath;
            break;
        }
    }

    NSString *imagePath = bundlePath ? NCResolveImagePath(bundlePath, image_name) : nil;
    if (imagePath.length > 0) {
        image = [UIImage nc_imageWithLocalPath:imagePath];
    } else {
        NCLogW(@"[NCChatUIUtility] image not found. bundle:%@, name:%@", bundleName, image_name);
    }

    [loadedObjectDict setObject:[NCUIWeakRefObject refWithObject:image] forKey:keyString];
    return image;
}

+ (CGSize)getTextDrawingSize:(NSString *)text
                        font:(UIFont *)font
             constrainedSize:(CGSize)constrainedSize {
    if (text.length <= 0) {
        return CGSizeZero;
    }

    if ([text respondsToSelector:@selector(boundingRectWithSize:options:attributes:context:)]) {
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
        NSDictionary *attributes =
            @{NSFontAttributeName : font, NSParagraphStyleAttributeName : paragraphStyle};

        return [text boundingRectWithSize:constrainedSize
                                  options:(NSStringDrawingTruncatesLastVisibleLine |
                                           NSStringDrawingUsesLineFragmentOrigin |
                                           NSStringDrawingUsesFontLeading)
                               attributes:attributes
                                  context:nil]
            .size;
    }
    return CGSizeZero;
}

+ (NSUInteger)visibleCharacterCountForText:(NSString *)text {
    if (text.length == 0) {
        return 0;
    }
    __block NSUInteger count = 0;
    [text enumerateSubstringsInRange:NSMakeRange(0, text.length)
                             options:NSStringEnumerationByComposedCharacterSequences
                          usingBlock:^(NSString *_Nullable substring, NSRange substringRange,
                                       NSRange enclosingRange, BOOL *_Nonnull stop) {
                            (void)substring;
                            (void)substringRange;
                            (void)enclosingRange;
                            (void)stop;
                            count += 1;
                          }];
    return count;
}

+ (BOOL)text:(NSString *)text hasVisibleCharacterCountOverLimit:(NSUInteger)limit {
    return [self visibleCharacterCountForText:text] > limit;
}

+ (BOOL)text:(NSString *)text
    wouldExceedVisibleCharacterLimit:(NSUInteger)limit
                      replacingRange:(NSRange)range
                            withText:(NSString *)replacementText {
    NSString *currentText = text ?: @"";
    if (range.location == NSNotFound || range.location > currentText.length ||
        range.length > currentText.length - range.location) {
        return YES;
    }
    NSString *updatedText = [currentText stringByReplacingCharactersInRange:range
                                                                 withString:replacementText ?: @""];
    return [self text:updatedText hasVisibleCharacterCountOverLimit:limit];
}

+ (NSUInteger)messageTextMaxVisibleCharacterCount {
    return NCMessageTextMaxVisibleCharacterCount;
}

+ (BOOL)isMessageTextOverMaxVisibleCharacterLimit:(NSString *)text {
    return [self text:text
        hasVisibleCharacterCountOverLimit:[self messageTextMaxVisibleCharacterCount]];
}

+ (BOOL)messageText:(NSString *)text
    wouldExceedMaxVisibleCharacterLimitReplacingRange:(NSRange)range
                                             withText:(NSString *)replacementText {
    return [self text:text
        wouldExceedVisibleCharacterLimit:[self messageTextMaxVisibleCharacterCount]
                          replacingRange:range
                                withText:replacementText];
}

+ (NSString *)formatLocalNotification:(id)message {
    if (![message isKindOfClass:[NCMessage class]]) {
        return @"";
    }
    return [self formatLocalNotificationWithNCMessage:(NCMessage *)message];
}

+ (NSString *)formatLocalNotificationWithNCMessage:(NCMessage *)message {
    return [self __formatNCMessage:(NCMessageContent *)message.content isAllMessage:NO];
}

+ (NSString *)formatStreamDigest:(id)message {
    if (![message isKindOfClass:[NCMessage class]]) {
        return @"";
    }
    NCMessage *ncMessage = (NCMessage *)message;
    if (![ncMessage.content isKindOfClass:[NCStreamMessage class]]) {
        return @"";
    }
    NCStreamSummaryModel *summary =
        [NCStreamUtilities parserStreamSummary:[NCMessageModel modelWithNCMessage:ncMessage]];
    if (summary.summary.length > 0) {
        return summary.summary;
    }

    NCStreamMessage *stream = (NCStreamMessage *)ncMessage.content;
    if (stream.sync) {
        return stream.content;
    }
    if (stream.content.length < NCStreamMessageCellLoadingLimit) {
        return [NCUILocalizedString(@"stream_message_typing") stringByAppendingString:@"..."];
    }
    return stream.content;
}

+ (NSString *)formatMessage:(id)messageContent
                  channelId:(NSString *)channelId
                channelType:(NSInteger)channelType
               isAllMessage:(BOOL)isAllMessage {
    (void)channelId;
    (void)channelType;
    if ([messageContent isKindOfClass:[NCMessageContent class]]) {
        return [self __formatNCMessage:(NCMessageContent *)messageContent
                          isAllMessage:isAllMessage];
    }
    return @"";
}

+ (NSString *)__truncateDigest:(NSString *)digest isAllMessage:(BOOL)isAllMessage {
    if (digest.length == 0) {
        return @"";
    }
    if (!isAllMessage && digest.length > 500) {
        return [[digest substringToIndex:500] stringByAppendingString:@"..."];
    }
    return digest;
}

+ (NSString *)__formatNCMessage:(NCMessageContent *)messageContent isAllMessage:(BOOL)isAllMessage {
    if (!messageContent) {
        return @"";
    }

    NSString *digest = @"";
    if ([messageContent isKindOfClass:[NCTextMessage class]]) {
        digest = ((NCTextMessage *)messageContent).text ?: @"";
    } else if ([messageContent isKindOfClass:[NCReferenceMessage class]]) {
        digest = ((NCReferenceMessage *)messageContent).content ?: @"";
    } else if ([messageContent isKindOfClass:[NCImageMessage class]]) {
        digest = NCUILocalizedString(@"image_message");
    } else if ([messageContent isKindOfClass:[NCHDVoiceMessage class]]) {
        digest = NCUILocalizedString(@"voice_message");
    } else if ([messageContent isKindOfClass:[NCFileMessage class]]) {
        NSString *fileDigest = NCUILocalizedString(@"file_message");
        NSString *name = ((NCFileMessage *)messageContent).name ?: @"";
        digest =
            name.length > 0 ? [NSString stringWithFormat:@"%@ %@", fileDigest, name] : fileDigest;
    } else if ([messageContent isKindOfClass:[NCShortVideoMessage class]]) {
        digest = NCUILocalizedString(@"video_message");
    } else if ([messageContent isKindOfClass:[NCGIFMessage class]]) {
        digest = NCUILocalizedString(@"gif_message");
    } else if ([messageContent isKindOfClass:[NCCombineMessage class]]) {
        digest = NCUILocalizedString(@"chat_history_message");
    } else if ([messageContent isKindOfClass:[NCLocationMessage class]]) {
        digest = NCUILocalizedString(@"unknown_message_cell_tip");
    } else if ([messageContent isKindOfClass:[NCStreamMessage class]]) {
        NCStreamMessage *stream = (NCStreamMessage *)messageContent;
        if (stream.sync) {
            digest = stream.content ?: @"";
        } else if (stream.content.length < NCStreamMessageCellLoadingLimit) {
            digest = [[NCUILocalizedString(@"stream_message_typing") stringByAppendingString:@"..."]
                copy];
        } else {
            digest = stream.content ?: @"";
        }
    } else if ([messageContent isKindOfClass:[NCInformationNotificationMessage class]]) {
        digest = ((NCInformationNotificationMessage *)messageContent).message ?: @"";
    } else if ([messageContent isKindOfClass:[NCGroupNotificationMessage class]]) {
        NCGroupNotificationMessage *groupNotification =
            (NCGroupNotificationMessage *)messageContent;
        digest = [self __formatGroupNotificationMessageContent:groupNotification] ?: groupNotification.message ?: @"";
    } else if ([messageContent isKindOfClass:[NCRecallNotificationMessage class]]) {
        NCRecallNotificationMessage *recall = (NCRecallNotificationMessage *)messageContent;
        if (recall.operatorId.length == 0) {
            digest = NCUILocalizedString(@"recalled_a_message");
        } else if (recall.admin) {
            digest = NCUILocalizedString(@"admin_recalled_a_message");
        } else if ([recall.operatorId isEqualToString:[NCEngine getCurrentUserId]]) {
            digest = NCUILocalizedString(@"you_recalled_a_message");
        } else {
            NCChatUIUserInfo *userInfo =
                [[NCUserInfoCacheManager sharedManager] getUserInfo:recall.operatorId];
            NSString *operatorName = userInfo.name.length > 0 ? userInfo.name : recall.operatorId;
            digest =
                [operatorName stringByAppendingString:NCUILocalizedString(@"recalled_a_message")];
        }
    } else if ([messageContent isKindOfClass:[NCUnknownMessage class]]) {
        digest = NCUILocalizedString(@"unknown_message_cell_tip");
    }

    return [self __truncateDigest:digest isAllMessage:isAllMessage];
}

+ (NSString *)formatMessage:(id)messageContent
                  channelId:(NSString *)channelId
                channelType:(NSInteger)channelType {
    return [self formatMessage:messageContent
                     channelId:channelId
                   channelType:channelType
                  isAllMessage:NO];
}

+ (NSString *)formatMessage:(id)messageContent {
    return [self formatMessage:messageContent channelId:nil channelType:0 isAllMessage:NO];
}

+ (BOOL)isVisibleMessage:(id)message {
    if (![message isKindOfClass:[NCMessage class]]) {
        return NO;
    }
    NCMessage *ncMessage = (NCMessage *)message;
    BOOL isUnkownMessage = [self isUnkownMessage:(long)ncMessage.clientId
                                         content:ncMessage.content];
    if (isUnkownMessage && NCChatUIConfigCenter.message.showUnkownMessage) {
        return YES;
    } else if (ncMessage.isPersisted) {
        return YES;
    }
    return NO;
}

+ (BOOL)isUnkownMessage:(long)clientId content:(id)content {
    if ([content isKindOfClass:[NCUnknownMessage class]]) {
        return YES;
    }
    if (!content && clientId > 0) {
        return YES;
    }
    return NO;
}

+ (NSDictionary *)getNotificationUserInfoDictionary:(id)message {
    if (![message isKindOfClass:[NCMessage class]]) {
        return nil;
    }
    return [self getNotificationUserInfoDictionaryWithNCMessage:(NCMessage *)message];
}

+ (NSDictionary *)getNotificationUserInfoDictionaryWithNCMessage:(NCMessage *)message {
    NSInteger channelType = (NSInteger)message.channelIdentifier.channelType;
    NSString *channelId = message.channelIdentifier.channelId;
    return [NCChatUIUtility getNotificationUserInfoDictionary:channelType
                                                   fromUserId:message.senderUserId
                                                    channelId:channelId
                                                   objectName:message.messageType
                                                     clientId:(long)message.clientId
                                                    messageId:message.messageId];
}

+ (NSDictionary *)getNotificationUserInfoDictionary:(NSInteger)channelType
                                         fromUserId:(NSString *)fromUserId
                                          channelId:(NSString *)channelId
                                         objectName:(NSString *)objectName {

    return [NCChatUIUtility getNotificationUserInfoDictionary:channelType
                                                   fromUserId:fromUserId
                                                    channelId:channelId
                                                   objectName:objectName
                                                     clientId:0
                                                    messageId:@""];
}

+ (NSDictionary *)getNotificationUserInfoDictionary:(NSInteger)channelType
                                         fromUserId:(NSString *)fromUserId
                                          channelId:(NSString *)channelId
                                         objectName:(NSString *)objectName
                                           clientId:(long)clientId
                                          messageId:(NSString *)messageId {
    NSString *type = NCLocalNotificationTypeForChannelType(channelType);
    if (type.length == 0) {
        return nil;
    }
    NSString *clientIdString = [NSString stringWithFormat:@"%ld", clientId];
    return @{
        @"rc" : @{
            @"cType" : type ?: @"",
            @"fId" : fromUserId ?: @"",
            @"oName" : objectName ?: @"",
            @"tId" : channelId ?: @"",
            @"mId" : clientIdString,
            @"id" : messageId ?: @""
        }
    };
}

+ (UIImage *)imageWithFileSuffix:(NSString *)type {
    NSString *filePath = NCChatUIConfigCenter.ui.fileSuffixDictionary[type];
    if (filePath) {
        UIImage *image = [UIImage imageWithContentsOfFile:filePath];
        if (image) {
            return image;
        }
    }
    NSString *fileTypeIcon = [NCChatUIUtility getFileTypeIcon:type];
    NSString *fileTypeKey =
        [NSString stringWithFormat:@"channel_msg_cell_file_%@_img", fileTypeIcon];
    return NCDynamicImage(fileTypeKey);
}

+ (NSString *)getFileTypeIcon:(NSString *)fileType {
    // Normalize the file extension to lowercase.
    fileType = [fileType lowercaseString];
    if ([fileType isEqualToString:@"png"] || [fileType isEqualToString:@"jpg"] ||
        [fileType isEqualToString:@"bmp"] || [fileType isEqualToString:@"cod"] ||
        [fileType isEqualToString:@"gif"] || [fileType isEqualToString:@"jpe"] ||
        [fileType isEqualToString:@"jpeg"] || [fileType isEqualToString:@"jfif"] ||
        [fileType isEqualToString:@"svg"] || [fileType isEqualToString:@"tif"] ||
        [fileType isEqualToString:@"tiff"] || [fileType isEqualToString:@"ras"] ||
        [fileType isEqualToString:@"ico"] ||
        ([fileType isEqualToString:@"pbm"] &&
         NC_IOS_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"10.0")) ||
        [fileType isEqualToString:@"pgm"] || [fileType isEqualToString:@"pnm"] ||
        [fileType isEqualToString:@"ppm"] || [fileType isEqualToString:@"xbm"] ||
        [fileType isEqualToString:@"xpm"] || [fileType isEqualToString:@"xwd"] ||
        [fileType isEqualToString:@"rgb"]) {
        return @"PictureFile";
    } else if ([fileType isEqualToString:@"log"] || [fileType isEqualToString:@"txt"] ||
               [fileType isEqualToString:@"html"] || [fileType isEqualToString:@"stm"] ||
               [fileType isEqualToString:@"uls"] || [fileType isEqualToString:@"bas"] ||
               [fileType isEqualToString:@"c"] || [fileType isEqualToString:@"h"] ||
               [fileType isEqualToString:@"rtf"] || [fileType isEqualToString:@"sct"] ||
               [fileType isEqualToString:@"tsv"] || [fileType isEqualToString:@"htt"] ||
               [fileType isEqualToString:@"htc"] || [fileType isEqualToString:@"etx"] ||
               [fileType isEqualToString:@"vcf"]) {
        return @"TextFile";
    } else if ([fileType isEqualToString:@"mp3"] || [fileType isEqualToString:@"au"] ||
               [fileType isEqualToString:@"snd"] || [fileType isEqualToString:@"mid"] ||
               [fileType isEqualToString:@"rmi"] || [fileType isEqualToString:@"aif"] ||
               [fileType isEqualToString:@"aifc"] || [fileType isEqualToString:@"m3u"] ||
               [fileType isEqualToString:@"ra"] || [fileType isEqualToString:@"ram"] ||
               [fileType isEqualToString:@"wav"] || [fileType isEqualToString:@"wma"]) {
        return @"Mp3File";
    } else if ([fileType isEqualToString:@"pdf"]) {
        return @"PdfFile";
    } else if ([fileType isEqualToString:@"doc"] || [fileType isEqualToString:@"docx"] ||
               [fileType isEqualToString:@"dot"] || [fileType isEqualToString:@"dotx"]) {
        return @"WordFile";
    } else if ([fileType isEqualToString:@"xls"] || [fileType isEqualToString:@"xlsx"] ||
               [fileType isEqualToString:@"xlc"] || [fileType isEqualToString:@"xlm"] ||
               [fileType isEqualToString:@"xla"] || [fileType isEqualToString:@"xlt"] ||
               [fileType isEqualToString:@"xlw"]) {
        return @"ExcelFile";
    } else if ([fileType isEqualToString:@"mp4"] || [fileType isEqualToString:@"mov"] ||
               [fileType isEqualToString:@"rmvb"] || [fileType isEqualToString:@"avi"] ||
               [fileType isEqualToString:@"mp2"] || [fileType isEqualToString:@"xpa"] ||
               [fileType isEqualToString:@"xpe"] || [fileType isEqualToString:@"mpeg"] ||
               [fileType isEqualToString:@"mpg"] || [fileType isEqualToString:@"mpv2"] ||
               [fileType isEqualToString:@"qt"] || [fileType isEqualToString:@"lsf"] ||
               [fileType isEqualToString:@"lsx"] || [fileType isEqualToString:@"asf"] ||
               [fileType isEqualToString:@"asr"] || [fileType isEqualToString:@"asx"] ||
               [fileType isEqualToString:@"wmv"] || [fileType isEqualToString:@"movie"]) {
        return @"VideoFile";
    } else if ([fileType isEqualToString:@"ppt"] || [fileType isEqualToString:@"pptx"]) {
        return @"pptFile";
    } else if ([fileType isEqualToString:@"pages"]) {
        return @"Pages";
    } else if ([fileType isEqualToString:@"numbers"]) {
        return @"Numbers";
    } else if ([fileType isEqualToString:@"key"]) {
        return @"Keynote";
    } else {
        return @"OtherFile";
    }
}

+ (NSString *)getReadableStringForFileSize:(long long)byteSize {
    if (byteSize < 0) {
        return @"0 B";
    } else if (byteSize < 1024) {
        return [NSString stringWithFormat:@"%lld B", byteSize];
    } else if (byteSize < 1024 * 1024) {
        double kSize = (double)byteSize / 1024;
        return [NSString stringWithFormat:@"%.2f KB", kSize];
    } else if (byteSize < 1024 * 1024 * 1024) {
        double kSize = (double)byteSize / (1024 * 1024);
        return [NSString stringWithFormat:@"%.2f MB", kSize];
    } else {
        double kSize = (double)byteSize / (1024 * 1024 * 1024);
        return [NSString stringWithFormat:@"%.2f GB", kSize];
    }
}

+ (UIImage *)defaultConversationHeaderImage:(NCChannelModel *)model {
    if (model.conversationModelType == NC_CONVERSATION_MODEL_TYPE_NORMAL) {
        if ([model isChannelType:NCChannelTypeSystem] ||
            [model isChannelType:NCChannelTypeDirect]) {
            return NCDynamicImage(@"channel-list_cell_portrait_msg_img");
        } else if ([model isChannelType:NCChannelTypeGroup]) {
            return NCDynamicImage(@"channel-list_cell_group_portrait_img");
        }
    }
    return NCDynamicImage(@"channel-list_cell_portrait_img");
}

+ (void)getConversationUnreadMentionedCount:(NCChannelModel *)model
                                     result:(void (^)(int num))result {
    NCChannelIdentifier *identifier =
        [[NCChannelIdentifier alloc] initWithChannelType:model.channelType
                                               channelId:model.channelId ?: @""];
    [NCBaseChannel
        getChannels:@[ identifier ]
         completion:^(NSArray<NCBaseChannel *> *_Nullable channels, NCError *_Nullable error) {
           dispatch_async(dispatch_get_main_queue(), ^{
             if (result) {
                 result((int)(channels.firstObject.mentionedCount));
             }
           });
         }];
}

+ (void)syncConversationReadStatusIfEnabled:(NCChannelModel *)conversation {
    if (!NCChatUIConfigCenter.message.enableSyncReadStatus) {
        return;
    }
    NCChannelType channelType = conversation.channelType;
    BOOL shouldSync = NO;
    if (channelType == NCChannelTypeDirect &&
        [NCChatUIConfigCenter.message.enabledReadReceiptConversationTypeList
            containsObject:@(channelType)]) {
        shouldSync = YES;
    } else if ((channelType == NCChannelTypeDirect &&
                ![NCChatUIConfigCenter.message.enabledReadReceiptConversationTypeList
                    containsObject:@(channelType)]) ||
               channelType == NCChannelTypeGroup || channelType == NCChannelTypeSystem) {
        shouldSync = YES;
    }
    if (!shouldSync) {
        return;
    }
    NCBaseChannel *channel = NCSyncReadStatusChannel(conversation);
    if (!channel) {
        return;
    }
    [channel clearUnreadCountWithCompletion:nil];
}

+ (BOOL)shouldNeedReadReceiptForChannelType:(NCChannelType)channelType {
    return [NCChatUIConfigCenter.message.enabledReadReceiptConversationTypeList
        containsObject:@(channelType)];
}

+ (NSString *)getPinYinUpperFirstLetters:(NSString *)hanZi {
    if (hanZi.length == 0) {
        return nil;
    } else {
        NSMutableString *pinYinResult = [[NSMutableString alloc] init];
        for (int i = 0; i < hanZi.length; i++) {
            [pinYinResult appendFormat:@"%c", NCPinyinFirstLetter([hanZi characterAtIndex:i])];
        }
        return [[pinYinResult copy] uppercaseString];
    }
}

+ (void)openURLInSafariViewOrWebView:(NSString *)url base:(UIViewController *)viewController {
    if (!url || url.length == 0) {
        NCLogD(@"[NexconnChatUI] : Push to web Page url is nil");
        return;
    }
    url = [url stringByReplacingOccurrencesOfString:@" " withString:@""];
    url = [self checkOrAppendHttpForUrl:url];
    NSURL *targetUrl = [NSURL URLWithString:url];
    if (!targetUrl) {
        NCLogI(@"Push to web Page url is Invalid");
        return;
    }

    if (NC_IOS_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"9.0")) {
        SFSafariViewController *safari = [[SFSafariViewController alloc] initWithURL:targetUrl];
        safari.modalPresentationStyle = UIModalPresentationFullScreen;
        [viewController presentViewController:safari animated:YES completion:nil];
    } else {
        [[UIApplication sharedApplication] openURL:targetUrl];
    }
}

+ (NSString *)checkOrAppendHttpForUrl:(NSString *)url {
    if (![[url lowercaseString] hasPrefix:@"http://"] &&
        ![[url lowercaseString] hasPrefix:@"https://"]) {
        url = [NSString stringWithFormat:@"http://%@", url];
    }
    return url;
}

static BOOL NCChatUIWindowIsUsable(UIWindow *window) {
    return window && !window.hidden && window.alpha > 0.01;
}

static UIWindow *NCChatUIFirstUsableWindow(NSArray<UIWindow *> *windows) {
    for (UIWindow *window in windows) {
        if (window.isKeyWindow) {
            return window;
        }
    }
    for (UIWindow *window in windows) {
        if (NCChatUIWindowIsUsable(window) && window.windowLevel == UIWindowLevelNormal) {
            return window;
        }
    }
    for (UIWindow *window in windows) {
        if (NCChatUIWindowIsUsable(window)) {
            return window;
        }
    }
    return windows.firstObject;
}

+ (UIWindow *)getKeyWindow {
    return [self getWindowForView:nil];
}

+ (UIWindow *)getWindowForView:(UIView *)view {
    if (view.window) {
        return view.window;
    }
    if (@available(iOS 13.0, *)) {
        UIWindow *fallbackWindow = nil;
        // iOS 13 多 Scene 下不能从全局 windows 推断当前页面，优先使用前台 Scene 的窗口集合。
        for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if (![scene isKindOfClass:[UIWindowScene class]]) {
                continue;
            }
            UISceneActivationState activationState = scene.activationState;
            if (activationState != UISceneActivationStateForegroundActive &&
                activationState != UISceneActivationStateForegroundInactive) {
                continue;
            }
            UIWindow *window = NCChatUIFirstUsableWindow(((UIWindowScene *)scene).windows);
            if (window.isKeyWindow) {
                return window;
            }
            if (!fallbackWindow) {
                fallbackWindow = window;
            }
        }
        if (fallbackWindow) {
            return fallbackWindow;
        }
    }
    return NCChatUIFirstUsableWindow([UIApplication sharedApplication].windows);
}

+ (UIEdgeInsets)getWindowSafeAreaInsets {
    return [self getWindowSafeAreaInsetsForView:nil];
}

+ (UIEdgeInsets)getWindowSafeAreaInsetsForView:(UIView *)view {
    UIEdgeInsets result = UIEdgeInsetsZero;
    if (@available(iOS 11.0, *)) {
        UIWindow *window = [self getWindowForView:view];
        if (window) {
            result = window.safeAreaInsets;
        }
    } else {
        result.top = [self getStatusBarHeightForView:view];
    }
    return result;
}

+ (CGFloat)getStatusBarHeightForView:(UIView *)view {
    if (@available(iOS 13.0, *)) {
        UIWindow *window = [self getWindowForView:view];
        UIStatusBarManager *statusBarManager = window.windowScene.statusBarManager;
        if (statusBarManager) {
            return CGRectGetHeight(statusBarManager.statusBarFrame);
        }
    }
    return CGRectGetHeight([UIApplication sharedApplication].statusBarFrame);
}

+ (UIInterfaceOrientation)getInterfaceOrientationForView:(UIView *)view {
    if (@available(iOS 13.0, *)) {
        UIWindow *window = [self getWindowForView:view];
        UIInterfaceOrientation orientation = window.windowScene.interfaceOrientation;
        if (orientation != UIInterfaceOrientationUnknown) {
            return orientation;
        }
    }
    return [UIApplication sharedApplication].statusBarOrientation;
}

/*
 References:
 https://blog.csdn.net/weixin_39339407/article/details/81162726
 https://www.jianshu.com/p/df094c044096
 https://www.jianshu.com/p/326ed98d92bb
 */
+ (UIImage *)fixOrientation:(UIImage *)image {

    // No-op if the orientation is already correct
    if (image.imageOrientation == UIImageOrientationUp)
        return image;

    // We need to calculate the proper transformation to make the image upright.
    // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
    CGAffineTransform transform = CGAffineTransformIdentity;

    switch (image.imageOrientation) {
    case UIImageOrientationDown:
    case UIImageOrientationDownMirrored:
        transform = CGAffineTransformTranslate(transform, image.size.width, image.size.height);
        transform = CGAffineTransformRotate(transform, M_PI);
        break;

    case UIImageOrientationLeft:
    case UIImageOrientationLeftMirrored:
        transform = CGAffineTransformTranslate(transform, image.size.width, 0);
        transform = CGAffineTransformRotate(transform, M_PI_2);
        break;

    case UIImageOrientationRight:
    case UIImageOrientationRightMirrored:
        transform = CGAffineTransformTranslate(transform, 0, image.size.height);
        transform = CGAffineTransformRotate(transform, -M_PI_2);
        break;
    default:
        break;
    }

    switch (image.imageOrientation) {
    case UIImageOrientationUpMirrored:
    case UIImageOrientationDownMirrored:
        transform = CGAffineTransformTranslate(transform, image.size.width, 0);
        transform = CGAffineTransformScale(transform, -1, 1);
        break;

    case UIImageOrientationLeftMirrored:
    case UIImageOrientationRightMirrored:
        transform = CGAffineTransformTranslate(transform, image.size.height, 0);
        transform = CGAffineTransformScale(transform, -1, 1);
        break;
    default:
        break;
    }

    // Now we draw the underlying CGImage into a new context, applying the transform
    // calculated above.
    CGContextRef ctx = CGBitmapContextCreate(
        NULL, image.size.width, image.size.height, CGImageGetBitsPerComponent(image.CGImage), 0,
        CGImageGetColorSpace(image.CGImage), CGImageGetBitmapInfo(image.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (image.imageOrientation) {
    case UIImageOrientationLeft:
    case UIImageOrientationLeftMirrored:
    case UIImageOrientationRight:
    case UIImageOrientationRightMirrored:
        // Grr...
        CGContextDrawImage(ctx, CGRectMake(0, 0, image.size.height, image.size.width),
                           image.CGImage);
        break;

    default:
        CGContextDrawImage(ctx, CGRectMake(0, 0, image.size.width, image.size.height),
                           image.CGImage);
        break;
    }

    // And now we just create a new UIImage from the drawing context
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
}

+ (BOOL)currentDeviceIsIPad {
    return [[UIDevice currentDevice].model containsString:@"iPad"];
}

+ (UIColor *)generateDynamicColor:(UIColor *)lightColor darkColor:(UIColor *)darkColor {
    if (!NCChatUIConfigCenter.ui.enableDarkMode) {
        return lightColor;
    }

    if (@available(iOS 13.0, *)) {
        UIColor *dyColor = [UIColor colorWithDynamicProvider:^UIColor *_Nonnull(
                                        UITraitCollection *_Nonnull traitCollection) {
          if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
              return darkColor;
          } else {
              return lightColor;
          }
        }];
        return dyColor;
    } else {
        return lightColor;
    }
}

+ (BOOL)hasLoadedImage:(NSString *)imageUrl {
    return [[NCImageLoader sharedImageLoader] hasLoadedImageURL:[NSURL URLWithString:imageUrl]];
}

+ (NSData *)getImageDataForURLString:(NSString *)imageUrl {
    return [[NCImageLoader sharedImageLoader] getImageDataForURL:[NSURL URLWithString:imageUrl]];
}

+ (BOOL)showProgressViewFor:(UIView *)view text:(NSString *)text animated:(BOOL)animated {
    NCMBProgressHUD *hud = [NCMBProgressHUD showHUDAddedTo:view animated:YES];
    if (hud || text.length > 0) {
        hud.label.text = text;
    }
    return hud != nil;
}

+ (BOOL)hideProgressViewFor:(UIView *)view animated:(BOOL)animated {
    return [NCMBProgressHUD hideHUDForView:view animated:animated];
}

+ (UIColor *)color:(NSString *)key originalColor:(NSString *)colorStr {

    UIColor *originalColor = [self transformColor:colorStr];

    if (key.length == 0) {
        return originalColor;
    }

    NSArray *pathArr = [key componentsSeparatedByString:@"_"];
    NSMutableArray *keyArr = [NSMutableArray arrayWithArray:pathArr];
    [keyArr removeObjectAtIndex:0];
    UIColor *currentColor = [self getColor:[keyArr componentsJoinedByString:@"_"] file:pathArr[0]];
    if (currentColor) {
        return currentColor;
    } else {
        return originalColor;
    }
}

+ (UIColor *)getColor:(NSString *)key file:(NSString *)group {
    NSString *matchValue = [self getColorDic][group][key];
    if (matchValue.length > 0) {
        return [self transformColor:matchValue];
    } else {
        return nil;
    }
}

+ (NSArray<UIBarButtonItem *> *)getLeftNavigationItems:(UIImage *)image
                                                 title:(NSString *)title
                                                target:(id)target
                                                action:(SEL)action {
    NCButton *backBtn = [NCButton buttonWithType:UIButtonTypeCustom];
    UIImage *resolvedImage = [NCSemanticContext imageflippedForRTL:image];
    if (!resolvedImage) {
        if (@available(iOS 13.0, *)) {
            resolvedImage = [UIImage systemImageNamed:@"chevron.backward"];
        }
        NCLogW(@"[NCChatUIUtility] left navigation image is nil, use fallback icon.");
    }
    if (resolvedImage) {
        [backBtn setImage:resolvedImage forState:UIControlStateNormal];
    }
    [backBtn setTitle:title forState:UIControlStateNormal];
    [backBtn setTitleColor:NCChatUIConfigCenter.ui.globalNavigationBarTintColor
                  forState:UIControlStateNormal];
    backBtn.tintColor = NCChatUIConfigCenter.ui.globalNavigationBarTintColor;
    [backBtn addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    [backBtn sizeToFit];
    CGRect backBtnFrame = backBtn.frame;
    backBtnFrame.size.width = MAX(backBtnFrame.size.width, 24.0f);
    backBtnFrame.size.height = MAX(backBtnFrame.size.height, 24.0f);
    backBtn.frame = backBtnFrame;
    if ([NCChatUIUtility isRTL]) {
        backBtn.semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;
    } else {
        backBtn.semanticContentAttribute = UISemanticContentAttributeForceLeftToRight;
    }
    UIBarButtonItem *leftButton = [[UIBarButtonItem alloc] initWithCustomView:backBtn];
    return @[ leftButton ];
}

+ (BOOL)isRTL {
    if (NCChatUIConfigCenter.ui.layoutDirection == NCChatUIInterfaceLayoutDirectionUnspecified) {
        UIWindow *window = [self getKeyWindow];
        UISemanticContentAttribute attr = window.semanticContentAttribute;
        UIUserInterfaceLayoutDirection _layoutDirection =
            [UIView userInterfaceLayoutDirectionForSemanticContentAttribute:attr];
        return _layoutDirection == UIUserInterfaceLayoutDirectionRightToLeft;
    } else if (NCChatUIConfigCenter.ui.layoutDirection ==
               NCChatUIInterfaceLayoutDirectionRightToLeft) {
        return YES;
    }
    return NO;
}

+ (BOOL)isAudioHolding {
    if ([NCSightActivityState sharedState].playerHolding ||
        NCRTCBridgeCallBoolSelector(@selector(isAudioHolding)) ||
        [[NCChatUIExtensionService sharedService] isAudioHolding]) {
        return YES;
    }
    return NO;
}

+ (BOOL)isCameraHolding {
    if ([NCSightActivityState sharedState].cameraHolding ||
        NCRTCBridgeCallBoolSelector(@selector(isCameraHolding)) ||
        [[NCChatUIExtensionService sharedService] isCameraHolding]) {
        return YES;
    }
    return NO;
}

#pragma mark - Privite Methods
+ (NSString *)localizedDescription:(id)messageContent {
    if (![messageContent isKindOfClass:[NCMessageContent class]]) {
        return @"";
    }
    NSString *objectName =
        [NCMessageContent messageTypeForContent:(NCMessageContent *)messageContent];
    if (objectName.length == 0) {
        return @"";
    }
    return NCUILocalizedString(objectName);
}

+ (NSDateFormatter *)getDateFormatter {
    static NSDateFormatter *dateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      dateFormatter = [[NSDateFormatter alloc] init];
    });
    return dateFormatter;
}

+ (NSString *)getMessageDate:(NSDate *)messageDate dateFormat:(NSDateFormatter *)formatter {
    [formatter setDateFormat:[NSString stringWithFormat:@"%@ %@", NCUILocalizedString(@"chat_date"),
                                                        [self getDateFormatterString:messageDate]]];
    return [formatter stringFromDate:messageDate];
}

+ (NSString *)getDateFormatterString:(NSDate *)messageDate {
    NSString *formatStringForHours =
        [NSDateFormatter dateFormatFromTemplate:@"j" options:0 locale:[NSLocale currentLocale]];
    NSRange containsA = [formatStringForHours rangeOfString:@"a"];
    BOOL hasAMPM = containsA.location != NSNotFound;
    NSString *formatStr = nil;
    if (hasAMPM) {
        formatStr = [self getFormatStringByMessageDate:messageDate];
    } else {
        formatStr = @"HH:mm";
    }
    return formatStr;
}

+ (BOOL)isSameYear:(NSDate *)messageDate {
    NSDate *now = [NSDate date];
    NSDateFormatter *formatter = [self getDateFormatter];
    [formatter setDateFormat:@"yyyy"];
    NSInteger currentYear = [[formatter stringFromDate:now] integerValue];
    NSInteger msgYear = [[formatter stringFromDate:messageDate] integerValue];
    if (currentYear == msgYear) {
        return YES;
    }
    return NO;
}

+ (BOOL)isSameMonth:(NSDate *)messageDate {
    NSDate *now = [NSDate date];
    NSDateFormatter *formatter = [self getDateFormatter];
    [formatter setDateFormat:@"MM"];
    NSInteger currentMonth = [[formatter stringFromDate:now] integerValue];
    NSInteger msgMonth = [[formatter stringFromDate:messageDate] integerValue];
    if (currentMonth == msgMonth) {
        return YES;
    }
    return NO;
}

+ (BOOL)isCurrentWeek:(NSDate *)messageDate {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    int unit = NSCalendarUnitWeekOfMonth | NSCalendarUnitMonth | NSCalendarUnitYear;
    NSDateComponents *nowCmps = [calendar components:unit fromDate:[NSDate date]];
    NSDateComponents *messageCmps = [calendar components:unit fromDate:messageDate];
    BOOL isCurrentWeek = (messageCmps.year == nowCmps.year) &&
                         (messageCmps.month == nowCmps.month) &&
                         (messageCmps.weekOfMonth == nowCmps.weekOfMonth);
    return isCurrentWeek;
}

+ (NSInteger)getIntervalDays:(NSDate *)messageDate {
    NSDate *now = [NSDate date];
    NSDateFormatter *formatter = [self getDateFormatter];
    [formatter setDateFormat:@"dd"];
    NSInteger currentDay = [[formatter stringFromDate:now] integerValue];
    NSInteger msgDay = [[formatter stringFromDate:messageDate] integerValue];
    return currentDay - msgDay;
}

+ (NSString *)getFormatStringByMessageDate:(NSDate *)messageDate {
    NSString *formatStr = nil;
    if ([[self class] isBetweenFromHour:0 toHour:6 currentDate:messageDate]) {
        formatStr = NCUILocalizedString(@"dawn");
    } else if ([[self class] isBetweenFromHour:6 toHour:12 currentDate:messageDate]) {
        formatStr = NCUILocalizedString(@"forenoon");
    } else if ([[self class] isBetweenFromHour:12 toHour:13 currentDate:messageDate]) {
        formatStr = NCUILocalizedString(@"noon");
    } else if ([[self class] isBetweenFromHour:13 toHour:18 currentDate:messageDate]) {
        formatStr = NCUILocalizedString(@"afternoon");
    } else {
        formatStr = NCUILocalizedString(@"evening");
    }
    return formatStr;
}

+ (BOOL)isBetweenFromHour:(NSInteger)fromHour
                   toHour:(NSInteger)toHour
              currentDate:(NSDate *)currentDate {
    NSDate *date1 = [self getCustomDateWithHour:fromHour currentDate:currentDate];
    NSDate *date2 = [self getCustomDateWithHour:toHour currentDate:currentDate];
    if (([currentDate compare:date1] == NSOrderedDescending ||
         [currentDate compare:date1] == NSOrderedSame) &&
        ([currentDate compare:date2] == NSOrderedAscending))
        return YES;
    return NO;
}

+ (NSDate *)getCustomDateWithHour:(NSInteger)hour currentDate:(NSDate *)currentDate {
    NSCalendar *currentCalendar =
        [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *currentComps;
    NSInteger unitFlags = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay |
                          NSCalendarUnitWeekday | NSCalendarUnitHour | NSCalendarUnitMinute |
                          NSCalendarUnitSecond;
    currentComps = [currentCalendar components:unitFlags fromDate:currentDate];
    // Set a specific time on the current day.
    NSDateComponents *resultComps = [[NSDateComponents alloc] init];
    [resultComps setYear:[currentComps year]];
    [resultComps setMonth:[currentComps month]];
    [resultComps setDay:[currentComps day]];
    [resultComps setHour:hour];
    NSCalendar *resultCalendar =
        [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    return [resultCalendar dateFromComponents:resultComps];
}

+ (NSString *)__formatGroupNotificationMessageContent:
    (NCGroupNotificationMessage *)groupNotification {
    NSData *jsonData = [groupNotification.data dataUsingEncoding:NSUTF8StringEncoding];
    if (jsonData == nil) {
        return nil;
    }
    NSDictionary *dictionary =
        [NSJSONSerialization JSONObjectWithData:jsonData
                                        options:NSJSONReadingMutableContainers
                                          error:nil];
    NSString *nickName = [dictionary[@"operatorNickname"] isKindOfClass:[NSString class]]
                             ? dictionary[@"operatorNickname"]
                             : nil;
    BOOL isMeOperate = NO;
    if ([groupNotification.operatorUserId isEqualToString:[NCEngine getCurrentUserId]]) {
        isMeOperate = YES;
        nickName = NCUILocalizedString(@"you");
    }
    return [self __formatGroupNotificationWithOperation:groupNotification
                                         dictionaryData:dictionary
                                               nickName:nickName
                                            isMeOperate:isMeOperate];
}

+ (NSString *)__formatGroupNotificationWithOperation:(NCGroupNotificationMessage *)groupNotification
                                      dictionaryData:(NSDictionary *)dictionary
                                            nickName:(NSString *)nickName
                                         isMeOperate:(BOOL)isMeOperate {
    NSString *message = nil;
    NSString *operatorUserId = groupNotification.operatorUserId;
    NSArray *targetUserNickName =
        [dictionary[@"targetUserDisplayNames"] isKindOfClass:[NSArray class]]
            ? dictionary[@"targetUserDisplayNames"]
            : nil;
    NSArray *targetUserIds = [dictionary[@"targetUserIds"] isKindOfClass:[NSArray class]]
                                 ? dictionary[@"targetUserIds"]
                                 : nil;
    if ([groupNotification.operation isEqualToString:@"Create"]) {
        message = [NSString stringWithFormat:NCUILocalizedString(isMeOperate ? @"group_have_created"
                                                                             : @"group_created"),
                                             nickName];
        return message;
    }
    if ([groupNotification.operation isEqualToString:@"Add"]) {

        message = [self __formatGroupNotificationOperationAdd:targetUserIds
                                           targetUserNickName:targetUserNickName
                                               operatorUserId:operatorUserId
                                                     nickName:nickName
                                                  isMeOperate:isMeOperate];
        return message;
    }

    if ([groupNotification.operation isEqualToString:@"Quit"]) {
        message = [NSString
            stringWithFormat:NCUILocalizedString(isMeOperate ? @"group_have_quit" : @"group_quit"),
                             nickName];
        return message;
    }

    if ([groupNotification.operation isEqualToString:@"Kicked"]) {

        message = [self __formatGroupNotificationOperationKicked:targetUserIds
                                              targetUserNickName:targetUserNickName
                                                  operatorUserId:operatorUserId
                                                        nickName:nickName
                                                     isMeOperate:isMeOperate];
        return message;
    }

    if ([groupNotification.operation isEqualToString:@"Rename"]) {
        NSString *groupName = [dictionary[@"targetGroupName"] isKindOfClass:[NSString class]]
                                  ? dictionary[@"targetGroupName"]
                                  : nil;
        message =
            [NSString stringWithFormat:NCUILocalizedString(@"group_changed"), nickName, groupName];
        return message;
    }

    if ([groupNotification.operation isEqualToString:@"Dismiss"]) {
        message = [NSString stringWithFormat:NCUILocalizedString(isMeOperate ? @"group_have_dismiss"
                                                                             : @"group_dismiss"),
                                             nickName];
        return message;
    }

    message = groupNotification.message;
    return message;
}

+ (NSString *)__formatGroupNotificationOperationAdd:(NSArray *)targetUserIds
                                 targetUserNickName:(NSArray *)targetUserNickName
                                     operatorUserId:(NSString *)operatorUserId
                                           nickName:(NSString *)nickName
                                        isMeOperate:(BOOL)isMeOperate {
    NSString *message = nil;
    if (targetUserNickName.count == 0) {
        message = [NSString stringWithFormat:NCUILocalizedString(@"group_join"), nickName];
        return message;
    }

    NSMutableString *names = [[NSMutableString alloc] init];
    NSMutableString *userIdStr = [[NSMutableString alloc] init];
    for (NSUInteger index = 0; index < targetUserNickName.count; index++) {
        if (![targetUserNickName[index] isKindOfClass:[NSString class]]) {
            continue;
        }
        [names appendString:targetUserNickName[index]];
        if (index != targetUserNickName.count - 1) {
            [names appendString:NCUILocalizedString(@"punctuation")];
        }
    }
    for (NSUInteger index = 0; index < targetUserIds.count; index++) {
        if (![targetUserIds[index] isKindOfClass:[NSString class]]) {
            continue;
        }
        [userIdStr appendString:targetUserIds[index]];
        if (index != targetUserNickName.count - 1) {
            [userIdStr appendString:NCUILocalizedString(@"punctuation")];
        }
    }

    if ([operatorUserId isEqualToString:userIdStr]) {
        message = [NSString stringWithFormat:NCUILocalizedString(@"group_join"), nickName];
        return message;
    }

    if (targetUserIds.count > targetUserNickName.count) {
        names =
            [NSMutableString stringWithFormat:@"%@%@", names, NCUILocalizedString(@"group_etc")];
    }
    message = [NSString stringWithFormat:NCUILocalizedString(isMeOperate ? @"group_have_invited"
                                                                         : @"group_invited"),
                                         nickName, names];
    return message;
}

+ (NSString *)__formatGroupNotificationOperationKicked:(NSArray *)targetUserIds
                                    targetUserNickName:(NSArray *)targetUserNickName
                                        operatorUserId:(NSString *)operatorUserId
                                              nickName:(NSString *)nickName
                                           isMeOperate:(BOOL)isMeOperate {
    NSString *message = nil;
    NSMutableString *names = [[NSMutableString alloc] init];
    for (NSUInteger index = 0; index < targetUserNickName.count; index++) {
        if (![targetUserNickName[index] isKindOfClass:[NSString class]]) {
            continue;
        }
        [names appendString:targetUserNickName[index]];
        if (index != targetUserNickName.count - 1) {
            [names appendString:NCUILocalizedString(@"punctuation")];
        }
    }

    if (targetUserIds.count > targetUserNickName.count) {
        names =
            [NSMutableString stringWithFormat:@"%@%@", names, NCUILocalizedString(@"group_etc")];
    }
    message = [NSString stringWithFormat:NCUILocalizedString(isMeOperate ? @"group_have_removed"
                                                                         : @"group_removed"),
                                         nickName, names];
    return message;
}

+ (UIColor *)transformColor:(NSString *)colorString {

    NSArray *colorStrings = [[colorString stringByReplacingOccurrencesOfString:@" " withString:@""]
        componentsSeparatedByString:@"#"];

    NSString *rgbString = nil;
    NSString *alphaString = nil;

    if (colorStrings.count > 0) {
        rgbString = colorStrings[0];
    }
    if (colorStrings.count > 1) {
        alphaString = colorStrings[1];
    }

    unsigned long rgbValue = 0;
    if ([rgbString hasPrefix:@"0x"] || [rgbString hasPrefix:@"0X"]) {
        rgbValue = strtoul([rgbString UTF8String], NULL, 16);
    } else {
        rgbValue = strtoul([rgbString UTF8String], NULL, 10);
    }

    float alphaValue = 1.0f;
    if (alphaString.length > 0) {
        alphaValue = [alphaString floatValue];
        if ([alphaString hasSuffix:@"%"]) {
            alphaValue /= 100.0;
        }
    }

    return [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16)) / 255.0
                           green:((float)((rgbValue & 0xFF00) >> 8)) / 255.0
                            blue:((float)(rgbValue & 0xFF)) / 255.0
                           alpha:alphaValue];
}

+ (NSDictionary *)getColorDic {
    static NSDictionary *colorDic = nil;
    if (!colorDic) {
        NSString *path = [self filePathForName:@"NCChatUIColor.plist"];
        colorDic = [[NSDictionary alloc] initWithContentsOfFile:path];
    }
    return colorDic;
}

+ (NSString *)getDisplayName:(NCChatUIUserInfo *)userInfo {
    if (userInfo.alias.length > 0) {
        return userInfo.alias;
    }
    return userInfo.name;
}
+ (NSString *)localizedString:(NSString *)key table:(NSString *)table {
    NSString *normalizedKey = key;
    if ([key isEqualToString:(NCMessageType.gif ?: @"RC:GIFMsg")]) {
        normalizedKey = @"gif_message";
    } else if ([key isEqualToString:(NCMessageType.shortVideo ?: @"RC:SightMsg")]) {
        normalizedKey = @"video_message";
    } else if ([key isEqualToString:NCMessageType.combine]) {
        normalizedKey = @"chat_history_message";
    } else if ([key isEqualToString:@"RC:ImgMsg"]) {
        normalizedKey = @"image_message";
    } else if ([key isEqualToString:@"RC:FileMsg"]) {
        normalizedKey = @"file_message";
    } else if ([key isEqualToString:@"RC:CardMsg"]) {
        normalizedKey = @"contact_card_message";
    } else if ([key isEqualToString:@"RC:VCSummary"]) {
        normalizedKey = @"audio_video_call_summary";
    } else if ([key isEqualToString:@"RCJrmf:RpMsg"]) {
        normalizedKey = @"red_packet_message";
    }
    return [[NCChatUILanguageManager sharedManager] localizedStringForKey:normalizedKey
                                                                    table:table];
}

+ (NSString *)filePathForName:(NSString *)name {
    NSBundle *tmp = [NSBundle mainBundle];
    ;
    NSString *resourcePath = [tmp resourcePath];
    NSString *bundlePath = [resourcePath stringByAppendingPathComponent:name];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:bundlePath]) {
        return bundlePath;
    } else {
        NSBundle *innerBundle = [NSBundle bundleForClass:[self class]];
        NSString *innerFilePath = [[innerBundle resourcePath] stringByAppendingPathComponent:name];
        return innerFilePath;
    }
}

+ (NSString *)bundlePathWithName:(NSString *)bundleName {
    NSString *bundlePath = nil;
    NSString *fullName = [NSString stringWithFormat:@"%@.bundle", bundleName];
    NSURL *rootBundleURL = [[NSBundle mainBundle] URLForResource:bundleName
                                                   withExtension:@"bundle"];
    if (rootBundleURL) {
        NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
        bundlePath = [resourcePath stringByAppendingPathComponent:fullName];
    } else {
        NSBundle *innerBundle = [NSBundle bundleForClass:[self class]];
        NSString *resourcePath = [innerBundle resourcePath];
        bundlePath = [resourcePath stringByAppendingPathComponent:fullName];
    }
    return bundlePath;
}

// Returns whether the current interface style is dark.
+ (BOOL)isDarkMode {
    if (@available(iOS 13.0, *)) {
        NSNumber *currentUserInterfaceStyle =
            [[NSUserDefaults standardUserDefaults] objectForKey:@"NCCurrentUserInterfaceStyle"];
        if (!currentUserInterfaceStyle) {
            currentUserInterfaceStyle =
                @(UITraitCollection.currentTraitCollection.userInterfaceStyle);
        }
        if (currentUserInterfaceStyle.integerValue == UIUserInterfaceStyleDark) {
            return YES;
        }
    }
    return NO;
}

@end
