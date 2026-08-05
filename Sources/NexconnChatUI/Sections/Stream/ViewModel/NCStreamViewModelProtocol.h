//
//  NCStreamViewModelProtocol.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol NCStreamViewModelProtocol <NSObject>

- (CGSize)calculateContentSize;

- (void)streamContentDidUpdate:(NSString *)content;

@end

NS_ASSUME_NONNULL_END
