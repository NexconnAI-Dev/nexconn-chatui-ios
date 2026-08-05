//
//  NCMessageModel+RRS.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import"NCMessageModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface NCMessageModel (RRS)
- (BOOL)rrs_shouldRespondReadReceipt;
- (BOOL)rrs_shouldFetchReadReceipt;
@end

NS_ASSUME_NONNULL_END
