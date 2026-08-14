//
//  NCFilePreviewViewController.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCFilePreviewViewController.h"
#import "NCChatUI.h"
#import "NCChatUIErrorCode.h"
#import "NCChatUICommonDefine.h"
#import "NCChatUIUtility.h"
#import <WebKit/WebKit.h>
#import "NCChatUIConfig.h"
#import "NCAlertView.h"
#import "NCActionSheetView.h"
#import "NCSemanticContext.h"
#import "NCButton.h"
#import "NCBaseImageView.h"
#import "NCFileUtility.h"
extern NSString *const NCUIDispatchDownloadMediaNotification;

@interface NCFilePreviewViewController () <NCChatUIMessageEventObserver>

@property (nonatomic, strong) NCFileMessage *fileMessage;
@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *sizeLabel;
@property (nonatomic, strong) UILabel *progressLabel;
@property (nonatomic, strong) NCBaseImageView *typeIconView;
@property (nonatomic, strong) NCBaseButton *downloadButton;
@property (nonatomic, strong) NCBaseButton *openInOtherAppButton;
@property (nonatomic, strong) NCBaseButton *cancelButton;

@property (nonatomic, assign) BOOL isVCPoped;

@end

@implementation NCFilePreviewViewController
#pragma mark - Life Cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = NCDynamicColor(@"auxiliary_background_1_color");
    self.title = NCUILocalizedString(@"preview_file");
    // self.view.frame starts below the navigation bar.
    self.edgesForExtendedLayout = UIRectEdgeNone;

    [self registerNotificationCenter];
    
    [self setNavigationItems];
    [self setupSubViews];
    if ([self isFileDownloaded] && [self isFileSupported]) {
        [self layoutAndPreviewFile];
    } else {
        [self layoutForShowFileInfo];
    }
}

- (void)dealloc {
    self.isVCPoped = YES;
    [self p_stopWebView];
    [[NCChatUI shared] removeMessageEventObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Notification
- (void)registerNotificationCenter {
    [[NCChatUI shared] addMessageEventObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateDownloadMediaStatus:)
                                                 name:NCUIDispatchDownloadMediaNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(windowDidBecomeKeyNotification)
                                                 name:UIWindowDidBecomeKeyNotification
                                               object:nil];
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
        // Dismiss the preview only when the file being viewed is deleted for everyone.
        void (^recallAlertAction)(void) = ^(void) {
            [NCAlertView showAlertController:nil message:NCUILocalizedString(@"message_delete_for_all_alert") actionTitles:nil cancelTitle:NCUILocalizedString(@"confirm") confirmTitle:nil preferredStyle:UIAlertControllerStyleAlert actionsBlock:nil cancelBlock:^{
                [self.navigationController popViewControllerAnimated:YES];
            } confirmBlock:nil inViewController:self.navigationController];
        };
        
        if (isCurrentMessageDeletedForAll) {
            if (self.presentedViewController) { // Dismiss the download cancellation alert before handling deletion.
                [self.presentedViewController dismissViewControllerAnimated:NO completion:^{
                    recallAlertAction();
                }];
            } else {
                recallAlertAction();
            }
        }
    });
}

- (void)updateDownloadMediaStatus:(NSNotification *)notify {
    NSDictionary *statusDic = notify.userInfo;
    if (self.messageModel.clientId == [statusDic[@"clientId"] longValue]) {
        if ([statusDic[@"type"] isEqualToString:@"progress"]) {
            float progress = (float)[statusDic[@"progress"] intValue] / 100.0f;
            [self downloading:progress];
        } else if ([statusDic[@"type"] isEqualToString:@"success"]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                // Do not start preview or playback after the view controller has been popped.
                if (self.isVCPoped) {
                    return;
                }
                
                self.fileMessage.localPath = statusDic[@"mediaPath"];
                if ([self isFileSupported]) {
                    [self layoutAndPreviewFile];
                } else {
                    [self layoutForShowFileInfo];
                }
            });
        } else if ([statusDic[@"type"] isEqualToString:@"error"]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self layoutForShowFileInfo];
                if ([statusDic[@"errorCode"] intValue] == NCChatUIErrorCodeNetworkUnavailable) {
                    [self showAlertController:NCUILocalizedString(@"connection_is_not_reachable")];
                } else {
                    [self showAlertController:NCUILocalizedString(@"file_download_failed")];
                }
            });
        } else if ([statusDic[@"type"] isEqualToString:@"cancel"]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self layoutForShowFileInfo];
                [self showAlertController:NCUILocalizedString(@"file_download_canceled")];
            });
        }
    }
}

