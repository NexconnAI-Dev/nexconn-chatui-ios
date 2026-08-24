//
//  NCChannelViewController.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseButton.h"
#import "NCBaseCollectionView.h"
#import "NCBaseImageView.h"
#import "NCBaseViewController.h"
#import "NCChannelModel.h"
#import "NCChatSessionInputBarControl.h"
#import "NCChatUIUserInfo.h"
#import "NCEditInputBarControl.h"
#import "NCEmojiBoardView.h"
#import "NCFullScreenEditView.h"
#import "NCMessageBaseCell.h"
#import "NCMessageModel.h"
#import "NCPluginBoardView.h"
#import "NCReferencingView.h"
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class NCMessage;
@class NCUploadMediaStatusListener;
@class NCBaseChannel;
@class NCChannelIdentifier;

/// Message loading type.
typedef enum : NSUInteger {
    /// Load messages regardless of remote sync success or failure.
    NCChannelLoadMessageTypeAlways,

    /// Ask whether to load local messages when remote sync fails.
    NCChannelLoadMessageTypeAsk,

    /// Load messages only after remote sync succeeds.
    NCChannelLoadMessageTypeOnlySuccess,
} NCChannelLoadMessageType;

/// Channel page view controller.
@interface NCChannelViewController
    : NCBaseViewController <UICollectionViewDelegate, UICollectionViewDataSource,
                            UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate,
                            UIScrollViewDelegate>

#pragma mark - Initialization

/// Initialize the channel page.
/// @param channelType Channel type.
/// @param channelId         Target channel ID.
/// @return The channel page instance.
- (id)initWithChannelType:(NCChannelType)channelType channelId:(NSString *)channelId;

#pragma mark - Channel Properties

/// Channel type of the current page.
@property (nonatomic, assign) NCChannelType channelType;

/// Target channel ID.
@property (nonatomic, copy) NSString *channelId;

/// Target sub-channel ID.
@property (nonatomic, copy, nullable) NSString *subChannelId;

/// Current channel context for this page.
/// This value is created from the latest channelType/channelId/subChannelId on each access.
/// It is intended for subclasses and page collaborators to reuse the page's current channel
/// context. The returned object may be nil when the current page context does not contain enough
/// information to build a channel. The underlying context object is not cached to avoid stale state
/// after page context changes.
@property (nonatomic, strong, nullable, readonly) NCBaseChannel *currentChannel;

/// Current channel identifier context for this page.
/// This value is created from the latest channelType/channelId/subChannelId on each access.
/// It is intended for subclasses and page collaborators to reuse the page's current channel
/// context. The returned object may be nil when the current page context does not contain enough
/// information to build a channel identifier. The underlying context object is not cached to avoid
/// stale state after page context changes.
@property (nonatomic, strong, nullable, readonly) NCChannelIdentifier *currentChannelIdentifier;

#pragma mark - Channel Page Properties

/// Sent time of the message to locate when entering the page.
/// Used for scenarios like tapping a search result to jump to a specific message.
@property (nonatomic, assign) long long locatedMessageSentTime;

/// Data source for message cell data models on the channel page.
/// Elements are NCMessageModel objects.
/// @warning Not thread-safe; operate on this property on the main thread only.
@property (nonatomic, strong) NSMutableArray *channelDataRepository;

/// CollectionView for the channel page.
@property (nonatomic, strong) NCBaseCollectionView *messageCollectionView;

#pragma mark Unread Count in Navigation Back Button

/// Array of channel types to count unread messages for (displayed in the navigation bar back
/// button). Specifies which channel types contribute to the unread count shown in the back button.
/// (OC should wrap NCChannelType in NSNumber to build the Array)
@property (nonatomic, strong, nullable) NSArray *displayChannelTypeArray;

/// Update the unread message count displayed in the navigation bar back button.
/// If you override this method, call super.
- (void)notifyUpdateUnreadMessageCount;

#pragma mark Top-Right Unread Message Count

/// Whether to show an unread message indicator in the top-right corner when unread count
/// exceeds 10. Default is NO. When enabled, if unread messages exceed 10, an indicator appears in
/// the top-right corner after entering the channel.
@property (nonatomic, assign) BOOL enableUnreadMessageIcon;

#pragma mark Top-Right Unread Mentioned Count

/// Whether to show unread mentioned (@) message count in the top-right corner.
///
/// Default is YES.
/// When a channel receives many messages (more than one screen), an indicator appears in the
/// top-right corner showing the unread mentioned count. Tapping it scrolls to the earliest unread
/// mentioned message and decrements the count. Subsequent taps reduce the count based on visible
/// mentioned messages.
@property (nonatomic, assign) BOOL enableUnreadMentionedIcon;

