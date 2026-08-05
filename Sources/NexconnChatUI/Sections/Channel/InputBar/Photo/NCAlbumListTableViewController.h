//
//  NCAlbumListTableViewController.h
//  NCChatUIExtension
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NCBaseTableViewController.h"

@protocol NCAlbumListViewControllerDelegate;
@interface NCAlbumListTableViewController : NCBaseTableViewController
@property (nonatomic, strong) NSArray *libraryList;
@property (nonatomic, weak) id<NCAlbumListViewControllerDelegate> delegate;
@end

@protocol NCAlbumListViewControllerDelegate <NSObject>

- (void)albumListViewController:(NCAlbumListTableViewController *)albumListViewController
                 selectedImages:(NSArray *)selectedImages
                isSendFullImage:(BOOL)enable;

@end
