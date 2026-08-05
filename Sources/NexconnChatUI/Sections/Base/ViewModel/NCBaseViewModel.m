//
//  NCBaseViewModel.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseViewModel.h"
#import "NCViewModelAdapterCenter.h"
#import "NCLoadingTipView.h"
#import "NCBaseCellViewModel.h"
@interface NCBaseViewModel () {
    id __weak _delegate;
}
@property (nonatomic, weak) NCLoadingTipView *loadingView;
@end

@implementation NCBaseViewModel


- (id)delegate {
    if (!_delegate) {
        id delegate = [NCViewModelAdapterCenter delegateForViewModelClass:[self class]];
        _delegate = delegate;
    }
    return _delegate;
}

- (void)setDelegate:(id)delegate {
    _delegate = delegate;
}

- (void)loadingWithTip:(NSString *)tip {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.loadingView) {
            [self.loadingView stopLoading];
        }
        self.loadingView = [NCLoadingTipView loadingWithTip:tip];
        [self.loadingView startLoading];
    });
   
}

- (void)stopLoading {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.loadingView stopLoading];
        self.loadingView = nil;
    });
   
}

- (void)removeSeparatorLineIfNeed:(NSArray *)array {
    for (NSArray *tmp in array) {
        if ([tmp isKindOfClass:[NSArray class]]) {
            NCBaseCellViewModel *vm = tmp.lastObject;
            if ([vm isKindOfClass:[NCBaseCellViewModel class]]) {
                vm.hideSeparatorLine = YES;
            }
        }
    }
}
@end
