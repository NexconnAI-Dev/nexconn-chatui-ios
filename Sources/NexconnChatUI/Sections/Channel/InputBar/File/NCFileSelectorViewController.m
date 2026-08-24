//
//  NCFileSelectorViewController.m
//  NCChatUIExtension
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCFileSelectorViewController.h"
#import "NCAlertView.h"
#import "NCChatUICommonDefine.h"
#import "NCChatUIConfig.h"
#import "NCSelectDirectoryTableViewCell.h"
#import "NCSelectFilesTableViewCell.h"
#import "NCSemanticContext.h"
@interface NCFileSelectorViewController ()

@property (nonatomic, strong) NSString *rootPath;
@property (nonatomic, assign) int maxSelectedNumber;
@property (nonatomic, strong) NSMutableArray *dataSource;
@property (nonatomic, strong) UIBarButtonItem *rightItem;
@property (nonatomic, strong) UIButton *buttonDone;
@property (nonatomic, strong) dispatch_queue_t directoryScanQueue;
@property (nonatomic, assign) NSUInteger dataSourceLoadRequestId;
@property (nonatomic, strong) UIView *directoryLoadingView;
@property (nonatomic, strong) UIActivityIndicatorView *directoryLoadingIndicatorView;
@end

static NSString *const NCFileValue = @"file";
static NSString *const NCDirectotyValue = @"Directory";
static NSString *const NCTypeValue = @"Type";
static NSString *const NCListValue = @"List";