/// Unread message count for this channel.
@property (nonatomic, assign) NSInteger unReadMessage;

/// Label for the top-right unread message count.
/// Displayed when unReadMessage > 10.
@property (nonatomic, strong) UILabel *unReadMessageLabel;

/// Button for the top-right unread message count.
@property (nonatomic, strong) NCBaseButton *unReadButton;

/// Label for the top-right mentioned (@) message count.
@property (nonatomic, strong) UILabel *unReadMentionedLabel;

@property (nonatomic, strong) NCBaseImageView *unreadRightBottomIcon;

/// Button for the top-right mentioned (@) message count.
@property (nonatomic, strong) NCBaseButton *unReadMentionedButton;

#pragma mark Bottom-Right Unread Message Count

/// Whether to show a new message indicator in the bottom-right corner when new messages arrive
/// below the current view.
///
/// Default is NO.
/// When enabled, if the user is scrolled to the bottom, new messages auto-update;
/// if the user is viewing earlier messages, a new message indicator appears in the bottom-right
/// corner. Tapping it scrolls to the bottom.
@property (nonatomic, assign) BOOL enableNewComingMessageIcon;

/// Label for the bottom-right unread message count.
@property (nonatomic, strong) UILabel *unReadNewMessageLabel;

#pragma mark - Input Bar

/// Input bar control at the bottom of the channel page.
@property (nonatomic, strong) NCChatSessionInputBarControl *chatSessionInputBarControl;

/// Normal input bar control for message editing.
@property (nonatomic, strong) NCEditInputBarControl *editInputBarControl;

/// Full-screen edit view for message editing.
@property (nonatomic, strong, nullable) NCFullScreenEditView *fullScreenEditView;

/// Whether to disable system emoji. Set this right after creating NCChannelViewController.
@property (nonatomic, assign) BOOL disableSystemEmoji;

/// Default input mode for the input bar.
/// Default is NCChatSessionInputBarInputText (text input mode). Set this after [super
/// viewWillAppear:animated].
@property (nonatomic) NCChatSessionInputBarInputType defaultInputType;

/// Extension display area for the channel page.
///
/// You can customize views displayed on the channel page here.
@property (nonatomic, strong) UIView *extensionView;

/// Reference content view above the input bar.
@property (nonatomic, strong) NCReferencingView *referencingView;

/// Placeholder label for the input bar. Default is nil (no placeholder).
///
/// Set in viewDidLoad:
/// self.placeholderLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, 180, 20)];
/// self.placeholderLabel.text = @"Test Placeholder";
/// self.placeholderLabel.textColor = [UIColor grayColor];
@property (nonatomic, strong) UILabel *placeholderLabel;

/// Callback when the input text view content changes.
/// @param inputTextView The text input view.
/// @param range         The range of the current operation.
/// @param text          The inserted text.
- (void)inputTextView:(UITextView *)inputTextView
    shouldChangeTextInRange:(NSRange)range
            replacementText:(NSString *)text;

/// Callback when the input bar size (height) changes.
/// @param chatInputBar The input bar control.
/// @param frame        The final frame the input bar should display.
/// Call super when overriding this method.
- (void)chatInputBar:(NCChatSessionInputBarControl *)chatInputBar shouldChangeFrame:(CGRect)frame;

/// Callback when a plugin board item is tapped.
/// @param pluginBoardView The plugin board view.
/// @param tag             The unique tag of the tapped plugin item.
- (void)pluginBoardView:(NCPluginBoardView *)pluginBoardView clickedItemWithTag:(NSInteger)tag;

#pragma mark - Display Settings

/// Whether to display the sender name for received messages.
///
/// Default is YES.
/// You can customize this for different scenarios like group chat vs. direct chat.
@property (nonatomic) BOOL displayUserNameInCell;

/// Number of messages to fetch from remote on pull-to-refresh after entering the channel page.
///
/// Default is 10. Value must be in range (1, 100].
/// Set this before viewDidLoad.
@property (nonatomic, assign) int defaultMessageCount;

/// Number of messages to fetch from remote on pull-to-refresh after entering the channel page.
/// Default is 10. Value must be in range (1, 100].
/// Set this before viewDidLoad.
@property (nonatomic, assign) int defaultRemoteHistoryMessageCount
    __attribute__((deprecated("Deprecated. Use defaultMessageCount instead.")));

