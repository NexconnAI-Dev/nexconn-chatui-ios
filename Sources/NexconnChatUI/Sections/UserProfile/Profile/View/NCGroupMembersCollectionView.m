//
//  NCGroupMembersCollectionView.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCChatUIUtility.h"
#import "NCChatUICommonDefine.h"

#import "NCGroupMembersCollectionView.h"
@interface NCGroupMembersCollectionView ()<UICollectionViewDataSource, UICollectionViewDelegate, NCCollectionViewModelResponder>

@property (nonatomic, strong) NCGroupMembersCollectionViewModel *viewModel;

@end

@implementation NCGroupMembersCollectionView

- (instancetype)initWithFrame:(CGRect)frame collectionViewLayout:(UICollectionViewLayout *)layout {
    self = [super initWithFrame:frame collectionViewLayout:layout];
    if (self) {
        self.delegate = self;
        self.dataSource = self;
        self.backgroundColor = NCDynamicColor(@"common_background_color");
        [NCGroupMembersCollectionViewModel registerCollectionViewCell:self];
    }
    return self;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    [self reloadData];
}

- (void)configViewModel:(NCGroupMembersCollectionViewModel *)viewModel {
    if (!viewModel) {
        return;
    }
    self.viewModel = viewModel;
    self.viewModel.responder = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self reloadData];
    });
}

#pragma mark -- NCCollectionViewModelResponder

- (void)reloadCollectionViewData {
    [self reloadData];
}

#pragma mark -- UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.viewModel numberOfItemsInSection:section]; // Use the item count supplied by the view model.
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    return [self.viewModel collectionView:collectionView cellForItemAtIndexPath:indexPath];
}

#pragma mark -- UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [self.viewModel collectionView:collectionView didSelectItemAtIndexPath:indexPath];
}

@end
