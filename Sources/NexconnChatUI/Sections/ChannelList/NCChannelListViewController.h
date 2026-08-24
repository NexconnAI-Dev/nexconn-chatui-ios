//
//  NCChannelListViewController.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseTableView.h"
#import "NCBaseViewController.h"
#import "NCChannelListBaseCell.h"
#import "NCChannelModel.h"
#import "NCChatUIThemeDefine.h"
#import <UIKit/UIKit.h>
@class NCNetworkIndicatorView;

NS_ASSUME_NONNULL_BEGIN

/// The channel list view controller.
@interface NCChannelListViewController
    : NCBaseViewController <UITableViewDataSource, UITableViewDelegate>

#pragma mark - Initialization

/// Initializes the channel list with the specified channel types.
///
/// @param displayConversationTypeArray An array of `NCChannelType` values wrapped in `NSNumber`.
/// @return A new channel list instance.
- (instancetype)initWithDisplayConversationTypes:(NSArray *)displayConversationTypeArray;

#pragma mark - Displayed Channel Types

/// The channel types displayed in the list.
///
/// Elements are `NCChannelType` values wrapped in `NSNumber`.
@property (nonatomic, strong) NSArray *displayConversationTypeArray;

/// Sets the channel types displayed in the list.
///
/// @param channelTypeArray An array of `NCChannelType` values wrapped in `NSNumber`.
- (void)setDisplayConversationTypes:(NSArray *)channelTypeArray;

#pragma mark - Pinned Channel Sort Priority

/// Whether pinned channels are sorted first. Defaults to `YES`.
///
/// When enabled, pinned channels are returned before unpinned channels.
/// When disabled, all channels are sorted by timestamp only.
@property (nonatomic, assign) BOOL topPriority;

#pragma mark - List Properties

/// The data source backing the channel list.
///
/// Elements are `NCChannelModel` objects.
///
/// @warning Not thread-safe. Access this property on the main thread only.
@property (nonatomic, strong) NSMutableArray *conversationListDataSource;

/// The table view used to display the channel list.
@property (nonatomic, strong) NCBaseTableView *conversationListTableView;

#pragma mark - Network Status Indicator

/// Whether to show a network-unavailable banner in the table view header when disconnected.
/// Defaults to `YES`.
@property (nonatomic, assign) BOOL isShowNetworkIndicatorView;

/// Whether to show a "connecting" indicator in the navigation bar during automatic reconnection.
/// Defaults to `NO`.
@property (nonatomic, assign) BOOL showConnectingStatusOnNavigatorBar;

#pragma mark - Appearance

/// The view displayed when the channel list is empty.
@property (nonatomic, strong) UIView *emptyConversationView;

/// The background color for normal cells.
@property (nonatomic, strong) UIColor *cellBackgroundColor;

/// The background color for pinned channel cells.
@property (nonatomic, strong) UIColor *topCellBackgroundColor;

/// The view that indicates network unavailability.
@property (nonatomic, strong) NCNetworkIndicatorView *networkIndicatorView;

/// Sets the avatar shape displayed in the channel list (applies globally).
///
/// Defaults to `NC_USER_AVATAR_RECTANGLE`. Set before `viewDidLoad`.
///
/// @param avatarStyle The avatar shape.
- (void)setConversationAvatarStyle:(NCUserAvatarStyle)avatarStyle;

/// Sets the avatar size displayed in the channel list (applies globally). Height must be >= 36.
///
/// Defaults to 46x46. Set before `viewDidLoad`.
///
/// @param size The avatar size.
- (void)setConversationPortraitSize:(CGSize)size;

#pragma mark - UI Callbacks

#pragma mark Tap Callbacks

/// Called when a channel list cell is tapped.
///
/// Override this method to navigate to the corresponding channel page.
///
/// @param conversationModelType The model type of the tapped channel.
/// @param model The data model of the tapped channel.
/// @param indexPath The index path of the cell.
- (void)onSelectedTableRow:(NCChannelModelType)conversationModelType
         conversationModel:(NCChannelModel *)model
               atIndexPath:(NSIndexPath *)indexPath;

/// Called when a cell's avatar is tapped.
///
/// @param model The data model of the cell.
- (void)didTapCellPortrait:(NCChannelModel *)model;

/// Called when a cell's avatar is long-pressed.
///
/// @param model The data model of the cell.
- (void)didLongPressCellPortrait:(NCChannelModel *)model;

#pragma mark Deletion Callback

/// Called when a channel cell is deleted.
///
/// @param model The data model of the deleted cell.
- (void)didDeleteConversationCell:(NCChannelModel *)model;

#pragma mark - Cell Display Callbacks

/// Called before incremental data is loaded into the list.
///
/// Override to modify, add, or remove items before display. The list renders the returned array.
///
/// @param dataSource The incremental data source (elements are `NCChannelModel` objects).
/// @return The modified data source.
- (NSMutableArray<NCChannelModel *> *)willReloadTableData:
    (NSMutableArray<NCChannelModel *> *)dataSource;

/// Called just before a cell is displayed.
///
/// Override to customize cell appearance.
///
/// @param cell The cell about to be displayed.
/// @param indexPath The index path of the cell.
- (void)willDisplayConversationTableCell:(NCChannelListBaseCell *)cell
                             atIndexPath:(NSIndexPath *)indexPath;

/// Called when a cell's state (e.g., read status) changes.
///
/// Override to update the cell display.
///
/// @param indexPath The index path of the cell.
- (void)updateCellAtIndexPath:(NSIndexPath *)indexPath;

#pragma mark - Custom Channel List Cell

/// Returns a custom cell for the channel list.
///
/// @param tableView The table view.
/// @param indexPath The index path.
/// @return A custom cell to display.
- (NCChannelListBaseCell *)ncChannelListTableView:(UITableView *)tableView
                            cellForRowAtIndexPath:(NSIndexPath *)indexPath;

/// Returns the height for a custom channel list cell.
///
/// @param tableView The table view.
/// @param indexPath The index path.
/// @return The cell height.
- (CGFloat)ncChannelListTableView:(UITableView *)tableView
          heightForRowAtIndexPath:(NSIndexPath *)indexPath;

/// Called when a custom channel cell is deleted via swipe.
///
/// Override to customize delete behavior. To confirm deletion, use the channel API to remove
/// the channel or its messages, and update `conversationListDataSource` and
/// `conversationListTableView`.
///
/// @param tableView The table view.
/// @param editingStyle The editing style (defaults to `UITableViewCellEditingStyleDelete`).
/// @param indexPath The index path.
- (void)ncChannelListTableView:(UITableView *)tableView
            commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
             forRowAtIndexPath:(NSIndexPath *)indexPath;

#pragma mark - Refresh

/// Reloads the channel list from the database.
///
/// @warning This operation is expensive. Use sparingly.
- (void)refreshConversationTableViewIfNeeded;

/// Inserts or updates a channel in the list and refreshes the UI.
///
/// If the model already exists in the data source, it is updated; otherwise it is inserted.
///
/// @param conversationModel The channel data model.
- (void)refreshConversationTableViewWithConversationModel:(NCChannelModel *)conversationModel;

/// Whether to keep displaying the channel list after the user logs out. Defaults to `YES`.
///
/// @warning Deprecated. The SDK closes the message database on disconnect for security reasons.
@property (nonatomic, assign) BOOL showConversationListWhileLogOut __deprecated_msg("");

#pragma mark - Other

/// Called when the unread message count is about to be updated.
///
/// This method is called on a background thread. Dispatch to the main thread for UI updates.
- (void)notifyUpdateUnreadMessageCount;

@end
NS_ASSUME_NONNULL_END
