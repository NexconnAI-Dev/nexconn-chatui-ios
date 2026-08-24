//
//  NCUserListTableViewCell.h
//  NCChatUIExtension
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseImageView.h"
#import "NCBaseLabel.h"
#import "NCBaseTableViewCell.h"
#import <UIKit/UIKit.h>
@interface NCUserListTableViewCell : NCBaseTableViewCell
@property (nonatomic, strong) NCBaseImageView *headImageView; // Avatar
@property (nonatomic, strong) NCBaseLabel *nameLabel;         // Name
@end
