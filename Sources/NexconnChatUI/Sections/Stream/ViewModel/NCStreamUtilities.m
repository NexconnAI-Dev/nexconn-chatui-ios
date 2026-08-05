//
//  NCStreamUtilities.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCStreamUtilities.h"
#import "NSDictionary+NCAccessor.h"

static NSString * const kStreamMessageExpansionSummeryKey = @"RC_Ext_StreamMsgSummary";
@implementation NCStreamSummaryModel

@end

@implementation NCStreamUtilities
+ (NCStreamSummaryModel *)parserStreamSummary:(NCMessageModel *)model {
    if (![model.content isKindOfClass:NCStreamMessage.class]) {
        return nil;
    }
    NSString *summaryConfig = [model.expansionDic nc_stringForKey:kStreamMessageExpansionSummeryKey];
    NSData *data = [summaryConfig dataUsingEncoding:NSUTF8StringEncoding];
    if (!data) {
        return nil;
    }
    // Deserialize the data into a dictionary.
    NSError *error = nil;
    NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    // Return nil for invalid JSON or a non-dictionary root object.
    if (error) {
        return nil;
    }
    NCStreamSummaryModel *summary = [NCStreamSummaryModel new];
    summary.isComplete = [dictionary nc_boolForKey:@"complete"];
    summary.summary = [dictionary nc_stringForKey:@"summary"];
    return summary;
}

@end
