//
//  NCNetworkIndicatorView.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseImageView.h"
#import "NCBaseView.h"
#import <UIKit/UIKit.h>
@interface NCNetworkIndicatorView : NCBaseView

@property (nonatomic, strong) NCBaseImageView *networkUnreachableImageView;

- (instancetype)initWithText:(NSString *)text;

- (void)setText:(NSString *)text;
@end
