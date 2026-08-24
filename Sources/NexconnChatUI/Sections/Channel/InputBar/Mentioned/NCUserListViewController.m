//
//  NCUserListViewController.m
//  NCChatUIExtension
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCUserListViewController.h"
#import "NCBaseTableView.h"
#import "NCChatUICommonDefine.h"
#import "NCChatUIConfig.h"
#import "NCImageView.h"
#import "NCInfoUpdateCenter.h"
#import "NCUserInfoCache.h"
#import "NCUserListTableViewCell.h"

@interface NCUserListViewController () <UITableViewDelegate, UITableViewDataSource,
                                        UISearchBarDelegate, UISearchControllerDelegate,
                                        UISearchResultsUpdating, NCInfoUpdateDelegate> {
    NSMutableArray *_tempOtherArr;
    NSMutableDictionary *allUsers;
    NSArray *allKeys;
}

@property (nonatomic, strong) NCBaseTableView *tableView;
@property (nonatomic, strong) NSMutableArray *dataArr;
@property (nonatomic, strong) UISearchController *searchController; // Search controller
@property (nonatomic, strong) dispatch_queue_t sortDataQueue;

@end

#define kScreenWidth [UIScreen mainScreen].bounds.size.width
#define kScreenHeight [UIScreen mainScreen].bounds.size.height

static NSString *NCManagedUserDisplayName(NCChatUIUserInfo *user) {
    if (user.alias.length > 0) {
        return user.alias;
    }
    if (user.name.length > 0) {
        return user.name;
    }
    return user.userId ?: @"";
}

@implementation NCUserListViewController {
    NSMutableArray *_searchResultArr; // Search results
}

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.definesPresentationContext = YES;
    self.tableView.backgroundColor = NCDynamicColor(@"common_background_color");
    [self registerUserInfoObserver];
    if ([self respondsToSelector:@selector(setExtendedLayoutIncludesOpaqueBars:)]) {
        [self setExtendedLayoutIncludesOpaqueBars:YES];
    }
    self.sortDataQueue = dispatch_queue_create("ai.nexconn.selectingSortDataQueue", NULL);

    allUsers = [NSMutableDictionary new];
    allKeys = [NSMutableArray new];
    self.dataArr = [NSMutableArray array];
    allUsers = nil; //[self sortedArrayWithPinYinDic:self.dataArr];
    [self.tableView reloadData];

    [self.dataSource getSelectingUserIdList:^(NSArray<NSString *> *userIdList) {
      [self loadAllUserInfoList:userIdList];
    }];

    // configNav
    [self configNav];
    // Lay out the view.
    [self setUpView];
    _searchResultArr = [NSMutableArray array];
}

- (void)dealloc {
    [NCInfoUpdateCenter removeInfoUpdateDelegate:self];
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // section
    if (self.searchController.active) {
        return 1;
    } else {
        return allKeys.count;
    }
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // row
    if (self.searchController.active) {
        return _searchResultArr.count;
    } else {
        if (section < 0 || section >= allKeys.count) {
            return 0;
        }
        NSString *key = [allKeys objectAtIndex:section];
        NSArray *arr = [allUsers objectForKey:key];
        return [arr count];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return NCChatUIConfigCenter.ui.globalMessagePortraitSize.height + 5 + 5;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    if (self.searchController.active) {
        return allKeys;
    } else {
        return nil;
    }
}
- (NSInteger)tableView:(UITableView *)tableView
    sectionForSectionIndexTitle:(NSString *)title
                        atIndex:(NSInteger)index {
    return index;
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIde = @"cellIde";
    NCUserListTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIde];
    if (cell == nil) {
        cell = [[NCUserListTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                              reuseIdentifier:cellIde];
    }
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];

    NCChatUIUserInfo *user = nil;
    user = [self userInfoAtIndexPath:indexPath];
    if (!user) {
        [tableView reloadData];
        return cell;
    }
    if (user.userId.length > 0) {
        NCChatUIUserInfo *cachedUserInfo = [[NCUserInfoCache sharedCache] getUserInfo:user.userId];
        user.alias = cachedUserInfo.alias;
    }

    [cell.nameLabel setText:NCManagedUserDisplayName(user)];
    cell.headImageView = [self portraitView:[NSURL URLWithString:user.avatarUrl]];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NCChatUIUserInfo *user = [self userInfoAtIndexPath:indexPath];
    if (user.userId.length == 0) {
        [tableView reloadData];
        return;
    }
    if (self.selectedBlock) {
        self.selectedBlock(user);
    }
    [self.searchController.searchBar resignFirstResponder];
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - searchController delegate

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    [self filterContentForSearchText:self.searchController.searchBar.text scope:nil];
}