/// Number of messages to load from local database on pull-to-refresh. Default is 10.
/// Set this before viewDidLoad.
/// From version 5.2.4 and later, use defaultRemoteHistoryMessageCount for message count.
@property (nonatomic, assign) int defaultLocalHistoryMessageCount
    __attribute__((deprecated("Deprecated. Use defaultMessageCount instead.")));

/// Message loading type.
///
/// Messages are first loaded from local storage; missing messages are synced from the server.
/// When server sync fails, a non-zero errorCode is returned along with locally available messages.
/// This property controls the loading behavior when server sync fails.
@property (nonatomic, assign) NCChannelLoadMessageType loadMessageType;

/// All currently selected messages.
/// Only has valid values when allowsMessageCellSelection is YES.
@property (nonatomic, strong, readonly) NSArray<NCMessageModel *> *selectedMessages;

/// Whether message cells are in multi-select editing mode. If YES, cells show multi-select style;
/// if NO, the page returns to its initial state.
@property (nonatomic, assign) BOOL allowsMessageCellSelection;

/// Toolbar view at the bottom of the page during multi-select editing mode.
@property (nonatomic, strong) UIToolbar *messageSelectionToolbar;

/// Show an error alert and leave the current channel page.
/// @param errorInfo The error message.
- (void)alertErrorAndLeft:(NSString *)errorInfo;

#pragma mark - UI Actions

/// Scroll to the bottom of the list.
/// @param animated Whether to animate.
- (void)scrollToBottomAnimated:(BOOL)animated;

/// Handle the back button tap.
/// @param sender The event sender.
/// Includes cleanup work for leaving the channel page.
/// Call super when overriding this method.
- (void)leftBarButtonItemPressed:(id)sender;

#pragma mark - Message Operations

#pragma mark Send Message

/// Send a message.
/// @param messageContent The message content.
/// @param pushContent    Remote push content shown when the receiver is offline.
/// When the receiver is offline and push is enabled, a remote push notification is sent.
/// The push contains pushContent (for display) and pushData (non-displayed data).
/// For built-in message types, if pushContent is nil, the default push format is used.
/// For custom message types, you must set pushContent to define push content; otherwise no push is
/// sent.
- (void)sendMessage:(NCMessageContent *)messageContent pushContent:(nullable NSString *)pushContent;

/// Send a media message (upload image or file to the app-specified server).
/// @param messageContent The message content.
/// @param pushContent    Remote push content shown when the receiver is offline.
/// @param appUpload      Whether to upload to the app-specified server.
/// Set appUpload to YES and implement the uploadMedia:uploadListener: callback to upload media to
/// your own server. In the callback, upload the media and notify the SDK of progress via the
/// uploadListener.
- (void)sendMediaMessage:(NCMediaMessageContent *)messageContent
             pushContent:(nullable NSString *)pushContent
               appUpload:(BOOL)appUpload;

/// Callback for uploading media to the app-specified server.
/// @param message        The media message entity (image or file message).
/// @param uploadListener The SDK upload progress listener.
/// Required when sending media via sendMediaMessage:pushContent:appUpload:.
- (void)uploadMedia:(NCMessage *)message
     uploadListener:(NCUploadMediaStatusListener *)uploadListener;

/// Cancel uploading a media message.
/// @param model        The media message model (file message).
/// When sending media via sendMediaMessage:pushContent:appUpload: (uploading to app server),
/// override this method to cancel your upload and call the uploadListener's cancelBlock to notify
/// the SDK.
- (void)cancelUploadMedia:(NCMessageModel *)model;

/// Resend a message.
/// @param messageContent The message content.
/// When a message fails to send and the user taps the error indicator, the original local message
/// is deleted and this method is called to resend the content.
- (void)resendMessage:(NCMessageContent *)messageContent
    __deprecated_msg("Use resendMessageWithModel instead");

/// Resend a message.
/// @param model The message model.
/// Call super when overriding.
- (void)resendMessageWithModel:(NCMessageModel *)model;

/// Refresh the message status on the channel page after a successful send.
/// @param message The successfully sent message.
/// Call super when overriding.
- (void)updateForMessageSendSuccess:(NCMessage *)message;

#pragma mark Insert Message

/// Insert and display a message on the channel page.
/// @param message The message entity.
/// This method inserts the corresponding content model into the data source and updates the UI.
/// The message is only inserted into the UI and is not stored in the database.
/// If the user leaves and re-enters the channel page, this message will not be displayed.
- (void)appendAndDisplayMessage:(NCMessage *)message;

#pragma mark Delete Message

