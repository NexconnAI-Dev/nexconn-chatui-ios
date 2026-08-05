//
//  NCBaseViewModel.h
//  Pods-NCUserProfile_Example
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN

@interface NCBaseViewModel : NSObject
@property (nonatomic, weak) id delegate;
- (void)loadingWithTip:(NSString *)tip;
- (void)stopLoading;
- (void)removeSeparatorLineIfNeed:(NSArray *)array;
@end

NS_ASSUME_NONNULL_END