- (void)windowDidBecomeKeyNotification {
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
}

#pragma mark - Private Methods
- (void)setupSubViews {
    [self.view addSubview:self.webView];
    [self.view addSubview:self.typeIconView];
    [self.view addSubview:self.nameLabel];
    [self.view addSubview:self.sizeLabel];
    [self.view addSubview:self.progressLabel];
    [self.view addSubview:self.cancelButton];
    [self.view addSubview:self.downloadButton];
    [self.view addSubview:self.openInOtherAppButton];
    [self.view bringSubviewToFront:self.cancelButton];
}

- (void)layoutForShowFileInfo {
    self.webView.hidden = YES;
    self.navigationItem.rightBarButtonItem.enabled = NO;

    self.typeIconView.hidden = NO;
    self.nameLabel.hidden = NO;
    self.sizeLabel.hidden = NO;
    self.sizeLabel.textColor = NCDynamicColor(@"text_secondary_color");
    self.cancelButton.hidden = YES;
    self.progressLabel.hidden = YES;
    if ([self isFileDownloaded]) {
        self.downloadButton.hidden = YES;
        self.openInOtherAppButton.hidden = NO;
    } else {
        self.downloadButton.hidden = NO;
        self.openInOtherAppButton.hidden = YES;
    }
}

- (void)layoutForDownloading {
    self.webView.hidden = YES;
    self.navigationItem.rightBarButtonItem.enabled = NO;

    self.typeIconView.hidden = NO;
    self.nameLabel.hidden = NO;
    self.sizeLabel.hidden = YES;
    self.downloadButton.hidden = YES;
    self.openInOtherAppButton.hidden = YES;
    self.cancelButton.hidden = NO;

    
    self.progressLabel.hidden = NO;
}

- (void)layoutAndPreviewFile {
    self.webView.hidden = NO;
    self.navigationItem.rightBarButtonItem.enabled = YES;

    self.typeIconView.hidden = YES;
    self.nameLabel.hidden = YES;
    self.sizeLabel.hidden = YES;
    self.downloadButton.hidden = YES;
    self.openInOtherAppButton.hidden = YES;
    self.cancelButton.hidden = YES;
    self.progressLabel.hidden = YES;

    if ([self.fileMessage.fileType isEqualToString:@"txt"]) {
        [self transformEncodingFromFilePath:self.fileMessage.localPath];
    }
    if (self.fileMessage.localPath) {
        NSURL *fileURL = [NSURL fileURLWithPath:self.fileMessage.localPath];
        // Use the request-based API for iOS 8 compatibility.
        if ([UIDevice currentDevice].systemVersion.floatValue < 9.0) {
            [self.webView loadRequest:[NSURLRequest requestWithURL:fileURL]];
            return;
        }
        if ([self.fileMessage.fileType isEqualToString:@"txt"]) {
            NSData *data = [NSData dataWithContentsOfURL:fileURL];
            // Load the file data with an explicit text MIME type and encoding.
            [self.webView loadData:data
                             MIMEType:@"text/plain"
                characterEncodingName:@"UTF-8"
                              baseURL:[NSURL fileURLWithPath:NSHomeDirectory()]];
        } else {
            [self.webView loadFileURL:fileURL allowingReadAccessToURL:fileURL];
        }
    }
}

