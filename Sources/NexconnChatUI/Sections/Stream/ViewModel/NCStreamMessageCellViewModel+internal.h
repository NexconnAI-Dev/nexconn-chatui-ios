//
//  NCStreamMessageCellViewModel+internal.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCStreamMessageCellViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface NCStreamMessageCellViewModel ()

@property (nonatomic, weak) NCMessageModel *model;

@property (nonatomic, assign) BOOL showReferMessage;

@property (nonatomic, assign) NCStreamMessageStatus status;

@property (nonatomic, assign) CGSize contentViewSize;

@property (nonatomic, assign) CGSize textViewSize;

@property (nonatomic, assign) CGSize referViewSize;

@property (nonatomic, strong) dispatch_queue_t calculateHeightQueue;

@property (nonatomic, copy) NSString *summary;

@property (nonatomic, assign) BOOL summaryComplete;

@end

NS_ASSUME_NONNULL_END
