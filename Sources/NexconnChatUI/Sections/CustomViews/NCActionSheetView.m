//
//  NCActionSheetView.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCActionSheetView.h"
#import "NCChatUICommonDefine.h"
#import "NCChatUIUtility.h"
#import "NCChatUIConfig.h"
#import "NCBaseTableView.h"
#import "NCBaseTableViewCell.h"
#define Space_Line 6
@interface NCActionSheetView()
@property (nonatomic, strong) UIView *maskCoverView; // Background mask.

@property (nonatomic, strong) NCBaseTableView *tableView; // Options table.

@property (nonatomic, strong) NSArray *cellArray; // Table items.

@property (nonatomic, copy) NSString *title; // Sheet title.

@property (nonatomic, copy) NSString *cancelTitle; // Cancel action title.

@property (nonatomic, strong) UIView *headView; // Title header view.

@property (nonatomic, assign) CGSize viewSize; // Parent view size.

@property (nonatomic, copy) void (^selectedBlock)(NSInteger index); // Option selection callback.

@property (nonatomic, copy) void (^cancelBlock)(void); // Cancellation callback.
@end

@implementation NCActionSheetView
+ (void)showActionSheetView:(NSString *)title
                  cellArray:(NSArray *)cellArray
                cancelTitle:(NSString *)cancelTitle
              selectedBlock:(void (^)(NSInteger index))selectedBlock
                cancelBlock:(void (^)(void))cancelBlock{
    UIWindow *keyWindow = [NCChatUIUtility getKeyWindow];
    [keyWindow endEditing:YES];
    NCActionSheetView *actionSheet = [[NCActionSheetView alloc] initWithTitle:title CellArray:cellArray viewSize:keyWindow.bounds.size cancelTitle:cancelTitle selectedBlock:selectedBlock cancelBlock:cancelBlock];
    [keyWindow addSubview:actionSheet];
}

- (instancetype)initWithTitle:(NSString *)title
                    CellArray:(NSArray *)cellArray
                   viewSize:(CGSize)viewSize
                  cancelTitle:(NSString *)cancelTitle
                selectedBlock:(void (^)(NSInteger index))selectedBlock
                  cancelBlock:(void (^)(void))cancelBlock{
    self = [super init];
    if (self) {
        _viewSize = viewSize;
        if (title.length > 0) {
            _title = title;
            [self addTitleView];
        }
        _cellArray = cellArray;
        _cancelTitle = cancelTitle;
        _selectedBlock = selectedBlock;
        _cancelBlock = cancelBlock;
        [self createUI];
        [self registerNotificationCenter];
    }
    return self;
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Notification
- (void)registerNotificationCenter {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(deviceOrientationDidChange:)
                                                 name:UIApplicationDidChangeStatusBarFrameNotification
                                               object:nil];
}

- (void)deviceOrientationDidChange:(NSNotification *)notification {
    UIDeviceOrientation interfaceOrientation = [UIDevice currentDevice].orientation;
    if (interfaceOrientation == UIDeviceOrientationLandscapeLeft || interfaceOrientation == UIDeviceOrientationLandscapeRight || interfaceOrientation == UIDeviceOrientationPortrait){
        [self removeFromSuperview];
    }
}

#pragma mark - Create UI
- (void)addTitleView{
    CGFloat height = [NCChatUIUtility getTextDrawingSize:self.title font:[UIFont systemFontOfSize:15] constrainedSize:CGSizeMake(self.viewSize.width-20, MAXFLOAT)].height;
    self.headView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.viewSize.width, height + 30)];
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, self.headView.frame.size.width - 20, self.headView.frame.size.height)];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.font = [UIFont systemFontOfSize:14];
    titleLabel.numberOfLines = 0;
    titleLabel.textColor = NCDynamicColor(@"text_secondary_color");
    titleLabel.text = self.title;
    [self.headView addSubview:titleLabel];
    self.tableView.tableHeaderView = self.headView;
}