- (void)moreAction {
    [NCActionSheetView showActionSheetView:nil cellArray:@[NCUILocalizedString(@"open_file_in_other_app")] cancelTitle:NCUILocalizedString(@"cancel") selectedBlock:^(NSInteger index) {
        [self openInOtherApp:self.fileMessage.localPath];
    } cancelBlock:^{
            
    }];
}

- (void)clickBackBtn:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
    self.isVCPoped = YES;
    [self p_stopWebView];
}

- (void)p_stopWebView {
    self.webView.hidden = YES;
    [self.webView stopLoading];
    [self.webView removeFromSuperview];
    self.webView = nil;
}

- (void)openInOtherApp:(NSString *)localPath {
    if (!localPath) {
        NCLogReleaseW(@"Localpath does not allow nil");
        return;
    }
    UIActivityViewController *activityVC =
        [[UIActivityViewController alloc] initWithActivityItems:@[ [NSURL fileURLWithPath:localPath] ]
                                          applicationActivities:nil];
    activityVC.modalPresentationStyle = UIModalPresentationFullScreen;
    if ([NCChatUIUtility currentDeviceIsIPad]) {
        UIPopoverPresentationController *popPresenter = [activityVC popoverPresentationController];
        UIWindow *window = [NCChatUIUtility getWindowForView:self.view];
        popPresenter.sourceView = window;
        popPresenter.sourceRect = CGRectMake(window.frame.size.width / 2, window.frame.size.height / 2, 0, 0);
        popPresenter.permittedArrowDirections = 0;
    }
    [self presentViewController:activityVC animated:YES completion:nil];
}

- (void)openCurrentFileInOtherApp {
    [self openInOtherApp:self.fileMessage.localPath];
}

- (void)startFileDownLoad {
    [self downloading:0];
    // 已持久化的直接文件消息走 message-based 下载（底层 unique_id = rc_message[clientId]），
    // 使发送端撤回时底层 cancel_download_media_message(clientId) 能命中并取消在途下载，与 Android 对齐。
    // 引用文件（NCReferenceMessage）与合并转发预览（合成负 clientId）不满足条件，仍走 URL-based 下载。
    if (self.messageModel.clientId > 0 &&
        [self.messageModel.content isKindOfClass:[NCFileMessage class]]) {
        [[NCChatUI shared] downloadMediaMessage:self.messageModel.clientId
                                       progress:nil
                                     completion:nil
                                         cancel:nil];
        return;
    }
    NSString *mediaUrl = self.fileMessage.remoteUrl ?: @"";
    NSString *fileName = [NCFileUtility recheckedFileName:self.fileMessage.name ?: mediaUrl.lastPathComponent ?: @""];
    if (mediaUrl.length == 0 || fileName.length == 0) {
        NSDictionary *statusDic = @{
            @"clientId" : @(self.messageModel.clientId),
            @"type" : @"error",
            @"errorCode" : @(NCChatUIErrorCodeUnknown)
        };
        [[NSNotificationCenter defaultCenter] postNotificationName:NCUIDispatchDownloadMediaNotification
                                                            object:nil
                                                          userInfo:statusDic];
        return;
    }
    [NCBaseChannel downloadMediaUrl:mediaUrl
                           fileName:fileName
                    progressHandler:^(NSInteger progress) {
        NSDictionary *statusDic = @{
            @"clientId" : @(self.messageModel.clientId),
            @"type" : @"progress",
            @"progress" : @(progress)
        };
        [[NSNotificationCenter defaultCenter] postNotificationName:NCUIDispatchDownloadMediaNotification
                                                            object:nil
                                                          userInfo:statusDic];
    } completionHandler:^(NSString * _Nullable mediaPath, NCError * _Nullable error) {
        if (error || mediaPath.length == 0) {
            NSDictionary *statusDic = @{
                @"clientId" : @(self.messageModel.clientId),
                @"type" : @"error",
                @"errorCode" : @(error ? error.code : NCChatUIErrorCodeUnknown)
            };
            [[NSNotificationCenter defaultCenter] postNotificationName:NCUIDispatchDownloadMediaNotification
                                                                object:nil
                                                              userInfo:statusDic];
            return;
        }
        // URL-based 下载底层不写 URL→本地路径映射，此处补写，供重进详情页 fileLocalPathForRemoteURL: 检测已下载状态
        // （合并转发/引用文件的合成消息无持久化 clientId，只能靠该映射恢复）
        [NCFileUtility setFileLocalPath:mediaPath forRemoteURL:mediaUrl];
        NSDictionary *statusDic = @{
            @"clientId" : @(self.messageModel.clientId),
            @"type" : @"success",
            @"mediaPath" : mediaPath
        };
        [[NSNotificationCenter defaultCenter] postNotificationName:NCUIDispatchDownloadMediaNotification
                                                            object:nil
                                                          userInfo:statusDic];
    } cancelHandler:^{
        NSDictionary *statusDic = @{
            @"clientId" : @(self.messageModel.clientId),
            @"type" : @"cancel"
        };
        [[NSNotificationCenter defaultCenter] postNotificationName:NCUIDispatchDownloadMediaNotification
                                                            object:nil
                                                          userInfo:statusDic];
    }];
}

