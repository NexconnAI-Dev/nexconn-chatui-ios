//
//  NCChannelListViewController.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCChannelListViewController.h"
#import "NCChatUILog.h"
#import "NCChannelListCell.h"
#import "NCChatUICommonDefine.h"
#import "NCChatUIUtility.h"
#import "NCNetworkIndicatorView.h"
#import "NCMJRefresh.h"
#import "UIImage+NCDynamicImage.h"
#import "NCChannelListDataSource.h"
#import "NCChannelListPendingDraftStore.h"
#import "NCChatUIConfig.h"
#import "NCChannelViewController.h"
#import "NCChatUI.h"

static NSString *const NCChatUIChannelDraftSaveWillBeginNotificationName =
    @"NCChatUIChannelDraftSaveWillBeginNotification";

@interface NCChannelListDataSource (UnreadStatusSync)
- (void)syncUnreadStatusForChannelIdentifier:(NCChannelIdentifier *)identifier;
@end

@interface NCChannelListViewController () <UITableViewDataSource, UITableViewDelegate, NCChannelListCellDelegate,NCChannelListDataSourceDelegate, NCConnectionStatusHandler, NCChannelHandler>

@property (nonatomic, strong) UIView *connectionStatusView;
@property (nonatomic, strong) UIView *navigationTitleView;
@property (nonatomic, strong) NCMJRefreshAutoNormalFooter *footer;
@property (nonatomic, strong) NCChannelListDataSource *dataSource;
@property (nonatomic, strong) NCChannelListPendingDraftStore *pendingDraftStore;
@property (nonatomic, assign) NSInteger pendingDraftSaveCount;
@property (nonatomic, assign) BOOL needsRefreshAfterDraftSave;
@end

@implementation NCChannelListViewController

#pragma mark - Initialization
- (instancetype)initWithDisplayConversationTypes:(NSArray *)displayConversationTypeArray
{
    self = [super init];
    if (self) {
        [self nc_commonInit];
        self.displayConversationTypeArray = displayConversationTypeArray;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self nc_commonInit];
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self nc_commonInit];
    }
    return self;
}

- (void)nc_commonInit {
    self.topPriority = YES;
    self.dataSource = [[NCChannelListDataSource alloc] init];
    self.dataSource.delegate = self;
    self.pendingDraftStore = [[NCChannelListPendingDraftStore alloc] init];
    self.isShowNetworkIndicatorView = YES;
    self.displayConversationTypeArray = @[@(NCChannelTypeDirect), @(NCChannelTypeGroup), @(NCChannelTypeSystem)];
}

#pragma mark - Life cycle
- (void)viewDidLoad {
    [super viewDidLoad];

    if ([self respondsToSelector:@selector(setExtendedLayoutIncludesOpaqueBars:)]) {
        self.extendedLayoutIncludesOpaqueBars = YES;
    }
    self.conversationListTableView = [[NCBaseTableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.conversationListTableView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    self.conversationListTableView.backgroundColor =
    NCDynamicColor(@"clear_color");
    self.view.backgroundColor = NCDynamicColor(@"view_background_color");
    self.conversationListTableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(1, 1, 0, CGFLOAT_MIN)];
    self.conversationListTableView.separatorColor = NCDynamicColor(@"line_background_color");
    CGFloat leftOffset = 12 + [NCChatUIConfig defaultConfig].ui.globalConversationPortraitSize.width + 12;
    if ([self.conversationListTableView respondsToSelector:@selector(setSeparatorInset:)]) {
        self.conversationListTableView.separatorInset = UIEdgeInsetsMake(0, leftOffset, 0, 0);
    }
    if ([self.conversationListTableView respondsToSelector:@selector(setLayoutMargins:)]) {
        self.conversationListTableView.layoutMargins = UIEdgeInsetsMake(0, leftOffset, 0, 0);
    }
    self.conversationListTableView.dataSource = self;
    self.conversationListTableView.delegate = self;
    self.conversationListTableView.ncmj_footer = self.footer;
    [self.view addSubview:self.conversationListTableView];
    [self registerObserver];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    self.dataSource.isConverstaionListAppear = YES;
    [self updateNetworkIndicatorView];
    if ([self shouldDelayRefreshForPendingDraftSave]) {
        return;
    }
    [self refreshConversationTableViewIfNeeded];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [self updateConnectionStatusView];
    if (self.dataSource.dataList.count == 0 &&
        [NCEngine getConnectionStatus] == NCConnectionStatusConnected) {
        [self refreshConversationTableViewIfNeeded];
    }
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf || !strongSelf.dataSource.isConverstaionListAppear) {
            return;
        }
        if (strongSelf.dataSource.dataList.count == 0 &&
            [NCEngine getConnectionStatus] == NCConnectionStatusConnected) {
            [strongSelf refreshConversationTableViewIfNeeded];
        }
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.5 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf || !strongSelf.dataSource.isConverstaionListAppear) {
            return;
        }
        if (strongSelf.dataSource.dataList.count == 0 &&
            [NCEngine getConnectionStatus] == NCConnectionStatusConnected) {
            [strongSelf refreshConversationTableViewIfNeeded];
        }
    });
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    self.dataSource.isConverstaionListAppear = NO;
    [self hideConnectingView];
    [self.conversationListTableView setEditing:NO];
}

- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {

    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self layoutSubview:size];
    }
        completion:^(id<UIViewControllerTransitionCoordinatorContext> context){

        }];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [NCEngine removeConnectionStatusHandlerForIdentifier:@"NCChannelListVC"];
    [NCEngine removeChannelHandlerForIdentifier:@"NCChannelListVC"];
}

#pragma mark - TableView
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataSource.dataList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NCChannelModel *model = nil;
    if (indexPath.row < self.dataSource.dataList.count) {
        model = self.dataSource.dataList[indexPath.row];
    }

    if (model.conversationModelType == NC_CONVERSATION_MODEL_TYPE_CUSTOMIZATION) {
        NCChannelListBaseCell *userCustomCell =
            [self ncChannelListTableView:tableView cellForRowAtIndexPath:indexPath];
        if (!userCustomCell) {
            NCLogReleaseW(@"The custom cell is returned as nil, "
                  @"if the conversationModelType is NC_CONVERSATION_MODEL_TYPE_CUSTOMIZATION, and the message type is NCContactNotificationMessage "
                  @"needs customized cell to display");
        }
        userCustomCell.selectionStyle = UITableViewCellSelectionStyleDefault;
        [userCustomCell setDataModel:model];
        [self willDisplayConversationTableCell:userCustomCell atIndexPath:indexPath];

        return userCustomCell;
    } else {
        static NSString *cellReuseIdentifier = @"nc.channelList.cellReuseIdentifier";
        NCChannelListCell *cell = [tableView dequeueReusableCellWithIdentifier:cellReuseIdentifier];
        if (!cell) {
            cell =
                [[NCChannelListCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellReuseIdentifier];
        }
        cell.delegate = self;
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        [cell setDataModel:model];
        [self willDisplayConversationTableCell:cell atIndexPath:indexPath];

        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NCChannelModel *model = self.dataSource.dataList[indexPath.row];
    if (model.conversationModelType == NC_CONVERSATION_MODEL_TYPE_CUSTOMIZATION) {
        return [self ncChannelListTableView:tableView heightForRowAtIndexPath:indexPath];
    } else {
        return NCChatUIConfigCenter.ui.globalConversationPortraitSize.height + 24.f;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row >= self.dataSource.dataList.count) {
        return;
    }
    NCChannelModel *model = self.dataSource.dataList[indexPath.row];
    [self onSelectedTableRow:model.conversationModelType conversationModel:model atIndexPath:indexPath];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (self.isShowNetworkIndicatorView && !self.networkIndicatorView.hidden) {
        return self.networkIndicatorView.bounds.size.height;
    } else {
        return 0;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (self.isShowNetworkIndicatorView && !self.networkIndicatorView.hidden) {
        return self.networkIndicatorView;
    } else {
        return nil;
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView
    commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
     forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NCChannelModel *model = self.dataSource.dataList[indexPath.row];

        if (model.conversationModelType == NC_CONVERSATION_MODEL_TYPE_NORMAL) {
            [self.dataSource deleteConversation:model completion:^(BOOL success) {
                if (success) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.dataSource.dataList removeObjectAtIndex:indexPath.row];
                        [self.conversationListTableView deleteRowsAtIndexPaths:@[ indexPath ]
                                                              withRowAnimation:UITableViewRowAnimationFade];
                        [self deleteAndReloadConversationCell:model];
                    });
                }
            }];
        } else {
            [self ncChannelListTableView:tableView commitEditingStyle:editingStyle forRowAtIndexPath:indexPath];
            [self deleteAndReloadConversationCell:model];
        }

        
    } else {
        NCLogD(@"editingStyle %ld is unsupported.", (long)editingStyle);
    }
}