#pragma mark - Notification
- (void)registerUserInfoObserver {
    [NCInfoUpdateCenter addInfoUpdateDelegate:self];
}

- (void)onUserInfoUpdate:(NCChatUIUserInfo *)userInfo {
    NSString *userId = userInfo.userId;
    __block NCChatUIUserInfo *needUpdateUserInfo = nil;
    NSArray *safeArray = [self.dataArr copy];
    for (NCChatUIUserInfo *userInfo in safeArray) {
        if ([userInfo.userId isEqualToString:userId]) {
            needUpdateUserInfo = userInfo;
            break;
        }
    }
    if (needUpdateUserInfo) {
        dispatch_async(self.sortDataQueue, ^{
          NCChatUIUserInfo *userInfo =
              [self.dataSource getSelectingUserInfo:needUpdateUserInfo.userId];
          if (!userInfo) {
              return;
          }
          needUpdateUserInfo.name = userInfo.name;
          needUpdateUserInfo.avatarUrl = userInfo.avatarUrl;
          NSMutableDictionary *tmpDict = [self sortedArrayWithPinYinDic:safeArray];
          dispatch_async(dispatch_get_main_queue(), ^{
            needUpdateUserInfo.alias = userInfo.alias;
            allUsers = tmpDict;
            allKeys = [[tmpDict allKeys]
                sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                  return [obj1 compare:obj2 options:NSNumericSearch];
                }];
            if (self.searchController.active) {
                [self filterContentForSearchText:self.searchController.searchBar.text scope:nil];
            } else {
                [self.tableView reloadData];
            }
          });
        });
    }
}

- (void)onGroupMemberInfoUpdate:(NCChatUIUserInfo *)userInfo groupId:(NSString *)groupId {
    [self onUserInfoUpdate:userInfo];
}

#pragma mark - Private Methods
- (NCChatUIUserInfo *)userInfoAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section < 0 || indexPath.row < 0) {
        return nil;
    }
    if (self.searchController.active) {
        if (indexPath.section != 0 || indexPath.row >= _searchResultArr.count) {
            return nil;
        }
        id user = _searchResultArr[indexPath.row];
        return [user isKindOfClass:[NCChatUIUserInfo class]] ? user : nil;
    }

    if (indexPath.section >= allKeys.count) {
        return nil;
    }
    NSString *key = allKeys[indexPath.section];
    NSArray *arrayForKey = [allUsers objectForKey:key];
    if (indexPath.row >= arrayForKey.count) {
        return nil;
    }
    id user = arrayForKey[indexPath.row];
    return [user isKindOfClass:[NCChatUIUserInfo class]] ? user : nil;
}

- (void)setUpView {
    [self.view addSubview:self.tableView];
}

