//
//  NCCombineMessagePreviewViewControllerm
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCCombineMessagePreviewViewController.h"
#import "NCChatUI.h"
#import "NCChatUICommonDefine.h"
#import "NCChatUIConfig.h"
#import "NCBaseImageView.h"
#import "NCMenuItem.h"

#define TIPVIEWWIDTH 140.0f

static NSString *const NCCombinePreviewTargetIdPrefix = @"__nc_combine_preview__";

@interface NCCombineMessagePreviewViewController ()

/// The combined preview expects `messageModel.content` to be an `NCCombineMessage`; this only narrows the runtime type.
- (nullable NCCombineMessage *)combineMessageFromMessageContent:(nullable NCMessageContent *)content;

@property (nonatomic, strong) NCMessageModel *messageModel;
@property (nonatomic, copy) NSString *navTitle;
@property (nonatomic, assign) BOOL displayDeletedMessageForAllDialog;

@property (nonatomic, strong) UIView *loadingTipView;
@property (nonatomic, strong) NCBaseImageView *loadingImageView;
@property (nonatomic, strong) UILabel *loadingLabel;
@property (nonatomic, strong) UIView *loadFailedTipView;
@property (nonatomic, strong) NCBaseImageView *loadFailedImageView;
@property (nonatomic, strong) UILabel *loadFailedLabel;

@end

@implementation NCCombineMessagePreviewViewController

#pragma mark - Life Cycle

+ (NSString *)combinePreviewTitleFromMessage:(NCCombineMessage *)message {
    if (![message isKindOfClass:[NCCombineMessage class]]) {
        return @"";
    }
    if (message.channelType == NCChannelTypeGroup) {
        return NCUILocalizedString(@"group_chat_history_title");
    }
    NSArray<NSString *> *nameList = message.nameList;
    if (nameList.count > 1) {
        return [NSString stringWithFormat:NCUILocalizedString(@"chat_history_title_x_and_y"),
                                          nameList.firstObject ?: @"",
                                          nameList.lastObject ?: @""];
    }
    if (nameList.count == 1) {
        return [NSString stringWithFormat:NCUILocalizedString(@"chat_history_title_x"),
                                          nameList.firstObject ?: @""];
    }
    return @"";
}

- (instancetype)initWithMessageModel:(NCMessageModel *)messageModel navTitle:(NSString *)navTitle {
    NSString *previewTargetId =
        [NSString stringWithFormat:@"%@-%ld", NCCombinePreviewTargetIdPrefix, messageModel.clientId];
    self = [super initWithChannelType:NCChannelTypeSystem channelId:previewTargetId];
    if (self) {
        self.messageModel = messageModel;
        NCCombineMessage *combineMessage = [self combineMessageFromMessageContent:messageModel.content];
        self.navTitle = navTitle.length > 0 ? navTitle : [self.class combinePreviewTitleFromMessage:combineMessage];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.view.backgroundColor = NCDynamicColor(@"common_background_color");
    self.title = self.navTitle;
    self.navigationItem.rightBarButtonItems = nil;

    UICollectionViewFlowLayout *layout =
        (UICollectionViewFlowLayout *)self.messageCollectionView.collectionViewLayout;
    layout.sectionInset = UIEdgeInsetsZero;

    [self addSubViews];
    [self loadPreviewMessages];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.displayDeletedMessageForAllDialog) {
        self.displayDeletedMessageForAllDialog = NO;
        [self showDeletedMessageForAllDialog];
    }
}

#pragma mark - Override

- (void)setupDraft:(void (^ _Nullable)(BOOL editValid))completion {
    if (completion) {
        completion(NO);
    }
}

- (void)loadRemainMessageAndScrollToBottom:(BOOL)animated {
    [self scrollToFirstMessageIfNeededAnimated:animated];
}

- (void)scrollToBottomAnimated:(BOOL)animated {
    [self scrollToFirstMessageIfNeededAnimated:animated];
}

