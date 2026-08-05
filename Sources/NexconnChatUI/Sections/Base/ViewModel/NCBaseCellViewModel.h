//
//  NCBaseCellViewModel.h
//  Pods-NCUserProfile_Example
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NCCellViewModelProtocol.h"

extern NSInteger const NCUserManagementCellHeight;

NS_ASSUME_NONNULL_BEGIN

@interface NCBaseCellViewModel : NSObject<NCCellViewModelProtocol>
@property (nonatomic, assign) BOOL hideSeparatorLine;
@end

NS_ASSUME_NONNULL_END
