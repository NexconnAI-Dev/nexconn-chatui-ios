//
//  NCAlbumListTableViewController.m
//  NCChatUIExtension
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCAlbumListTableViewController.h"
#import "NCAlbumModel.h"
#import "NCAlbumTableCell.h"
#import "NCAssetModel.h"
#import "NCChatUICommonDefine.h"
#import "NCChatUIUtility.h"
#import "NCPhotosPickerController.h"
#import "NCMBProgressHUD.h"
#import <MobileCoreServices/UTCoreTypes.h>
#import "NCChatUIConfig.h"
#import "NCAlertView.h"

static NSString *const cellReuseIdentifier = @"cell";

@interface NCAlbumListTableViewController ()
@property (nonatomic, strong) UILabel *tipsLabel;
@property (nonatomic, strong) NCMBProgressHUD *progressHUD;
@property (nonatomic, assign) BOOL isShowHUD;
@end

@implementation NCAlbumListTableViewController
#pragma mark - Life Cycle
- (void)dealloc {
    
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.libraryList = [NSMutableArray new];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = NCUILocalizedString(@"albums");
    [self setNavigationItem];
    [self setupTableView];
    [self setAuthorizationStatusAuthorized];
    [self getDataSourceAndReloadView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.libraryList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NCAlbumTableCell *cell = [tableView dequeueReusableCellWithIdentifier:cellReuseIdentifier forIndexPath:indexPath];
    [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
    [cell configCellWithItem:self.libraryList[indexPath.row]];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NCAlbumModel *assetsGroup = self.libraryList[indexPath.row];
    [self pushImagePickerController:assetsGroup animated:YES];
}

#pragma mark - Private Methods
- (void)setNavigationItem{
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.titleLabel.font = [[NCChatUIConfig defaultConfig].font fontOfSecondLevel];
    UIColor *color = NCDynamicResourceColor(@"primary_color", @"photoPicker_cancel", @"0x0099ff");
    [btn setTitleColor:color forState:UIControlStateNormal];
    [btn addTarget:self
            action:@selector(dismissCurrentModelViewController)
  forControlEvents:UIControlEventTouchUpInside];
    [btn setTitle:NCUILocalizedString(@"cancel") forState:UIControlStateNormal];
    [btn sizeToFit];
    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithCustomView:btn];
    [self.navigationItem setRightBarButtonItem:rightItem];
}

- (void)setupTableView{
    [self.tableView registerClass:[NCAlbumTableCell class] forCellReuseIdentifier:cellReuseIdentifier];
    self.tableView.tableFooterView = [[UIView alloc] init];
    self.tableView.rowHeight = 65.0f;
    self.tableView.tableFooterView = [UIView new];
    self.tableView.backgroundColor = NCDynamicColor(@"auxiliary_background_1_color");
    self.tableView.separatorColor = NCDynamicColor(@"line_background_color");
    self.tableView.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
    if ([self.tableView respondsToSelector:@selector(setSeparatorInset:)]) {
        [self.tableView setSeparatorInset:UIEdgeInsetsMake(0, 0, 0, 0)];
    }
}

- (void)getDataSourceAndReloadView{
    NCAssetHelper *sharedAssetHelper = [NCAssetHelper shareAssetHelper];
    NSArray *cacheAssetGroup = [sharedAssetHelper getCachePhotoGroups];
    if (cacheAssetGroup && cacheAssetGroup.count > 0) {
        self.libraryList = cacheAssetGroup;
        NCAlbumModel *assetsGroup = self.libraryList[0];
        // Albums are available, so hide the authorization prompt.
        if (self.tipsLabel) {
            [self.tipsLabel setHidden:YES];
        }
        [self pushImagePickerController:assetsGroup animated:NO];
        [self.tableView reloadData];
    } else {
        [NCChatUIUtility showProgressViewFor:self.tableView text:nil animated:YES];
        [sharedAssetHelper
            getAlbumsFromSystem:^(NSArray *assetGroup) {
                              if (assetGroup) {
                                  self.libraryList = assetGroup;
                              }
            
                              dispatch_async(dispatch_get_main_queue(), ^{
                                  BOOL isFirstRun = [[NSUserDefaults standardUserDefaults] boolForKey:@"nckit_first_happen"];
                                  // Handle this recovery only once per installation.
                                  if (assetGroup.count == 0 && !isFirstRun) {
                                      if (@available(iOS 15, *)) {
                                          // nothing to do
                                      } else if (@available(iOS 14, *)) {
                                          [NCChatUIUtility hideProgressViewFor:self.tableView animated:YES];
                                          // Photo library issue: https://developer.apple.com/forums/thread/658114
                                          [NCAlertView showAlertController:NCUILocalizedString(@"photo_library_bug_error_alert") message:nil actionTitles:nil cancelTitle:NCUILocalizedString(@"cancel") confirmTitle:NCUILocalizedString(@"restart_app") preferredStyle:UIAlertControllerStyleAlert actionsBlock:nil cancelBlock:nil confirmBlock:^{
                                              // Record the restart recovery so this case is not handled again.
                                              [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"nckit_first_happen"];
                                              [[NSUserDefaults standardUserDefaults] synchronize];
                                              
                                              exit(0);
                                          } inViewController:self];
                                          
                                          return;
                                      } else {
                                          // nothing to do
                                      }
                                  }

                                  
                                  [NCChatUIUtility hideProgressViewFor:self.tableView animated:YES];

                                  if (self.libraryList.count) {
                                      NCAlbumModel *assetsGroup = self.libraryList[0];
                                      [self pushImagePickerController:assetsGroup animated:NO];
                                      // Albums are available, so hide the authorization prompt.
                                      [self.tipsLabel setHidden:YES];
                                  } else {
                                      if ([[NCAssetHelper shareAssetHelper] hasAuthorizationStatusAuthorized]) {
                                          [self.tipsLabel setHidden:YES];
                                      }else{
                                          [self.tipsLabel setHidden:NO];
                                      }
                                  }
                                  [self.tableView reloadData];

                              });
                          }];
    }
}
- (NSString *)moveVideoFileAt:(NSString *)filePath {
    /*
     Copy the video to a temporary path before sending because the original
     photo-library path may no longer be accessible after an app restart.
     */
    if (filePath.length == 0) {
        return nil;
    }
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:filePath]) {
        long long millisecond = [[NSDate date] timeIntervalSince1970] * 1000;
        NSString *name = [NSString stringWithFormat:@"nc_tmp_video_%lld.mp4", millisecond];
        NSString *localPath = [NSTemporaryDirectory() stringByAppendingPathComponent:name];
        NSError *error = nil;
        [fileManager copyItemAtPath:filePath toPath:localPath error:&error];
        if (error) {
            return filePath;
        }
        return localPath;
    }
    return filePath;
}

