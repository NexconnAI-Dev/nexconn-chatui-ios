//
//  NCPhotoPickImageView.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCAssetModel.h"
#import "NCBaseImageView.h"
#import <UIKit/UIKit.h>
@interface NCPhotoPickImageView : NCBaseImageView
- (void)setPhotoModel:(NCAssetModel *)model;
@end
