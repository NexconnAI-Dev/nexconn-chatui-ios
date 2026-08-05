//
//  NCNameEditViewModel.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseViewModel.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, NCNameEditType) {
    NCNameEditTypeName,
    NCNameEditTypeRemark,
    NCNameEditTypeGroupName,
    NCNameEditTypeGroupMemberNickname,
};

@protocol NCNameEditViewModelDelegate <NSObject>
- (UIViewController *)currentViewController;

- (void)nameUpdateDidSuccess;

- (void)nameUpdateDidError:(NSString *)errorInfo;

@end

@interface NCNameEditViewModel : NCBaseViewModel

@property (nonatomic, weak) id<NCNameEditViewModelDelegate> delegate;

@property (nonatomic, copy) NSString *title;

@property (nonatomic, copy) NSString *content;

@property (nonatomic, copy) NSString *placeHolder;

@property (nonatomic, copy) NSString *tip;

@property (nonatomic, assign, readonly) NSInteger limit;

+ (instancetype)viewModelWithUserId:(NSString *)userId
                            groupId:(nullable NSString *)groupId
                               type:(NCNameEditType)type;

- (void)updateName:(NSString *)name;

- (void)getCurrentName:(void(^)(NSString *))block;
@end

NS_ASSUME_NONNULL_END
