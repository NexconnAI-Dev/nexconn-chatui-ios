//
//  NCSightFileBrowserCell.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCPaddingTableViewCell.h"

extern NSString  * const NCSightFileBrowserCellIdentifier;
NS_ASSUME_NONNULL_BEGIN

@interface NCSightFileBrowserCell : NCPaddingTableViewCell
@property (nonatomic, strong) UIImageView *imageIcon;
@property (nonatomic, strong) UILabel *labelTitle;
@property (nonatomic, strong) UILabel *labelTime;
@property (nonatomic, strong) UILabel *labelSubtitle;
@property (nonatomic, strong) UIStackView *rightStackView;
@property (nonatomic, strong) UIStackView *topStackView;
@property (nonatomic, strong) UIStackView *contentStackView;

@end

NS_ASSUME_NONNULL_END
