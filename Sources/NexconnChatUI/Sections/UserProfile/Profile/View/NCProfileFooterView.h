//
//  NCProfileFooterView.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseView.h"
#import "NCButtonItem.h"
NS_ASSUME_NONNULL_BEGIN

@interface NCProfileFooterView : NCBaseView

- (instancetype)initWithTopSpace:(CGFloat)topSpace
                     buttonSpace:(CGFloat)buttonSpace
                           items:(NSArray<NCButtonItem *> *)items;

@end

NS_ASSUME_NONNULL_END