- (NSString *)p_localPathForVideoAsset:(AVAsset *)avAsset info:(NSDictionary *)info {
    NSString *localPath = nil;
    if ([avAsset isKindOfClass:[AVURLAsset class]]) {
        AVURLAsset *urlAsset = (AVURLAsset *)avAsset;
        NSURL *url = urlAsset.URL;
        if (url.isFileURL) {
            localPath = url.path;
        } else {
            localPath = url.relativePath;
        }
    }
    if (localPath.length == 0) {
        id sandboxToken = info[@"PHImageFileSandboxExtensionTokenKey"];
        if ([sandboxToken isKindOfClass:[NSString class]] && [sandboxToken length] > 0) {
            NSArray *localPaths = [(NSString *)sandboxToken componentsSeparatedByString:@";"];
            NSString *tokenPath = localPaths.lastObject;
            if ([tokenPath isKindOfClass:[NSString class]] && tokenPath.length > 0) {
                localPath = tokenPath;
            }
        }
    }
    return localPath.length > 0 ? localPath : nil;
}

- (void)handlePhotos:(NSMutableArray *)photos result:(NSMutableArray *)results full:(BOOL)isFull {
    if (photos.count == 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.progressHUD hideAnimated:YES];
            self.isShowHUD = NO;
            if ([self.delegate respondsToSelector:@selector(albumListViewController:selectedImages:isSendFullImage:)] &&
                results.count) {
                [self.delegate albumListViewController:nil selectedImages:results isSendFullImage:isFull];
            }
            [self dismissCurrentModelViewController];
        });
    } else {
        NCAssetModel *model = [photos objectAtIndex:0];
        [photos removeObjectAtIndex:0];
        if (model.mediaType == PHAssetMediaTypeVideo && NSClassFromString(@"NCSightCapturer")) {
            [self p_getOriginVideo:model photos:photos result:results full:isFull];
        } else {
            [self p_getOriginImageData:model photos:photos result:results full:isFull];
        }
    }
}

- (void)p_getOriginVideo:(NCAssetModel *)model photos:(NSMutableArray *)photos result:(NSMutableArray *)results full:(BOOL)isFull{
    __weak typeof(self) weakSelf = self;
    [[NCAssetHelper shareAssetHelper] getOriginVideoWithAsset:model.asset
        result:^(AVAsset *avAsset, NSDictionary *info, NSString *imageIdentifier) {
            if (![[[NCAssetHelper shareAssetHelper] getAssetIdentifier:model.asset] isEqualToString:imageIdentifier]) {
                return;
            }
            if (avAsset) {
                NSMutableDictionary *assetInfo = [[NSMutableDictionary alloc] initWithCapacity:5];
                if (avAsset) {
                    [assetInfo setObject:avAsset forKey:@"avAsset"];
                }
                if (model.thumbnailImage) {
                    [assetInfo setObject:model.thumbnailImage forKey:@"thumbnail"];
                }
                NSString *localPath = [self p_localPathForVideoAsset:avAsset info:info];
                localPath = [self moveVideoFileAt:localPath];
                if (localPath.length < 1) {
                    [NCAlertView showAlertController:nil
                                             message:NCUILocalizedString(@"Selected_Damaged_Video")
                                    hiddenAfterDelay:1
                                    inViewController:self];
                    [self handlePhotos:photos result:results full:isFull];
                    return;
                }

                [assetInfo setObject:localPath forKey:@"localPath"];

                // NSDictionary* assetInfo = @{@"avAsset":model.avAsset,@"thumbnail":!model.thumbnailImage ?
                // [NSNull null] : model.thumbnailImage};
                [results addObject:[assetInfo copy]];
            }
            [self handlePhotos:photos result:results full:isFull];
        }
        progressHandler:^(double progress, NSError *error, BOOL *stop, NSDictionary *info) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
            if (progress < 1 && !error && !strongSelf.isShowHUD) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    strongSelf.isShowHUD = YES;
                    strongSelf.progressHUD =
                        [NCMBProgressHUD showHUDAddedTo:[NCChatUIUtility getWindowForView:self.view] animated:YES];
                    strongSelf.progressHUD.label.text = NCUILocalizedString(@"i_cloud_downloading");
                });
            }
            if (error) {
                // from iCloud download error
                strongSelf.progressHUD.label.text = NCUILocalizedString(@"i_cloud_download_fail");
                [strongSelf.progressHUD hideAnimated:YES afterDelay:1];
                strongSelf.isShowHUD = NO;
            }
    }];
}