- (NSString *)tableView:(UITableView *)tableView
    titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return NCUILocalizedString(@"delete");
}

#pragma mark - Target action
- (void)deleteAndReloadConversationCell:(NCChannelModel *)model{
    [self didDeleteConversationCell:model];
    [self notifyUpdateUnreadMessageCount];
    [self updateEmptyConversationView];
}

- (void)loadMore {
    __weak typeof(self) ws = self;
    [self.dataSource loadMoreConversations:^(NSMutableArray<NCChannelModel *> *modelList) {
        if(modelList.count > 0) {
            [ws.conversationListTableView reloadData];
            [ws updateEmptyConversationView];
        }
        [ws.footer endRefreshing];
    }];
}

- (void)layoutSubview:(CGSize)size {
    if (![NCChatUIUtility currentDeviceIsIPad]) {
        return;
    }
    self.conversationListTableView.frame = self.view.bounds;
    [self.conversationListTableView reloadData];
}

- (void)refreshConversationTableViewIfNeeded {
    [self.dataSource forceLoadConversationModelList:^(NSMutableArray *modelList) {
        [self mergePendingDraftCacheIntoModelList:modelList];
        [self.conversationListTableView reloadData];
        [self updateEmptyConversationView];
    }];
}

- (void)cachePendingDraft:(NSString *)draft
               channelType:(NCChannelType)channelType
                 channelId:(NSString *)channelId
              subChannelId:(NSString *)subChannelId {
    [self.pendingDraftStore cacheDraft:draft
                           channelType:channelType
                             channelId:channelId
                          subChannelId:subChannelId];
}

- (void)mergePendingDraftCacheIntoModelList:(NSMutableArray<NCChannelModel *> *)modelList {
    [self.pendingDraftStore mergeDraftIntoModelList:modelList];
}

- (BOOL)shouldDelayRefreshForPendingDraftSave {
    if (self.pendingDraftSaveCount <= 0) {
        return NO;
    }
    self.needsRefreshAfterDraftSave = YES;
    return YES;
}


- (void)sendReadReceiptIfNeed:(NCChannelModel *)model{
    [NCChatUIUtility syncConversationReadStatusIfEnabled:model];
}

#pragma mark - NCChannelListDataSourceDelegate

- (BOOL)showConversationOnTopPriority {
    return self.topPriority;
}

