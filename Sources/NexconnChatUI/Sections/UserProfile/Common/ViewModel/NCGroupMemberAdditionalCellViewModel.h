//
//  NCGroupMemberAdditionalCellViewModel.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseCellViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface NCGroupMemberAdditionalCellViewModel : NCBaseCellViewModel
@property (nonatomic, copy) NSString *title;
@property (nonatomic, strong) UIImage *portrait;
- (instancetype)initWithTitle:(NSString *)title
                     portrait:(UIImage *)portrait;

+ (void)registerCellForTableView:(UITableView *)tableView;
@end

NS_ASSUME_NONNULL_END
