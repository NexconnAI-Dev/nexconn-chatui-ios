//
//  NCSightFileBrowserViewController.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCSightFileBrowserViewController.h"
#import "NCBaseNavigationController.h"
#import "NCBaseTableViewCell.h"
#import "NCChatUICommonDefine.h"
#import "NCChatUIThemeManager.h"
#import "NCChatUIUserInfo.h"
#import "NCChatUIUtility.h"
#import "NCMessageModel.h"
#import "NCSemanticContext.h"
#import "NCSightFileBrowserCell.h"
#import "NCSightSlideViewController.h"
#import "NCUserInfoCacheManager.h"

@interface NCSightFileBrowserViewController ()

@property (nonatomic, strong) NCMessageModel *selectedMessageModel;
@property (nonatomic, strong) NSMutableArray<NCMessageModel *> *sightMessageModels;
@property (nonatomic, assign) NCChatUIBuiltInThemeType themesType;
@property (nonatomic, assign) BOOL isLoadingOlder;
@property (nonatomic, assign) BOOL isLoadingLater;
@property (nonatomic, strong, nullable) NCChannelIdentifier *previewChannelIdentifier;
@property (nonatomic, strong) NSMutableArray<NCLocalMessagesByTimeQuery *> *activeSightQueries;
@end

@implementation NCSightFileBrowserViewController
#pragma mark - Life Cycle
- (instancetype)initWithMessageModel:(NCMessageModel *)model {
    if (self = [super initWithStyle:UITableViewStyleGrouped]) {
        self.selectedMessageModel = model;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    self.themesType = [NCChatUIThemeManager currentInnerThemesType];
    if (self.themesType == NCChatUIBuiltInThemeTypeLively) {
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    } else {
        self.tableView.separatorInset = UIEdgeInsetsMake(0, 16, 0, 0);
    }
    [self loadSightMessagesAroundSelectedMessageModel:self.selectedMessageModel];
    self.refreshControl = [[UIRefreshControl alloc] init];
    self.refreshControl.tintColor = NCDynamicColor(@"disabled_color");
    [self.refreshControl addTarget:self
                            action:@selector(refreshAction:)
                  forControlEvents:UIControlEventValueChanged];
    self.tableView.tableFooterView = [UIView new];
    [self.tableView registerClass:[NCSightFileBrowserCell class]
           forCellReuseIdentifier:NCSightFileBrowserCellIdentifier];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.title = NCUILocalizedString(@"chat_files");
    [self.navigationController.navigationBar setBackgroundImage:nil
                                                  forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.shadowImage = nil;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new]
                                                  forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.shadowImage = [UIImage new];
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.sightMessageModels.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.themesType == NCChatUIBuiltInThemeTypeLively) {
        NCSightFileBrowserCell *cell =
            [tableView dequeueReusableCellWithIdentifier:NCSightFileBrowserCellIdentifier];
        return cell;
    } else {
        NSString *const identifier = @"NCSightFileCell";
        NCBaseTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
        if (!cell) {
            cell = [[NCBaseTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                              reuseIdentifier:identifier];
        }
        cell.textLabel.textColor = NCDynamicColor(@"text_primary_color");
        cell.detailTextLabel.textColor = NCDynamicColor(@"text_secondary_color");
        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.themesType == NCChatUIBuiltInThemeTypeLively) {
        return 76;
    }
    return 64;
}

- (void)tableView:(UITableView *)tableView
      willDisplayCell:(UITableViewCell *)cell
    forRowAtIndexPath:(NSIndexPath *)indexPath {
    NCMessageModel *messageModel = self.sightMessageModels[indexPath.row];
    NCShortVideoMessage *sightMessage = (NCShortVideoMessage *)messageModel.content;
    UIImage *image = NCDynamicImage(@"video_files_list_icon_img");

    long long timeSecond = messageModel.sentTime / 1000;
    NSString *timeString = [NCChatUIUtility convertMessageTime:timeSecond];
    NSString *sizeString =
        sightMessage.size > 1000000
            ? [NSString stringWithFormat:@"%0.1fM", sightMessage.size / 1024.0f / 1024.0f]
            : [NSString stringWithFormat:@"%0.1fKB", sightMessage.size / 1024.0f];
    NCChatUIUserInfo *userInfo = [self managedUserInfoForMessageModel:messageModel];
    NSString *displayName = [NCChatUIUtility getDisplayName:userInfo];
    NSString *userName =
        displayName.length > 20
            ? [NSString stringWithFormat:@"%@...", [displayName substringToIndex:20]]
            : displayName;
    if (self.themesType == NCChatUIBuiltInThemeTypeLively) {
        if ([cell isKindOfClass:[NCSightFileBrowserCell class]]) {
            NCSightFileBrowserCell *browserCell = (NCSightFileBrowserCell *)cell;
            browserCell.imageIcon.image = image;
            browserCell.labelTitle.text = sightMessage.name;
            browserCell.labelTime.text = timeString;
            browserCell.labelSubtitle.text =
                [NSString stringWithFormat:@"%@  %@", sizeString, userName];
        }
    } else {
        cell.imageView.image = image;
        cell.textLabel.text = sightMessage.name;
        cell.detailTextLabel.text =
            [NSString stringWithFormat:@"%@ %@ %@", userName, timeString, sizeString];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NCSightSlideViewController *ssv = [[NCSightSlideViewController alloc] init];
    ssv.messageModel = self.sightMessageModels[indexPath.row];
    ssv.topRightBtnHidden = YES;
    NCBaseNavigationController *navc =
        [[NCBaseNavigationController alloc] initWithRootViewController:ssv];
    navc.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:navc animated:YES completion:nil];
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    CGFloat totalHeight = scrollView.contentOffset.y + scrollView.frame.size.height;
    if (totalHeight - scrollView.contentSize.height <= 0 || self.isLoadingOlder ||
        self.sightMessageModels.count == 0) {
        return;
    }
    self.isLoadingOlder = YES;
    __weak typeof(self) weakSelf = self;
    [self getOlderSightMessageModelsThanModel:self.sightMessageModels.lastObject
                                        count:5
                                        times:0
                                   completion:^(NSArray<NCMessageModel *> *models) {
                                     dispatch_async(dispatch_get_main_queue(), ^{
                                       __strong typeof(weakSelf) strongSelf = weakSelf;
                                       if (!strongSelf) {
                                           return;
                                       }
                                       strongSelf.isLoadingOlder = NO;
                                       NSArray<NCMessageModel *> *uniqueModels =
                                           [strongSelf uniqueMessageModelsFromModels:models];
                                       if (uniqueModels.count == 0) {
                                           return;
                                       }
                                       NSMutableArray<NSIndexPath *> *indexPaths =
                                           [[NSMutableArray alloc] init];
                                       NSUInteger baseIndex = strongSelf.sightMessageModels.count;
                                       for (NSUInteger i = 0; i < uniqueModels.count; i++) {
                                           [indexPaths
                                               addObject:[NSIndexPath indexPathForRow:baseIndex + i
                                                                            inSection:0]];
                                       }
                                       [strongSelf.sightMessageModels
                                           addObjectsFromArray:uniqueModels];
                                       [strongSelf.tableView
                                           insertRowsAtIndexPaths:indexPaths
                                                 withRowAnimation:UITableViewRowAnimationMiddle];
                                     });
                                   }];
}

#pragma mark - Target action

- (void)refreshAction:(UIRefreshControl *)refreshControl {
    [refreshControl endRefreshing];
    if (self.isLoadingLater || self.sightMessageModels.count == 0) {
        return;
    }
    self.isLoadingLater = YES;
    __weak typeof(self) weakSelf = self;
    [self getLaterSightMessageModelsThanModel:self.sightMessageModels.firstObject
                                        count:5
                                        times:0
                                   completion:^(NSArray<NCMessageModel *> *models) {
                                     dispatch_async(dispatch_get_main_queue(), ^{
                                       __strong typeof(weakSelf) strongSelf = weakSelf;
                                       if (!strongSelf) {
                                           return;
                                       }
                                       strongSelf.isLoadingLater = NO;
                                       NSArray<NCMessageModel *> *uniqueModels =
                                           [strongSelf uniqueMessageModelsFromModels:models];
                                       if (uniqueModels.count == 0) {
                                           return;
                                       }
                                       NSMutableArray<NSIndexPath *> *indexPaths =
                                           [[NSMutableArray alloc] init];
                                       for (NSUInteger i = 0; i < uniqueModels.count; i++) {
                                           [indexPaths addObject:[NSIndexPath indexPathForRow:i
                                                                                    inSection:0]];
                                       }
                                       NSIndexSet *indexSet = [NSIndexSet
                                           indexSetWithIndexesInRange:NSMakeRange(
                                                                          0, uniqueModels.count)];
                                       [strongSelf.sightMessageModels insertObjects:uniqueModels
                                                                          atIndexes:indexSet];
                                       [strongSelf.tableView
                                           insertRowsAtIndexPaths:indexPaths
                                                 withRowAnimation:UITableViewRowAnimationMiddle];
                                     });
                                   }];
}

#pragma mark - Private Methods

static NCChannelIdentifier *
NCSightFileChannelIdentifierFromMessageModel(NCMessageModel *messageModel) {
    NSString *channelId = messageModel.channelId ?: @"";
    switch ((NCChannelType)messageModel.channelType) {
    case NCChannelTypeDirect:
        return [[NCChannelIdentifier alloc] initWithChannelType:NCChannelTypeDirect
                                                      channelId:channelId];
    case NCChannelTypeGroup:
        return [[NCChannelIdentifier alloc] initWithChannelType:NCChannelTypeGroup
                                                      channelId:channelId];
    case NCChannelTypeSystem:
        return [[NCChannelIdentifier alloc] initWithChannelType:NCChannelTypeSystem
                                                      channelId:channelId];
    case NCChannelTypeOpen:
        return [[NCChannelIdentifier alloc] initWithChannelType:NCChannelTypeOpen
                                                      channelId:channelId];
    case NCChannelTypeCommunity:
        return [[NCChannelIdentifier alloc] initWithChannelType:NCChannelTypeCommunity
                                                      channelId:channelId];
    default:
        return nil;
    }
}

- (NCChatUIUserInfo *)managedUserInfoForMessageModel:(NCMessageModel *)model {
    if (model.senderUserId.length == 0) {
        return nil;
    }
    if (model.channelType == NCChannelTypeGroup) {
        NCChatUIUserInfo *memberInfo =
            [[NCUserInfoCacheManager sharedManager] getUserInfo:model.senderUserId
                                                      inGroupId:model.channelId];
        NCChatUIUserInfo *userInfo =
            [[NCUserInfoCacheManager sharedManager] getUserInfo:model.senderUserId];
        if (memberInfo && userInfo.alias.length > 0) {
            memberInfo.alias = userInfo.alias;
        }
        return memberInfo ?: userInfo;
    }
    return [[NCUserInfoCacheManager sharedManager] getUserInfo:model.senderUserId];
}

- (NSArray<NCMessageModel *> *)uniqueMessageModelsFromModels:(NSArray<NCMessageModel *> *)models {
    if (models.count == 0) {
        return @[];
    }
    NSMutableSet<NSNumber *> *existingClientIds = [NSMutableSet set];
    for (NCMessageModel *model in self.sightMessageModels) {
        [existingClientIds addObject:@(model.clientId)];
    }
    NSMutableArray<NCMessageModel *> *uniqueModels = [NSMutableArray array];
    for (NCMessageModel *model in models) {
        NSNumber *clientId = @(model.clientId);
        if ([existingClientIds containsObject:clientId]) {
            continue;
        }
        [existingClientIds addObject:clientId];
        [uniqueModels addObject:model];
    }
    return uniqueModels;
}

- (NSArray<NCMessageModel *> *)messageModelsWithMessages:(NSArray<NCMessage *> *)messages {
    NSMutableArray<NCMessageModel *> *models = [NSMutableArray array];
    for (NCMessage *message in messages) {
        NCMessageModel *model = [NCMessageModel modelWithNCMessage:message];
        if (model) {
            [models addObject:model];
        }
    }
    return models;
}

- (void)querySightMessageModelsWithAnchorModel:(NCMessageModel *)anchorModel
                                         count:(NSInteger)count
                                   isAscending:(BOOL)isAscending
                                    completion:
                                        (void (^)(NSArray<NCMessageModel *> *models))completion {
    NCChannelIdentifier *channelIdentifier =
        self.previewChannelIdentifier ?: NCSightFileChannelIdentifierFromMessageModel(anchorModel);
    if (!channelIdentifier || channelIdentifier.channelId.length == 0) {
        if (completion) {
            completion(@[]);
        }
        return;
    }
    NCLocalMessagesByTimeQueryParams *params = [[NCLocalMessagesByTimeQueryParams alloc] init];
    params.channelIdentifier = channelIdentifier;
    params.pageSize = count;
    params.sentTime = anchorModel.sentTime;
    params.isAscending = isAscending;
    params.messageTypes = @[ NCMessageType.shortVideo ];
    NCLocalMessagesByTimeQuery *query =
        [NCBaseChannel createLocalMessagesByTimeQueryWithParams:params];
    @synchronized(self) {
        [self.activeSightQueries addObject:query];
    }
    __weak typeof(self) weakSelf = self;
    [query loadNextPageWithCompletion:^(NSArray<NCMessage *> *_Nullable messages,
                                        NCError *_Nullable error) {
      __strong typeof(weakSelf) strongSelf = weakSelf;
      if (strongSelf) {
          @synchronized(strongSelf) {
              [strongSelf.activeSightQueries removeObject:query];
          }
      }
      if (completion) {
          completion((error || !strongSelf)
                         ? @[]
                         : [strongSelf messageModelsWithMessages:(messages ?: @[])]);
      }
    }];
}

- (void)getLaterSightMessageModelsThanModel:(NCMessageModel *)model
                                      count:(NSInteger)count
                                      times:(int)times
                                 completion:
                                     (void (^)(NSArray<NCMessageModel *> *models))completion {
    [self
        querySightMessageModelsWithAnchorModel:model
                                         count:count
                                   isAscending:YES
                                    completion:^(NSArray<NCMessageModel *> *models) {
                                      NSArray<NCMessageModel *> *orderedModels =
                                          models.reverseObjectEnumerator.allObjects;
                                      if (times < 2 && orderedModels.count == 0 &&
                                          models.count == count && models.lastObject) {
                                          [self
                                              getLaterSightMessageModelsThanModel:models.lastObject
                                                                            count:count
                                                                            times:times + 1
                                                                       completion:completion];
                                          return;
                                      }
                                      if (completion) {
                                          completion(orderedModels ?: @[]);
                                      }
                                    }];
}

- (void)getOlderSightMessageModelsThanModel:(NCMessageModel *)model
                                      count:(NSInteger)count
                                      times:(int)times
                                 completion:
                                     (void (^)(NSArray<NCMessageModel *> *models))completion {
    [self
        querySightMessageModelsWithAnchorModel:model
                                         count:count
                                   isAscending:NO
                                    completion:^(NSArray<NCMessageModel *> *models) {
                                      if (times < 2 && models.count == 0 && models.count == count &&
                                          models.lastObject) {
                                          [self
                                              getOlderSightMessageModelsThanModel:models.lastObject
                                                                            count:count
                                                                            times:times + 1
                                                                       completion:completion];
                                          return;
                                      }
                                      if (completion) {
                                          completion(models ?: @[]);
                                      }
                                    }];
}

- (void)loadSightMessagesAroundSelectedMessageModel:(NCMessageModel *)selectedMessageModel {
    if (!selectedMessageModel) {
        NCLogReleaseW(@"Parameters are not allowed to be nil");
        return;
    }
    self.sightMessageModels = [@[ selectedMessageModel ] mutableCopy];
    [self.tableView reloadData];

    __weak typeof(self) weakSelf = self;
    self.previewChannelIdentifier =
        NCSightFileChannelIdentifierFromMessageModel(selectedMessageModel);
    [self
        getLaterSightMessageModelsThanModel:selectedMessageModel
                                      count:10
                                      times:0
                                 completion:^(NSArray<NCMessageModel *> *laterModels) {
                                   [weakSelf
                                       getOlderSightMessageModelsThanModel:selectedMessageModel
                                                                     count:10
                                                                     times:0
                                                                completion:^(
                                                                    NSArray<NCMessageModel *>
                                                                        *olderModels) {
                                                                  dispatch_async(
                                                                      dispatch_get_main_queue(), ^{
                                                                        __strong typeof(weakSelf)
                                                                            strongSelf = weakSelf;
                                                                        if (!strongSelf) {
                                                                            return;
                                                                        }
                                                                        NSMutableArray<
                                                                            NCMessageModel *>
                                                                            *sightMessageModels =
                                                                                [[NSMutableArray
                                                                                    alloc] init];
                                                                        [sightMessageModels
                                                                            addObjectsFromArray:
                                                                                laterModels];
                                                                        [sightMessageModels
                                                                            addObject:
                                                                                selectedMessageModel];
                                                                        [sightMessageModels
                                                                            addObjectsFromArray:
                                                                                olderModels];
                                                                        strongSelf
                                                                            .sightMessageModels =
                                                                            sightMessageModels;
                                                                        [strongSelf.tableView
                                                                                reloadData];
                                                                      });
                                                                }];
                                 }];
}

- (NSMutableArray<NCMessageModel *> *)sightMessageModels {
    if (!_sightMessageModels) {
        _sightMessageModels = [NSMutableArray array];
    }
    return _sightMessageModels;
}

- (NSMutableArray<NCLocalMessagesByTimeQuery *> *)activeSightQueries {
    if (!_activeSightQueries) {
        _activeSightQueries = [NSMutableArray array];
    }
    return _activeSightQueries;
}
@end
