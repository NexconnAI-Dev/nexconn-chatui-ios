//
//  NCActionSheetView.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NCActionSheetView : UIView <UITableViewDelegate, UITableViewDataSource>

+ (void)showActionSheetView:(NSString *)title
                  cellArray:(NSArray *)cellArray
                cancelTitle:(NSString *)cancelTitle
              selectedBlock:(void (^)(NSInteger index))selectedBlock
                cancelBlock:(void (^)(void))cancelBlock;
@end