- (NSMutableArray<NCChannelModel *> *)dataSource:(NCChannelListDataSource *)datasource willReloadTableData:(NSMutableArray<NCChannelModel *> *)modelList {
    return [self willReloadTableData:modelList];
}
- (void)dataSource:(NCChannelListDataSource *)dataSource willReloadAtIndexPaths:(NSArray <NSIndexPath *> *)indexPaths {
    if (self.dataSource.isConverstaionListAppear) {
        [self.conversationListTableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
        [self updateEmptyConversationView];
    }
}
- (void)dataSource:(NCChannelListDataSource *)dataSource willInsertAtIndexPaths:(NSArray <NSIndexPath *> *)indexPaths {
    [self.conversationListTableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
    [self updateEmptyConversationView];
}
- (void)dataSource:(NCChannelListDataSource *)dataSource willDeleteAtIndexPaths:(NSArray <NSIndexPath *> *)deleteIndexPaths willInsertAtIndexPaths:(NSArray <NSIndexPath *> *)insertIndexPaths {
    [self.conversationListTableView beginUpdates];
    [self.conversationListTableView
        deleteRowsAtIndexPaths:deleteIndexPaths
              withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.conversationListTableView
        insertRowsAtIndexPaths:insertIndexPaths
              withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.conversationListTableView endUpdates];
    [self updateEmptyConversationView];
}
- (void)refreshConversationTableViewIfNeededInDataSource:(NCChannelListDataSource *)datasource {
    [self refreshConversationTableViewIfNeeded];
}

- (void)notifyUpdateUnreadMessageCountInDataSource {
    [self notifyUpdateUnreadMessageCount];
}

#pragma makr - NCChannelListCell Delegate

- (void)didUpdateCell:(NCChannelListCell *)cell model:(NCChannelModel *)model {
    dispatch_main_async_safe(^{
        NSIndexPath *indexPath = [self.conversationListTableView indexPathForCell:cell];
        
        // Fall back to iteration when the cell is offscreen or in the reuse pool.
        if (!indexPath) {
            NSInteger index = [self.conversationListDataSource indexOfObject:model];
            if (index != NSNotFound) {
                indexPath = [NSIndexPath indexPathForRow:index inSection:0];
            }
        }
        
        if (indexPath) {
            [self updateCellAtIndexPath:indexPath];
        }
    });
}

#pragma mark - update view
- (void)updateNetworkIndicatorView {
    NCConnectionStatus status = [NCEngine getConnectionStatus];
    BOOL wasHidden = self.networkIndicatorView.hidden;

    // Match Android ChannelListViewModel.buildNoticeContent by reducing connection state to
    // indicator visibility and text. The SDK maps Idle to Suspend, losing the offline distinction,
    // so verify Connecting and Suspend against the device's actual network state.
    BOOL showBar = YES;
    NSString *textKey = @"connection_is_not_reachable";

    if (status == NCConnectionStatusConnected) {
        showBar = NO;
    } else if (status == NCConnectionStatusKickedOfflineByOtherClient) {
        textKey = @"kicked_offline_by_other_client";
    } else if (status == NCConnectionStatusProxyUnavailable) {
        textKey = @"connectionstatus_proxy_unavailable";
    } else if (status == NCConnectionStatusUnconnected) {
        textKey = @"connection_disconnect";
    } else if (status == NCConnectionStatusConnecting || status == NCConnectionStatusSuspend) {
        // With network access, updateConnectionStatusView shows the navigation spinner and this banner stays hidden.
        // Without network access, show the unavailable banner instead of a misleading connecting state.
        BOOL netAvailable =
            [[NCChatUI shared] getCurrentNetworkStatus] != NCChatUINetworkStatusNotReachable;
        showBar = !netAvailable;
    }
    // NetworkUnavailable, Unknown, and other disconnected states use the same unavailable fallback as Android.

    if (showBar) {
        self.networkIndicatorView.hidden = NO;
        [self.networkIndicatorView setText:NCUILocalizedString(textKey)];
    } else {
        self.networkIndicatorView.hidden = YES;
    }

    if (wasHidden != self.networkIndicatorView.hidden) {
        [self.conversationListTableView reloadData];
    }
}

- (void)updateConnectionStatusView {
    if (!self.showConnectingStatusOnNavigatorBar ||
        !self.dataSource.isConverstaionListAppear) {
        return;
    }

    NCConnectionStatus status = [NCEngine getConnectionStatus];
    // Keep the spinner and banner mutually exclusive. Show the spinner for Connecting or Suspend only when
    // the device has network access; otherwise updateNetworkIndicatorView shows the unavailable banner.
    BOOL netAvailable =
        [[NCChatUI shared] getCurrentNetworkStatus] != NCChatUINetworkStatusNotReachable;
    if ((status == NCConnectionStatusConnecting || status == NCConnectionStatusSuspend) &&
        netAvailable) {
        [self showConnectingView];
    } else {
        [self hideConnectingView];
    }
}

- (void)showConnectingView {
    UINavigationItem *visibleNavigationItem = nil;
    if (self.tabBarController) {
        visibleNavigationItem = self.tabBarController.navigationItem;
    } else if (self.navigationItem) {
        visibleNavigationItem = self.navigationItem;
    }

    if (visibleNavigationItem) {
        if (![visibleNavigationItem.titleView isEqual:self.connectionStatusView]) {
            self.navigationTitleView = visibleNavigationItem.titleView;
            visibleNavigationItem.titleView = self.connectionStatusView;
        }
    }
}

- (void)hideConnectingView {
    UINavigationItem *visibleNavigationItem = nil;
    if (self.tabBarController) {
        visibleNavigationItem = self.tabBarController.navigationItem;
    } else if (self.navigationItem) {
        visibleNavigationItem = self.navigationItem;
    }

    if (visibleNavigationItem) {
        if ([visibleNavigationItem.titleView isEqual:self.connectionStatusView]) {
            visibleNavigationItem.titleView = self.navigationTitleView;
        } else {
            self.navigationTitleView = visibleNavigationItem.titleView;
        }
    }
}

- (void)updateEmptyConversationView {
    if (self.dataSource.dataList.count == 0) {
        self.emptyConversationView.hidden = NO;
    } else {
        self.emptyConversationView.hidden = YES;
    }
}

#pragma mark - Notification selector
- (void)registerObserver {
    [NCEngine addConnectionStatusHandlerWithIdentifier:@"NCChannelListVC" handler:self];
    [NCEngine addChannelHandlerWithIdentifier:@"NCChannelListVC" handler:self];

    // Refresh once because the initial Connected event may arrive before this page registers.
    if ([NCEngine getConnectionStatus] == NCConnectionStatusConnected) {
        [self refreshConversationTableViewIfNeeded];
    }

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshConversationTableViewIfNeeded)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(draftSaveResultDidUpdate:)
                                                 name:NCChatUIChannelDraftSaveResultNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(draftSaveWillBegin:)
                                                 name:NCChatUIChannelDraftSaveWillBeginNotificationName
                                               object:nil];
}