- (void)loadAllUserInfoList:(NSArray *)userIdList {
    dispatch_async(self.sortDataQueue, ^{
      [self.dataArr removeAllObjects];
      NSString *currentUserId = [NCEngine getCurrentUserId];
      for (NSString *userId in userIdList) {
          if (![userId isEqualToString:currentUserId]) {
              NCChatUIUserInfo *userInfo = [self.dataSource getSelectingUserInfo:userId];
              if (userInfo) {
                  [self.dataArr addObject:userInfo];
              } else {
                  NCChatUIUserInfo *placeholderUserInfo = [NCChatUIUserInfo new];
                  placeholderUserInfo.userId = userId;
                  [self.dataArr addObject:placeholderUserInfo];
              }
          }
      }

      NSMutableDictionary *tmpDict = [self sortedArrayWithPinYinDic:self.dataArr];
      dispatch_async(dispatch_get_main_queue(), ^{
        allUsers = tmpDict;
        allKeys =
            [[tmpDict allKeys] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
              return [obj1 compare:obj2 options:NSNumericSearch];
            }];

        [self.tableView reloadData];
      });
    });
}

- (void)configNav {
    self.navigationItem.title = self.navigationTitle;
    UIBarButtonItem *leftButton =
        [[UIBarButtonItem alloc] initWithTitle:NCUILocalizedString(@"cancel")
                                         style:(UIBarButtonItemStylePlain)target:self
                                        action:@selector(leftBarButtonItemPressed:)];
    [self.navigationItem setLeftBarButtonItem:leftButton];
}

