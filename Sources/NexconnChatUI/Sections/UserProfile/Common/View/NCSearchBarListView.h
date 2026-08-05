//
//  NCSearchBarListView.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseView.h"

NS_ASSUME_NONNULL_BEGIN

@interface NCSearchBarListView : NCBaseView
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIView *searchBar;
@property (nonatomic, strong) UIStackView *contentStackView;
@property (nonatomic, strong) UILabel *labEmpty;

- (void)configureSearchBar:(UIView *)bar;
@end

NS_ASSUME_NONNULL_END