#pragma mark - NCConnectionStatusHandler

- (void)onConnectionStatusChanged:(NCConnectionStatusChangedEvent *)event {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateConnectionStatusView];
        [self updateNetworkIndicatorView];
        if (event.status == NCConnectionStatusConnected) {
            [self refreshConversationTableViewIfNeeded];
        }
    });
}

#pragma mark - NCChannelHandler

- (void)onChannelPinnedSync:(NCChannelPinnedSyncEvent *)event {
    if (!self.dataSource.isConverstaionListAppear) {
        return;
    }
    __weak typeof(self) ws = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (ws.conversationListDataSource.count <= 0) {
            return;
        }
        NSString *channelId = event.channelIdentifier.channelId;
        for (int i = 0; i < ws.conversationListDataSource.count; i++) {
            NCChannelModel *model = ws.conversationListDataSource[i];
            if ([model.channelId isEqualToString:channelId]) {
                model.isTop = event.isPinned;
                [ws refreshConversationTableViewIfNeeded];
                break;
            }
        }
    });
}

- (void)onChannelNoDisturbLevelSync:(NCChannelNoDisturbLevelSyncEvent *)event {
    if (!self.dataSource.isConverstaionListAppear) {
        return;
    }
    __weak typeof(self) ws = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (ws.conversationListDataSource.count <= 0) {
            return;
        }
        NSString *channelId = event.channelIdentifier.channelId;
        for (int i = 0; i < ws.conversationListDataSource.count; i++) {
            NCChannelModel *model = ws.conversationListDataSource[i];
            if ([model.channelId isEqualToString:channelId]) {
                model.noDisturbLevel = event.level;
                NSInteger refreshIndex = [ws.conversationListDataSource indexOfObject:model];
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:refreshIndex inSection:0];
                [ws.conversationListTableView reloadRowsAtIndexPaths:@[ indexPath ]
                                                    withRowAnimation:UITableViewRowAnimationNone];
                break;
            }
        }
    });
}

- (void)onChannelUnreadStatusSync:(NCChannelUnreadStatusSyncEvent *)event {
    if (!self.dataSource.isConverstaionListAppear) {
        return;
    }
    NCChannelIdentifier *identifier = event.channelIdentifier;
    if (!identifier ||
        ![self.displayConversationTypeArray containsObject:@(identifier.channelType)]) {
        return;
    }
    [self.dataSource syncUnreadStatusForChannelIdentifier:identifier];
}

