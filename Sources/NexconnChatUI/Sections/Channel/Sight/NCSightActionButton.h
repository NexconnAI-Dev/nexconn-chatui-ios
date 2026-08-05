//
//  NCSightActionButton.h
//  NCChatUIExtension
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, NCSightActionState) {
    NCSightActionStateBegin = 0,
    NCSightActionStateMoving,
    NCSightActionStateWillCancel,
    NCSightActionStateDidCancel,
    NCSightActionStateEnd,
    NCSightActionStateClick
};

@interface NCSightActionButton : UIView

@property (nonatomic, assign) BOOL supportLongPress;

@property (nonatomic, assign) NSUInteger canRecordMaxDuration;

@property (nonatomic, copy) void (^action)(NCSightActionState state);

- (void)quit;

@end
