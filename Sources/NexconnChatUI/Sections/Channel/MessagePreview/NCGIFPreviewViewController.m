//
//  NCGIFPreviewViewController.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCGIFPreviewViewController.h"
#import "NCGIFImage.h"
#import "NCChatUIUtility.h"
#import "NCChatUICommonDefine.h"
#import "NCAssetHelper.h"
#import "NCChatUI.h"
#import "NCAlertView.h"
#import "NCActionSheetView.h"
#import "NCSemanticContext.h"
#import "NCMBProgressHUD.h"
#import "NCGIFUtility.h"

@interface NCGIFPreviewViewController () <NCChatUIMessageEventObserver>

@property (nonatomic, strong) NSData *gifData;

// View used to display the GIF.
@property (nonatomic, strong) NCGIFImageView *gifView;

@property (nonatomic, strong) NCMBProgressHUD *progressHUD;

@end

@implementation NCGIFPreviewViewController
#pragma mark - Life Cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = NCDynamicColor(@"common_background_color");
    [self setNav];
    [self addSubViews];
    [self configModel];
    [self registerNotificationCenter];
}

- (void)dealloc {
    [[NCChatUI shared] removeMessageEventObserver:self];
}

#pragma mark - Data Handling
- (void)configModel {
    if (!self.messageModel && !self.messageModel.content) {
        return;
    }
    NCGIFMessage *gifMessage = (NCGIFMessage *)self.messageModel.content;
    if (gifMessage.localPath.length > 0) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            self.gifData = [NSData dataWithContentsOfFile:gifMessage.localPath];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self.gifData) {
                    self.gifView.animatedImage = [NCGIFImage animatedImageWithGIFData:self.gifData];
                }
            });
        });
    } else if (gifMessage.remoteUrl.length > 0) {
        self.progressHUD =
            [NCMBProgressHUD showHUDAddedTo:self.view animated:YES];
        self.progressHUD.label.text = NCUILocalizedString(@"file_is_downloading");
        self.progressHUD.bezelView.style = NCMBProgressHUDBackgroundStyleSolidColor;
        self.progressHUD.bezelView.color = [UIColor clearColor];
        
        __weak typeof(self) weakSelf = self;
        [NCBaseChannel downloadMediaUrl:gifMessage.remoteUrl
                               fileName:[NCGIFUtility downloadFileNameForMessageName:gifMessage.name
                                                                     mediaURLString:gifMessage.remoteUrl]
                        progressHandler:nil
                      completionHandler:^(NSString * _Nullable mediaPath, NCError * _Nullable error) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (error || mediaPath.length == 0) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    strongSelf.progressHUD.label.text = NCUILocalizedString(@"file_download_failed");
                    [strongSelf.progressHUD hideAnimated:YES afterDelay:1];
                    strongSelf.progressHUD = nil;
                });
                return;
            }
            // Save the downloaded file path.
            gifMessage.localPath = mediaPath;
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                strongSelf.gifData = [NSData dataWithContentsOfFile:mediaPath];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [strongSelf.progressHUD hideAnimated:YES];
                    strongSelf.progressHUD = nil;
                    if (strongSelf.gifData) {
                        strongSelf.gifView.animatedImage = [NCGIFImage animatedImageWithGIFData:strongSelf.gifData];
                    }
                });
            });
        }
                          cancelHandler:nil];
    }
}


- (void)saveGIF {
    NCGIFMessage *gifMessage =
        (NCGIFMessage *)self.messageModel.content;
    if (gifMessage.localPath.length > 0) {
        [NCAssetHelper savePhotosAlbumWithPath:gifMessage.localPath authorizationStatusBlock:^{
            [self showAlertController:NCUILocalizedString(@"access_right_title")
                              message:NCUILocalizedString(@"photo_access_right")
                          cancelTitle:NCUILocalizedString(@"ok")];
        } resultBlock:^(BOOL success) {
            [self showAlertWithSuccess:success];
        }];

    }
}

