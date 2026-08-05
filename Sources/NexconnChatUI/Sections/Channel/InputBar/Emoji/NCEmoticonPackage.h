//
//  NCEmoticonPackage.h
//  NCChatUIExtension
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCEmojiBoardView.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "NCBaseScrollView.h"
@interface NCEmoticonPackage : NSObject

/// Unique identifier of the emoticon package.
@property (nonatomic, copy) NSString *identify;

// Total page count of the emoticon package.
@property (nonatomic, assign) int totalPage;

// tabIcon
@property (nonatomic, strong) UIImage *tabImage;

/// Emoticon package container.
@property (nonatomic, strong) NCBaseScrollView *emotionContainerView;

/// Emoticon data source.
@property (nonatomic, strong) id<NCEmoticonTabSource> tabSource;

@property (nonatomic, weak) NCEmojiBoardView *emojBoardView;

- (id)initEmoticonPackage:(UIImage *)tabImage withTotalCount:(int)pageCount;

- (void)showEmoticonView:(int)index;

- (void)setNeedLayout;
@end