@implementation NCFileSelectorViewController
#pragma mark - Life Cycle
- (instancetype)initWithRootPath:(NSString *)rootPath {
    self = [super init];
    if (self) {
        self.rootPath = rootPath;
        self.maxSelectedNumber = 20;
        self.directoryScanQueue = dispatch_queue_create(
            "ai.nexconn.chatui.file-selector.directory-scan", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Hide separators below the final row.
    self.tableView.tableFooterView = [[UIView alloc] init];
    // Enable multiple selection.
    self.tableView.allowsMultipleSelection = YES;
    // Configure the separator color.
    self.tableView.backgroundColor = NCDynamicColor(@"auxiliary_background_1_color");
    self.tableView.separatorColor = NCDynamicColor(@"line_background_color");

    if ([self.tableView respondsToSelector:@selector(setSeparatorInset:)]) {
        [self.tableView setSeparatorInset:UIEdgeInsetsMake(0, 45, 0, 0)];
    }
    if ([self.tableView respondsToSelector:@selector(setLayoutMargins:)]) {
        [self.tableView setLayoutMargins:UIEdgeInsetsMake(0, 45, 0, 0)];
    }

    self.navigationItem.title = NCUILocalizedString(@"send_file");
    UIImage *imgMirror = NCDynamicImage(@"navigation_bar_btn_back_img");
    imgMirror = [NCSemanticContext imageflippedForRTL:imgMirror];
    if (self.isSubDirectory) {
        self.navigationItem.leftBarButtonItems =
            [NCChatUIUtility getLeftNavigationItems:imgMirror
                                              title:NCUILocalizedString(@"back")
                                             target:self
                                             action:@selector(clickBackBtn:)];
    } else {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        [btn addTarget:self
                      action:@selector(clickCancelBtn:)
            forControlEvents:UIControlEventTouchUpInside];
        UIColor *color = NCChatUIConfigCenter.ui.globalNavigationBarTintColor;
        btn.tintColor = color;
        [btn setTitleColor:color forState:UIControlStateNormal];
        [btn setTitle:NCUILocalizedString(@"cancel") forState:UIControlStateNormal];
        [btn sizeToFit];
        UIBarButtonItem *leftItem = [[UIBarButtonItem alloc] initWithCustomView:btn];

        self.navigationItem.leftBarButtonItem = leftItem;
    }
    [self getDataSourceList];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    UIColor *color = NCDynamicColor(@"primary_color");

    [btn setTitleColor:color forState:UIControlStateNormal];
    [btn addTarget:self
                  action:@selector(clickDoneBtn:)
        forControlEvents:UIControlEventTouchUpInside];
    [btn setTitle:NCUILocalizedString(@"confirm") forState:UIControlStateNormal];
    [btn sizeToFit];
    self.buttonDone = btn;
    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithCustomView:btn];
    [self.navigationItem setRightBarButtonItem:rightItem];
    self.navigationItem.rightBarButtonItem.enabled = NO;
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.dataSource.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSDictionary *dict = self.dataSource[section];
    NSArray *list = dict[NCListValue];
    return list.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *directoryCellReuseIdentifier = @"NCFileSelectorViewControllerDirectoryCellReuseId";
    NSString *cellReuseIdentifier = @"NCFileSelectorViewControllerCellReuseId";

    NSDictionary *dict = self.dataSource[indexPath.section];
    NSArray *list = dict[NCListValue];
    NSString *type = dict[NCTypeValue];

    UITableViewCell *retCell = nil;
    if ([type isEqualToString:NCFileValue]) {
        NCSelectFilesTableViewCell *cell =
            [tableView dequeueReusableCellWithIdentifier:cellReuseIdentifier];
        if (cell == nil) {
            cell = [[NCSelectFilesTableViewCell alloc] init];
        }
        NSString *fileName = list[indexPath.row];
        cell.fileNameLabel.text = fileName;
        cell.fileIconImageView.image =
            [NCChatUIUtility imageWithFileSuffix:[fileName pathExtension]];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        retCell = cell;
    } else {
        NCSelectDirectoryTableViewCell *directoryCell =
            [tableView dequeueReusableCellWithIdentifier:directoryCellReuseIdentifier];
        if (directoryCell == nil) {
            directoryCell = [[NCSelectDirectoryTableViewCell alloc] init];
        }
        NSString *path = list[indexPath.row];
        directoryCell.directoryNameLabel.text = path;
        directoryCell.selectionStyle = UITableViewCellSelectionStyleNone;
        retCell = directoryCell;
    }
    return retCell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 51.5f;
}

- (nullable NSIndexPath *)tableView:(UITableView *)tableView
           willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *indexPaths = [self.tableView indexPathsForSelectedRows];
    if (indexPaths.count >= self.maxSelectedNumber) {
        return nil;
    } else {
        return indexPath;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([[tableView cellForRowAtIndexPath:indexPath]
            isKindOfClass:[NCSelectDirectoryTableViewCell class]]) {
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
        NSString *dir = self.dataSource[indexPath.section][NCListValue][indexPath.row];
        [self selecteDirectory:dir];
    } else if ([[tableView cellForRowAtIndexPath:indexPath]
                   isKindOfClass:[NCSelectFilesTableViewCell class]]) {
        NSDictionary *dict = self.dataSource[indexPath.section];
        NSArray *list = dict[NCListValue];
        NSString *filePath =
            [NSString stringWithFormat:@"%@/%@", self.rootPath, list[indexPath.row]];
        if ([self.delegate respondsToSelector:@selector(canBeSelectedAtPath:)]) {
            if (![self.delegate canBeSelectedAtPath:filePath]) {
                [tableView deselectRowAtIndexPath:indexPath animated:NO];
                return;
            }
        } else {
            if ([self isOverMaximum:filePath]) {
                [tableView deselectRowAtIndexPath:indexPath animated:NO];
                [self presentOverMaximumAlert];
            } else {
                [self selecteFile:(NCSelectFilesTableViewCell *)[tableView
                                      cellForRowAtIndexPath:indexPath]];
            }
        }
    }
    [self updateRightButtonLayout];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self updateRightButtonLayout];
}