- (void)showAlertWithSuccess:(BOOL)success {
    if (success) {
        NCLogD(@"save image suceed");
        [self showAlertController:nil
                          message:NCUILocalizedString(@"save_photo_success")
                      cancelTitle:NCUILocalizedString(@"ok")];
    } else {
        NCLogD(@" save image fail");
        [self showAlertController:nil
                          message:NCUILocalizedString(@"save_photo_failed")
                      cancelTitle:NCUILocalizedString(@"ok")];
    }
}

#pragma mark - Notification
- (void)registerNotificationCenter {
    [[NCChatUI shared] addMessageEventObserver:self];
}

- (void)onDeletedMessagesForAll:(NSArray<NCMessage *> *)messages {
    if (messages.count == 0) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        BOOL isCurrentMessageDeletedForAll = NO;
        for (NCMessage *message in messages) {
            if (message.clientId == self.messageModel.clientId) {
                isCurrentMessageDeletedForAll = YES;
                break;
            }
        }
        // Dismiss the preview only when the GIF being viewed is deleted for everyone.
        if (isCurrentMessageDeletedForAll) {
            UIAlertController *alertController = [UIAlertController
                alertControllerWithTitle:nil
                                 message:NCUILocalizedString(@"message_delete_for_all_alert")
                          preferredStyle:UIAlertControllerStyleAlert];
            [alertController
                addAction:[UIAlertAction actionWithTitle:NCUILocalizedString(@"confirm")
                                                   style:UIAlertActionStyleDefault
                                                 handler:^(UIAlertAction *_Nonnull action) {
                                                     [self.navigationController popViewControllerAnimated:YES];
                                                 }]];
            [self.navigationController presentViewController:alertController animated:YES completion:nil];
        }
    });
}

#pragma mark - Private Methods

- (void)setNav {
    // Configure the left navigation item.
    UIImage *imgMirror = NCDynamicImage(@"navigation_bar_btn_back_img");
    imgMirror = [NCSemanticContext imageflippedForRTL:imgMirror];
    self.navigationItem.leftBarButtonItems = [NCChatUIUtility getLeftNavigationItems:imgMirror title:NCUILocalizedString(@"back") target:self action:@selector(clickBackBtn:)];
}

- (void)addSubViews {
    [self.view addSubview:self.gifView];
    // A long press lets the user choose whether to save the image.
    UILongPressGestureRecognizer *longPress =
        [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressed:)];
    [self.view addGestureRecognizer:longPress];
}


- (void)clickBackBtn:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)longPressed:(id)sender {
    UILongPressGestureRecognizer *press = (UILongPressGestureRecognizer *)sender;
    if (press.state == UIGestureRecognizerStateEnded) {
        return;
    } else if (press.state == UIGestureRecognizerStateBegan) {
        [NCActionSheetView showActionSheetView:nil cellArray:@[NCUILocalizedString(@"save")] cancelTitle:NCUILocalizedString(@"cancel") selectedBlock:^(NSInteger index) {
            [self saveGIF];
        } cancelBlock:^{
                
        }];
    }
}

- (void)showAlertController:(NSString *)title message:(NSString *)message cancelTitle:(NSString *)cancelTitle {
    [NCAlertView showAlertController:title message:message cancelTitle:cancelTitle inViewController:self];
}

- (CGFloat)getSafeAreaExtraBottomHeight {
    return [NCChatUIUtility getWindowSafeAreaInsets].bottom;
}

- (CGFloat)getDeviceNavBarHeight {
    return [NCChatUIUtility getWindowSafeAreaInsets].top;
}

#pragma mark - Getter & Setter
- (NCGIFImageView *)gifView {
    if (!_gifView) {
        CGRect viewFrame = self.view.bounds;
        CGFloat homeBarHeight = [self getSafeAreaExtraBottomHeight];
        CGFloat NavBarHeight = [self getDeviceNavBarHeight];
        _gifView = [[NCGIFImageView alloc]
            initWithFrame:CGRectMake(0, 0, viewFrame.size.width, viewFrame.size.height - NavBarHeight - homeBarHeight)];
        _gifView.userInteractionEnabled = YES;
        _gifView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _gifView;
}
@end
