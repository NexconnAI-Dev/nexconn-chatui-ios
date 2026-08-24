//
//  NCSightFileBrowserViewController.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseTableViewController.h"
#import <UIKit/UIKit.h>

@class NCMessageModel;
@interface NCSightFileBrowserViewController : NCBaseTableViewController

- (instancetype)initWithMessageModel:(NCMessageModel *)model;

@end
