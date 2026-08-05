//
//  NCNavigationItemsViewModel.m
//  NexconnUserProfile
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCNavigationItemsViewModel.h"
#import "NCUserSearchViewController.h"
#import "NCChatUICommonDefine.h"

@interface NCNavigationItemsViewModel()
@end

@implementation NCNavigationItemsViewModel

- (instancetype)initWithResponder:(UIViewController *)responder
{
    self = [super init];
    if (self) {
        self.responder = responder;
    }
    return self;
}

- (NSArray *)rightNavigationBarItems {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn addTarget:self
            action:@selector(rightBarItemClicked:)
  forControlEvents:UIControlEventTouchUpInside];
    UIImage *image = NCDynamicImage(@"friend_list_add_new_img");
    [btn setImage:image forState:UIControlStateNormal];
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:btn];
    return @[item];
}

- (void)rightBarItemClicked:(id)sender {
    if (self.responder) {
        NCUserSearchViewModel *vm = [[NCUserSearchViewModel alloc] init];
        NCUserSearchViewController *vc = [[NCUserSearchViewController alloc] initWithViewModel:vm];
        [self.responder.navigationController pushViewController:vc animated:YES];
    }
}

@end
