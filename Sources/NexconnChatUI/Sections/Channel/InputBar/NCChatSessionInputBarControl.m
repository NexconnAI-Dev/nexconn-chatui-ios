//
//  NCChatSessionInputBarControl.m
//  NCChatUIExtension
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCChatSessionInputBarControl.h"
#import <NexconnChatUI/NCChatUILog.h>
#import "NCAlbumListTableViewController.h"
#import "NCAssetHelper.h"
#import "NCChatUICommonDefine.h"
#import "NCChatUIExtensionService.h"
#import "NCFileSelectorViewController.h"
#import "NCMentionedStringRangeInfo.h"
#import "NCUserListViewController.h"
#import <CoreText/CoreText.h>
#import "NCVoiceRecordControl.h"
#import "NCAlertView.h"
#import "NCChatUIConfig.h"
#import "NCActionSheetView.h"
#import "NCInputContainerView+internal.h"
#import "NCSightViewController+ChatUI.h"
#import "NCSemanticContext.h"
#import "NCBaseButton.h"
#import "NCMenuController.h"
// Two 70-point cell rows, 14-point top and bottom padding, and spacing between rows.
#define Height_EmojBoardView 223.5f
#define Height_PluginBoardView 223.5f
// Standard system status-bar height
#define SYS_STATUSBAR_HEIGHT 20
// Hotspot status-bar height
#define HOTSPOT_STATUSBAR_HEIGHT 20
#define APP_STATUSBAR_HEIGHT (CGRectGetHeight([UIApplication sharedApplication].statusBarFrame))
// Detect an active hotspot from APP_STATUSBAR_HEIGHT.
#define IS_HOTSPOT_CONNECTED (APP_STATUSBAR_HEIGHT == (SYS_STATUSBAR_HEIGHT + HOTSPOT_STATUSBAR_HEIGHT) ? YES : NO)

NSString *const NCUIKeyboardWillShowNotification = @"NCUIKeyboardWillShowNotification";

@interface NCMenuController (KeyboardTracking)
- (void)updateKeyboardFrame:(CGRect)keyboardFrame visible:(BOOL)visible;
@end

@interface NCChatSessionInputBarControl () <NCEmojiViewDelegate, NCPluginBoardViewDelegate, UINavigationControllerDelegate,
    UIImagePickerControllerDelegate, NCAlbumListViewControllerDelegate,
    NCFileSelectorViewControllerDelegate, NCSelectingUserDataSource,
    NCVoiceRecordControlDelegate, NCInputContainerViewDelegate>

@property (nonatomic) CGRect keyboardFrame;

@property (nonatomic) BOOL isContainViewAppeared;

@property (nonatomic) int isNew;

@property (nonatomic, strong) NCVoiceRecordControl *voiceRecordControl;

@property (nonatomic, assign, readonly) CGFloat inputBarHeight;

@property (nonatomic, strong) NSMutableArray *mentionedRangeInfoList;

@property (nonatomic, strong) NSMutableDictionary *pluginTapBlockDic;

@property (nonatomic, assign) NCChatSessionInputBarControlType currentControlType;

@property (nonatomic, assign) NCChatSessionInputBarControlStyle currentControlStyle;

@property (nonatomic, strong) UIView *safeAreaView;

@property (nonatomic, strong) CALayer *topLineLayer;

@end

@implementation NCChatSessionInputBarControl
#pragma mark - Life Cycle
- (instancetype)initWithFrame:(CGRect)frame
            withContainerView:(UIView *)containerView
                  controlType:(NCChatSessionInputBarControlType)controlType
                 controlStyle:(NCChatSessionInputBarControlStyle)controlStyle
             defaultInputType:(NCChatSessionInputBarInputType)defaultInputType {
    self = [super initWithFrame:frame];
    if (self) {
        _containerView = containerView;
        [self nc_commonInit];
        [self setInputBarType:controlType style:controlStyle];
        [self setDefaultInputType:defaultInputType];
    }
    return self;
}

- (void)nc_commonInit {
    self.backgroundColor = NCDynamicColor(@"clear_color");
    self.keyboardFrame = CGRectZero;
    self.isNew = 0;
    [self addBottomAreaView];
    [self.layer addSublayer:self.topLineLayer];
}

#pragma mark - Super Methods
- (void)setFrame:(CGRect)frame{
    [super setFrame:frame];
    if (!self.isContainViewAppeared) {
        return;
    }
    if ([self.delegate respondsToSelector:@selector(chatInputBar:shouldChangeFrame:)]) {
        [self.delegate chatInputBar:self shouldChangeFrame:frame];
    }
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

#pragma mark - Public Methods
- (void)setInputBarType:(NCChatSessionInputBarControlType)type style:(NCChatSessionInputBarControlStyle)style {
    self.currentControlType = type;
    self.currentControlStyle = style;
    [self resetInputBar];

    if (NCChatSessionInputBarControlNoAvailableType == type) {
        [self addSubview:_inputContainerView];
        [self.inputTextView setEditable:NO];
        [self.emojiButton setEnabled:NO];
    } else {
        [self addSubview:self.inputContainerView];
    }
    [self updateSubviewsLayout];
    [self setDraft:self.inputTextView.text];
}

- (void)addMentionedUser:(NCChatUIUserInfo *)userInfo {
    [self insertMentionedUser:userInfo symbolRequset:YES];
}

- (void)pluginBoardView:(NCPluginBoardView *)pluginBoardView clickedItemWithTag:(NSInteger)tag {
    if ([self.delegate respondsToSelector:@selector(pluginBoardView:clickedItemWithTag:)]) {
        [self.delegate pluginBoardView:pluginBoardView clickedItemWithTag:tag];
    }
}

// Opens the system photo library.
- (void)openSystemAlbum {
    NCAlbumListTableViewController *albumListVC = [[NCAlbumListTableViewController alloc] init];
    albumListVC.delegate = self;
    NCBaseNavigationController *rootVC = [[NCBaseNavigationController alloc] initWithRootViewController:albumListVC];
    [self.delegate presentViewController:rootVC functionTag:PLUGIN_BOARD_ITEM_ALBUM_TAG];
}

// Opens the camera.
- (void)openSystemCamera {
    if ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo] == AVAuthorizationStatusNotDetermined) {
        [self requestCameraAccess:^(BOOL granted) {
            if (granted) {
                [self startCamera];
            } else {
                [self checkAndAlertCameraAccessRight];
            }
        }];
    } else {
        if ([self checkAndAlertCameraAccessRight]) {
            [self startCamera];
        }
    }
}

- (void)requestCameraAccess:(void (^)(BOOL granted))handler {
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo
                             completionHandler:^(BOOL granted) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (granted) {
                handler(YES);
            } else {
                handler(NO);
            }
        });
    }];
}