- (void)leftBarButtonItemPressed:(id)sender {
    if (_cancelBlock) {
        _cancelBlock();
    }
    [self.searchController.searchBar resignFirstResponder];
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

// Returns whether the source string contains or equals the search text.
- (void)filterContentForSearchText:(NSString *)searchText scope:(NSString *)scope {
    if (searchText.length == 0) {
        [_searchResultArr removeAllObjects];
        [self.tableView reloadData];
        return;
    }

    NSMutableArray *tempResults = [NSMutableArray array];
    NSUInteger searchOptions = NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch;
    NSArray *safeArray = [self.dataArr copy];
    for (NCChatUIUserInfo *user in safeArray) {
        NSString *displayName = NCManagedUserDisplayName(user);
        NSArray<NSString *> *candidates = @[
            displayName, user.alias ?: @"", user.name ?: @"", user.userId ?: @"",
            [NCChatUIUtility getPinYinUpperFirstLetters:displayName] ?: @""
        ];
        for (NSString *candidate in candidates) {
            if (candidate.length > 0 &&
                [candidate rangeOfString:searchText options:searchOptions].location != NSNotFound) {
                [tempResults addObject:user];
                break;
            }
        }
    }
    [_searchResultArr removeAllObjects];
    [_searchResultArr addObjectsFromArray:tempResults];
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSMutableDictionary *)sortedArrayWithPinYinDic:(NSArray *)friends {
    if (!friends)
        return nil;
    NSArray *_keys = @[
        @"A", @"B", @"C", @"D", @"E", @"F", @"G", @"H", @"I", @"J", @"K", @"L", @"M",
        @"N", @"O", @"P", @"Q", @"R", @"S", @"T", @"U", @"V", @"W", @"X", @"Y", @"Z",
    ];

    NSMutableDictionary *returnDic = [NSMutableDictionary new];
    _tempOtherArr = [NSMutableArray new];
    BOOL isReturn = NO;

    for (NSString *key in _keys) {

        if ([_tempOtherArr count]) {
            isReturn = YES;
        }

        NSMutableArray *tempArr = [NSMutableArray new];
        for (NCChatUIUserInfo *user in friends) {
            NSString *pyResult =
                [NCChatUIUtility getPinYinUpperFirstLetters:NCManagedUserDisplayName(user)];
            if (pyResult.length <= 0) {
                if (!isReturn) {
                    [_tempOtherArr addObject:user];
                }
                continue;
            }

            NSString *firstLetter = [pyResult substringToIndex:1];
            if ([firstLetter isEqualToString:key]) {
                [tempArr addObject:user];
            }

            if (isReturn)
                continue;
            char c = [pyResult characterAtIndex:0];
            if (isalpha(c) == 0) {
                [_tempOtherArr addObject:user];
            }
        }
        if (![tempArr count])
            continue;
        [returnDic setObject:tempArr forKey:key];
    }
    if ([_tempOtherArr count])
        [returnDic setObject:_tempOtherArr forKey:@"#"];

    return returnDic;
}

- (UIImageView *)portraitView:(NSURL *)portraitURL {
    NCImageView *portraitView = [[NCImageView alloc] init];
    portraitView.frame =
        CGRectMake(10.0, 5.0, NCChatUIConfigCenter.ui.globalMessagePortraitSize.width,
                   NCChatUIConfigCenter.ui.globalMessagePortraitSize.height);
    if ([NCChatUIUtility isRTL]) {
        portraitView.frame =
            CGRectMake(self.view.bounds.size.width -
                           NCChatUIConfigCenter.ui.globalMessagePortraitSize.height - 10,
                       5.0, NCChatUIConfigCenter.ui.globalMessagePortraitSize.width,
                       NCChatUIConfigCenter.ui.globalMessagePortraitSize.height);
    }
    [portraitView setPlaceholderImage:NCDynamicImage(@"channel-list_cell_portrait_msg_img")];
    [portraitView setImageURL:portraitURL];

    if (NCChatUIConfigCenter.ui.globalMessageAvatarStyle == NC_USER_AVATAR_RECTANGLE) {
        portraitView.layer.cornerRadius = NCChatUIConfigCenter.ui.portraitImageViewCornerRadius;
    } else if (NCChatUIConfigCenter.ui.globalMessageAvatarStyle == NC_USER_AVATAR_CYCLE) {
        portraitView.layer.cornerRadius =
            NCChatUIConfigCenter.ui.globalMessagePortraitSize.height / 2;
    }
    portraitView.layer.masksToBounds = YES;
    portraitView.contentMode = UIViewContentModeScaleAspectFill;

    return portraitView;
}

#pragma mark - Getters and Setters
- (UISearchController *)searchController {
    if (!_searchController) {
        _searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
        _searchController.delegate = self;
        [_searchController.searchBar sizeToFit];
        _searchController.searchResultsUpdater = self;
        // Search prompt
        _searchController.searchBar.placeholder = NCUILocalizedString(@"to_search");
        [_searchController.searchBar setKeyboardType:UIKeyboardTypeDefault];
        // Configure the search bar background color.
        _searchController.searchBar.barTintColor = NCDynamicColor(@"common_background_color");
        _searchController.searchBar.layer.borderColor =
            NCDynamicColor(@"common_background_color").CGColor;
        _searchController.searchBar.layer.borderWidth = 1;
        if (@available(iOS 13.0, *)) {
            _searchController.searchBar.searchTextField.backgroundColor =
                NCDynamicColor(@"auxiliary_background_1_color");
        }
        _searchController.dimsBackgroundDuringPresentation = NO;
        if ([NCChatUIUtility isRTL]) {
            _searchController.searchBar.semanticContentAttribute =
                UISemanticContentAttributeForceRightToLeft;
        } else {
            _searchController.searchBar.semanticContentAttribute =
                UISemanticContentAttributeForceLeftToRight;
        }
    }
    return _searchController;
}

- (NCBaseTableView *)tableView {
    if (!_tableView) {
        _tableView =
            [[NCBaseTableView alloc] initWithFrame:CGRectMake(0.0, 0.0, kScreenWidth, kScreenHeight)
                                             style:UITableViewStyleGrouped];
        _tableView.estimatedRowHeight = 0;
        _tableView.estimatedSectionHeaderHeight = 0;
        _tableView.estimatedSectionFooterHeight = 0;
        [_tableView setDelegate:self];
        [_tableView setDataSource:self];
        [_tableView setSectionIndexBackgroundColor:[UIColor clearColor]];
        [_tableView setSectionIndexColor:[UIColor darkGrayColor]];
        [_tableView setBackgroundColor:NCDynamicColor(@"auxiliary_background_1_color")];
        // Hide separators when there are no rows.
        UIView *v = [[UIView alloc] initWithFrame:CGRectZero];
        [_tableView setTableFooterView:v];
        _tableView.tableHeaderView = self.searchController.searchBar;
    }
    return _tableView;
}

@end