/// YES: long-press delete removes both local and remote messages.
/// NO: long-press delete only removes local messages.
/// Default changed to YES in version 5.6.3.
@property (nonatomic, assign) BOOL needDeleteRemoteMessage;

/// Delete a message and update the UI.
/// @param model The message cell data model.
/// From v5.2.3 onwards, behavior follows the needDeleteRemoteMessage setting.
/// Default is NO (local only); set to YES to also delete remote messages.
- (void)deleteMessage:(NCMessageModel *)model;

#pragma mark - Message Operation Callbacks

/// Callback before a message is sent.
/// @param messageContent The message content.
/// @return The modified message content.
/// Called when a message is about to be sent. You can filter or modify the content.
- (nullable NCMessageContent *)willSendMessage:(NCMessageContent *)messageContent;

/// Callback after a message is sent.
/// @param status          Send status. 0 = success, non-0 = failure.
/// @param messageContent   The message content.
- (void)didSendMessage:(NSInteger)status
               content:(NCMessageContent *)messageContent
    __deprecated_msg("Use - (void)didSendMessageModel:(NSInteger)status model:(NCMessageModel "
                     "*)messageModel instead");

/// Callback after a message is sent.
/// @param status          Send status. 0 = success, non-0 = failure.
/// @param messageModel   The message model.
- (void)didSendMessageModel:(NSInteger)status model:(NCMessageModel *)messageModel;

/// Callback when a message send is cancelled.
/// @param messageContent   The message content.
- (void)didCancelMessage:(NCMessageContent *)messageContent;

/// Callback before a message is inserted into the data source for display.
/// @param message The message entity.
/// @return The modified message entity.
/// Called when a message is about to be inserted into the data source. You can filter or modify it.
- (NCMessage *)willAppendAndDisplayMessage:(NCMessage *)message;

/// Callback before a message cell is displayed.
/// @param cell        The message cell.
/// @param indexPath   The index path of the cell's data model in the data source.
- (void)willDisplayMessageCell:(NCMessageBaseCell *)cell atIndexPath:(NSIndexPath *)indexPath;

/// Callback when a message is about to be selected in multi-select mode.
/// @param model The message cell data model.
/// @return Whether to proceed with the selection. Default is YES.
- (BOOL)willSelectMessage:(NCMessageModel *)model;

/// Callback when a message is about to be deselected in multi-select mode.
/// @param model The message cell data model.
/// @return Whether to proceed with the deselection. Default is YES.
- (BOOL)willCancelSelectMessage:(NCMessageModel *)model;

/// Callback when there are no more messages to fetch on pull-to-refresh.
- (void)noMoreMessageToFetch;

#pragma mark - Custom Messages

/// Entry point for registering custom messages.
/// If you have custom messages, call
/// - (void)registerClass:(Class)cellClass forMessageType:(NSString *)messageType
/// inside this method.
- (void)registerCustomCellsAndMessages;

/// Register a custom message cell.
/// @param cellClass     The custom message cell class.
/// @param messageType   Message type identifier (objectName).
/// Override sizeForMessageModel:withCollectionViewWidth:referenceExtraHeight: in your cell to
/// calculate the cell height. Register custom message cells inside the
/// registerCustomCellsAndMessages method of your channel page subclass. Do not register in other
/// methods to avoid rendering timing issues. Prefer using NCMessageType constants or the
/// +messageType value from custom message classes to avoid hard-coded strings. For example: [self
/// registerClass:[NCTextMessageCell class] forMessageType:NCMessageType.text]; [self
/// registerClass:[MyCustomMessageCell class] forMessageType:[MyCustomMessage messageType]];
- (void)registerClass:(Class)cellClass forMessageType:(NSString *)messageType;

/// Callback for displaying an unregistered message cell.
/// @param collectionView  The current CollectionView.
/// @param indexPath       The index path of the cell's data model in the data source.
/// @return The cell to display for unregistered messages.
/// Set showUnkownMessage to YES before using this callback.
/// Use this to pre-define display for unrecognized messages in older versions (e.g., prompt to
/// upgrade).
- (NCMessageBaseCell *)ncUnknownChannelCollectionView:(UICollectionView *)collectionView
                               cellForItemAtIndexPath:(NSIndexPath *)indexPath;

/// Callback for the size of an unregistered message cell.
/// @param collectionView          The current CollectionView.
/// @param collectionViewLayout    The current CollectionView layout.
/// @param indexPath               The index path of the cell's data model in the data source.
/// @return The size for the unregistered message cell.
/// Set showUnkownMessage to YES before using this callback.
- (CGSize)ncUnknownChannelCollectionView:(UICollectionView *)collectionView
                                  layout:(UICollectionViewLayout *)collectionViewLayout
                  sizeForItemAtIndexPath:(NSIndexPath *)indexPath;

