//
//  NCChatSessionInputBarControl.h
//  NCExtensionKit
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseNavigationController.h"
#import "NCChatUIUserInfo.h"
#import "NCEmojiBoardView.h"
#import "NCInputContainerView.h"
#import "NCPluginBoardView.h"
#import "NCTextView.h"
#import <NexconnChatSDK/NexconnChatSDK.h>
#import <UIKit/UIKit.h>
#define NC_ChatSessionInputBar_Height 49.5f
/// Unique tags for input bar extension items.
#define INPUT_MENTIONED_SELECT_TAG 1000
#define PLUGIN_BOARD_ITEM_ALBUM_TAG 1001
#define PLUGIN_BOARD_ITEM_CAMERA_TAG 1002
#define PLUGIN_BOARD_ITEM_FILE_TAG 1006
#define PLUGIN_BOARD_ITEM_VOIP_TAG 1101
#define PLUGIN_BOARD_ITEM_VIDEO_VOIP_TAG 1102
#define PLUGIN_BOARD_ITEM_EVA_TAG 1103
#define PLUGIN_BOARD_ITEM_RED_PACKET_TAG 1104
#define PLUGIN_BOARD_ITEM_VOICE_INPUT_TAG 1105
#define PLUGIN_BOARD_ITEM_PTT_TAG 1106
#define PLUGIN_BOARD_ITEM_CARD_TAG 1107
#define PLUGIN_BOARD_ITEM_REMOTE_CONTROL_TAG 1108
#define PLUGIN_BOARD_ITEM_TRANSFER_TAG 1109

NS_ASSUME_NONNULL_BEGIN

/// Tap delegate for the input bar.
@protocol NCChatSessionInputBarControlDelegate;

/// Data source for the input bar.
@protocol NCChatSessionInputBarControlDataSource;

/// Delegate for picture editing.
@protocol NCPictureEditDelegate;

/// Input bar control.
@interface NCChatSessionInputBarControl : UIView

#pragma mark - Channel Properties

/// Current channel type.
@property (nonatomic, assign) NCChannelType channelType;

/// Current channel ID.
@property (nonatomic, strong, nullable) NSString *channelId;

#pragma mark - Delegates

/// Tap callback delegate for the input bar.
@property (weak, nonatomic, nullable) id<NCChatSessionInputBarControlDelegate> delegate;

/// Data source callback for the input bar.
@property (weak, nonatomic, nullable) id<NCChatSessionInputBarControlDataSource> dataSource;

/// Deprecated. Tapping the edit button calls onClickEditPicture on this delegate.
@property (weak, nonatomic, nullable) id<NCPictureEditDelegate> photoEditorDelegate
    __deprecated_msg("Deprecated");

#pragma mark - View Display

/// The channel page view that contains this input bar.
@property (weak, nonatomic, readonly, nullable) UIView *containerView;

/// Container view.
@property (strong, nonatomic) NCInputContainerView *inputContainerView;

/// Button to switch between voice and text input.
@property (strong, nonatomic) NCButton *switchButton;

/// Button for recording voice messages.
@property (strong, nonatomic) NCButton *recordButton;

/// Text input view.
@property (strong, nonatomic) NCTextView *inputTextView;

/// Emoji button.
@property (strong, nonatomic) NCButton *emojiButton;

/// Additional (extension) input button.
@property (strong, nonatomic) NCButton *additionalButton;

/// Plugin board view for extension features.
@property (nonatomic, strong) NCPluginBoardView *pluginBoardView;

/// Emoji board view.
@property (nonatomic, strong) NCEmojiBoardView *emojiBoardView;

/// SafeArea view below the input bar. nil if the device has no SafeArea.
@property (nonatomic, strong, readonly, nullable) UIView *safeAreaView;

/// Top border line of the input bar.
@property (nonatomic, strong, readonly) CALayer *topLineLayer;

/// Callback when the view is about to appear.
- (void)containerViewWillAppear;

/// Callback when the view has appeared.
- (void)containerViewDidAppear;

/// Callback when the view is about to disappear.
- (void)containerViewWillDisappear;

#pragma mark - Settings

/// Current input bar status.
@property (nonatomic, assign) KBottomBarStatus currentBottomBarStatus;

/// Maximum number of input lines.
///
/// Valid range: 1~6. Values outside this range are clamped to the boundary.
@property (nonatomic, assign) NSInteger maxInputLines;

/// Draft text.
@property (nonatomic, strong, nullable) NSString *draft;

/// Mentioned (@) info.
@property (nonatomic, strong, readonly, nullable) NCMentionedInfo *mentionedInfo;