#pragma mark - Private Methods
- (NCSelectFilesTableViewCell *)getSelectFilesTableViewCell:(NCSelectFilesTableViewCell *)cell
                                                     source:(NSArray *)source
                                                        row:(NSInteger)row {
    NSString *fileName = [source objectAtIndex:row];
    cell.fileNameLabel.text = fileName;
    cell.fileIconImageView.image = [NCChatUIUtility imageWithFileSuffix:[fileName pathExtension]];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

- (NCSelectDirectoryTableViewCell *)getSelectDirectoryTableViewCell:
                                        (NCSelectDirectoryTableViewCell *)cell
                                                             source:(NSArray *)source
                                                                row:(NSInteger)row {
    cell.directoryNameLabel.text = source[row];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

- (void)selecteFile:(NCSelectFilesTableViewCell *)cell {
    [cell setSelected:YES];
    [self updateRightButtonLayout];
}

- (void)selecteDirectory:(NSString *)directoryName {
    NCFileSelectorViewController *vc = [[NCFileSelectorViewController alloc]
        initWithRootPath:[NSString stringWithFormat:@"%@/%@", self.rootPath, directoryName]];
    vc.isSubDirectory = YES;
    vc.delegate = self.delegate;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)clickBackBtn:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)clickCancelBtn:(id)sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)clickDoneBtn:(id)sender {
    NSMutableArray *selectedFileList = [[NSMutableArray alloc] init];
    for (NSIndexPath *indexPath in [self.tableView indexPathsForSelectedRows]) {
        if (indexPath.section >= self.dataSource.count) {
            continue;
        }
        NSDictionary *dict = self.dataSource[indexPath.section];
        if (![dict[NCTypeValue] isEqualToString:NCFileValue]) {
            continue;
        }
        NSArray *fileList = dict[NCListValue];
        if (indexPath.row >= fileList.count) {
            continue;
        }
        [selectedFileList
            addObject:[NSString stringWithFormat:@"%@/%@", self.rootPath,
                                                 [fileList objectAtIndex:indexPath.row]]];
    }

    if ([self.delegate respondsToSelector:@selector(fileDidSelect:)]) {
        [self.delegate fileDidSelect:[selectedFileList copy]];
    }

    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)getDataSourceList {
    self.dataSourceLoadRequestId += 1;
    NSUInteger requestId = self.dataSourceLoadRequestId;
    NSString *filePath = [self.rootPath copy];

    self.dataSource = [[NSMutableArray alloc] init];
    [self.tableView reloadData];
    [self p_setDirectoryLoading:YES];

    __weak typeof(self) weakSelf = self;
    dispatch_async(self.directoryScanQueue, ^{
      NSArray *dataSource =
          [NCFileSelectorViewController p_dataSourceListForDirectoryPath:filePath];
      dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf || strongSelf.dataSourceLoadRequestId != requestId) {
            return;
        }
        [strongSelf p_setDirectoryLoading:NO];
        strongSelf.dataSource = [dataSource mutableCopy];
        [strongSelf.tableView reloadData];
      });
    });
}