- (void)startCamera {
    Class sightType = NSClassFromString(@"NCSightViewController");
    if (sightType) {
        BOOL isAudioHolding = [self inputBarIsAudioHolding];
        BOOL isCameraHolding = [self inputBarIsCameraHolding];
        if (isAudioHolding || isCameraHolding) {
            NSString *alertMessage =
            isCameraHolding
            ? NCUILocalizedString(@"voip_video_call_existed_warning")
            : NCUILocalizedString(@"voip_audio_call_existed_warning");
            [NCAlertView showAlertController:alertMessage message:nil hiddenAfterDelay:1 inViewController:nil];
            return;
        }
        NCSightViewController *svc = [[sightType alloc] init];
        svc.delegate = self;
        [self.delegate presentViewController:svc functionTag:PLUGIN_BOARD_ITEM_CAMERA_TAG];
    } else {
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.delegate = self;
#if TARGET_IPHONE_SIMULATOR
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
#else
        picker.sourceType = UIImagePickerControllerSourceTypeCamera;
#endif
        [self.delegate presentViewController:picker functionTag:PLUGIN_BOARD_ITEM_CAMERA_TAG];
    }
}

// Opens the file selector.
- (void)openFileSelector {
    NSString *rootPath = [self fileSelectorRootPath];
    NCFileSelectorViewController *picker =
        [[NCFileSelectorViewController alloc] initWithRootPath:rootPath];
    picker.delegate = self;
    NCBaseNavigationController *rootVC = [[NCBaseNavigationController alloc] initWithRootViewController:picker];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate presentViewController:rootVC functionTag:PLUGIN_BOARD_ITEM_FILE_TAG];
    });
}

- (void)openDynamicFunction:(NSInteger)functionTag {
    if (self.pluginTapBlockDic[@(functionTag)]) {
        NCConversationPluginItemTapBlock tapBlock = self.pluginTapBlockDic[@(functionTag)];
        tapBlock(self);
    }
}

- (void)containerViewWillAppear {
    self.isContainViewAppeared = YES;
    [self nc_inputBar_registerForNotifications];
    if (_isNew == 0) {
        [self animationLayoutBottomBarWithStatus:KBottomBarDefaultStatus animated:NO];
    }
}

- (void)containerViewDidAppear {
    if (self.inputTextView.text && self.inputTextView.text.length > 0 &&
        (self.currentBottomBarStatus == KBottomBarKeyboardStatus ||
         (self.currentBottomBarStatus == KBottomBarDefaultStatus && _isNew == 0))) {
        [self changeTextViewHeight:self.inputTextView.text];
    }
    if (self.currentBottomBarStatus == KBottomBarKeyboardStatus) {
        [self animationLayoutBottomBarWithStatus:KBottomBarKeyboardStatus animated:NO];
    }
    _isNew = 1;
}

- (void)containerViewWillDisappear {
    self.isContainViewAppeared = NO;
    [self nc_inputBar_unregisterForNotifications];
}

- (void)containerViewSizeChangedNoAnnimation {
    [self updateSubviewsLayout];
    [self animationLayoutBottomBarWithStatus:self.currentBottomBarStatus animated:NO];
}

- (void)containerViewSizeChanged {
    [self animationLayoutBottomBarWithStatus:self.currentBottomBarStatus animated:YES];
}

- (void)updateStatus:(KBottomBarStatus)inputBarStatus animated:(BOOL)animated {
    [self animationLayoutBottomBarWithStatus:inputBarStatus animated:animated];
}

- (void)resetToDefaultStatus {
    if (self.currentBottomBarStatus != KBottomBarDefaultStatus) {
        [self animationLayoutBottomBarWithStatus:KBottomBarDefaultStatus animated:YES];
    }
}

- (void)setDefaultInputType:(NCChatSessionInputBarInputType)defaultInputType {
    if (defaultInputType == NCChatSessionInputBarInputVoice) {
        [self animationLayoutBottomBarWithStatus:KBottomBarRecordStatus animated:YES];
    } else if (defaultInputType == NCChatSessionInputBarInputExtention) {
        [self animationLayoutBottomBarWithStatus:KBottomBarPluginStatus animated:YES];
    }
}

- (void)cancelVoiceRecord {
    [self.voiceRecordControl onCancelRecordEvent];
}

- (void)endVoiceRecord {
    [self.voiceRecordControl onEndRecordEvent];
}

- (void)endVoiceTransfer {
    if ([self.delegate respondsToSelector:@selector(inputTextViewDidChangeOnEndVoiceTransfer:)]) {
        [self.delegate inputTextViewDidChangeOnEndVoiceTransfer:self.inputTextView];
    }
}

- (void)clearInputData {
    self.inputTextView.text = @"";
    [self.mentionedRangeInfoList removeAllObjects];
}

#pragma mark - NCVoiceRecordControlDelegate
- (BOOL)recordWillBegin{
    if ([self.delegate respondsToSelector:@selector(recordWillBegin)]) {
        NCLogF(@"recordWillBegin:==============> %d", [self.delegate recordWillBegin]);
        return [self.delegate recordWillBegin];
    }
    return YES;
}

- (void)voiceRecordControlDidBegin:(NCVoiceRecordControl *)voiceRecordControl {
    if ([self.delegate respondsToSelector:@selector(recordDidBegin)]) {
        [self.delegate recordDidBegin];
    }
}

- (void)voiceRecordControlDidCancel:(NCVoiceRecordControl *)voiceRecordControl {
    if ([self.delegate respondsToSelector:@selector(recordDidCancel)]) {
        [self.delegate recordDidCancel];
    }
}

- (void)voiceRecordControl:(NCVoiceRecordControl *)voiceRecordControl
                    didEnd:(NSData *)recordData
                  duration:(long)duration
                     error:(NSError *)error {
    if ([self.delegate respondsToSelector:@selector(recordDidEnd:duration:error:)]) {
        [self.delegate recordDidEnd:recordData duration:duration error:nil];
    }
}

#pragma mark - NCInputContainerViewDelegate
- (void)inputContainerViewSwitchButtonClicked:(NCInputContainerView *)inputContainerView {
    if (self.currentBottomBarStatus == KBottomBarRecordStatus) {
        [self animationLayoutBottomBarWithStatus:KBottomBarKeyboardStatus animated:YES];
    } else {
        [self animationLayoutBottomBarWithStatus:KBottomBarRecordStatus animated:YES];
    }
}

- (void)inputContainerViewEmojiButtonClicked:(NCInputContainerView *)inputContainerView {
    if (self.currentBottomBarStatus == KBottomBarEmojiStatus) {
        [self animationLayoutBottomBarWithStatus:KBottomBarKeyboardStatus animated:YES];
    } else {
        [self animationLayoutBottomBarWithStatus:KBottomBarEmojiStatus animated:YES];
    }
    [self enableEmojiBoardViewSendButton];
}