- (void)createUI {
    self.frame = [UIScreen mainScreen].bounds;
    [self addSubview:self.maskCoverView];
    [self addSubview:self.tableView];
}

- (UIView *)maskCoverView {
    if (!_maskCoverView) {
        _maskCoverView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        _maskCoverView.backgroundColor = NCDynamicColor(@"pop_layer_background_color");
        _maskCoverView.alpha = 0.4;
        _maskCoverView.userInteractionEnabled = YES;
    }
    return _maskCoverView;
}

- (NCBaseTableView *)tableView {
    if (!_tableView) {
        _tableView = [[NCBaseTableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
        _tableView.estimatedRowHeight = 0;
        _tableView.estimatedSectionHeaderHeight = 0;
        _tableView.estimatedSectionFooterHeight = 0;
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.backgroundColor = NCDynamicColor(@"common_background_color");
        _tableView.separatorInset = UIEdgeInsetsMake(0, -50, 0, 0);
        _tableView.separatorColor = NCDynamicColor(@"line_background_color");
        _tableView.rowHeight = 56.0;
        _tableView.bounces = NO;
        _tableView.scrollEnabled = NO;
        [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"OneCell"];
    }
    return _tableView;
}

#pragma mark <UITableViewDelegate,UITableViewDataSource>
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (section == 0) ? _cellArray.count : 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NCBaseTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"OneCell"];
    if (indexPath.section == 0) {
        cell.textLabel.text = _cellArray[indexPath.row];
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    } else {
        cell.textLabel.text = _cancelTitle;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    cell.contentView.backgroundColor = NCDynamicColor(@"common_background_color");
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    cell.textLabel.font = [[NCChatUIConfig defaultConfig].font fontOfSize:17];
    cell.textLabel.textColor = NCDynamicColor(@"text_primary_color");
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        if (self.selectedBlock) {
            self.selectedBlock(indexPath.row);
        }
    } else {
        if (self.cancelBlock) {
            self.cancelBlock();
        }
    }
    [self dismiss];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return CGFLOAT_MIN;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return (section == 0) ? Space_Line : 0.01f;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if (section == 0) {
        UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, Space_Line)];
        footerView.backgroundColor = NCDynamicColor(@"auxiliary_background_1_color");
        return footerView;
    } else {
        return nil;
    }
}

#pragma mark - Draw View
- (void)layoutSubviews {
    [super layoutSubviews];
    [self show];
    UIBezierPath *maskPath =
        [UIBezierPath bezierPathWithRoundedRect:self.tableView.bounds
                              byRoundingCorners:UIRectCornerTopRight | UIRectCornerTopLeft
                                    cornerRadii:CGSizeMake(6, 6)];
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    maskLayer.frame = self.tableView.bounds;
    maskLayer.path = maskPath.CGPath;
    _tableView.layer.mask = maskLayer;
}

// Slide the sheet in.
- (void)show {
    _tableView.frame =
        CGRectMake(0, self.viewSize.height, self.viewSize.width,
                   _tableView.rowHeight * (_cellArray.count + 1) + _headView.bounds.size.height + (Space_Line * 2) + [NCChatUIUtility getWindowSafeAreaInsets].bottom);
    [UIView animateWithDuration:.2
                     animations:^{
                         CGRect rect = _tableView.frame;
                         rect.origin.y -= _tableView.bounds.size.height;
                         _tableView.frame = rect;
                     }];
}

// Slide the sheet out.
- (void)dismiss {
    [UIView animateWithDuration:.2
        animations:^{
            CGRect rect = _tableView.frame;
            rect.origin.y += _tableView.bounds.size.height;
            _tableView.frame = rect;
        }
        completion:^(BOOL finished) {
            [self removeFromSuperview];
        }];
}

#pragma mark - Dismiss on Outside Tap
- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self dismiss];
}

@end