- (void)p_getOriginImageData:(NCAssetModel *)model photos:(NSMutableArray *)photos result:(NSMutableArray *)results full:(BOOL)isFull{
    __weak typeof(self) weakself = self;
    [[NCAssetHelper shareAssetHelper] getOriginImageDataWithAsset:model
        result:^(NSData *imageData, NSDictionary *info, NCAssetModel *assetModel) {
            BOOL downloadFinined = (![[info objectForKey:PHImageCancelledKey] boolValue] &&
                                    ![info objectForKey:PHImageErrorKey] &&
                                    ![[info objectForKey:PHImageResultIsDegradedKey] boolValue]);
            if (downloadFinined && imageData) {
                if ([[model.asset valueForKey:@"uniformTypeIdentifier"]
                        isEqualToString:(__bridge NSString *)kUTTypeGIF]) {
                    NSMutableDictionary *gifInfo = [[NSMutableDictionary alloc] init];
                    [gifInfo setObject:@"GIF" forKey:@"GIF"];
                    [gifInfo setObject:imageData forKey:@"imageData"];
                    [results addObject:gifInfo];
                } else {
                    [results addObject:imageData];
                }
                [weakself handlePhotos:photos result:results full:isFull];
            }
        }
        progressHandler:^(double progress, NSError *error, BOOL *stop, NSDictionary *info) {
            if (progress < 1 && !error && !weakself.isShowHUD) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    weakself.isShowHUD = YES;
                    weakself.progressHUD =
                        [NCMBProgressHUD showHUDAddedTo:[NCChatUIUtility getWindowForView:self.view]
                                             animated:YES];
                    weakself.progressHUD.label.text = NCUILocalizedString(@"i_cloud_downloading");
                });
            }
            if (error) {
                // from iCloud download error
                weakself.progressHUD.label.text = NCUILocalizedString(@"i_cloud_download_fail");
                [weakself.progressHUD hideAnimated:YES afterDelay:1];
                weakself.isShowHUD = NO;
            }
        }];
}

- (void)pushImagePickerController:(NCAlbumModel *)assetsGroup animated:(BOOL)animated {

    NCPhotosPickerController *imagePickerVC = [NCPhotosPickerController imagePickerViewController];
    imagePickerVC.count = assetsGroup.count;
    imagePickerVC.currentAsset = assetsGroup.asset;
    imagePickerVC.title = assetsGroup.albumName;
    __weak typeof(self) weakself = self;
    [imagePickerVC setSendPhotosBlock:^(NSArray *photos, BOOL isFull) {
        NSMutableArray *selectedPhotos = [NSMutableArray array];
        [weakself handlePhotos:[photos mutableCopy] result:selectedPhotos full:isFull];
    }];

    [self.navigationController pushViewController:imagePickerVC animated:animated];
}

- (void)dismissCurrentModelViewController {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)setAuthorizationStatusAuthorized {
    if (![[NCAssetHelper shareAssetHelper] hasAuthorizationStatusAuthorized] && [PHPhotoLibrary authorizationStatus] != PHAuthorizationStatusNotDetermined) {
        self.tipsLabel.hidden = NO;
    }
}

- (UILabel *)tipsLabel{
    if (!_tipsLabel) {
        _tipsLabel = [[UILabel alloc] init];
        _tipsLabel.frame = CGRectMake(8, 64, self.view.frame.size.width - 16, 100);
        _tipsLabel.textAlignment = NSTextAlignmentCenter;
        _tipsLabel.numberOfLines = 0;
        _tipsLabel.font = [[NCChatUIConfig defaultConfig].font fontOfSecondLevel];
        _tipsLabel.textColor = NCDynamicColor(@"text_primary_color");
        _tipsLabel.text = NCUILocalizedString(@"photo_access_right");
        [self.view addSubview:_tipsLabel];
        _tipsLabel.hidden = YES;
    }
    return _tipsLabel;
}
@end