- (void)inputContainerViewAdditionalButtonClicked:(NCInputContainerView *)inputContainerView {
    if (self.currentBottomBarStatus == KBottomBarPluginStatus) {
        [self animationLayoutBottomBarWithStatus:KBottomBarKeyboardStatus animated:YES];
    } else {
        [self animationLayoutBottomBarWithStatus:KBottomBarPluginStatus animated:YES];
    }
}

- (void)inputContainerView:(NCInputContainerView *)inputContainerView forControlEvents:(UIControlEvents)controlEvents {
    [self didTouchRecordButtonEvent:controlEvents];
}

- (void)inputContainerView:(NCInputContainerView *)inputContainerView didChangeFrame:(CGRect)frame {
    CGRect vRect = self.frame;
    vRect.size.height = frame.size.height;
    vRect.origin.y += self.frame.size.height - vRect.size.height;
    self.frame = vRect;
}

- (BOOL)inputTextView:(UITextView *)inputTextView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text{
    if ([self.delegate respondsToSelector:@selector(inputTextView:shouldChangeTextInRange:replacementText:)]) {
        [self.delegate inputTextView:inputTextView shouldChangeTextInRange:range replacementText:text];
    }

    if ([text isEqualToString:@"\n"]) {
        if ([self.delegate respondsToSelector:@selector(inputTextViewDidTouchSendKey:)]) {
            NSString *formatString =
                [inputTextView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            if (formatString.length > 0) {
                [self.delegate inputTextViewDidTouchSendKey:inputTextView];
                [self.mentionedRangeInfoList removeAllObjects];
            }
        }
        NCLogD(@"Enter key call inputTextViewDidChange");
        return NO;
    }

    BOOL shouldUseDefaultChangeText = [self willUpdateInputTextMetionedInfo:text range:range];
    return shouldUseDefaultChangeText;
}

- (void)inputTextViewDidChange:(UITextView *)inputTextView {
    if ([self.delegate respondsToSelector:@selector(inputTextViewDidChange:)]) {
        [self.delegate inputTextViewDidChange:inputTextView];
    }
}

#pragma mark -  NCEmojiViewDelegate
- (void)didTouchEmojiView:(NCEmojiBoardView *)emojiView touchedEmoji:(NSString *)string {
    if (nil == string) {
        NSRange range = NSMakeRange(self.inputTextView.selectedRange.location - 1, 1);
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(inputTextView:shouldChangeTextInRange:replacementText:)]) {
            [self.delegate inputTextView:self.inputTextView shouldChangeTextInRange:range replacementText:string];
        }
        // Update mention metadata.
        if ([self.inputTextView.delegate respondsToSelector:@selector(textView:shouldChangeTextInRange:replacementText:)]) {
            BOOL shouldChange = [self.inputTextView.delegate textView:self.inputTextView shouldChangeTextInRange:range replacementText:string];
            if (shouldChange) {
                [self.inputTextView deleteBackward];
            }
        }
    } else {
        NSString *replaceString = string;
        if (replaceString.length < 5000) {
            NSMutableAttributedString *attStr = [[NSMutableAttributedString alloc] initWithString:replaceString];
            [attStr addAttribute:NSFontAttributeName
                           value:self.inputTextView.font
                           range:NSMakeRange(0, replaceString.length)];
            UIColor *foreColor = NCDynamicColor(@"text_primary_color");
            if (foreColor) {
                [attStr addAttribute:NSForegroundColorAttributeName
                               value:foreColor
                               range:NSMakeRange(0, replaceString.length)];
            }
       
            NSInteger cursorPosition;
            if (self.inputTextView.selectedTextRange) {
                cursorPosition = self.inputTextView.selectedRange.location;
            } else {
                cursorPosition = 0;
            }
            // Clamp the caret position to the text storage length.
            if (cursorPosition > self.inputTextView.textStorage.length)
                cursorPosition = self.inputTextView.textStorage.length;
            [self.inputTextView.textStorage insertAttributedString:attStr atIndex:cursorPosition];
            // Notify the text delegate so mention ranges follow the inserted emoji.
            if ([self.inputTextView.delegate respondsToSelector:@selector(textView:shouldChangeTextInRange:replacementText:)]) {
                [self.inputTextView.delegate textView:self.inputTextView shouldChangeTextInRange:self.inputTextView.selectedRange replacementText:string];
            }
            
            NSRange range;
            range.location = self.inputTextView.selectedRange.location + string.length;
            range.length = 0;
            self.inputTextView.selectedRange = range;
        }
    }
    
    UITextView *textView = self.inputTextView;
    CGRect line = [textView caretRectForPosition:textView.selectedTextRange.start];
    CGFloat overflow =
    line.origin.y + line.size.height - (textView.contentOffset.y + textView.bounds.size.height -
                                        textView.contentInset.bottom - textView.contentInset.top);
    if (overflow > 0) {
        // We are at the bottom of the visible text and introduced a line feed,
        // scroll down (iOS 7 does not do it)
        // Scroll caret to visible area
        CGPoint offset = textView.contentOffset;
        offset.y += overflow + 7; // leave 7 pixels margin
        // Cannot animate with setContentOffset:animated: or caret will not appear
        __weak typeof(textView) weakTextView = textView;
        [UIView animateWithDuration:.2
                         animations:^{
            [weakTextView setContentOffset:offset];
        }];
    }
    [self enableEmojiBoardViewSendButton];
   
    if ([self.delegate respondsToSelector:@selector(emojiView:didTouchedEmoji:)]) {
        [self.delegate emojiView:emojiView didTouchedEmoji:string];
    }
}

