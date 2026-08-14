//
//  NCCombineMsgFilePreviewViewController.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCCombineMsgFilePreviewViewController.h"
#import "NCChatUI.h"
#import "NCChatUIErrorCode.h"
#import "NCChatUICommonDefine.h"
#import "NCChatUIUtility.h"
#import <WebKit/WebKit.h>
#import "NCChatUIConfig.h"
#import "NCActionSheetView.h"
#import "NCSemanticContext.h"
#import "NCButton.h"
#import "NCBaseImageView.h"
#import "NCAlertView.h"
#import "NCFileUtility.h"

extern NSString *const NCUIDispatchDownloadMediaNotification;

@interface NCCombineMsgFilePreviewViewController ()

@property (nonatomic, copy) NSString *remoteURL;
@property (nonatomic, copy) NSString *localPath;
@property (nonatomic, copy) NSString *fileName;
@property (nonatomic, copy) NSString *fileType;
@property (nonatomic, assign) NCChannelType channelType;
@property (nonatomic, copy) NSString *channelId;
@property (nonatomic, assign) long long fileSize;
@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *sizeLabel;
@property (nonatomic, strong) UILabel *progressLabel;
@property (nonatomic, strong) NCBaseImageView *typeIconView;
@property (nonatomic, strong) UIProgressView *progressView;
@property (nonatomic, strong) NCBaseButton *downloadButton;
@property (nonatomic, strong) NCBaseButton *openInOtherAppButton;
@property (nonatomic, strong) NCBaseButton *cancelButton;

@property (nonatomic, assign) int extentLayoutForY;

@end