- (void)cancelFileDownload {
    // 与 startFileDownLoad 对称：message-based 下载的文件消息用 message-based 取消（rc_message[clientId]）。
    if (self.messageModel.clientId > 0 &&
        [self.messageModel.content isKindOfClass:[NCFileMessage class]]) {
        [[NCChatUI shared] cancelDownloadMediaMessage:self.messageModel.clientId];
        return;
    }
    NSString *mediaUrl = self.fileMessage.remoteUrl ?: @"";
    if (mediaUrl.length == 0) {
        return;
    }
    [NCBaseChannel cancelDownloadMediaUrl:mediaUrl completion:^(NCError * _Nullable error) {
        NSDictionary *statusDic = nil;
        if (error) {
            statusDic = @{
                @"clientId" : @(self.messageModel.clientId),
                @"type" : @"error",
                @"errorCode" : @(error.code)
            };
        } else {
            statusDic = @{
                @"clientId" : @(self.messageModel.clientId),
                @"type" : @"cancel"
            };
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:NCUIDispatchDownloadMediaNotification
                                                            object:nil
                                                          userInfo:statusDic];
    }];
}

- (void)showAlertController:(NSString *)message {
    [NCAlertView showAlertController:nil message:message cancelTitle:NCUILocalizedString(@"ok") inViewController:self];
}

- (void)downloading:(float)progress {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self layoutForDownloading];
        self.sizeLabel.textColor = NCDynamicColor(@"primary_color");
        self.progressLabel.text = [NSString
            stringWithFormat:@"%@(%@/%@)", NCUILocalizedString(@"file_is_downloading"),
                             [NCChatUIUtility getReadableStringForFileSize:progress * self.fileMessage.size],
                             [NCChatUIUtility getReadableStringForFileSize:self.fileMessage.size]];
    });
}

- (BOOL)isFileDownloading {
    // todo
    return NO;
}

