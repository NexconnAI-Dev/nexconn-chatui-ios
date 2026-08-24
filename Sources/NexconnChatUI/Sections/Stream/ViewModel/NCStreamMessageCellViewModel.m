//
//  NCStreamMessageCellViewModel.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//
#import <CoreFoundation/CoreFoundation.h>
#import <CoreText/CoreText.h>

#import "NCStreamMessageCellViewModel.h"
#import "NCChatUIConfig.h"
#import "NCMessageCellTool.h"
#import "NCMMMarkdown.h"
#import "NCChatUICommonDefine.h"
#import "NCChatUIErrorCode.h"
#import "NCStreamMessageCellViewModel+internal.h"
#import "NCStreamTextContentViewModel.h"
#import "NCStreamMarkdownContentViewModel.h"
#import "NSDictionary+NCAccessor.h"
#import "NCStreamHTMLContentViewModel.h"
#import "NCChatUI.h"

#import "NCStreamUtilities.h"

NSUInteger const NCStreamMessageCellDisplayTextLimit = 10000;
NSUInteger const NCStreamMessageCellLoadingLimit = 20;
CGFloat const ncUnfoldButtonHeight = 42;
CGFloat const ncContentTop = 10;
CGFloat const ncContentBottom = 10;
CGFloat const ncContentSpace = 10;
CGFloat const ncTextLeadingX = 12;
static NSInteger const NCStreamMessageRequestInProcessErrorCode = 39006;

@interface NCStreamMessageCellViewModel () <NCMessageHandler, NCStreamContentViewModelDelegate>

@property (nonatomic, copy) NSString *streamMessageHandlerIdentifier;

@end

@implementation NCStreamMessageCellViewModel

