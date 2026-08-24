//
//  NCSelectChannelViewController.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCSelectChannelViewController.h"
#import "NCBaseTableView.h"
#import "NCChatUI.h"
#import "NCChatUICommonDefine.h"
#import "NCChatUIConfig.h"
#import "NCChatUIUtility.h"
#import "NCSelectChannelCell.h"
typedef void (^CompleteBlock)(NSArray<NCBaseChannel *> *conversationList);

@interface NCSelectChannelViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) NSMutableArray<NCBaseChannel *> *selectedConversationArray;

@property (nonatomic, strong) NCBaseTableView *conversationTableView;

@property (nonatomic, strong) UIBarButtonItem *rightBarButtonItem;

@property (nonatomic, strong) NSArray<NCBaseChannel *> *listingConversationArray;

@property (nonatomic, strong, nullable) NCChannelsQuery *channelsQuery;

@property (nonatomic, strong) CompleteBlock completeBlock;

@end

@implementation NCSelectChannelViewController
#pragma mark - Life Cycle
- (instancetype)initSelectConversationViewControllerCompleted:
    (void (^)(NSArray<NCBaseChannel *> *conversationList))completedBlock {
    if (self = [super init]) {
        self.completeBlock = completedBlock;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupNavi];
    self.view.backgroundColor = NCDynamicColor(@"auxiliary_background_1_color");
    [self.view addSubview:self.conversationTableView];
    self.selectedConversationArray = [[NSMutableArray alloc] init];
    [self loadConversationList];
}

- (void)loadConversationList {
    NCChannelsQueryParams *params = [[NCChannelsQueryParams alloc] init];
    params.channelTypes = @[ @(NCChannelTypeDirect), @(NCChannelTypeGroup) ];
    params.pageSize = 200;
    self.channelsQuery = [NCBaseChannel createChannelsQueryWithParams:params];
    __weak typeof(self) weakSelf = self;
    [self.channelsQuery loadNextPageWithCompletion:^(NSArray<NCBaseChannel *> *_Nullable channels,
                                                     NCError *_Nullable error) {
      __strong typeof(weakSelf) strongSelf = weakSelf;
      if (!strongSelf) {
          return;
      }
      dispatch_async(dispatch_get_main_queue(), ^{
        strongSelf.listingConversationArray = channels ?: @[];
        [strongSelf.conversationTableView reloadData];
      });
    }];
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (!self.listingConversationArray) {
        return 0;
    } else {
        return self.listingConversationArray.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.listingConversationArray.count <= indexPath.row) {
        return nil;
    }

    static NSString *reusableID = @"NCSelectChannelCell";
    NCSelectChannelCell *cell = [tableView dequeueReusableCellWithIdentifier:reusableID];
    if (!cell) {
        cell = [[NCSelectChannelCell alloc] initWithStyle:UITableViewCellStyleDefault
                                          reuseIdentifier:reusableID];
    }

    NCBaseChannel *conversation = self.listingConversationArray[indexPath.row];
    BOOL ifSelected = [self.selectedConversationArray containsObject:conversation];
    [cell setConversation:conversation ifSelected:ifSelected];

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 70;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row >= self.listingConversationArray.count) {
        return;
    }
    NCBaseChannel *channel = self.listingConversationArray[indexPath.row];
    if ([self.selectedConversationArray containsObject:channel]) {
        [self.selectedConversationArray removeObject:channel];
    } else if (channel) {
        [self.selectedConversationArray addObject:channel];
    }
    [self updateRightButton];
    [UIView performWithoutAnimation:^{
      [self.conversationTableView reloadRowsAtIndexPaths:@[ indexPath ]
                                        withRowAnimation:UITableViewRowAnimationNone];
    }];
}

#pragma mark - Target Action

- (void)onLeftButtonClick:(id)sender {
    [self.navigationController popViewControllerAnimated:NO];
}

- (void)onRightButtonClick:(id)sender {
    if (!self.selectedConversationArray) {
        return;
    }
    if (self.completeBlock) {
        self.completeBlock(self.selectedConversationArray.copy);
    }
    [self.navigationController popViewControllerAnimated:NO];
}

#pragma mark - Private Methods
- (void)setupNavi {
    self.title = NCUILocalizedString(@"select_contact");
    UIBarButtonItem *leftBarItem =
        [[UIBarButtonItem alloc] initWithTitle:NCUILocalizedString(@"cancel")
                                         style:UIBarButtonItemStylePlain
                                        target:self
                                        action:@selector(onLeftButtonClick:)];
    leftBarItem.tintColor = NCChatUIConfigCenter.ui.globalNavigationBarTintColor;
    self.navigationItem.leftBarButtonItem = leftBarItem;

    self.rightBarButtonItem =
        [[UIBarButtonItem alloc] initWithTitle:NCUILocalizedString(@"ok")
                                         style:UIBarButtonItemStylePlain
                                        target:self
                                        action:@selector(onRightButtonClick:)];
    self.rightBarButtonItem.tintColor = NCChatUIConfigCenter.ui.globalNavigationBarTintColor;
    self.navigationItem.rightBarButtonItem = self.rightBarButtonItem;

    [self updateRightButton];
}

- (void)updateRightButton {
    [self.rightBarButtonItem setEnabled:self.selectedConversationArray.count > 0];
}

#pragma mark - Getters and Setters

- (NCBaseTableView *)conversationTableView {
    if (!_conversationTableView) {
        CGFloat homeBarHeight = [NCChatUIUtility getWindowSafeAreaInsets].bottom;
        CGRect frame =
            CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y,
                       self.view.frame.size.width, self.view.frame.size.height - homeBarHeight);
        _conversationTableView = [[NCBaseTableView alloc] initWithFrame:frame
                                                                  style:UITableViewStyleGrouped];
        _conversationTableView.estimatedRowHeight = 0;
        _conversationTableView.estimatedSectionHeaderHeight = 0;
        _conversationTableView.estimatedSectionFooterHeight = 0;
        _conversationTableView.dataSource = self;
        _conversationTableView.delegate = self;
        _conversationTableView.backgroundColor = [UIColor clearColor];
        _conversationTableView.tableFooterView = [[UIView alloc] init];
    }
    return _conversationTableView;
}

@end
