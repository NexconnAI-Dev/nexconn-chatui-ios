//
//  NCBaseNavigationController.m
//  NCChatUIExtension
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseNavigationController.h"
#import "NCSemanticContext.h"
@interface NCBaseNavigationController ()

@end

@implementation NCBaseNavigationController
 
- (instancetype)initWithRootViewController:(UIViewController *)rootViewController {
    self = [super initWithRootViewController:rootViewController];
    if (self) {
        if ([NCSemanticContext isRTL]) {
            self.view.semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;
            self.navigationBar.semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;
        }else{
            self.view.semanticContentAttribute = UISemanticContentAttributeForceLeftToRight;
            self.navigationBar.semanticContentAttribute = UISemanticContentAttributeForceLeftToRight;
        }
    }
    return self;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view.
}
- (BOOL)shouldAutorotate {
    return NO;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
        [[NSUserDefaults standardUserDefaults] setObject:@(UITraitCollection.currentTraitCollection.userInterfaceStyle)
                                                  forKey:@"NCCurrentUserInterfaceStyle"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

@end