- (void)draftSaveResultDidUpdate:(NSNotification *)notification {
    NSDictionary *dict = notification.userInfo;
    if (![dict isKindOfClass:[NSDictionary class]]) {
        return;
    }
    NSString *channelId = dict[@"channelId"];
    NSString *subChannelId = dict[@"subChannelId"];
    NSString *draft = dict[@"draft"];
    NSNumber *channelTypeNumber = dict[@"channelType"];
    BOOL updated = [dict[@"updated"] boolValue];
    if (!channelTypeNumber || channelId.length == 0) {
        return;
    }
    NCChannelType channelType = (NCChannelType)channelTypeNumber.integerValue;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!updated) {
            [self finishPendingDraftSaveWithoutUpdate];
            return;
        }
        NSString *normalizedDraft = [draft isKindOfClass:[NSString class]] ? draft : @"";
        [self cachePendingDraft:normalizedDraft
                    channelType:channelType
                      channelId:channelId
                   subChannelId:subChannelId];
        NCChannelModel *conversationModel;
        for (NCChannelModel *model in self.conversationListDataSource) {
            if (![model isMatchingChannelType:channelType
                                     channelId:channelId]) {
                continue;
            }
            NSString *leftSubChannelId = model.subChannelId ?: @"";
            NSString *rightSubChannelId = subChannelId ?: @"";
            if (![leftSubChannelId isEqualToString:rightSubChannelId]) {
                continue;
            }
            conversationModel = model;
            break;
        }
        if (conversationModel) {
            NSInteger index = [self.conversationListDataSource indexOfObject:conversationModel];
            if (NSNotFound == index) {
                return;
            }
            conversationModel.draft = normalizedDraft;
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
            [self.conversationListTableView reloadRowsAtIndexPaths:@[indexPath]
                                                  withRowAnimation:UITableViewRowAnimationNone];
        }
        [self finishPendingDraftSaveAfterUpdate];
    });
}

- (void)draftSaveWillBegin:(NSNotification *)notification {
    void (^work)(void) = ^{
        self.pendingDraftSaveCount += 1;
    };
    if ([NSThread isMainThread]) {
        work();
    } else {
        dispatch_async(dispatch_get_main_queue(), work);
    }
}

- (void)finishPendingDraftSaveAfterUpdate {
    if (self.pendingDraftSaveCount > 0) {
        self.pendingDraftSaveCount -= 1;
    }
    if (self.pendingDraftSaveCount == 0) {
        self.needsRefreshAfterDraftSave = NO;
    }
    if (self.dataSource.isConverstaionListAppear) {
        [self refreshConversationTableViewIfNeeded];
    }
}

- (void)finishPendingDraftSaveWithoutUpdate {
    if (self.pendingDraftSaveCount > 0) {
        self.pendingDraftSaveCount -= 1;
    }
    if (self.pendingDraftSaveCount > 0) {
        return;
    }

    BOOL shouldRefresh = self.needsRefreshAfterDraftSave;
    self.needsRefreshAfterDraftSave = NO;
    if (shouldRefresh && self.dataSource.isConverstaionListAppear) {
        [self refreshConversationTableViewIfNeeded];
    }
}

#pragma mark - View Setter&Getter

- (NCMJRefreshAutoNormalFooter *)footer {
    if(!_footer) {
        _footer = [NCMJRefreshAutoNormalFooter footerWithRefreshingTarget:self refreshingAction:@selector(loadMore)];
        _footer.refreshingTitleHidden = YES;
    }
    return _footer;
}

- (NCNetworkIndicatorView *)networkIndicatorView {
    if (!_networkIndicatorView) {
        _networkIndicatorView = [[NCNetworkIndicatorView alloc]
            initWithText:NCUILocalizedString(@"connection_is_not_reachable")];
        _networkIndicatorView.backgroundColor = NCDynamicColor(@"network_Indicator_view_bg_color");
        [_networkIndicatorView setFrame:CGRectMake(0, 0, self.view.bounds.size.width, 48)];
        _networkIndicatorView.hidden = YES;
    }
    return _networkIndicatorView;
}