- (BOOL)isFileDownloaded {
    if (self.fileMessage.localPath.length > 0 && [NCFileUtility isFileExist:self.fileMessage.localPath]) {
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)isFileSupported {
    if (![[NCChatUIUtility getFileTypeIcon:self.fileMessage.fileType] isEqualToString:@"OtherFile"]) {
        return YES;
    } else {
        return NO;
    }
}

#pragma mark - Text File Encoding
- (NSString *)examineTheFilePathStr:(NSString *)str {
    NSStringEncoding *useEncodeing = nil; // Detect encodings with a byte-order mark, such as UTF-8.
    NSString *body = [NSString
        stringWithContentsOfFile:str
                    usedEncoding:useEncodeing
                           error:
                               nil];
    if (!body) {
        // If detection fails, try GB18030 first (0x80000632).
        body = [NSString stringWithContentsOfFile:str encoding:0x80000632 error:nil];
    }
    if (!body) {
        // If GB18030 fails, fall back to GBK (0x80000631).
        body = [NSString stringWithContentsOfFile:str encoding:0x80000631 error:nil];
    }
    return body;
}

- (void)transformEncodingFromFilePath:(NSString *)filePath {       // Decode the file into a valid string.
    NSString *body = [self examineTheFilePathStr:filePath];        // Read and decode the file contents.
    NSData *data = [body dataUsingEncoding:NSUTF16StringEncoding]; // Replace the original file with UTF-16 data.
    [data writeToFile:filePath atomically:YES];                    // Subsequent reads use the normalized encoding.
}

- (void)setNavigationItems {
    // Configure the right navigation item.
    
    NCButton *rightBtn = [NCButton buttonWithType:UIButtonTypeCustom];
//    rightBtn.imageEdgeInsets = UIEdgeInsetsMake(8, 8, 8, 8);
    rightBtn.imageView.contentMode = UIViewContentModeScaleAspectFit;
    UIImage *rightImage = NCDynamicImage(@"file_preview_forward_img");
    [rightBtn setImage:rightImage forState:UIControlStateNormal];
    [rightBtn addTarget:self action:@selector(moreAction) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:rightBtn];

    // Configure the left navigation item.
    UIImage *imgMirror = NCDynamicImage(@"navigation_bar_btn_back_img");
    imgMirror = [NCSemanticContext imageflippedForRTL:imgMirror];
    self.navigationItem.leftBarButtonItems = [NCChatUIUtility getLeftNavigationItems:imgMirror title:NCUILocalizedString(@"back") target:self action:@selector(clickBackBtn:)];
}

#pragma mark - Getters and Setters

- (WKWebView *)webView {
    if (!_webView) {
        //获取状态栏的rect
        CGFloat statusBarHeight = [NCChatUIUtility getStatusBarHeightForView:self.view];
        //获取导航栏的rect
        CGRect navRect = self.navigationController.navigationBar.frame;
        //那么导航栏+状态栏的高度
        CGFloat totalHeight = statusBarHeight + navRect.size.height;
        CGRect webViewRect = self.view.bounds;
        if (webViewRect.size.height > ([UIScreen mainScreen].bounds.size.height - totalHeight)) {
            webViewRect.size.height -= totalHeight;
        }
        _webView = [[WKWebView alloc] initWithFrame:webViewRect];
        _webView.scrollView.contentInset = (UIEdgeInsets){8, 8, 8, 8};
        [_webView sizeToFit];
        _webView.backgroundColor = NCDynamicColor(@"auxiliary_background_1_color");
        [_webView setOpaque:NO];
    }
    return _webView;
}

- (NCBaseImageView *)typeIconView {
    if (!_typeIconView) {
        _typeIconView =
            [[NCBaseImageView alloc] initWithFrame:CGRectMake((self.view.bounds.size.width - 75) / 2, 64, 75, 75)];
        _typeIconView.image = [NCChatUIUtility imageWithFileSuffix:self.fileMessage.fileType];
    }

    return _typeIconView;
}

- (UILabel *)nameLabel {
    if (!_nameLabel) {
        _nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, CGRectGetMaxY(self.typeIconView.frame)+16, self.view.bounds.size.width - 10 * 2, 21)];
        _nameLabel.font = [[NCChatUIConfig defaultConfig].font fontOfSecondLevel];
        _nameLabel.text = self.fileMessage.name;
        _nameLabel.textAlignment = NSTextAlignmentCenter;
        _nameLabel.textColor = NCDynamicColor(@"text_primary_color");
        _nameLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    }
    return _nameLabel;
}