- (void)didSendButtonEvent:(NCEmojiBoardView *)emojiView sendButton:(UIButton *)sendButton {
    NSString *_sendText = self.inputTextView.text;

    NSString *_formatString = [_sendText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

    if (0 == [_formatString length]) {
        [self showAlertController:nil
                          message:NCUILocalizedString(@"white_space_message")
                      cancelTitle:NCUILocalizedString(@"ok")];
        return;
    }
    if ([self.delegate respondsToSelector:@selector(emojiView:didTouchSendButton:)]) {
        [self.delegate emojiView:emojiView didTouchSendButton:sendButton];
    }

    self.inputTextView.text = @"";
    [self.mentionedRangeInfoList removeAllObjects];
    [self enableEmojiBoardViewSendButton];
}

#pragma mark - UIImagePickerControllerDelegate method
// Handles an image selected from the library or captured by the camera.
- (void)imagePickerController:(UIImagePickerController *)picker
        didFinishPickingImage:(UIImage *)image
                  editingInfo:(NSDictionary *)editingInfo {
    [picker dismissViewControllerAnimated:YES completion:nil];
    if ([self.delegate respondsToSelector:@selector(imageDidCapture:)]) {
        [self.delegate imageDidCapture:image];
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - NCSightViewControllerDelegate
- (void)sightViewController:(UIViewController *)sightVC didFinishCapturingStillImage:(UIImage *)image {
    if ([self.delegate respondsToSelector:@selector(imageDidCapture:)]) {
        [self.delegate imageDidCapture:image];
    }
    [sightVC dismissViewControllerAnimated:YES completion:nil];
}

- (void)sightViewController:(UIViewController *)sightVC
         didWriteSightAtURL:(NSURL *)url
                  thumbnail:(UIImage *)thumnail
                   duration:(NSUInteger)duration {
    [sightVC
     dismissViewControllerAnimated:YES
     completion:^{
        if ([self.delegate respondsToSelector:@selector(sightDidFinishRecord:thumbnail:duration:)]) {
            [self.delegate sightDidFinishRecord:url.path thumbnail:thumnail duration:duration];
        }
    }];
}

- (void)sightViewController:(NCSightViewController *)sightVC
         didWriteFailedWith:(NSError *)error
                     status:(NSInteger)status {
    if ([self.delegate respondsToSelector:@selector(sightDidRecordFailedWith:status:)]) {
        [self.delegate sightDidRecordFailedWith:error status:status];
    }
}
#pragma mark - NCFileSelectorViewControllerDelegate
- (void)fileDidSelect:(NSArray *)filePathList {
    if ([self.delegate respondsToSelector:@selector(fileDidSelect:)]) {
        [self.delegate fileDidSelect:filePathList];
    }
}

- (BOOL)canBeSelectedAtPath:(NSString *)path {
    if ([self.delegate respondsToSelector:@selector(canBeSelectedAtFilePath:)]) {
        return [self.delegate canBeSelectedAtFilePath:path];
    }
    return YES;
}

#pragma mark - NCAlbumListViewControllerDelegate
- (void)albumListViewController:(NCAlbumListTableViewController *)albumListViewController
                 selectedImages:(NSArray *)selectedImageDatas
                isSendFullImage:(BOOL)enable {
    if ([self.delegate respondsToSelector:@selector(imageDataDidSelect:fullImageRequired:)]) {
        [self.delegate imageDataDidSelect:selectedImageDatas fullImageRequired:enable];
    }
}

- (void)onClickEditPhoto:(UIViewController *)rootCtrl previewImage:(UIImage *)previewImage {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    if (self.photoEditorDelegate &&
        [self.photoEditorDelegate respondsToSelector:@selector(onClickEditPicture:originalImage:editCompletion:)]) {
        [self.photoEditorDelegate onClickEditPicture:rootCtrl
                                       originalImage:previewImage
                                      editCompletion:^(UIImage *editedImage) {
                                          [[NSNotificationCenter defaultCenter]
                                              postNotificationName:@"onClickEditPictureCompletion"
                                                            object:editedImage];
                                      }];
    }
#pragma clang diagnostic pop
}

#pragma mark - NCSelectingUserDataSource
- (void)getSelectingUserIdList:(void (^)(NSArray<NSString *> *userIdList))completion {
    if ([self.dataSource respondsToSelector:@selector(getSelectingUserIdList:functionTag:)]) {
        [self.dataSource getSelectingUserIdList:^(NSArray<NSString *> *userIdList) {
            if (completion) {
                completion(userIdList);
            }
        }
                                    functionTag:INPUT_MENTIONED_SELECT_TAG];
    } else {
        if (completion) {
            completion(nil);
        }
    }
}

- (NCChatUIUserInfo *)getSelectingUserInfo:(NSString *)userId {
    if ([self.dataSource respondsToSelector:@selector(getSelectingUserInfo:)]) {
        return [self.dataSource getSelectingUserInfo:userId];
    } else {
        return nil;
    }
}

- (NSString *)fileSelectorRootPath {
    if ([self.dataSource respondsToSelector:@selector(fileSelectorRootPath)]) {
        NSString *rootPath = [self.dataSource fileSelectorRootPath];
        if (rootPath.length > 0) {
            return rootPath;
        }
    }
    return nil;
}

- (CGFloat)inputBarBottomSafeAreaInset {
    if ([self.dataSource respondsToSelector:@selector(inputBarBottomSafeAreaInset)]) {
        return [self.dataSource inputBarBottomSafeAreaInset];
    }
    return 0;
}

- (BOOL)inputBarIsAudioHolding {
    if ([self.delegate respondsToSelector:@selector(inputBarIsAudioHolding:)]) {
        return [self.delegate inputBarIsAudioHolding:self];
    }
    return NO;
}

- (BOOL)inputBarIsCameraHolding {
    if ([self.delegate respondsToSelector:@selector(inputBarIsCameraHolding:)]) {
        return [self.delegate inputBarIsCameraHolding:self];
    }
    return NO;
}

#pragma mark - NCPictureEditDelegate
- (void)setPhotoEditorDelegate:(id<NCPictureEditDelegate>)photoEditorDelegate {
    if (photoEditorDelegate &&
        [photoEditorDelegate respondsToSelector:@selector(onClickEditPicture:originalImage:editCompletion:)]) {
        _photoEditorDelegate = photoEditorDelegate;
    }
}

#pragma mark - Notifications

- (void)nc_inputBar_registerForNotifications {
    [self nc_inputBar_unregisterForNotifications];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(nc_inputBar_didReceiveKeyboardWillShowNotification:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(nc_inputBar_didReceiveKeyboardWillShowNotification:)
                                                 name:NCUIKeyboardWillShowNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(nc_inputBar_didReceiveKeyboardWillHideNotification:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)nc_inputBar_unregisterForNotifications {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)nc_inputBar_didReceiveKeyboardWillShowNotification:(NSNotification *)notification {
    NCLogD(@"%s", __FUNCTION__);
    if (self.isHidden) {
        return;
    }
    if (@available(iOS 15.0, *)) {
        UIApplicationState state = [UIApplication sharedApplication].applicationState;
        if (state == UIApplicationStateBackground) {
            return;
        }
    }
    
    BOOL shouldHideMenuControllers = NO;
    
    // textViewBeginEditing is set by the input text view's textViewShouldBeginEditing delegate callback.
    // Ignore keyboard events initiated by other text fields on the channel page.
    if (self.inputContainerView.textViewBeginEditing) {
        NSDictionary *userInfo = [notification userInfo];
        CGRect keyboardBeginFrame = [userInfo[UIKeyboardFrameBeginUserInfoKey] CGRectValue];
        CGRect keyboardEndFrame = [userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
        [[NCMenuController sharedMenuController] updateKeyboardFrame:keyboardEndFrame visible:YES];
        BOOL shouldUpdateKeyboardLayout = !CGRectEqualToRect(keyboardBeginFrame, keyboardEndFrame) || self.inputContainerView.currentBottomBarStatus != KBottomBarKeyboardStatus;
        if (shouldUpdateKeyboardLayout) {
            UIViewAnimationCurve animationCurve = [userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
            NSInteger animationCurveOption = (animationCurve << 16);
            
            double animationDuration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
            [UIView animateWithDuration:animationDuration delay:0.0 options:animationCurveOption animations:^{
                self.keyboardFrame = keyboardEndFrame;
                [self animationLayoutBottomBarWithStatus:KBottomBarKeyboardStatus animated:NO];
            }completion:^(BOOL finished){
                
            }];
        }
        shouldHideMenuControllers = shouldUpdateKeyboardLayout;
    }else {
        /*
         PAASIOSDEV-407: After an alert restores the input text view as first
         responder, the system keyboard posts a second notification after
         textViewBeginEditing becomes YES, while emoji and third-party keyboards
         may post only the earlier notification. Repost asynchronously with the
         recorded keyboard frame so the input bar is laid out above the keyboard.
         This can repeat the standard-keyboard animation or slightly delay custom
         keyboard layout.
         */
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.inputContainerView.textViewBeginEditing) {
                NSMutableDictionary *userInfo = notification.userInfo.mutableCopy;
                userInfo[UIKeyboardFrameEndUserInfoKey] = @(self.keyboardFrame);
                [[NSNotificationCenter defaultCenter] postNotificationName:NCUIKeyboardWillShowNotification object:notification.object userInfo:userInfo.copy];
            }
        });
        shouldHideMenuControllers = YES;
    }
    
    if (!shouldHideMenuControllers) {
        return;
    }
    
    if (@available(iOS 13.0, *)) {
        [[UIMenuController sharedMenuController] hideMenuFromView:self];
    } else {
        [[UIMenuController sharedMenuController] setMenuItems:nil];
        [UIMenuController sharedMenuController].menuVisible = NO;
    }
    [[NCMenuController sharedMenuController] hideMenuAnimated:NO];

}

- (void)nc_inputBar_didReceiveKeyboardWillHideNotification:(NSNotification *)notification {
    NCLogD(@"%s", __FUNCTION__);
    [[NCMenuController sharedMenuController] updateKeyboardFrame:CGRectZero visible:NO];
    if (self.isHidden) {
        return;
    }
    if (self.currentBottomBarStatus == KBottomBarKeyboardStatus) {
        [self animationLayoutBottomBarWithStatus:KBottomBarDefaultStatus animated:NO];
    }
}

#pragma mark - Mentioned
// Shifts mention ranges that follow the edited character range.
- (void)updateAllMentionedRangeInfo:(NSInteger)changedLocation length:(NSInteger)changedLength {
    for (NCMentionedStringRangeInfo *mentionedInfo in self.mentionedRangeInfoList) {
        if (mentionedInfo.range.location >= changedLocation) {
            mentionedInfo.range = NSMakeRange(mentionedInfo.range.location + changedLength, mentionedInfo.range.length);
        }
    }
}

- (void)showChooseUserViewController:(void (^)(NCChatUIUserInfo *selectedUserInfo))selectedBlock
                              cancel:(void (^)(void))cancelBlock {
    // Prefer the delegate's custom user-selection flow when it implements the optional callback.
    if ([self.delegate respondsToSelector:@selector(showChooseUserViewController:cancel:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate performSelector:@selector(showChooseUserViewController:cancel:)
                                withObject:selectedBlock
                                withObject:cancelBlock];
        });

        return;
    }
}

- (BOOL)willUpdateInputTextMetionedInfo:(NSString *)text range:(NSRange)range{
    BOOL shouldUseDefaultChangeText = YES;
    if (self.isMentionedEnabled) {
        // Track the edited range.
        NSInteger changedLocation = 0;
        NSInteger changedLength = 0;

        // An empty replacement string represents deletion.
        if (text.length == 0) {
            for (NCMentionedStringRangeInfo *mentionedInfo in [self.mentionedRangeInfoList copy]) {
                NSRange mentionedRange = mentionedInfo.range;
                // Deleting at the end of a mention removes the entire mention.
                if (range.length == 1 && (mentionedRange.location + mentionedRange.length == range.location + 1)) {
                    shouldUseDefaultChangeText = NO;
                    [self.inputTextView.textStorage deleteCharactersInRange:mentionedRange];
                    // Mutating textStorage does not trigger inputTextViewDidChange, so invoke it explicitly.
                    [self inputTextViewDidChange:self.inputTextView];
                    range.location = range.location - mentionedRange.length + 1;
                    range.length = 0;
                    self.inputTextView.selectedRange = NSMakeRange(mentionedRange.location, 0);

                    changedLocation = mentionedInfo.range.location;
                    changedLength = -(NSInteger)mentionedInfo.range.length;

                    [self.mentionedRangeInfoList removeObject:mentionedInfo];
                    break;
                } else if (mentionedRange.location <= range.location &&
                           range.location < mentionedRange.location + mentionedRange.length) {
                    [self.mentionedRangeInfoList removeObject:mentionedInfo];
                    // Continue so a range deletion removes every overlapping mention.
                }
            }

            if (changedLength == 0) {
                // Record an ordinary deletion that does not end at a mention boundary.
                changedLocation = range.location + 1;
                changedLength = -(NSInteger)range.length;
            }
        } else {
            if ([text isEqualToString:@"@"]) {
                if ([self shouldTriggerMentionedChoose:self.inputTextView range:range]) {
                    __weak typeof(self) weakSelf = self;
                    [self showChooseUserViewController:^(NCChatUIUserInfo *selectedUserInfo) {
                        [weakSelf insertMentionedUser:selectedUserInfo symbolRequset:NO];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [weakSelf animationLayoutBottomBarWithStatus:(KBottomBarKeyboardStatus) animated:YES];
                        });
                    }
                        cancel:^{
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [weakSelf animationLayoutBottomBarWithStatus:(KBottomBarKeyboardStatus) animated:YES];
                            });
                        }];
                }
            }

            // Inserting inside a mention invalidates it; other mentions are shifted by the edit length below.
            for (NCMentionedStringRangeInfo *mentionedInfo in [self.mentionedRangeInfoList copy]) {
                NSRange strRange = mentionedInfo.range;
                if ((range.location > strRange.location) && (range.location < (strRange.location + strRange.length))) {
                    [self.mentionedRangeInfoList removeObject:mentionedInfo];
                    break;
                }
            }
            changedLocation = range.location;
            changedLength = text.length - range.length;
        }

        [self updateAllMentionedRangeInfo:changedLocation length:changedLength];
    }
    return shouldUseDefaultChangeText;
}