- (void)chatInputBar:(NCChatSessionInputBarControl *)chatInputBar shouldChangeFrame:(CGRect)frame {
    CGRect collectionViewRect = self.messageCollectionView.frame;
    collectionViewRect.size.height = CGRectGetMinY(frame) - collectionViewRect.origin.y;
    if (!chatInputBar.hidden) {
        [self.messageCollectionView setFrame:collectionViewRect];
    }
}

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView {
    if ([self.messageCollectionView numberOfItemsInSection:0] > 0) {
        [self.messageCollectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                                                       atScrollPosition:UICollectionViewScrollPositionTop
                                                               animated:YES];
    }
    return NO;
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
referenceSizeForHeaderInSection:(NSInteger)section {
    return CGSizeMake(collectionView.bounds.size.width, 0);
}

- (NSArray<UIMenuItem *> *)getLongTouchMessageCellMenuList:(NCMessageModel *)model {
    if ([model.content isKindOfClass:[NCTextMessage class]] ||
        [model.content isKindOfClass:[NCReferenceMessage class]]) {
        UIMenuItem *copyItem = [[NCMenuItem alloc] initWithTitle:NCUILocalizedString(@"copy")
                                                           image:NCDynamicImage(@"channel_menu_item_copy_img")
                                                          action:@selector(onCopyMessage:)];
        return @[ copyItem ];
    }
    return @[];
}

#pragma mark - Message Event

- (void)showDeletedMessageForAllDialog {
    UIAlertController *alertController = [UIAlertController
        alertControllerWithTitle:nil
                         message:NCUILocalizedString(@"message_delete_for_all_alert")
                  preferredStyle:UIAlertControllerStyleAlert];
    [alertController
        addAction:[UIAlertAction actionWithTitle:NCUILocalizedString(@"confirm")
                                           style:UIAlertActionStyleDefault
                                         handler:^(UIAlertAction *_Nonnull action) {
                                             [self.navigationController popViewControllerAnimated:YES];
                                         }]];
    [self.navigationController presentViewController:alertController animated:YES completion:nil];
}

- (void)onDeletedMessagesForAll:(NSArray<NCMessage *> *)messages {
    if (messages.count == 0 || !self.messageModel) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        BOOL isCurrentMessageDeletedForAll = NO;
        for (NCMessage *message in messages) {
            if (message.clientId == self.messageModel.clientId) {
                isCurrentMessageDeletedForAll = YES;
                break;
            }
        }
        if (isCurrentMessageDeletedForAll) {
            if ([self isViewLoaded] && self.view.window != nil) {
                [self showDeletedMessageForAllDialog];
            } else {
                self.displayDeletedMessageForAllDialog = YES;
            }
        }
    });
}

#pragma mark - Private

- (nullable NCCombineMessage *)combineMessageFromMessageContent:(nullable NCMessageContent *)content {
    if ([content isKindOfClass:[NCCombineMessage class]]) {
        return (NCCombineMessage *)content;
    }
    return nil;
}

- (void)loadPreviewMessages {
    NCCombineMessage *combineMessage = [self combineMessageFromMessageContent:self.messageModel.content];
    if (!combineMessage) {
        [self showLoadFailedTipView];
        return;
    }
    [self loadPreviewMessagesFromCombineMessage:combineMessage];
}

- (void)loadPreviewMessagesFromCombineMessage:(NCCombineMessage *)combineMessage {
    if (combineMessage.jsonMsgKey.length > 0) {
        if (combineMessage.localPath.length > 0 &&
            [[NSFileManager defaultManager] fileExistsAtPath:combineMessage.localPath]) {
            [self loadPreviewMessagesFromLocalPath:combineMessage.localPath combineMessage:combineMessage];
        } else if (combineMessage.remoteUrl.length > 0) {
            [self downloadPreviewMessagesForCombineMessage];
        } else {
            [self showLoadFailedTipView];
        }
        return;
    }

    if (combineMessage.msgList.count > 0) {
        [self reloadWithPreviewMessageList:combineMessage.msgList combineMessage:combineMessage];
    } else {
        [self showLoadFailedTipView];
    }
}

- (void)loadPreviewMessagesFromLocalPath:(NSString *)localPath combineMessage:(NCCombineMessage *)combineMessage {
    NSData *data = [NSData dataWithContentsOfFile:localPath];
    if (data.length == 0) {
        [self showLoadFailedTipView];
        return;
    }
    id jsonObject = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
    if (![jsonObject isKindOfClass:[NSArray class]]) {
        [self showLoadFailedTipView];
        return;
    }
    [self reloadWithPreviewMessageList:(NSArray *)jsonObject combineMessage:combineMessage];
}