/// List of mentioned user IDs currently in the input field, or nil when no user is mentioned.
@property (nonatomic, strong, readonly, nullable) NSArray<NSString *> *mentionedUserIdList;

/// Whether the mention (@) feature is enabled.
@property (nonatomic, assign) BOOL isMentionedEnabled;

#pragma mark - Initialization

/// Initialize the input bar.
///
/// @param frame            Display frame.
/// @param containerView    The channel page view.
/// @param controlType      Menu type.
/// @param controlStyle     Layout style.
/// @param defaultInputType Default input mode.
/// @return The input bar instance.
- (instancetype)initWithFrame:(CGRect)frame
            withContainerView:(UIView *)containerView
                  controlType:(NCChatSessionInputBarControlType)controlType
                 controlStyle:(NCChatSessionInputBarControlStyle)controlStyle
             defaultInputType:(NCChatSessionInputBarInputType)defaultInputType;

/// Set the input bar style.
///
/// @param type  Menu type.
/// @param style Layout style.
///
/// Set this after viewDidLoad of the channel page to change the input bar style.
- (void)setInputBarType:(NCChatSessionInputBarControlType)type
                  style:(NCChatSessionInputBarControlStyle)style;

/// Cancel voice recording.
- (void)cancelVoiceRecord;

/// End voice recording.
- (void)endVoiceRecord;

/// End voice-to-text transfer.
- (void)endVoiceTransfer;

/// Set the input bar status.
///
/// @param status          Input bar status.
/// @param animated        Whether to animate.
///
/// Set this after containerViewWillAppear (i.e., after the channel page's viewWillAppear).
- (void)updateStatus:(KBottomBarStatus)status animated:(BOOL)animated;

/// Reset to the default status.
- (void)resetToDefaultStatus;

- (void)clearInputData;

/// Called when the content area size changes.
///
/// Call this when the parent view's frame changes and this view's frame needs recalculation.
- (void)containerViewSizeChanged;

/// Called when the content area size changes (without animation).
///
/// Call this when the parent view's frame changes and this view's frame needs recalculation,
/// without animation.
- (void)containerViewSizeChangedNoAnnimation;

/// Set the default input type.
///
/// @param defaultInputType  The default input type.
- (void)setDefaultInputType:(NCChatSessionInputBarInputType)defaultInputType;

/// Add a mentioned user.
///
/// @param userInfo    The mentioned user info.
- (void)addMentionedUser:(NCChatUIUserInfo *)userInfo;

/// Open the system photo album to select images.
///
/// Selection results are returned via the delegate.
- (void)openSystemAlbum;

/// Open the system camera to capture photos.
///
/// Capture results are returned via the delegate.
- (void)openSystemCamera;

/// Open the file selector to choose files.
///
/// Selection results are returned via the delegate.
- (void)openFileSelector;

/// Trigger a plugin item event by tag.
///
/// @param functionTag The tag of the plugin item.
- (void)openDynamicFunction:(NSInteger)functionTag;

@end

/// Tap delegate for the input bar.
@protocol NCChatSessionInputBarControlDelegate <NSObject>

/// Present a view controller.
///
/// @param viewController The view controller to present.
/// @param functionTag    The function tag identifier.
- (void)presentViewController:(UIViewController *)viewController functionTag:(NSInteger)functionTag;

@optional

/// Callback when the input bar size (height) changes.
///
/// @param chatInputBar The input bar control.
/// @param frame        The final frame the input bar should display.
- (void)chatInputBar:(NCChatSessionInputBarControl *)chatInputBar shouldChangeFrame:(CGRect)frame;

/// Callback when the keyboard Return button is tapped.
///
/// @param inputTextView The text input view.
- (void)inputTextViewDidTouchSendKey:(UITextView *)inputTextView;

/// Callback when the input text view content changes.
///
/// @param inputTextView The text input view.
/// @param range         The range of the current operation.
/// @param text          The inserted text.
- (void)inputTextView:(UITextView *)inputTextView
    shouldChangeTextInRange:(NSRange)range
            replacementText:(NSString *)text;

/// Callback after the input text view content has changed.
///
/// @param inputTextView The text input view.
- (void)inputTextViewDidChange:(UITextView *)inputTextView;

/// Callback after the input text view content has changed (voice-to-text).
///
/// @param inputTextView The text input view.
- (void)inputTextViewDidChangeOnEndVoiceTransfer:(UITextView *)inputTextView;

/// Callback when an extension item on the plugin board is tapped.
///
/// @param pluginBoardView The plugin board view.
/// @param tag             The unique tag of the tapped extension item.
- (void)pluginBoardView:(NCPluginBoardView *)pluginBoardView clickedItemWithTag:(NSInteger)tag;

