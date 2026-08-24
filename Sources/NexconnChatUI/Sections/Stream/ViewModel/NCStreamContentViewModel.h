//
//  NCStreamContentViewModel.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCStreamViewModelProtocol.h"
#import <Foundation/Foundation.h>
@class NCStreamContentView;
NS_ASSUME_NONNULL_BEGIN

@protocol NCStreamContentViewModelDelegate <NSObject>

- (void)streamContentLayoutWillUpdate;

@end

@interface NCStreamContentViewModel : NSObject <NCStreamViewModelProtocol>

@property (nonatomic, copy) NSString *content;

@property (nonatomic, weak) id<NCStreamContentViewModelDelegate> delegate;

@property (nonatomic, assign) CGSize contentSize;

+ (NSString *)failedInfo;

- (NCStreamContentView *)streamContentView;

- (CGFloat)contentMaxWidth;

@end

NS_ASSUME_NONNULL_END
