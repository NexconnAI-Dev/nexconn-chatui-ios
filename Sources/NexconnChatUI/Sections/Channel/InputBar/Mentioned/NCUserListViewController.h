//
//  NCUserListViewController.h
//  NCChatUIExtension
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCChatUIUserInfo.h"
#import <UIKit/UIKit.h>
#import "NCBaseViewController.h"

@protocol NCSelectingUserDataSource;

@interface NCUserListViewController : NCBaseViewController

@property (nonatomic, copy) void (^selectedBlock)(NCChatUIUserInfo *selectedUserInfo);
@property (nonatomic, copy) void (^cancelBlock)(void);

@property (nonatomic, strong) NSString *navigationTitle;

@property (nonatomic, weak) id<NCSelectingUserDataSource> dataSource;
@property (nonatomic, assign) int maxSelectedUserNumber;

@end

@protocol NCSelectingUserDataSource <NSObject>

- (void)getSelectingUserIdList:(void (^)(NSArray<NSString *> *userIdList))completion;

- (NCChatUIUserInfo *)getSelectingUserInfo:(NSString *)userId;

@end