- (UILabel *)sizeLabel {
    if (!_sizeLabel) {
        _sizeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.nameLabel.frame)+12, self.view.bounds.size.width, 16)];
        _sizeLabel.font = [[NCChatUIConfig defaultConfig].font fontOfAnnotationLevel];
        _sizeLabel.text = [NCChatUIUtility getReadableStringForFileSize:self.fileMessage.size];
        _sizeLabel.textAlignment = NSTextAlignmentCenter;
        _sizeLabel.textColor = NCDynamicColor(@"text_secondary_color");
    }
    return _sizeLabel;
}

- (UILabel *)progressLabel {
    if (!_progressLabel) {
        _progressLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, CGRectGetMaxY(self.nameLabel.frame)+12, self.view.bounds.size.width - 10 * 2, 16)];
        _progressLabel.textColor = NCDynamicColor(@"primary_color");
        _progressLabel.textAlignment = NSTextAlignmentCenter;
        _progressLabel.font = [[NCChatUIConfig defaultConfig].font fontOfAnnotationLevel];
    }
    return _progressLabel;
}

- (NCBaseButton *)cancelButton {
    if (!_cancelButton) {
        _cancelButton = [[NCBaseButton alloc] initWithFrame:self.downloadButton.frame];
        [_cancelButton setTitle:NCUILocalizedString(@"cancel") forState:(UIControlStateNormal)];
        [_cancelButton addTarget:self
                          action:@selector(cancelFileDownload)
                forControlEvents:UIControlEventTouchUpInside];
        _cancelButton.backgroundColor = NCDynamicColor(@"primary_color");
        _cancelButton.layer.cornerRadius = 5.0f;
//        _cancelButton.layer.borderWidth = 0.5f;
//        _cancelButton.layer.borderColor = [HEXCOLOR(0x0181dd) CGColor];
    }
    return _cancelButton;
}

- (NCBaseButton *)downloadButton {
    if (!_downloadButton) {
        _downloadButton =
            [[NCBaseButton alloc] initWithFrame:CGRectMake(10, CGRectGetMaxY(self.sizeLabel.frame)+12, self.view.bounds.size.width - 10 * 2, 40)];
        _downloadButton.backgroundColor =NCDynamicColor(@"primary_color");
        _downloadButton.layer.cornerRadius = 5.0f;
//        _downloadButton.layer.borderWidth = 0.5f;
//        _downloadButton.layer.borderColor = [HEXCOLOR(0x0181dd) CGColor];
        [_downloadButton setTitle:NCUILocalizedString(@"start_download_file")
                         forState:UIControlStateNormal];
        [_downloadButton addTarget:self
                            action:@selector(startFileDownLoad)
                  forControlEvents:UIControlEventTouchUpInside];
    }
    return _downloadButton;
}

- (NCBaseButton *)openInOtherAppButton {
    if (!_openInOtherAppButton) {
        _openInOtherAppButton =
            [[NCBaseButton alloc] initWithFrame:self.downloadButton.frame];
        _openInOtherAppButton.backgroundColor = NCDynamicColor(@"primary_color");
        _openInOtherAppButton.layer.cornerRadius = 5.0f;
//        _openInOtherAppButton.layer.borderWidth = 0.5f;
//        _openInOtherAppButton.layer.borderColor = [HEXCOLOR(0x0181dd) CGColor];
        [_openInOtherAppButton setTitle:NCUILocalizedString(@"open_file_in_other_app")
                               forState:UIControlStateNormal];
        [_openInOtherAppButton addTarget:self
                                  action:@selector(openCurrentFileInOtherApp)
                        forControlEvents:UIControlEventTouchUpInside];
    }
    return _openInOtherAppButton;
}

- (NCFileMessage *)fileMessage {
    if (!_fileMessage) {
        if ([self.messageModel.content isKindOfClass:[NCReferenceMessage class]]) {
            NCReferenceMessage *refer = (NCReferenceMessage *)self.messageModel.content;
            return (NCFileMessage *)refer.referMsg;
        }
        return (NCFileMessage *)self.messageModel.content;
    }
    return _fileMessage;
}

@end
