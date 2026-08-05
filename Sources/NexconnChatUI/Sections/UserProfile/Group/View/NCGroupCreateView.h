//
//  NCGroupCreateView.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseView.h"
#import "NCImageView.h"
#import "NCNameEditView.h"
#import "NCBaseButton.h"
NS_ASSUME_NONNULL_BEGIN

@protocol NCGroupCreateViewDelegate <NSObject>

- (void)portaitImageViewDidClick;

@end

@interface NCGroupCreateView : NCBaseView

@property (nonatomic, weak) id<NCGroupCreateViewDelegate> delegate;

@property (nonatomic, strong) NCImageView *portraitImageView;

@property (nonatomic, strong) NCNameEditView *nameEditView;

@property (nonatomic, strong) NCBaseButton *createButton;

@end

NS_ASSUME_NONNULL_END
