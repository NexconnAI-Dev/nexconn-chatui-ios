//
//  NCUserProfileTextCellViewModel.h
//  NexconnUserProfile
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCProfileCellViewModel.h"
#import <NexconnChatSDK/NexconnChatSDK.h>
#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN
/// Cell type
typedef NS_ENUM(NSUInteger, NCUProfileCellType) {
    /// Image cell
    NCUProfileCellTypeImage,
    /// Text cell
    NCUProfileCellTypeText,
};

/// Profile common cell view model
@interface NCProfileCommonCellViewModel : NCProfileCellViewModel

/// Title
@property (nonatomic, copy) NSString *title;

/// Detail text
@property (nonatomic, copy, nullable) NSString *detail;

/// Channel type
@property (nonatomic, assign) NCChannelType channelType;

/// Whether to hide the arrow indicator
@property (nonatomic, assign) BOOL hiddenArrow;

/// Cell type
@property (nonatomic, assign) NCUProfileCellType type;

/// Registers the cell
+ (void)registerCellForTableView:(UITableView *)tableView;

/// Creates an `NCProfileCommonCellViewModel` instance
///
/// @param type cell type
/// @param title The title
/// @param detail The detail text
- (instancetype)initWithCellType:(NCUProfileCellType)type
                           title:(NSString *)title
                          detail:(nullable NSString *)detail;
@end

NS_ASSUME_NONNULL_END