- (BOOL)shouldTriggerMentionedChoose:(UITextView *)textView range:(NSRange)range {
    if (range.location == 0) {
        return YES;
    } else if (!isalnum([textView.text characterAtIndex:range.location - 1])) {
        // Do not trigger mention selection when "@" follows an alphanumeric character.
        return YES;
    }
    return NO;
}

- (void)insertMentionedUser:(NCChatUIUserInfo *)userInfo symbolRequset:(BOOL)symbolRequset {
    if (!self.isMentionedEnabled || userInfo.userId == nil) {
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        // Clamp the caret position to the text storage length.
        NSUInteger cursorPosition = self.inputTextView.selectedRange.location;
        if (cursorPosition > self.inputTextView.textStorage.length) {
            cursorPosition = self.inputTextView.textStorage.length;
        }
        // Mention start position
        NSUInteger mentionedPosition;

        // Mention display text
        NSString *insertContent = nil;
        NSInteger changeRangeLength;
        if (symbolRequset) {
            if (userInfo.name.length > 0) {
                insertContent = [NSString stringWithFormat:@"@%@ ", userInfo.name];
            } else {
                insertContent = [NSString stringWithFormat:@"@%@ ", userInfo.userId];
            }
            mentionedPosition = cursorPosition;
            changeRangeLength = [insertContent length];
        } else {
            if (userInfo.name.length > 0) {
                insertContent = [NSString stringWithFormat:@"%@ ", userInfo.name];
            } else {
                insertContent = [NSString stringWithFormat:@"%@ ", userInfo.userId];
            }
            mentionedPosition = (cursorPosition >= 1) ? (cursorPosition - 1) : 0;
            changeRangeLength = [insertContent length] + 1;
        }

        NSMutableAttributedString *attStr = [[NSMutableAttributedString alloc] initWithString:insertContent];
        [attStr addAttribute:NSFontAttributeName
                       value:self.inputTextView.font
                       range:NSMakeRange(0, insertContent.length)];
        UIColor *foreColor = NCDynamicColor(@"text_primary_color");
        if (foreColor) {
            [attStr addAttribute:NSForegroundColorAttributeName
                           value:foreColor
                           range:NSMakeRange(0, insertContent.length)];
        }
     
        [self.inputTextView.textStorage insertAttributedString:attStr atIndex:cursorPosition];
        // Mutating textStorage does not trigger inputTextViewDidChange, so invoke it explicitly.
        [self inputTextViewDidChange:self.inputTextView];
        self.inputTextView.selectedRange = NSMakeRange(cursorPosition + insertContent.length, 0);
        [self updateAllMentionedRangeInfo:cursorPosition length:insertContent.length];

        NCMentionedStringRangeInfo *mentionedStrInfo = [[NCMentionedStringRangeInfo alloc] init];
        mentionedStrInfo.content = insertContent;
        mentionedStrInfo.userId = userInfo.userId;
        mentionedStrInfo.range = NSMakeRange(mentionedPosition, changeRangeLength);
        [self.mentionedRangeInfoList addObject:mentionedStrInfo];

        if ([self.inputTextView.delegate respondsToSelector:@selector(textView:shouldChangeTextInRange:replacementText:)]) {
            [self.inputTextView.delegate textView:self.inputTextView shouldChangeTextInRange: self.inputTextView.selectedRange replacementText:insertContent];
        }
    });
}

