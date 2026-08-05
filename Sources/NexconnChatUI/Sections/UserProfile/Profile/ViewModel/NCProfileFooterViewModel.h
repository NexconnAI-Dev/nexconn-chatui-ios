//
//  NCProfileFooterViewModel.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NCBaseViewModel.h"
#import "NCButtonItem.h"
@class NCProfileFooterViewModel;
NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, NCProfileFooterViewType) {
    NCProfileFooterViewTypeAddFriend,
    NCProfileFooterViewTypeChat,
    NCProfileFooterViewTypeGroupOwner,
    NCProfileFooterViewTypeGroupMember
};

@protocol NCProfileFooterViewModelDelegate <NSObject>

@optional

/// Called before loading the data source
///
/// @param viewModel viewModel
/// @param models The current data source
/// @return The data source processed by the app, or `nil` to use the default
///
- (nullable NSArray <NCButtonItem *> *)profileFooterViewModel:(NCProfileFooterViewModel *)viewModel
                                     willLoadButtonItemsViewModels:(NSArray <NCButtonItem *> *)models;

@end

/// Profile footer view model
@interface NCProfileFooterViewModel : NCBaseViewModel

@property (nonatomic, weak, readonly) UIViewController *responder;

/// Delegate
@property (nonatomic, weak) id<NCProfileFooterViewModelDelegate> delegate;

/// footer type
@property (nonatomic, assign, readonly) NCProfileFooterViewType type;

/// Target identifier
@property (nonatomic, copy, readonly) NSString *channelId;

/// Whether to verify friendship
@property (nonatomic, assign) BOOL verifyFriend;

/// Creates an `NCProfileFooterViewModel` instance
///
/// @param responder The current view controller
/// @param type footer type
/// @param channelId The target identifier
- (instancetype)initWithResponder:(UIViewController *)responder
                             type:(NCProfileFooterViewType)type
                         channelId:(NSString *)channelId;

/// Loads the view
///
/// @return view
- (UIView *)loadView;

@end

NS_ASSUME_NONNULL_END