@implementation NCCombineMsgFilePreviewViewController
#pragma mark - Life Cycle
- (instancetype)initWithRemoteURL:(NSString *)remoteURL
                      channelType:(NCChannelType)channelType
                         channelId:(NSString *)channelId
                         fileSize:(long long)fileSize
                         fileName:(NSString *)fileName
                         fileType:(NSString *)fileType {
    if (self = [super init]) {
        self.remoteURL = remoteURL;
        self.channelType = channelType;
        self.channelId = channelId;
        self.fileSize = fileSize;
        self.fileName = [NCFileUtility recheckedFileName:fileName];
        self.fileType = fileType;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = NCDynamicColor(@"auxiliary_background_1_color");
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.title = NCUILocalizedString(@"preview_file");

    // Adjust the layout for a translucent navigation bar.
    if (self.navigationController.navigationBar.translucent) {
        self.extentLayoutForY = 64;
    } else {
        self.extentLayoutForY = 0;
    }
    // Configure the right navigation item.
    NCButton *rightBtn = [NCButton buttonWithType:UIButtonTypeCustom];
    rightBtn.imageView.contentMode = UIViewContentModeScaleAspectFit;
    UIImage *rightImage = NCDynamicImage(@"file_preview_forward_img");
    [rightBtn setImage:rightImage forState:UIControlStateNormal];
    [rightBtn addTarget:self action:@selector(moreAction) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:rightBtn];

    // Configure the left navigation item.
    UIImage *imgMirror = NCDynamicImage(@"navigation_bar_btn_back_img");
    imgMirror = [NCSemanticContext imageflippedForRTL:imgMirror];
    self.navigationItem.leftBarButtonItems = [NCChatUIUtility getLeftNavigationItems:imgMirror title:NCUILocalizedString(@"back") target:self action:@selector(clickBackBtn:)];

    [self registerNotificationCenter];
    [self setupSubviews];
    
    if ([self isFileDownloaded] && [self isFileSupported]) {
        [self layoutAndPreviewFile];
    } else {
        [self layoutForShowFileInfo];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Private Methods

- (void)registerNotificationCenter {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateDownloadMediaStatus:)
                                                 name:NCUIDispatchDownloadMediaNotification
                                               object:nil];
}

- (void)updateDownloadMediaStatus:(NSNotification *)notify {
    NSDictionary *statusDic = notify.userInfo;
    if (![self.remoteURL isEqualToString:statusDic[@"mediaUrl"]]) {
        return;
    }
    NSString *type = statusDic[@"type"];
    dispatch_main_async_safe(^{
        if ([type isEqualToString:@"progress"]) {
            [self layoutForDownloading];
            float progress = (float)[statusDic[@"progress"] intValue] / 100.0f;
            [self downloading:progress];
        } else if ([type isEqualToString:@"success"]) {
            self.localPath = statusDic[@"mediaPath"];
            if ([self isFileSupported]) {
                [self layoutAndPreviewFile];
            } else {
                [self layoutForShowFileInfo];
            }
        } else if ([type isEqualToString:@"error"]) {
            [self layoutForShowFileInfo];
            if ([statusDic[@"errorCode"] intValue] == NCChatUIErrorCodeNetworkUnavailable) {
                [self showAlertController:NCUILocalizedString(@"connection_is_not_reachable")];
            } else {
                [self showAlertController:NCUILocalizedString(@"file_download_failed")];
            }
        } else if ([type isEqualToString:@"cancel"]) {
            [self layoutForShowFileInfo];
            [self showAlertController:NCUILocalizedString(@"file_download_canceled")];
        }
    });
}


- (void)setupSubviews {
    [self.view addSubview:self.webView];
    [self.view addSubview:self.typeIconView];
    [self.view addSubview:self.nameLabel];
    [self.view addSubview:self.sizeLabel];
    [self.view addSubview:self.progressLabel];
    [self.view addSubview:self.progressView];
    [self.view addSubview:self.downloadButton];
    [self.view addSubview:self.openInOtherAppButton];
    [self.view addSubview:self.cancelButton];
    [self.view bringSubviewToFront:self.cancelButton];
}

- (void)startFileDownLoad {
    [self layoutForDownloading];
    [NCBaseChannel downloadMediaUrl:self.remoteURL
                           fileName:self.fileName
                    progressHandler:^(NSInteger progress){
                               (void)progress;
                           }
                  completionHandler:^(NSString * _Nullable mediaPath, NCError * _Nullable error) {
                               (void)mediaPath;
                               (void)error;
                           }
                      cancelHandler:^{
                      }];
}

- (void)showAlertController:(NSString *)message {
    [NCAlertView showAlertController:nil message:message cancelTitle:NCUILocalizedString(@"ok") inViewController:self];
}

- (void)downloading:(float)progress {
    [self.progressView setProgress:progress animated:YES];
    self.progressLabel.text =
        [NSString stringWithFormat:@"%@(%@/%@)", NCUILocalizedString(@"file_is_downloading"),
                                   [NCChatUIUtility getReadableStringForFileSize:progress * self.fileSize],
                                   [NCChatUIUtility getReadableStringForFileSize:self.fileSize]];
}

- (BOOL)isFileDownloaded {
    NSString *fileLocalPath = self.localPath;
    /// fileLocalPath is absolute and must be corrected when the sandbox path changes after relaunch.
    if (fileLocalPath) {
        fileLocalPath = [NCFileUtility correctedFilePath:fileLocalPath];
    }
    if ([NCFileUtility isFileExist:fileLocalPath]) {
        self.localPath = fileLocalPath;
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)isFileSupported {
    if (![[NCChatUIUtility getFileTypeIcon:self.fileType] isEqualToString:@"OtherFile"]) {
        return YES;
    } else {
        return NO;
    }
}

- (void)layoutForShowFileInfo {
    self.webView.hidden = YES;
    self.navigationItem.rightBarButtonItem.enabled = NO;

    self.typeIconView.hidden = NO;
    self.nameLabel.hidden = NO;
    self.sizeLabel.hidden = NO;
    self.progressView.hidden = YES;
    self.progressLabel.hidden = YES;
    self.cancelButton.hidden = YES;
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
    self.progressView.hidden = NO;
    self.progressLabel.hidden = NO;
    self.cancelButton.hidden = NO;
}

- (void)layoutAndPreviewFile {
    self.webView.hidden = NO;
    self.navigationItem.rightBarButtonItem.enabled = YES;

    self.typeIconView.hidden = YES;
    self.nameLabel.hidden = YES;
    self.sizeLabel.hidden = YES;
    self.downloadButton.hidden = YES;
    self.openInOtherAppButton.hidden = YES;
    self.progressView.hidden = YES;
    self.progressLabel.hidden = YES;
    self.cancelButton.hidden = YES;

    if ([self.fileType isEqualToString:@"txt"]) {
        [self transformEncodingFromFilePath:self.localPath];
    }
    if (self.localPath) {
        NSURL *fileURL = [NSURL fileURLWithPath:self.localPath];
        [self.webView loadFileURL:fileURL allowingReadAccessToURL:fileURL];
    }
}

- (void)moreAction {
    [NCActionSheetView showActionSheetView:nil cellArray:@[NCUILocalizedString(@"open_file_in_other_app")] cancelTitle:NCUILocalizedString(@"cancel") selectedBlock:^(NSInteger index) {
        [self openInOtherApp:self.localPath];
    } cancelBlock:^{
            
    }];
}

- (void)clickBackBtn:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)openInOtherApp:(NSString *)localPath {
    if (!localPath) {
        return;
    }
    UIActivityViewController *activityVC =
        [[UIActivityViewController alloc] initWithActivityItems:@[ [NSURL fileURLWithPath:localPath] ]
                                          applicationActivities:nil];
    if ([NCChatUIUtility currentDeviceIsIPad]) {
        UIPopoverPresentationController *popPresenter = [activityVC popoverPresentationController];
        UIWindow *window = [NCChatUIUtility getWindowForView:self.view];
        popPresenter.sourceView = window;
        popPresenter.sourceRect = CGRectMake(window.frame.size.width / 2, window.frame.size.height / 2, 0, 0);
        popPresenter.permittedArrowDirections = 0;
    }
    [self presentViewController:activityVC animated:YES completion:nil];
}

- (void)cancelFileDownload {
    [NCBaseChannel cancelDownloadMediaUrl:self.remoteURL completion:nil];
}

- (void)openCurrentFileInOtherApp {
    [self openInOtherApp:self.localPath];
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

#pragma mark - Getters and Setters
- (WKWebView *)webView {
    if (!_webView) {
        _webView = [[WKWebView alloc]
            initWithFrame:CGRectMake(0, self.extentLayoutForY, [UIScreen mainScreen].bounds.size.width,
                                     [UIScreen mainScreen].bounds.size.height - self.extentLayoutForY)];
        _webView.scrollView.contentInset = (UIEdgeInsets){8, 8, 8, 8};
        _webView.backgroundColor = NCDynamicColor(@"auxiliary_background_1_color");
        
    }
    return _webView;
}

- (NCBaseImageView *)typeIconView {
    if (!_typeIconView) {
        _typeIconView = [[NCBaseImageView alloc]
            initWithFrame:CGRectMake((self.view.bounds.size.width - 75) / 2, 30 + self.extentLayoutForY, 75, 75)];
        _typeIconView.image = [NCChatUIUtility imageWithFileSuffix:self.fileType];
    }

    return _typeIconView;
}

- (UILabel *)nameLabel {
    if (!_nameLabel) {
        _nameLabel = [[UILabel alloc]
            initWithFrame:CGRectMake(10, 122 + self.extentLayoutForY, self.view.bounds.size.width - 10 * 2, 21)];
        _nameLabel.font = [[NCChatUIConfig defaultConfig].font fontOfSecondLevel];
        _nameLabel.text = self.fileName;
        _nameLabel.textAlignment = NSTextAlignmentCenter;
        _nameLabel.textColor = NCDynamicColor(@"text_primary_color");
        _nameLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    }
    return _nameLabel;
}

- (UILabel *)sizeLabel {
    if (!_sizeLabel) {
        _sizeLabel =
            [[UILabel alloc] initWithFrame:CGRectMake(0, 151 + self.extentLayoutForY, self.view.bounds.size.width, 12)];
        _sizeLabel.font = [[NCChatUIConfig defaultConfig].font fontOfGuideLevel];
        _sizeLabel.text = [NCChatUIUtility getReadableStringForFileSize:self.fileSize];
        _sizeLabel.textAlignment = NSTextAlignmentCenter;
        _sizeLabel.textColor = NCDynamicColor(@"text_secondary_color");
    }
    return _sizeLabel;
}

- (UILabel *)progressLabel {
    if (!_progressLabel) {
        _progressLabel = [[UILabel alloc]
            initWithFrame:CGRectMake(10, 151 + self.extentLayoutForY, self.view.bounds.size.width - 10 * 2, 21)];
        _progressLabel.textColor = NCDynamicColor(@"text_secondary_color");
        _progressLabel.textAlignment = NSTextAlignmentCenter;
        _progressLabel.font = [[NCChatUIConfig defaultConfig].font fontOfGuideLevel];
    }
    return _progressLabel;
}

- (UIProgressView *)progressView {
    if (!_progressView) {
        _progressView = [[UIProgressView alloc]
            initWithFrame:CGRectMake(10, 184 + self.extentLayoutForY, self.view.bounds.size.width - 10 * 3, 8)];
        _progressView.transform = CGAffineTransformMakeScale(1.0f, 4.0f);
        _progressView.progressViewStyle = UIProgressViewStyleDefault;
        _progressView.progressTintColor = NCDynamicColor(@"primary_color");
    }
    return _progressView;
}

- (NCBaseButton *)downloadButton {
    if (!_downloadButton) {
        _downloadButton = [[NCBaseButton alloc]
            initWithFrame:CGRectMake(10, 197 + self.extentLayoutForY, self.view.bounds.size.width - 10 * 2, 40)];
        _downloadButton.backgroundColor = NCDynamicColor(@"primary_color");
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
        _openInOtherAppButton = [[NCBaseButton alloc]
            initWithFrame:CGRectMake(10, 197 + self.extentLayoutForY, self.view.bounds.size.width - 10 * 2, 40)];
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
@end