#pragma mark - Target Action
- (float)getBoardViewBottomOriginY {
    float gap = (NC_IOS_SYSTEM_VERSION_LESS_THAN(@"7.0")) ? 64 : 0;
    float bottom = [self getSafeAreaExtraBottomHeight];
    gap += bottom;
    if (bottom > 0) {// A hotspot does not add another status-bar offset on devices with a bottom safe area.
        return [UIScreen mainScreen].bounds.size.height - gap;
    } else {
        return IS_HOTSPOT_CONNECTED ? [UIScreen mainScreen].bounds.size.height - gap - 20
        : [UIScreen mainScreen].bounds.size.height - gap;
    }
}

- (float)getSafeAreaExtraBottomHeight {
    return [self inputBarBottomSafeAreaInset];
}

- (BOOL)checkAndAlertCameraAccessRight {
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (authStatus == AVAuthorizationStatusDenied || authStatus == AVAuthorizationStatusRestricted) {
        [self showAlertController:NCUILocalizedString(@"access_right_title")
                          message:NCUILocalizedString(@"camera_access_right")
                      cancelTitle:NCUILocalizedString(@"ok")];
        return NO;
    }
    return YES;
}


- (void)resetInputContainerView {
    [self setInputBarType:self.currentControlType style:self.currentControlStyle];
}

- (void)animationLayoutBottomBarWithStatus:(KBottomBarStatus)bottomBarStatus animated:(BOOL)animated {
    [self.pluginBoardView.extensionView setHidden:YES];
    if (animated == YES) {
        [UIView beginAnimations:@"Move_bar" context:nil];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
        [UIView setAnimationDuration:0.25f];
        [UIView setAnimationDelegate:self];
        [self layoutBottomBarWithStatus:bottomBarStatus];
        [UIView commitAnimations];
    } else {
        [self layoutBottomBarWithStatus:bottomBarStatus];
    }
}

- (void)layoutBottomBarWithStatus:(KBottomBarStatus)bottomBarStatus {
    [self.inputContainerView setBottomBarWithStatus:bottomBarStatus];
    CGRect chatInputBarRect = self.frame;
    float bottomY = [self getBoardViewBottomOriginY];
    switch (bottomBarStatus) {
        case KBottomBarDefaultStatus: {
            [self hiddenEmojiBoardView:YES pluginBoardView:YES];
            chatInputBarRect.origin.y = bottomY - self.bounds.size.height;
        } break;
        case KBottomBarKeyboardStatus: {
            [self hiddenEmojiBoardView:YES pluginBoardView:YES];
            // bottomY already excludes the bottom safe-area inset.
            if (self.keyboardFrame.size.height > 0) {
                // The system keyboard height includes the same inset, so add it back after subtracting the keyboard.
                chatInputBarRect.origin.y = bottomY - self.bounds.size.height - self.keyboardFrame.size.height + [self getSafeAreaExtraBottomHeight];
            }else{
               // An external keyboard does not present the on-screen keyboard.
                chatInputBarRect.origin.y = bottomY - self.bounds.size.height;
            }
        } break;
        case KBottomBarPluginStatus: {
            [self pluginBoardView];
            [self hiddenEmojiBoardView:YES pluginBoardView:NO];
            chatInputBarRect.origin.y = bottomY - self.bounds.size.height - self.pluginBoardView.bounds.size.height;
        } break;
        case KBottomBarEmojiStatus: {
            [self emojiBoardView];
            [self hiddenEmojiBoardView:NO pluginBoardView:YES];
            chatInputBarRect.origin.y = bottomY - self.bounds.size.height - self.emojiBoardView.bounds.size.height;
        } break;
        case KBottomBarRecordStatus: {
            [self hiddenEmojiBoardView:YES pluginBoardView:YES];
            chatInputBarRect.origin.y = bottomY - self.bounds.size.height;
        } break;
        default:
            break;
    }
    [self setFrame:chatInputBarRect];
    
    [[NCChatUIExtensionService sharedService] inputBarStatusDidChange:bottomBarStatus inInputBar:self];
}

