//
//  NCBaseTableViewController.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseTableViewController.h"
#import "NCSemanticContext.h"
@interface NCBaseTableViewController ()

@end

@implementation NCBaseTableViewController
- (instancetype)initWithStyle:(UITableViewStyle)style {
    if (self = [super initWithStyle:UITableViewStyleGrouped]) {
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self closeSelfSizing];
    [self updateRTLUI];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    [self saveCurrentUserInterfaceStyle];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    [self saveCurrentUserInterfaceStyle];
}

- (void)saveCurrentUserInterfaceStyle {
    if (@available(iOS 13.0, *)) {
        [[NSUserDefaults standardUserDefaults]
            setObject:@(UITraitCollection.currentTraitCollection.userInterfaceStyle)
               forKey:@"NCCurrentUserInterfaceStyle"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (void)closeSelfSizing {
    self.tableView.estimatedRowHeight = 0;
    self.tableView.estimatedSectionHeaderHeight = 0;
    self.tableView.estimatedSectionFooterHeight = 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}

- (void)updateRTLUI {
    if ([NCSemanticContext isRTL]) {
        self.tableView.semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;
    } else {
        self.tableView.semanticContentAttribute = UISemanticContentAttributeForceLeftToRight;
    }
}

@end