/// Callback when an emoji is tapped.
///
/// @param emojiView    The emoji board view.
/// @param touchedEmoji The string encoding of the tapped emoji.
- (void)emojiView:(NCEmojiBoardView *)emojiView didTouchedEmoji:(NSString *)touchedEmoji;

/// Callback when the send button on the emoji board is tapped.
///
/// @param emojiView  The emoji board view.
/// @param sendButton The send button.
- (void)emojiView:(NCEmojiBoardView *)emojiView didTouchSendButton:(UIButton *)sendButton;

/// Query whether another module is currently holding the audio channel.
///
- (BOOL)inputBarIsAudioHolding:(NCChatSessionInputBarControl *)chatInputBar;

/// Query whether another module is currently holding the camera.
///
- (BOOL)inputBarIsCameraHolding:(NCChatSessionInputBarControl *)chatInputBar;

/// Called when voice recording is about to begin.
/// @return YES to continue recording; NO to stop (e.g., when audio is held by another module, show
/// an alert).
- (BOOL)recordWillBegin;

/// Called when voice recording has begun.
- (void)recordDidBegin;

/// Called when voice recording is cancelled.
- (void)recordDidCancel;

/// Called when voice recording has ended.
- (void)recordDidEnd:(NSData *)recordData duration:(long)duration error:(nullable NSError *)error;

/// Called after a photo is captured by the camera.
///
/// @param image   The captured image selected for sending.
- (void)imageDidCapture:(UIImage *)image;

/// Called after a short video is recorded by the camera.
///
/// @param url URL of the short video.
/// @param image Thumbnail image (first frame) of the short video.
/// @param duration Duration of the short video in seconds.
- (void)sightDidFinishRecord:(NSString *)url
                   thumbnail:(UIImage *)image
                    duration:(NSUInteger)duration;

/// Called when short video recording fails.
///
/// @param error The error.
/// @param status AVAssetWriter status.
- (void)sightDidRecordFailedWith:(NSError *)error status:(NSInteger)status;

/// Called when images are selected from the album. Returns NSData for each image.
///
/// @param selectedImages   The selected images.
/// @param full             Whether the user requested full-resolution images.
- (void)imageDataDidSelect:(NSArray *)selectedImages fullImageRequired:(BOOL)full;

/// Called when files are selected.
///
/// @param filePathList   List of selected file paths.
- (void)fileDidSelect:(NSArray *)filePathList;

/// Called when a file is selected on the file selector page.
///
/// @param path File path.
/// @return YES to allow the file to be selected; NO to disallow.
/// Default is YES. Use this to control whether certain files can be selected.
- (BOOL)canBeSelectedAtFilePath:(NSString *)path;

/// Callback when the input bar status changes (not yet implemented).
///
/// @param bottomBarStatus The current status.
- (void)chatSessionInputBarStatusChanged:(KBottomBarStatus)bottomBarStatus;

- (void)didSetDraft:(NSDictionary *)info;

@end

@protocol NCChatSessionInputBarControlDataSource <NSObject>

/// Get the list of user IDs for selection.
///
/// @param completion  Callback when retrieval is complete.
/// @param functionTag Function tag identifier.
- (void)getSelectingUserIdList:(void (^)(NSArray<NSString *> *userIdList))completion
                   functionTag:(NSInteger)functionTag;

/// Get the user info for a user ID being selected.
///
/// @param userId           The user ID.
/// @return The user info.
- (nullable NCChatUIUserInfo *)getSelectingUserInfo:(NSString *)userId;

/// Get extra info to store in the draft.
/// @return Draft extra info dictionary.
- (nullable NSDictionary *)getDraftExtraInfo;

/// Get the optional root directory for the file selector.
///
/// @return The file selector root directory.
- (nullable NSString *)fileSelectorRootPath;

/// Get the bottom safe area height.
///
///
/// @return The bottom safe area height.
- (CGFloat)inputBarBottomSafeAreaInset;

@end

/// Delegate for picture editing.
@protocol NCPictureEditDelegate <NSObject>

/// Called when the edit button is tapped. Use rootCtrl for navigation. Defaults to
/// NCPictureEditViewController.
///
/// @param rootCtrl The root controller for navigation.
/// @param originalImage The original image.
/// @param editCompletion Block to pass the edited image back to the SDK.
- (void)onClickEditPicture:(UIViewController *)rootCtrl
             originalImage:(UIImage *)originalImage
            editCompletion:(void (^)(UIImage *editedImage))editCompletion
    __attribute__((deprecated));

@end

NS_ASSUME_NONNULL_END
