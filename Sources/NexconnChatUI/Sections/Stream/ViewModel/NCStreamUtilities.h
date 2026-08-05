//
//  NCStreamUtilities.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NCMessageModel.h"
NS_ASSUME_NONNULL_BEGIN
extern NSUInteger const NCStreamMessageCellLoadingLimit;
@interface NCStreamSummaryModel : NSObject

@property (nonatomic, assign) BOOL isComplete;

@property (nonatomic, copy) NSString *summary;

@end

@interface NCStreamUtilities : NSObject

+ (nullable NCStreamSummaryModel *)parserStreamSummary:(NCMessageModel *)model;

@end

NS_ASSUME_NONNULL_END
