//
//  NCSearchBarListView.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCSearchBarListView.h"
#import "NCChatUICommonDefine.h"

@interface NCSearchBarListView()
@property (nonatomic, strong) UIView *barContainerView;
@end

@implementation NCSearchBarListView

- (void)setupView {
    [super setupView];
    self.backgroundColor = NCDynamicColor(@"auxiliary_background_1_color");
    [self addSubview:self.contentStackView];
    [self.contentStackView addArrangedSubview:self.tableView];
    [self addSubview:self.labEmpty];
}

- (UIView *)containerViewFor:(UIView *)bar {
    bar.translatesAutoresizingMaskIntoConstraints = NO;
    
    UIView *outer = [UIView new];
    outer.translatesAutoresizingMaskIntoConstraints = NO;
    
    CGFloat barHeight = 40;
    UIView *inner = [UIView new];
    inner.translatesAutoresizingMaskIntoConstraints = NO;
    inner.layer.cornerRadius = barHeight/2;
    inner.layer.masksToBounds = YES;
    inner.backgroundColor = NCDynamicColor(@"common_background_color");
    
    [outer addSubview:inner];
    [inner addSubview:bar];
    // Lower horizontal constraint priority to avoid conflicts when tableFooterView has zero width.
    NSLayoutConstraint *leadingConstraint = [inner.leadingAnchor constraintEqualToAnchor:outer.leadingAnchor constant:NCUserManagementViewPadding];
    leadingConstraint.priority = UILayoutPriorityDefaultHigh; // 750
    
    NSLayoutConstraint *trailingConstraint = [inner.trailingAnchor constraintEqualToAnchor:outer.trailingAnchor constant:-NCUserManagementViewPadding];
    trailingConstraint.priority = UILayoutPriorityDefaultHigh; // 750

    NSLayoutConstraint *heightConstraint = [inner.heightAnchor constraintEqualToConstant:barHeight];
    heightConstraint.priority = UILayoutPriorityDefaultHigh; // 750

    [NSLayoutConstraint activateConstraints:@[
        leadingConstraint,
        trailingConstraint,
        [inner.topAnchor constraintEqualToAnchor:outer.topAnchor constant:8],
        [inner.bottomAnchor constraintEqualToAnchor:outer.bottomAnchor],
        heightConstraint,
        
        [bar.centerYAnchor constraintEqualToAnchor:inner.centerYAnchor],
        [bar.leadingAnchor constraintEqualToAnchor:inner.leadingAnchor],
        [bar.trailingAnchor constraintEqualToAnchor:inner.trailingAnchor],
    ]];
    return outer;
}

- (void)configureSearchBar:(UIView *)bar {
    bar.translatesAutoresizingMaskIntoConstraints = NO;
    if (self.barContainerView) {
        [self.contentStackView removeArrangedSubview:self.barContainerView];
    }
    self.searchBar = bar;
    if (bar) {
        self.barContainerView = [self containerViewFor:bar];
        [self.contentStackView insertArrangedSubview:self.barContainerView atIndex:0];
    }
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

- (void)setupConstraints {
    [super setupConstraints];
    
    NSLayoutAnchor *topAnchor;
    if (@available(iOS 11.0, *)) {
        topAnchor = self.safeAreaLayoutGuide.topAnchor;
    } else {
        topAnchor = self.topAnchor;
    }
    
    [NSLayoutConstraint activateConstraints:@[
        [self.contentStackView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [self.contentStackView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [self.contentStackView.topAnchor constraintEqualToAnchor:topAnchor],
        [self.contentStackView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        
        [self.labEmpty.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        [self.labEmpty.centerXAnchor constraintEqualToAnchor:self.centerXAnchor]
    ]];
}

- (UITableView *)tableView {
    if(!_tableView) {
        UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectZero
                                                              style:UITableViewStyleGrouped];
        tableView.tableFooterView = [UIView new];
        tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        tableView.backgroundColor =  NCDynamicColor(@"auxiliary_background_1_color");
        tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0.1)];
        tableView.sectionHeaderHeight = 0;
        if (@available(iOS 15.0, *)) {
            tableView.sectionHeaderTopPadding = 0;
        }
        // Configure the right-side section index.
        tableView.sectionIndexBackgroundColor = [UIColor clearColor];
        tableView.sectionIndexColor = NCDynamicColor(@"text_secondary_color");
        tableView.translatesAutoresizingMaskIntoConstraints = NO;
        [tableView setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisVertical];
        _tableView = tableView;
    }
    return _tableView;
}


- (UIStackView *)contentStackView {
    if (!_contentStackView) {
        _contentStackView = [[UIStackView alloc] init];
        _contentStackView.axis = UILayoutConstraintAxisVertical;
        _contentStackView.alignment = UIStackViewAlignmentFill;
        _contentStackView.distribution = UIStackViewDistributionFill;
        _contentStackView.spacing = 20;
        _contentStackView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _contentStackView;
}


- (UILabel *)labEmpty {
    if (!_labEmpty) {
        UILabel *lab = [[UILabel alloc] init];
        lab.text = NCUILocalizedString(@"no_data");
        lab.textColor = NCDynamicColor(@"text_primary_color");
        lab.font = [UIFont systemFontOfSize:17];
        lab.textAlignment = NSTextAlignmentCenter;
        lab.hidden = YES;
        lab.translatesAutoresizingMaskIntoConstraints = NO;
        [lab sizeToFit];
        _labEmpty = lab;
    }
    return _labEmpty;
}

@end