+ (instancetype)viewModelWithModel:(NCMessageModel *)model {
    NCStreamMessageCellViewModel *cellVM = [NCStreamMessageCellViewModel new];
    [cellVM configMessage:model];
    return cellVM;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.calculateHeightQueue =
            dispatch_queue_create("ai.nexconn.calculateHeightQueue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (CGSize)getMessageContentViewSize {
    if (CGSizeEqualToSize(self.contentViewSize, CGSizeZero)) {
        [self syncRefreshViewSizes];
    }
    return self.contentViewSize;
}

- (void)initRequestStreamMessage {
    NCStreamMessage *streamMessage = (NCStreamMessage *)self.model.content;
    if (streamMessage.sync) {
        return;
    }
    if (self.summaryComplete || (self.summary && !self.summaryComplete)) {
        return;
    }
    [self requestStreamMessage];
}

- (void)requestStreamMessage {
    [self unregisterStreamMessageHandler];
    [self registerStreamMessageHandler];
    NCLogD(@"[Stream] mUid:%@; addMessageHandlerWithIdentifier", self.model.messageId);
    [self refreshMessageFromStoreWithCompletion:^(NCMessage *_Nullable message) {
      if (!message) {
          [self requestStreamMessageResult:NCChatUIErrorCodeInvalidParameterMessageUid];
          return;
      }
      [message requestStreamMessageWithCompletion:^(NCError *_Nullable error) {
        NSInteger code = error ? error.code : NCChatUIErrorCodeSuccess;
        NCLogD(@"[Stream] mUid:%@; requestStreamMessageWithCompletion, code:%@",
               self.model.messageId, @(code));
        if (code != NCChatUIErrorCodeSuccess) {
            [self requestStreamMessageResult:code];
        }
      }];
    }];
}

- (void)dealloc {
    [self unregisterStreamMessageHandler];
}

- (void)registerStreamMessageHandler {
    if (self.streamMessageHandlerIdentifier.length == 0) {
        self.streamMessageHandlerIdentifier =
            [NSString stringWithFormat:@"NCStreamMessageCellVM-%p", self];
    }
    [NCEngine addMessageHandlerWithIdentifier:self.streamMessageHandlerIdentifier handler:self];
}

- (void)unregisterStreamMessageHandler {
    if (self.streamMessageHandlerIdentifier.length == 0) {
        return;
    }
    [NCEngine removeMessageHandlerForIdentifier:self.streamMessageHandlerIdentifier];
}

- (void)applyNCMessageToModel:(NCMessage *)message {
    if (!message) {
        return;
    }
    if ([message.content isKindOfClass:[NCMessageContent class]]) {
        self.model.content = message.content;
    }
    self.model.expansionDic = message.metadata;
    if (message.messageId.length > 0) {
        self.model.messageId = message.messageId;
    }
}

- (void)refreshMessageFromStoreWithCompletion:(void (^)(NCMessage *_Nullable message))completion {
    NSString *messageId = self.model.messageId ?: @"";
    NCGetMessageByIdParams *params = nil;
    if (messageId.length > 0) {
        params = [[NCGetMessageByIdParams alloc] initWithMessageId:messageId];
    } else if (self.model.clientId > 0) {
        params = [[NCGetMessageByIdParams alloc] initWithMessageClientId:self.model.clientId];
    }
    if (!params) {
        if (completion) {
            completion(nil);
        }
        return;
    }
    [NCBaseChannel
        getMessageByIdWithParams:params
                      completion:^(NCMessage *_Nullable message, NCError *_Nullable error) {
                        (void)error;
                        if (message) {
                            [self applyNCMessageToModel:message];
                            [self parserSummary];
                        }
                        if (completion) {
                            completion(message);
                        }
                      }];
}

- (void)asyncRefreshViewSizes {
    __block CGSize referViewSize = CGSizeZero;
    __block CGSize textViewSize = CGSizeZero;
    __block CGFloat height = ncContentTop + ncContentBottom;
    dispatch_async(self.calculateHeightQueue, ^{
      // Calculate the content height.
      if (self.showReferMessage) {
          referViewSize = [self getReferViewSize];
          height += referViewSize.height + ncContentSpace;
      }

      textViewSize = [self getTextViewSize];
      height += textViewSize.height;

      if (self.status == NCStreamMessageStatusBottomFailed ||
          self.status == NCStreamMessageStatusBottomUnfold ||
          self.status == NCStreamMessageStatusBottomLoading) {
          height += ncUnfoldButtonHeight;
      }
      // Deliver the result on the main queue.
      dispatch_async(dispatch_get_main_queue(), ^{
        self.textViewSize = textViewSize;
        self.referViewSize = referViewSize;
        self.contentViewSize =
            CGSizeMake([NCMessageCellTool getMessageContentViewMaxWidth], height);
        self.model.cellSize = CGSizeZero;
        if ([self.delegate respondsToSelector:@selector(contentLayoutDidUpdate)]) {
            [self.delegate contentLayoutDidUpdate];
        }
      });
    });
}

- (void)syncRefreshViewSizes {
    CGFloat height = ncContentTop + ncContentBottom;
    // Calculate the content height.
    if (self.showReferMessage) {
        self.referViewSize = [self getReferViewSize];
        height += self.referViewSize.height + ncContentSpace;
    }

    self.textViewSize = [self getTextViewSize];
    height += self.textViewSize.height;

    if (self.status == NCStreamMessageStatusBottomFailed ||
        self.status == NCStreamMessageStatusBottomUnfold ||
        self.status == NCStreamMessageStatusBottomLoading) {
        height += ncUnfoldButtonHeight;
    }
    self.contentViewSize = CGSizeMake([NCMessageCellTool getMessageContentViewMaxWidth], height);
    if ([self.delegate respondsToSelector:@selector(contentLayoutDidUpdate)]) {
        [self.delegate contentLayoutDidUpdate];
    }
}

- (CGSize)getTextViewSize {
    if (self.status == NCStreamMessageStatusContentLoading) {
        return CGSizeMake([self.contentViewModel contentMaxWidth], 21);
    }
    if (self.status == NCStreamMessageStatusContentFailedWhenLoading) {
        NSDictionary *attributes =
            @{NSFontAttributeName : [[NCChatUIConfig defaultConfig].font fontOfSecondLevel]};
        CGSize size =
            [[self.contentViewModel.class failedInfo]
                boundingRectWithSize:CGSizeMake([self.contentViewModel contentMaxWidth], 200)
                             options:(NSStringDrawingTruncatesLastVisibleLine |
                                      NSStringDrawingUsesLineFragmentOrigin |
                                      NSStringDrawingUsesFontLeading)
                          attributes:attributes
                             context:nil]
                .size;
        return CGSizeMake([self.contentViewModel contentMaxWidth], ceilf(size.height));
    }

    return [self.contentViewModel calculateContentSize];
}

- (CGSize)getReferViewSize {
    NCStreamMessage *streamMsg = (NCStreamMessage *)self.model.content;
    NCStreamReferenceInfo *streamReferInfo = streamMsg.referenceInfo;
    CGFloat height = 17; // Height of one name line.
    if ([streamReferInfo.content isKindOfClass:[NCImageMessage class]]) {
        NCImageMessage *msg = (NCImageMessage *)streamReferInfo.content;
        CGFloat space = 5.0;
        height =
            [NCMessageCellTool getThumbnailImageSize:msg.thumbnailImage].height + height + space;
    } else {
        height = 34; // Height of two text lines.
    }
    return CGSizeMake([self.contentViewModel contentMaxWidth], height);
}

#pragma mark-- private

- (void)configMessage:(NCMessageModel *)model {
    self.model = model;
    NCStreamMessage *streamMsg = (NCStreamMessage *)self.model.content;
    if ([streamMsg.type.lowercaseString isEqualToString:@"markdown"]) {
        self.contentType = NCStreamContentTypeMarkdown;
    } else if ([streamMsg.type.lowercaseString isEqualToString:@"html"]) {
        self.contentType = NCStreamContentTypeHTML;
    } else {
        self.contentType = NCStreamContentTypeText;
    }
    [self parserSummary];
    [self checkReferView:streamMsg];
    [self checkStreamStatus];
    [self createStreamContentModel];
    [self initRequestStreamMessage];
}

- (void)createStreamContentModel {
    if (self.contentType == NCStreamContentTypeMarkdown) {
        self.contentViewModel = [[NCStreamMarkdownContentViewModel alloc] init];
    } else if (self.contentType == NCStreamContentTypeHTML) {
        self.contentViewModel = [[NCStreamHTMLContentViewModel alloc] init];
    } else {
        self.contentViewModel = [[NCStreamTextContentViewModel alloc] init];
    }
    self.contentViewModel.delegate = self;
    [self.contentViewModel streamContentDidUpdate:self.content];
}

- (void)checkStreamStatus {
    NCStreamMessage *streamMsg = (NCStreamMessage *)self.model.content;
    NCLogD(@"[Stream] mUid:%@; checkStreamStatus %@, %@, %@, %@", self.model.messageId,
           @(streamMsg.sync), @(self.summaryComplete), @(self.summary.length),
           @(streamMsg.content.length));
    if (streamMsg.sync || self.summaryComplete) {
        self.status = NCStreamMessageStatusNormal;
    } else if (self.summary.length > 0 && !streamMsg.sync && !self.summaryComplete) {
        self.status = NCStreamMessageStatusBottomUnfold;
    } else if (streamMsg.content.length < NCStreamMessageCellLoadingLimit) {
        self.status = NCStreamMessageStatusContentLoading;
    } else {
        self.status = NCStreamMessageStatusNormal;
    }
}

- (void)checkReferView:(NCStreamMessage *)streamMsg {
    self.showReferMessage = streamMsg.referenceInfo ? YES : NO;
}

- (void)reloadStreamContent:(NCStreamMessageStatus)status {
    self.status = status;
    if ([self.contentViewModel.content isEqualToString:self.content]) {
        [self asyncRefreshViewSizes];
    } else {
        [self.contentViewModel streamContentDidUpdate:self.content];
    }
}

- (void)requestStreamMessageResult:(NSInteger)code {
    [self refreshMessageFromStoreWithCompletion:^(NCMessage *_Nullable message) {
      (void)message;
      NCStreamMessage *streamMsg = (NCStreamMessage *)self.model.content;
      if (streamMsg.sync || self.summaryComplete) {
          [self reloadStreamContent:NCStreamMessageStatusNormal];
      } else if (code == NCStreamMessageRequestInProcessErrorCode) {
          return;
      } else {
          if (self.status == NCStreamMessageStatusBottomLoading) {
              [self reloadStreamContent:NCStreamMessageStatusBottomFailed];
          } else if (self.status == NCStreamMessageStatusContentLoading) {
              [self reloadStreamContent:NCStreamMessageStatusContentFailedWhenLoading];
          } else if (self.status == NCStreamMessageStatusNormal) {
              [self reloadStreamContent:NCStreamMessageStatusContentFailedWhenNormal];
          }
      }
      [self unregisterStreamMessageHandler];
      NCLogD(@"[Stream] mUid:%@; removeMessageHandlerForIdentifier", self.model.messageId);
    }];
}

- (void)parserSummary {
    NCStreamSummaryModel *summary = [NCStreamUtilities parserStreamSummary:self.model];
    self.summaryComplete = summary.isComplete;
    self.summary = summary.summary;
}

#pragma mark-- NCMessageHandler
/// Handles request preparation and clears stale data from a previously interrupted stream.
- (void)onStreamMessageRequestInit:(NCStreamMessageRequestInitEvent *)event {
    if (![event.messageId isEqualToString:self.model.messageId]) {
        return;
    }
    NCLogD(@"[Stream] mUid:%@; onStreamMessageRequestInit", event.messageId);
    [self refreshMessageFromStoreWithCompletion:nil];
}

/// Handles an incremental streaming message update.
- (void)onStreamMessageRequestDelta:(NCStreamMessageDeltaEvent *)event {
    NCMessage *message = event.message;
    if (![message.messageId isEqualToString:self.model.messageId]) {
        return;
    }
    NSString *content = ((NCStreamMessage *)(self.model.content)).content;
    if (content.length >= NCStreamMessageCellDisplayTextLimit) {
        return;
    }
    [self applyNCMessageToModel:message];
    if (self.status == NCStreamMessageStatusBottomLoading) {
        self.status = NCStreamMessageStatusNormal;
    } else {
        [self checkStreamStatus];
    }
    [self reloadStreamContent:self.status];
    NCLogD(@"[Stream] mUid:%@; onStreamMessageRequestDelta, content:%@", message.messageId,
           event.chunkInfo.content);
}

/// Handles completion of a streaming message response.
- (void)onStreamMessageRequestComplete:(NCStreamMessageRequestCompleteEvent *)event {
    if (![event.messageId isEqualToString:self.model.messageId]) {
        return;
    }
    NSInteger code = event.error ? event.error.code : NCChatUIErrorCodeSuccess;
    [self requestStreamMessageResult:code];
    NCLogD(@"[Stream] mUid:%@; onStreamMessageRequestComplete, code:%@", event.messageId, @(code));
}

#pragma mark-- NCStreamContentViewModelDelegate

- (void)streamContentLayoutWillUpdate {
    [self asyncRefreshViewSizes];
}

#pragma mark-- Getter

- (NSString *)content {
    if (self.status == NCStreamMessageStatusNone ||
        self.status == NCStreamMessageStatusContentLoading ||
        self.status == NCStreamMessageStatusContentFailedWhenLoading) {
        return @"";
    }
    if (self.status == NCStreamMessageStatusBottomFailed ||
        self.status == NCStreamMessageStatusBottomUnfold ||
        self.status == NCStreamMessageStatusBottomLoading) {
        return self.summary;
    }
    NSString *content = ((NCStreamMessage *)(self.model.content)).content;
    if (content.length < self.summary.length) {
        content = self.summary;
    }
    if (content.length >= NCStreamMessageCellDisplayTextLimit) {
        content = [content substringWithRange:NSMakeRange(0, NCStreamMessageCellDisplayTextLimit)];
    }
    if (self.status == NCStreamMessageStatusContentFailedWhenNormal) {
        content =
            [content stringByAppendingFormat:@"\n\n%@",
                                             NCUILocalizedString(@"stream_failed_with_requesting")];
    }
    return content;
}

@end
