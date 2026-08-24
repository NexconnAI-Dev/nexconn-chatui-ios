//
//  NCGroupProfileMembersCellViewModel.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCGroupProfileMembersCellViewModel.h"
#import "NCGroupProfileMembersCell.h"

@interface NCGroupProfileMembersCellViewModel ()

@property (nonatomic, strong) NCGroupMembersCollectionViewModel *collectionViewModel;

@property (nonatomic, assign) NSInteger showItemCount;

@end

@implementation NCGroupProfileMembersCellViewModel

- (instancetype)initWithItemCount:(NSInteger)showItemCount {
    self = [super init];
    if (self) {
        self.showItemCount = showItemCount;
    }
    return self;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NCGroupProfileMembersCell *cell =
        [tableView dequeueReusableCellWithIdentifier:NCGroupProfileMembersCellIdentifier
                                        forIndexPath:indexPath];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    [cell.membersView configViewModel:self.collectionViewModel];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat result =
        (CGFloat)self.showItemCount / NCGroupMembersCollectionViewModelPortraitLineCount;
    NSInteger line = ceil(result);
    return NCGroupProfileMembersCellTextTopSpace + NCGroupProfileMembersCellTextBottomSpace +
           NCGroupMembersCollectionViewModelItemHeight * line +
           NCGroupMembersCollectionViewModelLineSpace * (line - 1);
}

- (void)configViewModel:(NCGroupMembersCollectionViewModel *)viewModel {
    self.collectionViewModel = viewModel;
}

#pragma mark-- getter & setter

- (void)setDelegate:(id<NCGroupMembersCollectionViewModelDelegate>)delegate {
    self.collectionViewModel.delegate = delegate;
}

- (id<NCGroupMembersCollectionViewModelDelegate>)delegate {
    return self.collectionViewModel.delegate;
}

@end