#pragma mark - Tap Event Callbacks

/// Callback when message content in a cell is tapped.
/// @param model The message cell data model.
/// The SDK has default handling for built-in messages (images, voice, location, etc.) such as
/// viewing and playback. Call super when overriding to preserve SDK default behavior.
- (void)didTapMessageCell:(NCMessageModel *)model;

/// Callback when message content in a cell is long-pressed.
/// @param model The message cell data model.
/// @param view  The view in the long-press area.
/// The SDK shows a context menu by default.
/// Call super when overriding to preserve SDK default behavior.
- (void)didLongTouchMessageCell:(NCMessageModel *)model inView:(UIView *)view;

/// Get the context menu items for long-pressing message content in a cell.
/// @param model The message cell data model.
/// The SDK displays the menu returned by this method.
/// Call super when overriding to preserve SDK default behavior.
- (NSArray<UIMenuItem *> *)getLongTouchMessageCellMenuList:(NCMessageModel *)model;

/// Callback when a URL in a message cell is tapped.
/// @param url   The tapped URL.
/// @param model The message cell data model.
- (void)didTapUrlInMessageCell:(NSString *)url model:(NCMessageModel *)model;

/// Callback when the referenced content preview in a quote message is tapped.
/// @param model The quote message cell data model.
- (void)didTapReferencedContentView:(NCMessageModel *)model;

/// Callback when a phone number in a message cell is tapped.
/// @param phoneNumber The tapped phone number.
/// @param model       The message cell data model.
- (void)didTapPhoneNumberInMessageCell:(NSString *)phoneNumber model:(NCMessageModel *)model;

/// Callback when a cell avatar is tapped.
/// @param userId  The user ID of the tapped avatar.
- (void)didTapCellPortrait:(NSString *)userId;

/// Callback when a cell avatar is long-pressed.
/// @param userId  The user ID of the avatar.
- (void)didLongPressCellPortrait:(NSString *)userId;

- (void)didTapReceiptStatusView:(NCMessageModel *)model;

#pragma mark - Voice, Image, Location, File Message Display & Operations

/// Callback when voice recording starts.
- (void)onBeginRecordEvent;

/// Callback when voice recording ends.
- (void)onEndRecordEvent;

/// Callback when voice recording is cancelled (onEndRecordEvent will not be called).
- (void)onCancelRecordEvent;

/// Whether to enable continuous playback of unread voice messages.
/// If YES, tapping a voice message plays all subsequent unplayed voice messages sequentially.
@property (nonatomic, assign) BOOL enableContinuousReadUnreadVoice;

/// View the image in an image message.
/// @param model   The message cell data model.
/// The SDK calls NCImageSlideController by default to download and display the image.
- (void)presentImagePreviewController:(NCMessageModel *)model;

/// Whether to save newly captured photos to local storage after sending.
/// If YES, implement saveNewPhotoToLocalSystemAfterSendingSuccess: to handle saving.
@property (nonatomic, assign) BOOL enableSaveNewPhotoToLocalSystem;

/// Callback to save a newly captured photo to local storage after sending.
/// @param newImage    The image.
/// You can save the image or perform other operations as needed.
- (void)saveNewPhotoToLocalSystemAfterSendingSuccess:(UIImage *)newImage;

/// View the file in a file message.
/// @param model   The message cell data model.
- (void)presentFilePreviewViewController:(NCMessageModel *)model;

/// Callback when "@" is typed in the input bar, about to show the user picker.
/// @param selectedBlock Callback after a user is selected.
/// @param cancelBlock   Callback when selection is cancelled.
/// Override this method to present a custom user picker. Call selectedBlock with the selected
/// UserInfo when done.
- (void)showChooseUserViewController:(void (^)(NCChatUIUserInfo *selectedUserInfo))selectedBlock
                              cancel:(void (^)(void))cancelBlock;

/// Callback for message forwarding.
/// @param index            0 = forward individually, 1 = forward as combined message.
/// @param completedBlock   Return the list of channels to forward to.
/// Override this to present a custom channel picker. Call completedBlock with the selected channels
/// when done.
- (void)forwardMessage:(NSInteger)index
             completed:(void (^)(NSArray<NCBaseChannel *> *conversationList))completedBlock;

- (void)addMentionedUserToCurrentInput:(NCChatUIUserInfo *)userInfo;

@end
NS_ASSUME_NONNULL_END