- (void)downloadPreviewMessagesForCombineMessage {
    NCCombineMessage *combineMessage = [self combineMessageFromMessageContent:self.messageModel.content];
    if (!combineMessage) {
        [self showLoadFailedTipView];
        return;
    }
    [self showLoadingTipView];
    __weak typeof(self) weakSelf = self;
    void (^successHandler)(NSString *) = ^(NSString *mediaPath) {
        dispatch_main_async_safe(^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) {
                return;
            }
            NCCombineMessage *currentCombineMessage =
                [strongSelf combineMessageFromMessageContent:strongSelf.messageModel.content] ?: combineMessage;
            currentCombineMessage.localPath = mediaPath;
            [strongSelf loadPreviewMessagesFromLocalPath:mediaPath combineMessage:currentCombineMessage];
        });
    };
    void (^failedHandler)(void) = ^{
        dispatch_main_async_safe(^{
            [weakSelf showLoadFailedTipView];
        });
    };
    if (self.messageModel.clientId > 0) {
        [[NCChatUI shared] downloadMediaMessage:self.messageModel.clientId
            progress:^(int progress) {
            }
          completion:^(NSString * _Nullable mediaPath, NCError * _Nullable error) {
                if (mediaPath.length > 0 && !error) {
                    successHandler(mediaPath);
                    return;
                }
                failedHandler();
            }
            cancel:^{
                failedHandler();
            }];
        return;
    }
    if (combineMessage.remoteUrl.length == 0) {
        [self showLoadFailedTipView];
        return;
    }
    NSString *fileName = [self fallbackDownloadFileNameForCombineMessage:combineMessage];
    [[NCChatUI shared] downloadMediaFile:fileName
                                mediaUrl:combineMessage.remoteUrl
                                progress:^(int progress) {
                                }
                              completion:^(NSString * _Nullable mediaPath, NCError * _Nullable error) {
                                  if (mediaPath.length > 0 && !error) {
                                      successHandler(mediaPath);
                                      return;
                                  }
                                  failedHandler();
                              }
                                  cancel:^{
                                      failedHandler();
                                  }];
}

- (void)reloadWithPreviewMessageList:(NSArray<NSDictionary *> *)messageList
                      combineMessage:(NCCombineMessage *)combineMessage {
    NSMutableArray<NCMessageModel *> *previewModels =
        [self previewModelsFromMessageList:messageList combineMessage:combineMessage];
    [self figureOutPreviewConversationDataRepository:previewModels];
    self.channelDataRepository = previewModels;
    [self stopAnimation];
    self.loadingTipView.hidden = YES;
    self.loadFailedTipView.hidden = YES;
    [self.messageCollectionView reloadData];
    [self scrollToFirstMessageIfNeededAnimated:NO];
}

- (NSMutableArray<NCMessageModel *> *)previewModelsFromMessageList:(NSArray<NSDictionary *> *)messageList
                                                    combineMessage:(NCCombineMessage *)combineMessage {
    NSMutableArray<NCMessageModel *> *previewModels = [NSMutableArray array];
    [messageList enumerateObjectsUsingBlock:^(NSDictionary *dictionary, NSUInteger index, BOOL *stop) {
        (void)stop;
        NCMessageModel *messageModel =
            [self previewModelFromDictionary:dictionary previewIndex:index combineMessage:combineMessage];
        if (messageModel) {
            [previewModels addObject:messageModel];
        }
    }];
    return previewModels;
}

