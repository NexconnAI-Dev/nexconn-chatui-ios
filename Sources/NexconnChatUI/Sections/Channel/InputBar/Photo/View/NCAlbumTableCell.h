//
//  NCAlbumTableCell.h
//  NCChatUIExtension
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCAlbumModel.h"
#import "NCAssetHelper.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "NCBaseTableViewCell.h"
@interface NCAlbumTableCell : NCBaseTableViewCell

- (void)configCellWithItem:(NCAlbumModel *)model;

@end
