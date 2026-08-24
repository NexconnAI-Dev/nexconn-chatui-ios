//
//  NCStreamTextContentViewModel.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCStreamContentViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface NCStreamTextContentViewModel : NCStreamContentViewModel <NCStreamViewModelProtocol>

@property (nonatomic, copy, readonly) NSAttributedString *attributedContent;

@end

NS_ASSUME_NONNULL_END
