//
//  NCFileSelectorViewController.m
//  NCChatUIExtension
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCFileSelectorViewController.h"
#import "NCChatUICommonDefine.h"
#import "NCSelectDirectoryTableViewCell.h"
#import "NCSelectFilesTableViewCell.h"
#import "NCChatUIConfig.h"
#import "NCAlertView.h"
#import "NCSemanticContext.h"
@interface NCFileSelectorViewController ()

@property (nonatomic, strong) NSString *rootPath;
@property (nonatomic, assign) int maxSelectedNumber;
@property (nonatomic, strong) NSMutableArray *dataSource;
@property (nonatomic, strong) UIBarButtonItem *rightItem;
@property (nonatomic, strong) UIButton *buttonDone;
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
        self.navigationItem.leftBarButtonItems = [NCChatUIUtility getLeftNavigationItems:imgMirror title:NCUILocalizedString(@"back") target:self action:@selector(clickBackBtn:)];
    } else {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        [btn addTarget:self
                action:@selector(clickCancelBtn:)
      forControlEvents:UIControlEventTouchUpInside];
        UIColor *color =  NCChatUIConfigCenter.ui.globalNavigationBarTintColor;
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *directoryCellReuseIdentifier = @"NCFileSelectorViewControllerDirectoryCellReuseId";
    NSString *cellReuseIdentifier = @"NCFileSelectorViewControllerCellReuseId";

    NSDictionary *dict = self.dataSource[indexPath.section];
    NSArray *list = dict[NCListValue];
    NSString *type = dict[NCTypeValue];

    UITableViewCell *retCell = nil;
    if ([type isEqualToString:NCFileValue]) {
        NCSelectFilesTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellReuseIdentifier];
        if (cell == nil) {
            cell = [[NCSelectFilesTableViewCell alloc] init];
        }
        NSString *fileName = list[indexPath.row];
        cell.fileNameLabel.text = fileName;
        cell.fileIconImageView.image = [NCChatUIUtility imageWithFileSuffix:[fileName pathExtension]];
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

- (nullable NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *indexPaths = [self.tableView indexPathsForSelectedRows];
    if (indexPaths.count >= self.maxSelectedNumber) {
        return nil;
    } else {
        return indexPath;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([[tableView cellForRowAtIndexPath:indexPath] isKindOfClass:[NCSelectDirectoryTableViewCell class]]) {
        NSString *dir = self.dataSource[indexPath.section][NCListValue][indexPath.row];
        [self selecteDirectory:dir];
    } else if ([[tableView cellForRowAtIndexPath:indexPath] isKindOfClass:[NCSelectFilesTableViewCell class]]) {
        NSDictionary *dict = self.dataSource[indexPath.section];
        NSArray *list = dict[NCListValue];
        NSString *filePath = [NSString stringWithFormat:@"%@/%@", self.rootPath, list[indexPath.row]];
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
                [self selecteFile:(NCSelectFilesTableViewCell *)[tableView cellForRowAtIndexPath:indexPath]];
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

- (NCSelectDirectoryTableViewCell *)getSelectDirectoryTableViewCell:(NCSelectDirectoryTableViewCell *)cell
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
    __block NSArray *fileList;
    [self.dataSource enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        NSDictionary *dict = (NSDictionary *)obj;
        if ([dict[NCTypeValue] isEqualToString:NCFileValue]) {
            fileList = dict[NCListValue];
            *stop = YES;
        }
    }];
    for (NSIndexPath *indexPath in [self.tableView indexPathsForSelectedRows]) {
        [selectedFileList
            addObject:[NSString stringWithFormat:@"%@/%@", self.rootPath, [fileList objectAtIndex:indexPath.row]]];
    }

    if ([self.delegate respondsToSelector:@selector(fileDidSelect:)]) {
        [self.delegate fileDidSelect:[selectedFileList copy]];
    }

    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)getDataSourceList {
    NSString *filePath = self.rootPath;
    NSMutableArray *fileList = [[NSMutableArray alloc] init];
    NSMutableArray *docList = [[NSMutableArray alloc] init];
    for (NSString *file in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:filePath error:nil]) {
        BOOL fool;
        [[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"%@/%@", filePath, file]
                                             isDirectory:&fool];
        if (!fool) {
            [fileList addObject:file];
        } else {
            [docList addObject:file];
        }
    }
    self.dataSource = [[NSMutableArray alloc] init];
    if (docList.count > 0) {
        [self.dataSource addObject:@{NCTypeValue : NCDirectotyValue, NCListValue : docList}];
    }
    if (fileList.count > 0) {
        [self.dataSource addObject:@{NCTypeValue : NCFileValue, NCListValue : fileList}];
    }
}

- (void)updateRightButtonLayout {
    NSArray *indexPaths = [self.tableView indexPathsForSelectedRows];

    if (indexPaths.count > 0) {
        self.navigationItem.rightBarButtonItem.enabled = YES;
        NSString *title = [NCUILocalizedString(@"confirm")
            stringByAppendingString:[NSString stringWithFormat:@"(%ld/20)", (long)indexPaths.count]];
        UIColor *color = NCDynamicResourceColor(@"primary_color", @"confirm_text_enable", @"0x0099ff");
        [self.buttonDone setTitleColor:color forState:UIControlStateNormal];
        [self.buttonDone setTitle: title forState:UIControlStateNormal];
        
    } else {
        UIColor *color = NCDynamicColor(@"primary_color");
        self.navigationItem.rightBarButtonItem.enabled = NO;
        [self.buttonDone setTitleColor:color forState:UIControlStateNormal];
        [self.buttonDone setTitle: NCUILocalizedString(@"confirm") forState:UIControlStateNormal];
    }
    [self.buttonDone sizeToFit];
}

- (BOOL)isOverMaximum:(NSString *)filePath {
    BOOL isOverMaximum = NO;
    NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
    unsigned long long length = [fileAttributes fileSize];
    float ff = length / 1024.0 / 1024.0;
    if (ff > 100) {
        isOverMaximum = YES;
    }
    return isOverMaximum;
}

- (void)presentOverMaximumAlert {
    [NCAlertView showAlertController:nil message:NCUILocalizedString(@"over_maximum") cancelTitle:NCUILocalizedString(@"ok") inViewController:self];
}

@end