+ (NSArray *)p_dataSourceListForDirectoryPath:(NSString *)filePath {
    if (filePath.length <= 0) {
        return @[];
    }

    NSURL *directoryURL = [NSURL fileURLWithPath:filePath isDirectory:YES];
    NSArray *properties = @[ NSURLIsDirectoryKey ];
    NSArray<NSURL *> *contents =
        [[NSFileManager defaultManager] contentsOfDirectoryAtURL:directoryURL
                                      includingPropertiesForKeys:properties
                                                         options:0
                                                           error:nil];
    NSMutableArray *fileList = [[NSMutableArray alloc] init];
    NSMutableArray *docList = [[NSMutableArray alloc] init];
    for (NSURL *fileURL in contents) {
        NSString *fileName = fileURL.lastPathComponent;
        if (fileName.length <= 0) {
            continue;
        }
        NSNumber *isDirectory = nil;
        [fileURL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:nil];
        if (isDirectory.boolValue) {
            [docList addObject:fileName];
        } else {
            [fileList addObject:fileName];
        }
    }

    [docList sortUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    [fileList sortUsingSelector:@selector(localizedCaseInsensitiveCompare:)];

    NSMutableArray *dataSource = [[NSMutableArray alloc] init];
    if (docList.count > 0) {
        [dataSource addObject:@{NCTypeValue : NCDirectotyValue, NCListValue : docList}];
    }
    if (fileList.count > 0) {
        [dataSource addObject:@{NCTypeValue : NCFileValue, NCListValue : fileList}];
    }
    return [dataSource copy];
}

- (void)p_setDirectoryLoading:(BOOL)loading {
    if (loading) {
        self.tableView.backgroundView = self.directoryLoadingView;
        [self.directoryLoadingIndicatorView startAnimating];
        return;
    }

    if (self.tableView.backgroundView == self.directoryLoadingView) {
        self.tableView.backgroundView = nil;
    }
    [self.directoryLoadingIndicatorView stopAnimating];
}

- (UIView *)directoryLoadingView {
    if (!_directoryLoadingView) {
        _directoryLoadingView = [[UIView alloc] initWithFrame:self.tableView.bounds];
        _directoryLoadingView.backgroundColor = self.tableView.backgroundColor;

        UIActivityIndicatorView *indicatorView = nil;
        if (@available(iOS 13.0, *)) {
            indicatorView = [[UIActivityIndicatorView alloc]
                initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
        } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            indicatorView = [[UIActivityIndicatorView alloc]
                initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
#pragma clang diagnostic pop
        }
        indicatorView.hidesWhenStopped = YES;
        indicatorView.translatesAutoresizingMaskIntoConstraints = NO;
        [_directoryLoadingView addSubview:indicatorView];
        [NSLayoutConstraint activateConstraints:@[
            [indicatorView.centerXAnchor
                constraintEqualToAnchor:_directoryLoadingView.centerXAnchor],
            [indicatorView.centerYAnchor
                constraintEqualToAnchor:_directoryLoadingView.centerYAnchor]
        ]];
        self.directoryLoadingIndicatorView = indicatorView;
    }
    return _directoryLoadingView;
}

- (void)updateRightButtonLayout {
    NSArray *indexPaths = [self.tableView indexPathsForSelectedRows];

    if (indexPaths.count > 0) {
        self.navigationItem.rightBarButtonItem.enabled = YES;
        NSString *title = [NCUILocalizedString(@"confirm")
            stringByAppendingString:[NSString
                                        stringWithFormat:@"(%ld/20)", (long)indexPaths.count]];
        UIColor *color =
            NCDynamicResourceColor(@"primary_color", @"confirm_text_enable", @"0x0099ff");
        [self.buttonDone setTitleColor:color forState:UIControlStateNormal];
        [self.buttonDone setTitle:title forState:UIControlStateNormal];

    } else {
        UIColor *color = NCDynamicColor(@"primary_color");
        self.navigationItem.rightBarButtonItem.enabled = NO;
        [self.buttonDone setTitleColor:color forState:UIControlStateNormal];
        [self.buttonDone setTitle:NCUILocalizedString(@"confirm") forState:UIControlStateNormal];
    }
    [self.buttonDone sizeToFit];
}

- (BOOL)isOverMaximum:(NSString *)filePath {
    BOOL isOverMaximum = NO;
    NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath
                                                                                    error:nil];
    unsigned long long length = [fileAttributes fileSize];
    float ff = length / 1024.0 / 1024.0;
    if (ff > 100) {
        isOverMaximum = YES;
    }
    return isOverMaximum;
}

- (void)presentOverMaximumAlert {
    [NCAlertView showAlertController:nil
                             message:NCUILocalizedString(@"over_maximum")
                         cancelTitle:NCUILocalizedString(@"ok")
                    inViewController:self];
}

@end