- (UIView *)connectionStatusView {
    if (!_connectionStatusView) {
        _connectionStatusView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 44)];

        UIActivityIndicatorView *indicatorView = [[UIActivityIndicatorView alloc] init];
        [indicatorView startAnimating];
        [_connectionStatusView addSubview:indicatorView];

        NSString *loading = NCUILocalizedString(@"connecting");
        CGSize textSize = [NCChatUIUtility getTextDrawingSize:loading
                                                      font:[[NCChatUIConfig defaultConfig].font fontOfSecondLevel]
                                           constrainedSize:CGSizeMake(_connectionStatusView.frame.size.width, 2000)];

        CGRect frame = CGRectMake(
            (_connectionStatusView.frame.size.width - (indicatorView.frame.size.width + textSize.width + 3)) / 2,
            (_connectionStatusView.frame.size.height - indicatorView.frame.size.height) / 2,
            indicatorView.frame.size.width, indicatorView.frame.size.height);
        indicatorView.frame = frame;
        frame = CGRectMake(indicatorView.frame.origin.x + 14 + indicatorView.frame.size.width,
                           (_connectionStatusView.frame.size.height - textSize.height) / 2, textSize.width,
                           textSize.height);
        UILabel *label = [[UILabel alloc] initWithFrame:frame];
        [label setFont:[[NCChatUIConfig defaultConfig].font fontOfSecondLevel]];
        [label setText:loading];
        [_connectionStatusView addSubview:label];
    }
    return _connectionStatusView;
}

@synthesize emptyConversationView = _emptyConversationView;
- (UIView *)emptyConversationView {
    if (!_emptyConversationView) {
        _emptyConversationView = [[NCBaseImageView alloc] initWithImage:NCDynamicImage(@"channel-list_no_message_img")];
        _emptyConversationView.center = self.view.center;
        CGRect emptyRect = _emptyConversationView.frame;
        emptyRect.origin.y -= 36;
        [_emptyConversationView setFrame:emptyRect];
        UILabel *emptyLabel =
            [[UILabel alloc] init];
        emptyLabel.text = NCUILocalizedString(@"no_message");
        [emptyLabel setFont:[[NCChatUIConfig defaultConfig].font fontOfFourthLevel]];
        [emptyLabel setTextColor:NCDynamicColor(@"text_primary_color")];
        emptyLabel.textAlignment = NSTextAlignmentCenter;
        [emptyLabel sizeToFit];
        emptyLabel.center = CGPointMake(_emptyConversationView.bounds.size.width/2, _emptyConversationView.frame.size.height + emptyLabel.frame.size.height/2);
        [_emptyConversationView addSubview:emptyLabel];
        [self.conversationListTableView addSubview:_emptyConversationView];
    }
    return _emptyConversationView;
}

- (void)setEmptyConversationView:(UIView *)emptyConversationView {
    if (_emptyConversationView) {
        [_emptyConversationView removeFromSuperview];
    }
    _emptyConversationView = emptyConversationView;
    [self.conversationListTableView addSubview:_emptyConversationView];
}

- (void)setShowConnectingStatusOnNavigatorBar:(BOOL)showConnectingStatusOnNavigatorBar {
    _showConnectingStatusOnNavigatorBar = showConnectingStatusOnNavigatorBar;
    if (!_showConnectingStatusOnNavigatorBar) {
        [self hideConnectingView];
    }
}

- (void)setConversationListDataSource:(NSMutableArray *)conversationListDataSource {
    self.dataSource.dataList = conversationListDataSource;
}

- (NSMutableArray *)conversationListDataSource {
    return self.dataSource.dataList;
}

- (void)setDisplayConversationTypeArray:(NSArray *)displayConversationTypeArray {
    self.dataSource.displayConversationTypeArray = [self filteredDisplayConversationTypes:displayConversationTypeArray];
}

- (NSArray *)displayConversationTypeArray {
    return self.dataSource.displayConversationTypeArray;
}

- (void)setCellBackgroundColor:(UIColor *)cellBackgroundColor {
    self.dataSource.cellBackgroundColor = cellBackgroundColor;
}

- (UIColor *)cellBackgroundColor {
    return self.dataSource.cellBackgroundColor;
}

- (void)setTopCellBackgroundColor:(UIColor *)topCellBackgroundColor {
    self.dataSource.topCellBackgroundColor = topCellBackgroundColor;
}

- (UIColor *)topCellBackgroundColor {
    return self.dataSource.topCellBackgroundColor;
}

