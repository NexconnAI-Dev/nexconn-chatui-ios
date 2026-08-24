//
//  NCStreamContentView.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCMessageModel.h"
#import "NCStreamContentViewModel.h"
#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN

@protocol NCStreamContentViewDelegate <NSObject>

- (void)streamContentViewDidLongPress;

- (void)streamContentViewDidClickUrl:(NSString *)urlString;

@end

@interface NCStreamContentView : UIView

@property (nonatomic, weak) id<NCStreamContentViewDelegate> delegate;

- (void)configViewModel:(NCStreamContentViewModel *)contentViewModel;

- (void)showLoading;

- (void)showFailed;

- (void)cleanView;

@end

NS_ASSUME_NONNULL_END
