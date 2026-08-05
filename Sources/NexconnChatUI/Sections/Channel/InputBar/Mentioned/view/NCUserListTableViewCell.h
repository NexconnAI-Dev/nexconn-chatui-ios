//
//  NCUserListTableViewCell.h
//  NCChatUIExtension
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NCBaseTableViewCell.h"
#import "NCBaseImageView.h"
#import "NCBaseLabel.h"
@interface NCUserListTableViewCell : NCBaseTableViewCell
@property (nonatomic, strong) NCBaseImageView *headImageView; //Avatar
@property (nonatomic, strong) NCBaseLabel *nameLabel;         //Name
@end