#pragma mark - Hooks
- (void)notifyUpdateUnreadMessageCount {
}
- (void)didTapCellPortrait:(NCChannelModel *)model {
}
- (void)didLongPressCellPortrait:(NCChannelModel *)model {
}
- (NSMutableArray<NCChannelModel *> *)willReloadTableData:(NSMutableArray<NCChannelModel *> *)dataSource {
    return dataSource;
}
- (void)willDisplayConversationTableCell:(NCChannelListBaseCell *)cell atIndexPath:(NSIndexPath *)indexPath {
}
- (void)updateCellAtIndexPath:(NSIndexPath *)indexPath {
}
- (void)onSelectedTableRow:(NCChannelModelType)conversationModelType
         conversationModel:(NCChannelModel *)model
               atIndexPath:(NSIndexPath *)indexPath {
    if (self.navigationController) {
        NCChannelType channelType = model.channelType;
        if (channelType == NCChannelTypeOpen) {
            return;
        }
        NCChannelViewController *conversationVC =
            [[NCChannelViewController alloc] initWithChannelType:channelType
                                                                  channelId:model.channelId];
        conversationVC.channelType = channelType;
        conversationVC.channelId = model.channelId;
        conversationVC.subChannelId = model.subChannelId;
        conversationVC.title = model.conversationTitle;
        if (model.conversationModelType == NC_CONVERSATION_MODEL_TYPE_NORMAL) {
            conversationVC.unReadMessage = model.unreadMessageCount;
            conversationVC.enableNewComingMessageIcon = YES; // Enable the new-message indicator.
            conversationVC.enableUnreadMessageIcon = YES;
        }
        [self.navigationController pushViewController:conversationVC animated:YES];
    }else{
        NCLogI(@"navigationController is nil , Please Rewrite `onSelectedTableRow:conversationModel:atIndexPath:` method to implement the conversation cell click to push NCChannelViewController vc");
    }
}
- (void)didDeleteConversationCell:(NCChannelModel *)model {
}
- (void)ncChannelListTableView:(UITableView *)tableView
                commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
                 forRowAtIndexPath:(NSIndexPath *)indexPath {
}
- (NCChannelListBaseCell *)ncChannelListTableView:(UITableView *)tableView
                                 cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return nil;
}
- (CGFloat)ncChannelListTableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 64.5f;
}

#pragma mark - Backward Compatibility

- (void)setDisplayConversationTypes:(NSArray *)channelTypeArray {
    self.displayConversationTypeArray = channelTypeArray;
}

- (NSArray *)filteredDisplayConversationTypes:(NSArray *)displayConversationTypeArray {
    if (displayConversationTypeArray.count == 0) {
        return displayConversationTypeArray;
    }

    NSMutableArray *filteredTypes = [[NSMutableArray alloc] init];
    for (NSNumber *typeNumber in displayConversationTypeArray) {
        NCChannelType channelType = (NCChannelType)typeNumber.integerValue;
        switch (channelType) {
            case NCChannelTypeDirect:
            case NCChannelTypeGroup:
            case NCChannelTypeSystem:
            case NCChannelTypeCommunity:
                [filteredTypes addObject:typeNumber];
                break;
            default:
                break;
        }
    }
    return filteredTypes.copy;
}
- (void)setConversationAvatarStyle:(NCUserAvatarStyle)avatarStyle {
    NCChatUIConfigCenter.ui.globalConversationAvatarStyle = avatarStyle;
}
- (void)setConversationPortraitSize:(CGSize)size {
    NCChatUIConfigCenter.ui.globalConversationPortraitSize = size;
}
- (void)refreshConversationTableViewWithConversationModel:(NCChannelModel *)conversationModel {
    [self.dataSource refreshConversationForChannelType:conversationModel.channelType
                                             channelId:conversationModel.channelId
                                          subChannelId:conversationModel.subChannelId];
}

#pragma mark - traitCollection
- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    [self fitDarkMode];
}

- (void)fitDarkMode {
    if (!NCChatUIConfigCenter.ui.enableDarkMode) {
        return;
    }
    if (@available(iOS 13.0, *)) {
        self.networkIndicatorView.networkUnreachableImageView.image = NCDynamicImage(@"network_unreachable_img");
        if ([self.emptyConversationView isKindOfClass:[UIImageView class]]) {
            UIImageView *imageView = (UIImageView *)self.emptyConversationView;
            if (imageView.image.nc_imageLocalPath && imageView.image.nc_imageLocalPath.length > 0 &&
                [imageView.image nc_needReloadImage]) {
                imageView.image = [UIImage nc_imageWithLocalPath:imageView.image.nc_imageLocalPath];
            }
        }
        if (self.dataSource.isConverstaionListAppear) {
            [self.conversationListTableView reloadData];
        }
    }
}
@end
