//
//  NCProfileGenderCellViewModel.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseCellViewModel.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, NCChatUIUserGender) {
    NCChatUIUserGenderUnknown = 0,
    NCChatUIUserGenderMale = 1,
    NCChatUIUserGenderFemale = 2
};

@interface NCProfileGenderCellViewModel : NCBaseCellViewModel

@property (nonatomic, assign) NCChatUIUserGender gender;

@property (nonatomic, assign) BOOL isSelect;

+ (instancetype)cellViewModel:(NCChatUIUserGender)gender;

- (void)reloadData;

@end

NS_ASSUME_NONNULL_END
