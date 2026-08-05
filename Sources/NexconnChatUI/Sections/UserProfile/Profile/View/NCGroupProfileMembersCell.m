//
//  NCGroupProfileMembersCell.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCGroupProfileMembersCell.h"
#import "NCChatUICommonDefine.h"

NSString  * const NCGroupProfileMembersCellIdentifier = @"NCGroupProfileMembersCellIdentifier";


@implementation NCGroupProfileMembersCell

- (void)setupView {
    [super setupView];
    [self.paddingContainerView addSubview:self.membersView];
}

- (void)setupConstraints {
    [super setupConstraints];
    [NSLayoutConstraint activateConstraints:@[
           [self.membersView.leadingAnchor constraintEqualToAnchor:self.paddingContainerView.leadingAnchor],
           [self.membersView.trailingAnchor constraintEqualToAnchor:self.paddingContainerView.trailingAnchor],
           [self.membersView.topAnchor constraintEqualToAnchor:self.paddingContainerView.topAnchor constant:NCGroupProfileMembersCellTextTopSpace],
           [self.membersView.bottomAnchor constraintEqualToAnchor:self.paddingContainerView.bottomAnchor]
       ]];
}

#pragma mark -- getter

- (NCGroupMembersCollectionView *)membersView {
    if (!_membersView) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.itemSize = CGSizeMake(NCGroupMembersCollectionViewModelItemWidth, NCGroupMembersCollectionViewModelItemHeight); // Size of each item.
        layout.minimumLineSpacing = NCGroupMembersCollectionViewModelLineSpace;
        layout.sectionInset = UIEdgeInsetsMake(0, NCGroupMembersCollectionViewModelLineSpace, 0, NCGroupMembersCollectionViewModelLineSpace);
        CGFloat width = [UIScreen mainScreen].bounds.size.width;
        CGFloat padding = (width-32 - 5 * layout.itemSize.width - NCGroupMembersCollectionViewModelLineSpace * 2)/4;
        if (padding<0) { // Compress item width when the screen cannot fit the default layout.
            CGFloat newWidth = NCGroupMembersCollectionViewModelItemWidth - (5*4-padding)/5;
            if (newWidth !=0) {
                layout.itemSize = CGSizeMake(newWidth, NCGroupMembersCollectionViewModelItemHeight);
            }
            padding = 5;
        }
        layout.minimumInteritemSpacing = padding;
        _membersView = [[NCGroupMembersCollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        _membersView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _membersView;
}

@end
