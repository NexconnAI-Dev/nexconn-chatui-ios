//
//  NCFileSelectorViewController.h
//  NCChatUIExtension
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NCBaseTableViewController.h"

@protocol NCFileSelectorViewControllerDelegate <NSObject>
- (void)fileDidSelect:(NSArray *)filePathList;
@optional
- (BOOL)canBeSelectedAtPath:(NSString *)path;
@end

@interface NCFileSelectorViewController : NCBaseTableViewController
@property (nonatomic, weak) id<NCFileSelectorViewControllerDelegate> delegate;
@property (nonatomic, assign) BOOL isSubDirectory;

- (instancetype)initWithRootPath:(NSString *)rootPath;
@end