- (void)hiddenEmojiBoardView:(BOOL)hiddenEmojiBoardView
             pluginBoardView:(BOOL)hiddenPluginBoardView {
    if (self.emojiBoardView) {
        [self.emojiBoardView setHidden:hiddenEmojiBoardView];
        if (!hiddenEmojiBoardView) {
            self.emojiBoardView.frame = CGRectMake(0, [self getBoardViewBottomOriginY] - Height_EmojBoardView, self.containerView.bounds.size.width, Height_EmojBoardView);
        }
    }
    if (self.pluginBoardView) {
        [self.pluginBoardView setHidden:hiddenPluginBoardView];
        if (!hiddenPluginBoardView) {
            self.pluginBoardView.frame = CGRectMake(0, [self getBoardViewBottomOriginY] - Height_PluginBoardView,
                                                    self.containerView.bounds.size.width, Height_PluginBoardView);
        }
    }
}

#pragma mark - Private Methods
- (void)didTouchRecordButtonEvent:(UIControlEvents)event {
    switch (event) {
    case UIControlEventTouchDown: {
        [self.voiceRecordControl onBeginRecordEvent];
    } break;
    case UIControlEventTouchUpInside: {
        [self.voiceRecordControl onEndRecordEvent];
    } break;
    case UIControlEventTouchDragExit: {
        [self.voiceRecordControl dragExitRecordEvent];
    } break;
    case UIControlEventTouchUpOutside: {
        [self.voiceRecordControl onCancelRecordEvent];

    } break;
    case UIControlEventTouchDragEnter: {
        [self.voiceRecordControl dragEnterRecordEvent];
    } break;
    case UIControlEventTouchCancel: {
        [self.voiceRecordControl onEndRecordEvent];
    } break;
    default:
        break;
    }
}

- (void)enableEmojiBoardViewSendButton{
    if (self.inputTextView.text && self.inputTextView.text.length > 0) {
           [self.emojiBoardView enableSendButton:YES];
       } else {
           [self.emojiBoardView enableSendButton:NO];
       }
}

- (void)updateSubviewsLayout{
    CGRect containerViewFrame = self.bounds;
    if (self.currentControlType == NCChatSessionInputBarControlNoAvailableType) {
        self.inputContainerView.frame = containerViewFrame;
    } else {
        self.inputContainerView.frame = containerViewFrame;
    }
    [self.inputContainerView setInputBarStyle:self.currentControlStyle];
}

- (void)resetInputBar {
    if (self.inputContainerView) {
        NSString *text = self.inputTextView.text;
        [self.inputContainerView removeFromSuperview];
        self.inputContainerView = nil;
        self.inputTextView.text = text;
    }
}

- (void)changeTextViewHeight:(NSString *)text {
    if (text.length != 0) {
        [self animationLayoutBottomBarWithStatus:(KBottomBarKeyboardStatus) animated:YES];
    }
}

- (void)showAlertController:(NSString *)title message:(NSString *)message cancelTitle:(NSString *)cancelTitle {
    dispatch_async(dispatch_get_main_queue(), ^{
        [NCAlertView showAlertController:title message:message cancelTitle:cancelTitle inViewController:nil];
    });
}

#pragma mark - Getters and Setters

- (NCInputContainerView *)inputContainerView {
    if (!_inputContainerView) {
        _inputContainerView = [[NCInputContainerView alloc] initWithFrame:self.bounds];
        _inputContainerView.delegate = self;
        _inputContainerView.backgroundColor = NCDynamicColor(@"common_background_color");
    }
    return _inputContainerView;
}

- (NCButton *)switchButton {
    return self.inputContainerView.switchButton;
}

- (NCTextView *)inputTextView {
    return self.inputContainerView.inputTextView;
}

- (NCButton *)recordButton {
    return self.inputContainerView.recordButton;
}

- (NCButton *)emojiButton {
    return self.inputContainerView.emojiButton;
}

- (NCButton *)additionalButton {
    return self.inputContainerView.additionalButton;
}

- (UIView *)newLine {
    UIView *line = [UIView new];
    line.backgroundColor = NCDynamicColor(@"line_background_color");
    return line;
}

- (NSMutableDictionary *)pluginTapBlockDic {
    if (!_pluginTapBlockDic) {
        _pluginTapBlockDic = [[NSMutableDictionary alloc] init];
    }
    return _pluginTapBlockDic;
}

- (NCEmojiBoardView *)emojiBoardView {
    if (!_emojiBoardView) {
        _emojiBoardView = [[NCEmojiBoardView alloc]
            initWithFrame:CGRectMake(0, [self getBoardViewBottomOriginY], self.frame.size.width, Height_EmojBoardView)
                 delegate:self];
        for (id<NCEmoticonTabSource> source in
             [[NCChatUIExtensionService sharedService] getEmoticonTabList:self.channelType channelId:self.channelId]) {
            [_emojiBoardView addExtensionEmojiTab:source];
        };
        _emojiBoardView.hidden = YES;
        _emojiBoardView.delegate = self;
        _emojiBoardView.channelType = self.channelType;
        _emojiBoardView.channelId = self.channelId;
        [self.containerView addSubview:_emojiBoardView];
    }
    return _emojiBoardView;
}

- (NCPluginBoardView *)pluginBoardView {
    if (!_pluginBoardView) {
        _pluginBoardView = [[NCPluginBoardView alloc]
            initWithFrame:CGRectMake(0, [self getBoardViewBottomOriginY], self.containerView.bounds.size.width,
                                     Height_PluginBoardView)];

        // Add the default plugin items before app-provided custom items.
        [_pluginBoardView insertItem:NCDynamicImage(@"channel_plugin_item_picture_img")
                    highlightedImage:NCDynamicImage(@"channel_plugin_item_picture_highlighted_img")
                               title:NCUILocalizedString(@"photos")
                             atIndex:0
                                 tag:PLUGIN_BOARD_ITEM_ALBUM_TAG];
        
        [_pluginBoardView insertItem:NCDynamicImage(@"channel_plugin_item_camera_img")
                    highlightedImage:NCDynamicImage(@"channel_plugin_item_camera_highlighted_img")
                               title:NCUILocalizedString(@"camera")
                             atIndex:1
                                 tag:PLUGIN_BOARD_ITEM_CAMERA_TAG];

        NSInteger index = 100;
        NSArray *pluginItemInfoList =
            [[NCChatUIExtensionService sharedService] getPluginBoardItemInfoList:self.channelType
                                                                  channelId:self.channelId];
        for (NCChatUIExtensionPluginItemInfo *itemInfo in pluginItemInfoList) {
            NSInteger tag;
            if (itemInfo.tag > 0) {
                tag = itemInfo.tag;
            } else {
                tag = PLUGIN_BOARD_ITEM_RED_PACKET_TAG;
            }
            [self.pluginBoardView insertItem:itemInfo.normalImage highlightedImage:itemInfo.highlightedImage title:itemInfo.title atIndex:index tag:tag];
            [self.pluginTapBlockDic setObject:itemInfo.tapBlock forKey:@(tag)];
            index++;
        }
        NCLogF(@"pluginItemInfoList count:==============> %ld", (long)pluginItemInfoList.count);
        _pluginBoardView.hidden = YES;
        _pluginBoardView.pluginBoardDelegate = self;
        [self.containerView addSubview:_pluginBoardView];
    }
    return _pluginBoardView;
}

