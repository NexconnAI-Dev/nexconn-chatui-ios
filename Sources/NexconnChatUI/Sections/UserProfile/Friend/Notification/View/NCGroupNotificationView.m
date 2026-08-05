//
//  NCGroupNotificationView.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCGroupNotificationView.h"
#import "NCChatUICommonDefine.h"
#import "NCMJRefreshAutoNormalFooter.h"
#import "NCNetworkIndicatorView.h"
#import "NCBaseTableView.h"

@interface NCGroupNotificationView()
@property (nonatomic, strong) NCMJRefreshAutoNormalFooter *footer;
@property (nonatomic, strong) NCNetworkIndicatorView *networkIndicatorView;
/** Callback target. */
@property (weak, nonatomic) id refreshingTarget;
/** Callback selector. */
@property (assign, nonatomic) SEL refreshingAction;
@end

@implementation NCGroupNotificationView

- (void)addRefreshingTarget:(id)target withSelector:(SEL)selector {
    self.refreshingAction = selector;
    self.refreshingTarget = target;
}

- (void)setupView {
    [super setupView];
    self.tableView.ncmj_footer = self.footer;
    [self addSubview:self.labEmpty];
}

- (void)loadMore {
    if (self.refreshingTarget) {
        if ([self.refreshingTarget respondsToSelector:self.refreshingAction]) {
            [self.refreshingTarget performSelector:self.refreshingAction];
        }
    }
}

- (void)stopRefreshing {
    [self.footer endRefreshing];
}

- (NCMJRefreshAutoNormalFooter *)footer {
    if(!_footer) {
        _footer = [NCMJRefreshAutoNormalFooter footerWithRefreshingTarget:self refreshingAction:@selector(loadMore)];
        _footer.refreshingTitleHidden = YES;
    }
    return _footer;
}

- (NCNetworkIndicatorView *)networkIndicatorView {
    if (!_networkIndicatorView) {
        _networkIndicatorView = [[NCNetworkIndicatorView alloc]
            initWithText:NCUILocalizedString(@"connection_is_not_reachable")];
        _networkIndicatorView.backgroundColor = NCDynamicColor(@"network_Indicator_view_bg_color");
        [_networkIndicatorView setFrame:CGRectMake(0, 0, 48, 48)];
        _networkIndicatorView.hidden = YES;
    }
    return _networkIndicatorView;
}

@end