- (NCMessageModel *)previewModelFromDictionary:(NSDictionary *)dictionary
                                  previewIndex:(NSUInteger)previewIndex
                                combineMessage:(NCCombineMessage *)combineMessage {
    if (![dictionary isKindOfClass:[NSDictionary class]]) {
        return nil;
    }

    NSString *objectName = [self stringValueFromObject:dictionary[@"objectName"]];
    NSDictionary *contentDictionary = dictionary[@"content"];
    if (objectName.length == 0 || ![contentDictionary isKindOfClass:[NSDictionary class]]) {
        return nil;
    }

    NCMessageContent *previewContent = [NCMessageBridgeHelper messageContentFromMessageType:objectName
                                                                           contentDictionary:contentDictionary];
    if (!previewContent) {
        return nil;
    }
    NCChannelType channelType = combineMessage.channelType;
    NSString *channelId = [self stringValueFromObject:dictionary[@"channelId"]] ?: (self.messageModel.channelId ?: @"");
    NSString *senderUserId = [self stringValueFromObject:dictionary[@"fromUserId"]] ?: @"";
    long long sentTime = [self longLongValueFromObject:dictionary[@"timestamp"]];
    NCMessageModel *model = [[NCMessageModel alloc] init];
    model.senderUserId = senderUserId;
    model.channelId = channelId;
    model.sentTime = sentTime;
    model.objectName = objectName;
    model.channelType = channelType;
    model.content = previewContent;
    model.clientId = [self syntheticPreviewMessageClientIdForIndex:previewIndex sentTime:sentTime];
    model.messageId = [NSString stringWithFormat:@"%lld", sentTime];
    NSString *currentUserId = [NCEngine getCurrentUserId] ?: @"";
    model.messageDirection = [senderUserId isEqualToString:currentUserId] ? NCMessageDirectionSend : NCMessageDirectionReceive;
    if ([previewContent isKindOfClass:[NCHDVoiceMessage class]]) {
        model.receivedStatusInfo.isListened = YES;
    }
    return model;
}

- (long)syntheticPreviewMessageClientIdForIndex:(NSUInteger)previewIndex sentTime:(long long)sentTime {
    long long parentSeed = llabs((long long)self.messageModel.clientId);
    if (parentSeed == 0) {
        parentSeed = llabs(self.messageModel.sentTime);
    }
    if (parentSeed == 0) {
        parentSeed = llabs(sentTime);
    }

    long long syntheticClientId = -((parentSeed % 1000000000000LL) * 1000LL + (long long)previewIndex + 1);
    if (syntheticClientId == 0) {
        syntheticClientId = -((long long)previewIndex + 1);
    }
    return (long)syntheticClientId;
}

- (void)figureOutPreviewConversationDataRepository:(NSArray<NCMessageModel *> *)messageModels {
    for (NSInteger index = 0; index < messageModels.count; index++) {
        NCMessageModel *currentModel = messageModels[index];
        if (index == 0) {
            currentModel.isDisplayMessageTime = YES;
            continue;
        }

        NCMessageModel *previousModel = messageModels[index - 1];
        long long interval = llabs(currentModel.sentTime - previousModel.sentTime);
        if (interval / 1000 <= 3 * 60) {
            if (currentModel.isDisplayMessageTime && currentModel.cellSize.height > 0) {
                CGSize size = currentModel.cellSize;
                size.height = MAX(0, size.height - [self previewTimeLabelIncrementForModel:currentModel]);
                currentModel.cellSize = size;
            }
            currentModel.isDisplayMessageTime = NO;
        } else {
            currentModel.isDisplayMessageTime = YES;
        }
    }
}

- (CGFloat)previewTimeLabelIncrementForModel:(NCMessageModel *)messageModel {
    if ([messageModel.content isKindOfClass:[NCHDVoiceMessage class]]) {
        return 36;
    }
    return 45;
}

- (NSString *)stringValueFromObject:(id)object {
    if ([object isKindOfClass:[NSString class]]) {
        return object;
    }
    if ([object isKindOfClass:[NSNumber class]]) {
        return [(NSNumber *)object stringValue];
    }
    return nil;
}

- (long long)longLongValueFromObject:(id)object {
    if ([object respondsToSelector:@selector(longLongValue)]) {
        return [object longLongValue];
    }
    return 0;
}

- (NSString *)fallbackDownloadFileNameForCombineMessage:(NCCombineMessage *)combineMessage {
    if (combineMessage.name.length > 0) {
        return combineMessage.name;
    }
    NSString *lastPathComponent = [[NSURL URLWithString:combineMessage.remoteUrl ?: @""] lastPathComponent];
    if (lastPathComponent.length > 0) {
        return lastPathComponent;
    }
    return [NSString stringWithFormat:@"combine_%lld.json", self.messageModel.sentTime];
}

