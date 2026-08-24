//
//  NCSelectFilesTableViewCell.h
//  NCChatUIExtension
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseImageView.h"
#import "NCBaseLabel.h"
#import "NCBaseTableViewCell.h"
#import <UIKit/UIKit.h>
@interface NCSelectFilesTableViewCell : NCBaseTableViewCell

@property (nonatomic, strong) NCBaseImageView *selectedImageView;

@property (nonatomic, strong) NCBaseImageView *fileIconImageView;

@property (nonatomic, strong) NCBaseLabel *fileNameLabel;

@end