- (NSMutableArray *)mentionedRangeInfoList {
    if (!_mentionedRangeInfoList) {
        _mentionedRangeInfoList = [[NSMutableArray alloc] init];
    }
    return _mentionedRangeInfoList;
}

- (void)setDraft:(NSString *)draft {
    if (draft && draft.length > 0) {
        __autoreleasing NSError *error = nil;
        NSData *draftData = [draft dataUsingEncoding:NSUTF8StringEncoding];
        if (draftData) {
            NSDictionary *draftDict =
                [NSJSONSerialization JSONObjectWithData:draftData options:kNilOptions error:&error];
            if (!error && [draftDict count] > 0) {
                if ([draftDict.allKeys containsObject:@"draftContent"]) {
                    draft = [draftDict objectForKey:@"draftContent"];
                }
                NSArray *mentionedRangeInfoList = [draftDict objectForKey:@"mentionedRangeInfoList"];
                for (NSString *mentionedInfoString in mentionedRangeInfoList) {
                    NCMentionedStringRangeInfo *mentionedInfo =
                        [[NCMentionedStringRangeInfo alloc] initWithDecodeString:mentionedInfoString];
                    if (mentionedInfo) {
                        [self.mentionedRangeInfoList addObject:mentionedInfo];
                    }
                }
                if ([self.delegate respondsToSelector:@selector(didSetDraft:)]) {
                    [self.delegate didSetDraft:draftDict];
                }
            }
        }

        self.inputTextView.text = draft;
    }
}

- (NSString *)draft {
    NSString *draft = self.inputTextView.text;
    if (draft.length > 0) {
        NSMutableDictionary *dataDict = [NSMutableDictionary new];
        [dataDict setObject:draft forKey:@"draftContent"];

        if ([self.dataSource respondsToSelector:@selector(getDraftExtraInfo)]) {
            NSDictionary *dict = [self.dataSource getDraftExtraInfo];
            if ([dict isKindOfClass:[NSDictionary class]]) {
                [dataDict addEntriesFromDictionary:dict];
            }
        }

        NSMutableArray *mentionedRangeInfoList = [NSMutableArray new];
        for (NCMentionedStringRangeInfo *mentionedInfo in self.mentionedRangeInfoList) {
            NSString *mentionedInfoString = [mentionedInfo encodeToString];
            if (mentionedInfoString) {
                [mentionedRangeInfoList addObject:mentionedInfoString];
            }
        }

        // Store the mentioned-user metadata with the draft.
        if (mentionedRangeInfoList.count > 0) {
            [dataDict setObject:mentionedRangeInfoList forKey:@"mentionedRangeInfoList"];
        }
        NSData *data = [NSJSONSerialization dataWithJSONObject:dataDict options:kNilOptions error:nil];
        draft = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        return draft;
    }
    return draft;
}

- (NCMentionedInfo *)mentionedInfo {
    NSArray<NSString *> *mentionedUserIdList = self.mentionedUserIdList;
    if (mentionedUserIdList.count > 0) {
        NCMentionedInfo *mentionedInfo = [[NCMentionedInfo alloc] initWithType:NCMentionedTypeUsers
                                                                     userIdList:mentionedUserIdList
                                                               mentionedContent:nil];
        //    [self.mentionedRangeInfoList removeAllObjects];
        return mentionedInfo;
    }
    return nil;
}

- (NSArray<NSString *> *)mentionedUserIdList {
    if (self.mentionedRangeInfoList.count == 0) {
        return nil;
    }
    NSMutableArray<NSString *> *mentionedUserIdList = [[NSMutableArray alloc] init];
    for (NCMentionedStringRangeInfo *mentionedInfo in self.mentionedRangeInfoList) {
        if (mentionedInfo.userId.length > 0) {
            [mentionedUserIdList addObject:mentionedInfo.userId];
        }
    }
    return mentionedUserIdList.copy;
}

- (CGFloat)inputBarHeight {
    return NC_ChatSessionInputBar_Height;
}

- (NCVoiceRecordControl *)voiceRecordControl {
    if (!_voiceRecordControl) {
        _voiceRecordControl = [[NCVoiceRecordControl alloc] initWithConversationType:self.channelType];
        _voiceRecordControl.delegate = self;
    }
    return _voiceRecordControl;
}

- (CALayer *)topLineLayer {
    if (!_topLineLayer) {
        CALayer *layer = [CALayer layer];
        layer.frame = CGRectMake(0, 0, self.frame.size.width, 0.5);
        layer.backgroundColor = NCDynamicColor(@"clear_color").CGColor;
        _topLineLayer = layer;
    }
    return _topLineLayer;
}

- (void)addBottomAreaView {
    CGFloat bottom = [NCChatUIUtility getWindowSafeAreaInsets].bottom;
    if (bottom > 0) {
        UIView * bottomAreaView= [[UIView alloc] initWithFrame:CGRectMake(0, self.containerView.bounds.size.height - bottom,
                                                                          self.containerView.bounds.size.width, bottom)];
        bottomAreaView.backgroundColor = NCDynamicColor(@"auxiliary_background_1_color");
        self.safeAreaView = bottomAreaView;
        [self.containerView addSubview:bottomAreaView];
    }
}

- (void)setCurrentBottomBarStatus:(KBottomBarStatus)currentBottomBarStatus {
    self.inputContainerView.currentBottomBarStatus = currentBottomBarStatus;
}

- (KBottomBarStatus)currentBottomBarStatus {
    return self.inputContainerView.currentBottomBarStatus;
}

- (NSInteger)maxInputLines {
    return self.inputContainerView.maxInputLines;
}

- (void)setMaxInputLines:(NSInteger)maxInputLines {
    self.inputContainerView.maxInputLines = maxInputLines;
}
@end