- (void)scrollToFirstMessageIfNeededAnimated:(BOOL)animated {
    if ([self.messageCollectionView numberOfItemsInSection:0] > 0) {
        [self.messageCollectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                                           atScrollPosition:UICollectionViewScrollPositionTop
                                                   animated:animated];
    }
}

- (void)addSubViews {
    [self.view addSubview:self.loadingTipView];
    [self.loadingTipView addSubview:self.loadingImageView];
    [self.loadingTipView addSubview:self.loadingLabel];
    [self.view addSubview:self.loadFailedTipView];
    [self.loadFailedTipView addSubview:self.loadFailedImageView];
    [self.loadFailedTipView addSubview:self.loadFailedLabel];
}

- (void)showLoadingTipView {
    [self startAnimation];
    self.loadingTipView.hidden = NO;
    self.loadFailedTipView.hidden = YES;
}

- (void)showLoadFailedTipView {
    [self stopAnimation];
    self.loadingTipView.hidden = YES;
    self.loadFailedTipView.hidden = NO;
}

- (void)startAnimation {
    CABasicAnimation *rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.toValue = @(M_PI * 2.0);
    rotationAnimation.duration = 1.5;
    rotationAnimation.cumulative = YES;
    rotationAnimation.repeatCount = MAXFLOAT;
    [self.loadingImageView.layer addAnimation:rotationAnimation forKey:@"rotationAnimation"];
}

- (void)stopAnimation {
    [self.loadingImageView.layer removeAnimationForKey:@"rotationAnimation"];
}

#pragma mark - Tip Views

- (UIView *)loadingTipView {
    if (!_loadingTipView) {
        _loadingTipView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, TIPVIEWWIDTH, 62)];
        _loadingTipView.center = self.view.center;
        _loadingTipView.hidden = YES;
    }
    return _loadingTipView;
}

- (NCBaseImageView *)loadingImageView {
    if (!_loadingImageView) {
        _loadingImageView = [[NCBaseImageView alloc] initWithFrame:CGRectMake((TIPVIEWWIDTH - 27) / 2, 0, 27, 27)];
        _loadingImageView.image = NCDynamicImage(@"channel_msg_combine_loading_img");
    }
    return _loadingImageView;
}

- (UILabel *)loadingLabel {
    if (!_loadingLabel) {
        _loadingLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 42, TIPVIEWWIDTH, 21)];
        _loadingLabel.font = [[NCChatUIConfig defaultConfig].font fontOfThirdLevel];
        _loadingLabel.numberOfLines = 1;
        _loadingLabel.textAlignment = NSTextAlignmentCenter;
        _loadingLabel.backgroundColor = [UIColor clearColor];
        _loadingLabel.textColor = NCDynamicColor(@"text_secondary_color");
        _loadingLabel.text = NCUILocalizedString(@"combine_message_loading");
    }
    return _loadingLabel;
}

- (UIView *)loadFailedTipView {
    if (!_loadFailedTipView) {
        _loadFailedTipView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, TIPVIEWWIDTH, 90)];
        _loadFailedTipView.center = self.view.center;
        _loadFailedTipView.hidden = YES;
    }
    return _loadFailedTipView;
}

- (NCBaseImageView *)loadFailedImageView {
    if (!_loadFailedImageView) {
        _loadFailedImageView = [[NCBaseImageView alloc] initWithFrame:CGRectMake((TIPVIEWWIDTH - 45) / 2, 0, 45, 54)];
        _loadFailedImageView.image = NCDynamicImage(@"combine_msg_preview_failed_img");
        _loadFailedImageView.userInteractionEnabled = NO;
    }
    return _loadFailedImageView;
}

- (UILabel *)loadFailedLabel {
    if (!_loadFailedLabel) {
        _loadFailedLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 69, TIPVIEWWIDTH, 21)];
        _loadFailedLabel.font = [[NCChatUIConfig defaultConfig].font fontOfThirdLevel];
        _loadFailedLabel.numberOfLines = 1;
        _loadFailedLabel.textAlignment = NSTextAlignmentCenter;
        _loadFailedLabel.backgroundColor = [UIColor clearColor];
        _loadFailedLabel.textColor = NCDynamicColor(@"text_secondary_color");
        _loadFailedLabel.text = NCUILocalizedString(@"combine_message_load_failed");
    }
    return _loadFailedLabel;
}

@end
