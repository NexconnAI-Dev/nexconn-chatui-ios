//
//  NCBaseViewController.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseViewController.h"
@interface NCBaseViewController ()

@property (nonatomic, strong) UIPercentDrivenInteractiveTransition *interactiveTransition;
@end

@implementation NCBaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    [self saveCurrentUserInterfaceStyle];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    [self saveCurrentUserInterfaceStyle];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)saveCurrentUserInterfaceStyle {
    if (@available(iOS 13.0, *)) {
        [[NSUserDefaults standardUserDefaults] setObject:@(UITraitCollection.currentTraitCollection.userInterfaceStyle)
                                                  forKey:@"NCCurrentUserInterfaceStyle"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

@end
