//
//  NCStreamMessageCellViewModel.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseCellViewModel.h"
#import "NCMessageModel.h"
#import "NCStreamContentViewModel.h"

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    NCStreamMessageStatusNone,
    NCStreamMessageStatusNormal,
    NCStreamMessageStatusContentLoading,
    NCStreamMessageStatusContentFailedWhenLoading,
    NCStreamMessageStatusContentFailedWhenNormal,
    NCStreamMessageStatusBottomUnfold,
    NCStreamMessageStatusBottomLoading,
    NCStreamMessageStatusBottomFailed,
} NCStreamMessageStatus;

typedef enum : NSUInteger {
    NCStreamContentTypeText,
    NCStreamContentTypeMarkdown,
    NCStreamContentTypeHTML,
} NCStreamContentType;

extern CGFloat const ncUnfoldButtonHeight;
extern CGFloat const ncContentTop;
extern CGFloat const ncContentSpace;
extern CGFloat const ncTextLeadingX;
@protocol NCStreamMessageCellViewModelDelegate <NSObject>

- (void)contentLayoutDidUpdate;

@end

@interface NCStreamMessageCellViewModel : NSObject

@property (nonatomic, copy, readonly)  NSString *content;

@property (nonatomic, weak) id<NCStreamMessageCellViewModelDelegate> delegate;

@property (nonatomic, assign, readonly) BOOL showReferMessage;

@property (nonatomic, assign) NCStreamContentType contentType;

@property (nonatomic, assign, readonly) NCStreamMessageStatus status;

@property (nonatomic, assign, readonly) CGSize contentViewSize;

@property (nonatomic, assign, readonly) CGSize textViewSize;

@property (nonatomic, assign, readonly) CGSize referViewSize;

@property (nonatomic, strong) NCStreamContentViewModel *contentViewModel;

+ (instancetype)viewModelWithModel:(NCMessageModel *)model;

- (CGSize)getMessageContentViewSize;

- (void)requestStreamMessage;

- (void)reloadStreamContent:(NCStreamMessageStatus)status;
@end

NS_ASSUME_NONNULL_END
