//
//  NCEditInputBarConfig.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCEditInputBarConfig.h"
#import "NSDictionary+NCAccessor.h"
#import "NSMutableArray+NCOperation.h"
#import "NSMutableDictionary+NCOperation.h"

static NSString *const messageIdKey = @"messageId";
static NSString *const sentTimeKey = @"sentTime";
static NSString *const stateDataKey = @"stateData";
static NSString *const stateDataTextContentKey = @"textContent";
static NSString *const stateDataMentionedKey = @"mentionedRangeInfoList";
static NSString *const stateDataReferenceInfoKey = @"referenceInfo";
static NSString *const stateDataReferenceSenderNameKey = @"senderName";
static NSString *const stateDataReferenceContentKey = @"content";
static NSString *const stateDataReferenceStatusKey = @"referencedMsgStatus";

@implementation NCEditInputBarConfig

- (instancetype)initWithData:(NSString *)data {
    self = [super init];
    if (self) {
        [self setupData:data];
    }
    return self;
}

- (void)setupData:(NSString *)data {
    NSData *draftData = [data dataUsingEncoding:NSUTF8StringEncoding];
    if (draftData) {
        __autoreleasing NSError *error = nil;
        NSDictionary *draftDict = [NSJSONSerialization JSONObjectWithData:draftData
                                                                  options:kNilOptions
                                                                    error:&error];
        if (!error && draftDict.count > 0) {
            self.messageId = [draftDict nc_stringForKey:messageIdKey];
            self.sentTime = [draftDict nc_longLongIntForKey:sentTimeKey];

            NSDictionary *stateData = [draftDict nc_dictionaryForKey:stateDataKey];
            if (stateData) {
                self.textContent = [stateData nc_stringForKey:stateDataTextContentKey];
                // Mention range metadata.
                NSArray *mentionedRangeInfoList = [stateData nc_arrayForKey:stateDataMentionedKey];
                if (mentionedRangeInfoList) {
                    NSMutableArray *mentionedRangeInfoTemp = [NSMutableArray array];
                    for (NSString *encodedInfo in mentionedRangeInfoList) {
                        NCMentionedStringRangeInfo *info =
                            [[NCMentionedStringRangeInfo alloc] initWithDecodeString:encodedInfo];
                        if (info) {
                            [mentionedRangeInfoTemp addObject:info];
                        }
                    }
                    self.mentionedRangeInfo = [mentionedRangeInfoTemp copy];
                }
                // Referenced message metadata.
                NSDictionary *referenceInfo =
                    [stateData nc_dictionaryForKey:stateDataReferenceInfoKey];
                if (referenceInfo) {
                    self.referencedSenderName =
                        [referenceInfo nc_stringForKey:stateDataReferenceSenderNameKey];
                    self.referencedContent =
                        [referenceInfo nc_stringForKey:stateDataTextContentKey];
                    self.referencedMsgStatus = (NCReferenceMessageStatus)
                        [referenceInfo nc_intForKey:stateDataReferenceStatusKey];
                }
            }
        }
    }
}

- (NSString *)encode {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict nc_setObject:self.messageId forKey:messageIdKey];
    [dict nc_setObject:@(self.sentTime) forKey:sentTimeKey];

    NSMutableDictionary *stateData = [NSMutableDictionary dictionary];
    [stateData nc_setObject:self.textContent forKey:stateDataTextContentKey];

    // Mention range metadata.
    NSMutableArray *mentionedRangeInfoList = [NSMutableArray array];
    for (NCMentionedStringRangeInfo *info in self.mentionedRangeInfo) {
        [mentionedRangeInfoList nc_addObject:[info encodeToString]];
    }
    [stateData nc_setObject:mentionedRangeInfoList forKey:stateDataMentionedKey];

    // Referenced message metadata.
    if (_referencedSenderName || _referencedContent) {
        NSMutableDictionary *referenceInfo = [NSMutableDictionary dictionary];
        [referenceInfo nc_setObject:self.referencedSenderName
                             forKey:stateDataReferenceSenderNameKey];
        [referenceInfo nc_setObject:self.referencedContent forKey:stateDataTextContentKey];
        [referenceInfo nc_setObject:@((NSInteger)self.referencedMsgStatus)
                             forKey:stateDataReferenceStatusKey];

        [stateData nc_setObject:referenceInfo forKey:stateDataReferenceInfoKey];
    }
    [dict nc_setObject:stateData forKey:stateDataKey];

    NSData *data = [NSJSONSerialization dataWithJSONObject:dict options:kNilOptions error:nil];
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

@end
