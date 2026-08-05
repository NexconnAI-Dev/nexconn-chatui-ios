//
//  NCChannelViewController.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCChannelViewController.h"
#import "NCChannelCollectionViewHeader.h"
#import "NCFilePreviewViewController.h"
#import "NCChatUICommonDefine.h"
#import "NCOldMessageNotificationMessage.h"
#import "NCOldMessageNotificationMessageCell.h"
#import "NCSightMessageCell.h"
#import "NCHDVoiceMessageCell.h"
#import "NCSightSlideViewController.h"
#import "NCImageSlideController.h"
#import "NCSystemSoundPlayer.h"
#import "NCUserInfoCacheManager.h"
#import "NCVoicePlayer.h"
#import "NCChatUIExtensionManager.h"
#import <AVFoundation/AVFoundation.h>
#import <SafariServices/SafariServices.h>
#import "NCMessageSelectionUtility.h"
#import "NCChannelViewLayout.h"
#import "NCHDVoiceMsgDownloadManager.h"
#import "NCHDVoiceMsgDownloadInfo.h"
#import "NCGIFPreviewViewController.h"
#import "NCCombineMessagePreviewViewController.h"
#import "NCCombineMessageUtility.h"
#import "NCActionSheetView.h"
#import "NCSelectChannelViewController.h"
#import "NCForwardManager.h"
#import "NCCombineMessageCell.h"
#import "NCResendManager.h"
#import "NCReferencingView.h"
#import "NCReferenceMessageCell.h"
#import "NCChannelDataSource.h"
#import "NCChannelVCUtil.h"
#import "NCChatUIConfig.h"
#import "NCButton.h"
#import "NCSemanticContext.h"
#import "NCReadWriteLock.h"
#import "NCStreamMessageCell.h"
#import "NCStreamUtilities.h"

#import "NCEditInputBarControl.h"
#import "NCUserListViewController.h"
#import "NCChannelViewController+Edit.h"
#import "NCChannelDataSource+Edit.h"
#import "NCMessageModel+Edit.h"
#import "NCTextPreviewView+Edit.h"
#import "NCMessageModel+RRS.h"
#import "NCChatUIErrorCode.h"
#import "NCBatchSubmitManager.h"
#import "NCChannelViewController+RRS.h"
#import "NCMessageReadDetailViewController.h"
#import "NCToastView.h"

#import "NCMenuItem.h"
#import "NCMenuController.h"

#import "NCChannelTitleView.h"
#import "NCUserOnlineStatusManager.h"
#import "NCUserOnlineStatusUtil.h"
#import "NCGroupMentionViewController.h"
#import "NCChatUI.h"
#import <NexconnChatSDK/NexconnChatSDK.h>
#define UNREAD_MESSAGE_MAX_COUNT 99
#define COLLECTION_VIEW_REFRESH_CONTROL_HEIGHT 30

@interface NCChannelDataSource (MessageHandlerInternal)
- (void)handleModifiedMessages:(NSArray<NCMessage *> *)messages;
@end

extern NSString *const NCUIDispatchDownloadMediaNotification;

NSString *const NCConversationViewScrollNotification = @"NCConversationViewScrollNotification";
NSString *const NCUIReferencedMessageUId = @"referenceMessageUId";
NSUInteger const NCStreamMessageTextLimit = 10000;
static NSUInteger const NCMessageTextMaxLength = 5000;
static NSTimeInterval const NCTypingStatusTimeoutInterval = 6.0;

static NSString *NCConversationReadReceiptHandlerIdentifier(NCChannelViewController *viewController) {
    return [NSString stringWithFormat:@"NCChannelVC-RRS-%p", viewController];
}

static NSString *NCConversationConnectionStatusHandlerIdentifier(NCChannelViewController *viewController) {
    return [NSString stringWithFormat:@"NCChannelVC-CONN-%p", viewController];
}

static NSString *NCConversationTypingStatusHandlerIdentifier(NCChannelViewController *viewController) {
    return [NSString stringWithFormat:@"NCChannelVC-TYPING-%p", viewController];
}

@interface NCUploadImageStatusListener : NSObject
@property(nonatomic, copy) void (^updateBlock)(int progress);
@property(nonatomic, copy) void (^successBlock)(NSString *url);
@property(nonatomic, copy) void (^errorBlock)(NSInteger errorCode);
@end

static int NCUnreadCountForDisplayConversationTypes(NSArray *displayConversationTypeArray) {
    if (displayConversationTypeArray.count == 0) {
        return 0;
    }

    NCChannelsUnreadCountParams *params = [[NCChannelsUnreadCountParams alloc] init];
    params.channelTypes = [displayConversationTypeArray copy];
    params.levels = @[ @(NCChannelNoDisturbLevelAllMessage) ];

    __block int unreadCount = 0;
    dispatch_semaphore_t waitUnreadCount = dispatch_semaphore_create(0);
    [NCBaseChannel getChannelsUnreadCountByNoDisturbLevelWithParams:params
                                                         completion:^(NSInteger count, NCError * _Nullable error) {
        (void)error;
        unreadCount = (int)count;
        dispatch_semaphore_signal(waitUnreadCount);
    }];
    dispatch_semaphore_wait(waitUnreadCount, DISPATCH_TIME_FOREVER);
    return unreadCount;
}

static NSString *NCCombinePreviewNavigationTitle(NCCombineMessage *message) {
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

@interface NCChannelViewController () <
    UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, NCMessageCellDelegate,
    NCChatSessionInputBarControlDelegate, UIGestureRecognizerDelegate, UIScrollViewDelegate,
    UINavigationControllerDelegate, NCChannelHandler,
NCChatSessionInputBarControlDataSource, NCMessagesMultiSelectedProtocol, NCReferencingViewDelegate, NCTextPreviewViewDelegate, NCMessagesLoadProtocol, NCMessageHandler, NCConnectionStatusHandler, NCSelectingUserDataSource, NCChatUIMessageEventObserver> {
    int _defaultLocalHistoryMessageCount;
    int _defaultMessageCount;
    int _defaultRemoteHistoryMessageCount;
}

@property (nonatomic, strong) NCChannelDataSource *dataSource;
@property (nonatomic, strong) NCChannelVCUtil *util;

#pragma mark flag
@property (nonatomic, assign) BOOL isConversationAppear;
@property (nonatomic, assign) BOOL isTakeNewPhoto; // Whether the outgoing image was captured and may need saving to Photos.
@property (nonatomic, assign) BOOL isContinuousPlaying; // Whether voice messages are playing continuously.
@property (nonatomic, assign) BOOL isTouchScrolled; /// Whether scrolling was initiated by touch.
@property (nonatomic, assign) BOOL sendMsgAndNeedScrollToBottom;

#pragma mark data
@property (nonatomic, strong) NSMutableArray *typingMessageArray;
@property (nonatomic, strong) NSArray<NCChatUIExtensionMessageCellInfo *> *extensionMessageCellInfoList;
@property (nonatomic, strong) NSMutableDictionary *cellMsgDict;
@property (nonatomic, strong) NCMessageModel *currentSelectedModel;
// Configuration for the active edit session.
@property (nonatomic, strong) NCEditInputBarConfig *editingInputBarConfig;
// Last bottom-bar state, used to restore the keyboard when the view reappears.
@property (nonatomic, assign) KBottomBarStatus latestInputBottomBarStatus;

#pragma mark view
@property (nonatomic, strong) UITapGestureRecognizer *resetBottomTapGesture;
@property (nonatomic, strong) NCChannelCollectionViewHeader *collectionViewHeader;
@property (nonatomic, strong) NCChannelTitleView *conversationTitleView;

#pragma mark Common
@property (nonatomic, copy) NSString *navigationTitle;
@property (nonatomic, assign) BOOL displayingTypingStatus;
@property (nonatomic, strong) NSTimer *typingStatusRestoreTimer;
@property (nonatomic, strong) NSArray<UIBarButtonItem *> *leftBarButtonItems;
@property (nonatomic, strong) NSArray<UIBarButtonItem *> *rightBarButtonItems;
@property (nonatomic, strong) NCBatchSubmitManager *readReceiptBatchManager; // Batches read receipt submissions.

- (BOOL)isInputTextTooLong:(NSString *)text;
- (void)showTypingNavigationTitle:(NSString *)title sentTime:(long long)sentTime;
- (void)scheduleTypingStatusRestoreWithSentTime:(long long)sentTime;
- (void)invalidateTypingStatusRestoreTimer;
- (void)restoreNavigationTitleForTypingStatusIfNeeded;
@end

static NSString *const ncUnknownMessageCellIndentifier = @"ncUnknownMessageCellIndentifier";
static NSString *const ncMessageBaseCellIndentifier = @"ncMessageBaseCellIndentifier";

#pragma clang diagnostic ignored "-Wincomplete-implementation"
@implementation NCChannelViewController
#pragma mark - LifeCycle
- (id)initWithChannelType:(NCChannelType)channelType channelId:(NSString *)channelId {
    self = [super init];
    if (self) {
        self.channelType = channelType;
        self.channelId = channelId;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self nc_commonInit];
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self nc_commonInit];
    }
    return self;
}

- (NCBaseChannel *)currentChannel {
    NSString *channelId = self.channelId ?: @"";
    if (channelId.length == 0) {
        return nil;
    }

    switch (self.channelType) {
        case NCChannelTypeDirect:
            return [[NCDirectChannel alloc] initWithChannelId:channelId];
        case NCChannelTypeGroup:
            return [[NCGroupChannel alloc] initWithChannelId:channelId];
        case NCChannelTypeSystem:
            return [[NCSystemChannel alloc] initWithChannelId:channelId];
        case NCChannelTypeCommunity: {
            NSString *subChannelId = self.subChannelId ?: @"";
            if (subChannelId.length == 0) {
                return nil;
            }
            return [[NCCommunitySubChannel alloc] initWithChannelId:channelId
                                                        subChannelId:subChannelId];
        }
        default:
            return nil;
    }
}

- (NCChannelIdentifier *)currentChannelIdentifier {
    NSString *channelId = self.channelId ?: @"";
    if (channelId.length == 0) {
        return nil;
    }

    switch (self.channelType) {
        case NCChannelTypeDirect:
            return [[NCChannelIdentifier alloc] initWithChannelType:NCChannelTypeDirect
                                                          channelId:channelId];
        case NCChannelTypeGroup:
            return [[NCChannelIdentifier alloc] initWithChannelType:NCChannelTypeGroup
                                                          channelId:channelId];
        case NCChannelTypeSystem:
            return [[NCChannelIdentifier alloc] initWithChannelType:NCChannelTypeSystem
                                                          channelId:channelId];
        case NCChannelTypeCommunity: {
            NSString *subChannelId = self.subChannelId ?: @"";
            if (subChannelId.length == 0) {
                return nil;
            }
            return [[NCCommunitySubChannelIdentifier alloc] initWithChannelId:channelId
                                                                  subChannelId:subChannelId];
        }
        default:
            return nil;
    }
}

- (void)nc_commonInit {
    self.isConversationAppear = NO;
    /* Start with a zero-height header as though all messages are loaded.
       Set it to 30 points when the service reports more messages. */
    self.channelDataRepository = [[NSMutableArray alloc] init];
    self.messageCollectionView = nil;

    self.displayUserNameInCell = YES;
    self.enableContinuousReadUnreadVoice = YES;
    self.typingMessageArray = [[NSMutableArray alloc] init];
    self.cellMsgDict = [[NSMutableDictionary alloc] init];
    self.isContinuousPlaying = NO;
    [[NCMessageSelectionUtility sharedManager] setMultiSelect:NO];
    
    self.dataSource = [[NCChannelDataSource alloc] init:self];
    self.dataSource.loadDelegate = self;
    self.util = [[NCChannelVCUtil alloc] init:self];
    self.enableUnreadMentionedIcon = YES;
    self.defaultMessageCount = 10;
    // Since 5.6.3, message deletion includes the remote copy by default.
    self.needDeleteRemoteMessage = YES;
    
    // Initialize batched read receipt submission.
    [self setupReadReceiptBatchManager];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    //-----
    // Do any additional setup after loading the view.
    // self.edgesForExtendedLayout = UIRectEdgeBottom | UIRectEdgeTop;
    if (NC_IOS_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        // The interactive back gesture conflicts with press handling.
        self.extendedLayoutIncludesOpaqueBars = YES;
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    [self initializedSubViews];
    [self registerAllInternalClass];
    [self registerCustomCellsAndMessages];
    [self registerNotification];

    [NCMessageSelectionUtility sharedManager].delegate = self;

#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_10_3
    if (@available(iOS 11.0, *)) {
        self.additionalSafeAreaInsets = UIEdgeInsetsMake(-[self getSafeAreaExtraBottomHeight], 0, 0, 0);
    }
#endif
    [[NCSystemSoundPlayer defaultPlayer] setIgnoreChannelType:self.channelType channelId:self.channelId];
    [self updateDraftBeforeViewAppear];
    [self setNavigationItem];
    
    [self registerSectionHeaderView];
    [self.chatSessionInputBarControl.pluginBoardView removeItemWithTag:PLUGIN_BOARD_ITEM_TRANSFER_TAG];
    
    if (self.disableSystemEmoji) {
        [self disableSystemDefaultEmoji];
    }
    
    // Refresh presence in the navigation title.
    [self updateNavigationTitleOnlineStatus];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    self.messageSelectionToolbar.frame =
        CGRectMake(0, self.view.bounds.size.height - NC_ChatSessionInputBar_Height - [self getSafeAreaExtraBottomHeight],
                   self.view.bounds.size.width, NC_ChatSessionInputBar_Height);
}

- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {

    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
    }
        completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
            [self layoutSubview:size];
        }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self edit_viewWillAppear:animated];
    
    // System channels have no input-bar callback to trigger the initial scroll.
    if (!self.chatSessionInputBarControl && [self.dataSource isAtTheBottomOfTableView] && self.locatedMessageSentTime == 0) {
        [self.messageCollectionView performBatchUpdates:^{
            [self.messageCollectionView reloadData];
        } completion:^(BOOL finished) {
            [self scrollToBottomAnimated:NO];
        }];
    }
    
    self.navigationController.interactivePopGestureRecognizer.delaysTouchesBegan = NO;

    [self.messageCollectionView addGestureRecognizer:self.resetBottomTapGesture];
    
    // Skip the regular input bar lifecycle while edit mode owns input state.
    if (![self edit_isMessageEditing]) {
        [self.chatSessionInputBarControl containerViewWillAppear];
    }
    
    [[NCSystemSoundPlayer defaultPlayer] setIgnoreChannelType:self.channelType channelId:self.channelId];
    
    [[NCChatUIExtensionManager sharedManager] extensionViewWillAppear:self.channelType
                                                              channelId:self.channelId
                                                         extensionView:self.extensionView];
    if(self.placeholderLabel) {
        [self.placeholderLabel removeFromSuperview];
        [self.chatSessionInputBarControl.inputTextView addSubview:self.placeholderLabel];
        self.placeholderLabel.hidden = self.chatSessionInputBarControl.draft.length > 0;
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    NCLogD(@"%s======%@", __func__, self);
    self.isConversationAppear = YES;
    [self edit_viewDidAppear:animated];
    
    // Skip the regular input bar lifecycle while edit mode owns input state.
    if (![self edit_isMessageEditing]) {
        [self.chatSessionInputBarControl containerViewDidAppear];
    }
    [self updateDraftAfterViewAppear];
    
    self.navigationTitle = [self currentNavigationTitle];
    
    [NCEngine addChannelHandlerWithIdentifier:NCConversationTypingStatusHandlerIdentifier(self) handler:self];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.util syncReadStatus];
    
    if (_resetBottomTapGesture) {
        [self.messageCollectionView removeGestureRecognizer:_resetBottomTapGesture];
    }
    [[NCSystemSoundPlayer defaultPlayer] resetIgnoreConversation];
    [self stopPlayingVoiceMessage];
    self.isConversationAppear = NO;
    [self.currentChannel clearUnreadCountWithCompletion:nil];

    [self.chatSessionInputBarControl cancelVoiceRecord];
    [NCEngine removeChannelHandlerForIdentifier:NCConversationTypingStatusHandlerIdentifier(self)];
    
    // Restore the navigation title.
    [self restoreNavigationTitleForTypingStatusIfNeeded];
    [self setNavigationTitle:self.navigationTitle];
    
    // Skip the regular input bar lifecycle while edit mode owns input state.
    if (![self edit_isMessageEditing]) {
        // Handle the regular input draft only outside edit mode.
        [self.util saveDraftIfNeed];
        
        [self.chatSessionInputBarControl containerViewWillDisappear];
    }
    [[NCChatUIExtensionManager sharedManager] extensionViewWillDisappear:self.channelType channelId:self.channelId];
    
    // Save edit state when the view disappears without an explicit exit.
    [self edit_saveCurrentEditStateIfNeeded];
    [self edit_viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if (!self.navigationController || ![self.navigationController.viewControllers containsObject:self]) {
        [self.dataSource cancelAppendMessageQueue];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
    // Save edit state before releasing resources for a memory warning.
    [self edit_saveCurrentEditStateIfNeeded];
}

- (void)didMoveToParentViewController:(UIViewController *)parent{
    [super didMoveToParentViewController:parent];
    if (!parent){
        [self quitConversationViewAndClear];
    }
}

- (void)dealloc {
    [self invalidateTypingStatusRestoreTimer];
    [[NCChatUI shared] removeMessageEventObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self quitConversationViewAndClear];
    NCLogD(@"%s======%@", __func__, self);
}

#pragma mark - Register Message
- (void)registerCustomCellsAndMessages {
    
}
- (void)registerAllInternalClass {
    // Built-in message types.
    [self registerClass:[NCTextMessageCell class] forMessageType:NCMessageType.text];
    [self registerClass:[NCImageMessageCell class] forMessageType:NCMessageType.image];
    [self registerClass:[NCGIFMessageCell class] forMessageType:NCMessageType.gif];
    [self registerClass:[NCCombineMessageCell class] forMessageType:NCMessageType.combine];
    [self registerClass:[NCHDVoiceMessageCell class] forMessageType:NCMessageType.hdVoice];
    [self registerClass:[NCFileMessageCell class] forMessageType:NCMessageType.file];
    [self registerClass:[NCReferenceMessageCell class] forMessageType:NCMessageType.reference];
    [self registerClass:[NCSightMessageCell class] forMessageType:NCMessageType.shortVideo];
    [self registerClass:[NCTipMessageCell class] forMessageType:NCInformationNotificationMessageIdentifier];
    [self registerClass:[NCTipMessageCell class] forMessageType:NCGroupNotificationMessageIdentifier];
    [self registerClass:[NCStreamMessageCell class] forMessageType:NCMessageType.stream];

    [self registerClass:[NCUnknownMessageCell class] forCellWithReuseIdentifier:ncUnknownMessageCellIndentifier];
    [self registerClass:[NCOldMessageNotificationMessageCell class]
         forMessageType:NCOldMessageNotificationMessageTypeIdentifier];
    [self registerClass:[NCMessageBaseCell class] forCellWithReuseIdentifier:ncMessageBaseCellIndentifier];
    // Register extension messages, such as CallKit messages.
    self.extensionMessageCellInfoList =
        [[NCChatUIExtensionManager sharedManager] getMessageCellInfoList:self.channelType channelId:self.channelId];
    for (NCChatUIExtensionMessageCellInfo *cellInfo in self.extensionMessageCellInfoList) {
        [self registerClass:cellInfo.messageCellClass forMessageType:cellInfo.messageType];
    }
    
}

- (void)registerClass:(Class)cellClass forMessageType:(NSString *)messageType {
    if (!cellClass || messageType.length == 0) {
        return;
    }
    [self.messageCollectionView registerClass:cellClass
                               forCellWithReuseIdentifier:messageType];
    [self.cellMsgDict setObject:cellClass forKey:messageType];
}

- (void)registerClass:(Class)cellClass forCellWithReuseIdentifier:(NSString *)identifier {
    [self.messageCollectionView registerClass:cellClass forCellWithReuseIdentifier:identifier];
}

#pragma mark - UI Display
- (void)initializedSubViews {
    // Initialize channel page controls.
    [self createChatSessionInputBarControl];
    [self createConversationMessageCollectionView];
    
    self.view.backgroundColor = NCDynamicColor(@"auxiliary_background_1_color");
    [self.view addSubview:self.messageCollectionView];
}

- (void)createChatSessionInputBarControl {
    if (!self.chatSessionInputBarControl && self.channelType != NCChannelTypeSystem) {
        self.chatSessionInputBarControl = [[NCChatSessionInputBarControl alloc]
                                       initWithFrame:CGRectMake(0, self.view.bounds.size.height - NC_ChatSessionInputBar_Height -
                                                                       [self getSafeAreaExtraBottomHeight],
                                                                self.view.bounds.size.width, NC_ChatSessionInputBar_Height)
                                   withContainerView:self.view
                                         controlType:NCChatSessionInputBarControlDefaultType
                                        controlStyle:NC_CHAT_INPUT_BAR_STYLE_SWITCH_CONTAINER_EXTENTION
                                    defaultInputType:self.defaultInputType];

        NCChannelIdentifier *inputBarChannelIdentifier = self.currentChannelIdentifier;
        if (inputBarChannelIdentifier) {
            self.chatSessionInputBarControl.channelType = inputBarChannelIdentifier.channelType;
        }
        self.chatSessionInputBarControl.channelId = self.channelId;
        self.chatSessionInputBarControl.delegate = self;
        self.chatSessionInputBarControl.dataSource = self;
        [self.view addSubview:self.chatSessionInputBarControl];
        
        // Initialize message editing controls.
        [self edit_createEditBarControl];
    }
}


- (void)createConversationMessageCollectionView {
    if (!self.messageCollectionView) {

        CGRect _conversationViewFrame = self.view.bounds;

        CGFloat _conversationViewFrameY = CGRectGetMaxY([UIApplication sharedApplication].statusBarFrame) +
                                          CGRectGetMaxY(self.navigationController.navigationBar.bounds);

        if (NC_IOS_SYSTEM_VERSION_LESS_THAN(@"7.0")) {

            _conversationViewFrame.origin.y = 0;
        } else {
            _conversationViewFrame.origin.y = _conversationViewFrameY;
        }

        _conversationViewFrame.size.height =
            self.view.bounds.size.height - self.chatSessionInputBarControl.frame.size.height - _conversationViewFrameY;
        self.dataSource.customFlowLayout.sectionInset = UIEdgeInsetsMake(20, 0, 0, 0);
        self.messageCollectionView =
            [[NCBaseCollectionView alloc] initWithFrame:_conversationViewFrame collectionViewLayout:self.dataSource.customFlowLayout];
        UIColor *color = NCDynamicColor(@"auxiliary_background_1_color");
        [self.messageCollectionView setBackgroundColor:color];
        self.messageCollectionView.showsHorizontalScrollIndicator = NO;
        self.messageCollectionView.alwaysBounceVertical = YES;

        self.messageCollectionView.dataSource = self;
        self.messageCollectionView.delegate = self;
    }
}

// Updates the iPad layout.
- (void)layoutSubview:(CGSize)size {
    if (![NCChatUIUtility currentDeviceIsIPad]) {
        return;
    }
    CGRect frame = CGRectMake(0, 0, size.width, size.height);
    frame.size.height = frame.size.height - self.chatSessionInputBarControl.frame.size.height;
    self.messageCollectionView.frame = frame;
    for (NCMessageModel *model in self.channelDataRepository) {
        model.cellSize = CGSizeZero;
    }
    [self.messageCollectionView reloadData];
    self.collectionViewHeader.frame = CGRectMake(0, -40, size.width, 40);

    CGRect controlFrame = self.chatSessionInputBarControl.frame;
    controlFrame.size.width = self.view.frame.size.width;
    controlFrame.origin.y =
        self.messageCollectionView.frame.size.height - self.chatSessionInputBarControl.frame.size.height;
    self.chatSessionInputBarControl.frame = controlFrame;
    [self.chatSessionInputBarControl containerViewSizeChangedNoAnnimation];
    
    // Keep the edit control aligned with the input bar.
    self.editInputBarControl.frame = controlFrame;
}

- (void)setNavigationItem{
    self.navigationItem.leftBarButtonItems = [self getLeftBackButton];
    
    // Direct channels use a custom title view to display presence.
    if ([self isDisplayOnlineStatus]) {
        self.conversationTitleView = [[NCChannelTitleView alloc] init];
        self.navigationItem.titleView = self.conversationTitleView;
        
        // Preserve an existing controller or navigation item title in the custom title view.
        NSString *existingTitle = self.title ?: self.navigationItem.title;
        if (existingTitle.length > 0) {
            [self updateNavigationTitle:existingTitle];
        }
    }
}

- (void)updateUnreadMsgCountLabel {
    if (self.channelDataRepository.count > 0) {
        if (self.dataSource.unreadNewMsgArr.count > 0) {
            if ([self.dataSource isAtTheBottomOfTableView]) {
                [self.dataSource.unreadNewMsgArr removeAllObjects];
                self.unreadRightBottomIcon.hidden = YES;
            } else {
                self.unreadRightBottomIcon.hidden = NO;
                self.unReadNewMessageLabel.text =
                    (self.dataSource.unreadNewMsgArr.count > 99)
                        ? @"99+"
                        : [NSString stringWithFormat:@"%li", (long)self.dataSource.unreadNewMsgArr.count];
            }
        } else {
            self.unreadRightBottomIcon.hidden = YES;
        }
    } else {
        self.unreadRightBottomIcon.hidden = YES;
    }
    [self updateUnreadMsgCountLabelFrame];
}

- (void)updateUnreadMsgCountLabelFrame {
    if (!self.unreadRightBottomIcon.hidden) {
        CGRect rect = self.unreadRightBottomIcon.frame;
        if ([self edit_isMessageEditing]) {
            rect.origin.y = self.editInputBarControl.frame.origin.y - 12 - 35;
            [self.unreadRightBottomIcon setFrame:rect];
            return;
        }
        if (self.referencingView) {
            rect.origin.y =
                self.chatSessionInputBarControl.frame.origin.y - 12 - 35 - self.referencingView.frame.size.height;
        } else {
            rect.origin.y = self.chatSessionInputBarControl.frame.origin.y - 12 - 35;
        }
        [self.unreadRightBottomIcon setFrame:rect];
    }
}

- (void)setupUnReadMessageView {
    if (self.unReadButton != nil) {
        [self.unReadButton removeFromSuperview];
    }
    [self.view addSubview:self.unReadButton];
    [self.unReadButton bringSubviewToFront:self.messageCollectionView];
    [self.util adaptUnreadButtonSize:self.unReadMessageLabel];
}

- (void)tapRightTopUnReadMentionedButton:(UIButton *)sender {
    if (self.dataSource.unreadMentionedMessages.count <= 0) {
        return;
    }
    [self.dataSource tapRightTopUnReadMentionedButton:sender];
}

- (void)loadRemainMessageAndScrollToBottom:(BOOL)animated {
    self.locatedMessageSentTime = 0;
    self.channelDataRepository = [[NSMutableArray alloc] init];
    [self.dataSource loadLatestHistoryMessage];
    [self.messageCollectionView reloadData];
    [self scrollToBottomAnimated:animated];
}

// Restoring a draft from search opens the keyboard and scrolls to the bottom.
// Apply it immediately only when no target message must remain visible.
- (void)updateDraftBeforeViewAppear {
    if (self.locatedMessageSentTime == 0) {
        [self setupDraft:^(BOOL editValid) {
            if (!self.isConversationAppear) {
                return;
            }
            if (editValid) {
                BOOL isFirstResponder = [self.editInputBarControl.editInputContainer.inputTextView isFirstResponder];
                if (!isFirstResponder) {
                    [self.editInputBarControl restoreFocus];
                }
            } else {
                BOOL isFirstResponder = [self.chatSessionInputBarControl.inputContainerView.inputTextView isFirstResponder];
                if (!isFirstResponder) {
                    [self.chatSessionInputBarControl.inputContainerView becomeFirstResponder];
                }
            }
        }];
    }
}

// Restoring a draft from search opens the keyboard and scrolls to the bottom.
// When locating a target message, defer draft restoration until containerViewDidAppear.
- (void)updateDraftAfterViewAppear {
    if (self.locatedMessageSentTime) {
        [self setupDraft:nil];
    }
}

- (void)setupDraft:(void (^ _Nullable)(BOOL editValid))completion {
    NCBaseChannel *channel = self.currentChannel;
    if (!channel) {
        if (completion) {
            completion(NO);
        }
        return;
    }
    NCChannelIdentifier *channelIdentifier = self.currentChannelIdentifier;
    if (!channelIdentifier) {
        if (completion) {
            completion(NO);
        }
        return;
    }
    [NCBaseChannel getChannels:@[channelIdentifier] completion:^(NSArray<NCBaseChannel *> * _Nullable channels, NSError * _Nullable error) {
        (void)error;
        NCBaseChannel *currentChannel = channels.firstObject ?: channel;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.dataSource getInitialMessage:currentChannel];
        });
        [channel reloadWithCompletion:^(NCBaseChannel * _Nullable latestChannel, NSError * _Nullable error) {
            (void)error;
            dispatch_async(dispatch_get_main_queue(), ^{
                NCBaseChannel *activeChannel = latestChannel ?: channel;
                NCEditedMessageDraft *editedMessageDraft = activeChannel.editedMessageDraft;
                BOOL editValid = editedMessageDraft && editedMessageDraft.content.length > 0;
                if (editValid) {
                    [self edit_showEditingMessage:editedMessageDraft];
                } else {
                    self.chatSessionInputBarControl.draft = activeChannel.draft;
                }
                if (completion) {
                    completion(editValid);
                }
            });
        }];
    }];
}

- (void)setupReadReceiptBatchManager {
    self.readReceiptBatchManager = [[NCBatchSubmitManager alloc] init];
    __weak typeof(self) weakSelf = self;
    [self.readReceiptBatchManager setupSubmitCallback:^(NSArray *items, NCBatchSubmitResultCallback resultCallback) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            if (resultCallback) {
                resultCallback(NCChatUIErrorCodeUnknown, YES);
            }
            return;
        }
        
        // Batch items are message ID strings.
        NSArray *messageIds = items;
        if (messageIds.count == 0) {
            if (resultCallback) {
                resultCallback(NCChatUIErrorCodeInvalidParameterMessageUid, NO);
            }
            return;
        }
        
        NCBaseChannel *channel = strongSelf.currentChannel;
        if (!channel) {
            if (resultCallback) {
                resultCallback(NCChatUIErrorCodeUnknown, YES);
            }
            return;
        }

        [channel sendReadReceiptResponseWithMessageIds:messageIds
                                            completion:^(NCError * _Nullable error) {
            if (resultCallback) {
                NSInteger code = error ? error.code : NCChatUIErrorCodeSuccess;
                BOOL refillData = NO;
                if (code != NCChatUIErrorCodeSuccess
                    && code != NCChatUIErrorCodeRrsv5Unavailable
                    && code != NCChatUIErrorCodeRrsv5ReadReceiptNotSupport
                    && code != NCChatUIErrorCodeMessageReadReceiptNotSupport) {
                    refillData = YES;
                }
                resultCallback(code, refillData);
            }
        }];
    }];
}

#pragma mark - Notification selector

- (void)registerNotification {
    [[NCChatUI shared] addMessageEventObserver:self];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didSendingMessageNotification:)
                                                 name:@"NCUISendingMessageNotification"
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleAppResumeNotification)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleWillResignActiveNotification)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(stopPlayingVoiceMessage)
                                                 name:UIWindowDidResignKeyNotification
                                               object:nil];

    [NCEngine addConnectionStatusHandlerWithIdentifier:NCConversationConnectionStatusHandlerIdentifier(self) handler:self];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateDownloadStatus:)
                                                 name:NCHQDownloadStatusChangeNotify
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(downloadMediaNotification:)
                                                 name:NCUIDispatchDownloadMediaNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveContinuousPlayNotification:)
                                                 name:kNCContinuousPlayNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(currentViewFrameChange:)
                                                 name:UIApplicationWillChangeStatusBarFrameNotification
                                               object:nil];

    // Observe user presence changes.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onUserOnlineStatusChanged:)
                                                 name:NCChatUIUserOnlineStatusChangedNotification
                                               object:nil];
    
    [self rrs_observeReadReceipt];
}

- (void)onDeletedMessagesForAll:(NSArray<NCMessage *> *)messages {
    if (messages.count == 0) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        for (NCMessage *deletedMessage in messages) {
            long deletedMessageClientId = (long)deletedMessage.clientId;
            NCChannelIdentifier *identifier = deletedMessage.channelIdentifier;
            if (!identifier) {
                continue;
            }
            if ([NCVoicePlayer defaultPlayer].messageClientId == deletedMessageClientId) {
                [self stopPlayingVoiceMessage];
            }

            [self p_removeSelectedMessageModelForDeletedMessage:deletedMessage];
            [self.dataSource didDeleteMessageForAll:deletedMessage];

            if (self.enableUnreadMentionedIcon &&
                identifier.channelType == self.channelType &&
                [identifier.channelId isEqual:self.channelId] &&
                ![self isRemainMessageExisted] &&
                self.dataSource.unreadMentionedMessages.count != 0) {
                [self.dataSource removeMentionedMessage:deletedMessageClientId];
            }

            if (self.referencingView && self.referencingView.referModel.clientId == deletedMessageClientId) {
                [self.chatSessionInputBarControl resetToDefaultStatus];
                [self dismissReferencingView:self.referencingView];
                [NCAlertView showAlertController:nil
                                         message:NCUILocalizedString(@"message_delete_for_all_alert")
                                     cancelTitle:NCUILocalizedString(@"confirm")
                                inViewController:self];
            }

            [self updateLeftBarUnreadMessageCount:deletedMessage];

            if ([self edit_isMessageEditing]) {
                NCMessageModel *model = [NCMessageModel modelWithNCMessage:deletedMessage];
                if (model) {
                    [self edit_refreshEditInputReferenceViewIfNeeded:@[model]
                                                               status:NCReferenceMessageStatusDeleted];
                }
            }
        }
    });
}

- (void)didSendingMessageNotification:(NSNotification *)notification {
    NCMessage *messageObject = [notification.object isKindOfClass:[NCMessage class]] ? notification.object : nil;
    NSDictionary *statusDic = notification.userInfo;
    self.sendMsgAndNeedScrollToBottom = YES;
    if (messageObject && !statusDic) {
        // Insert the incoming message.
        NCChannelIdentifier *identifier = messageObject.channelIdentifier;
        if (identifier &&
            identifier.channelType == self.channelType &&
            [identifier.channelId isEqual:self.channelId]) {
            [self updateForMessageSendOut:messageObject];
            if (messageObject.sentStatus == NCMessageSentStatusSending) {
                [self updateForMessageSendProgress:0 clientId:(long)messageObject.clientId];
            }
        }
    }
    if (statusDic) {
        // Update the existing message state.
        NSNumber *channelType = statusDic[@"channelType"] ?: statusDic[@"channelType"];
        NSString *channelId = statusDic[@"channelId"] ?: statusDic[@"channelId"];
        NSString *subChannelId = statusDic[@"subChannelId"];
        NSNumber *clientId = statusDic[@"clientId"];
        if (channelType.intValue == self.channelType &&
            [channelId isEqual:self.channelId] &&
            (!subChannelId || [subChannelId isEqualToString:(self.subChannelId ?: @"")])) {
            NSNumber *sentStatus = statusDic[@"sentStatus"];
            NCMessage *statusMessage = [statusDic[@"message"] isKindOfClass:[NCMessage class]] ? statusDic[@"message"] : nil;
            long resolvedMessageId = clientId.longValue;
            if (resolvedMessageId <= 0 && statusMessage) {
                resolvedMessageId = (long)statusMessage.clientId;
            }
            if (resolvedMessageId <= 0 && !statusMessage) {
                return;
            }
            if (sentStatus.intValue == NCMessageSentStatusSending) {
                NSNumber *progress = statusDic[@"progress"];
                [self updateForMessageSendProgress:progress.intValue clientId:resolvedMessageId];
            } else if (sentStatus.intValue == NCMessageSentStatusSent) {
                if (statusMessage) {
                    [self updateForMessageSendSuccess:statusMessage sourceClientId:resolvedMessageId];
                } else {
                    [self.util sendMessageStatusNotification:CONVERSATION_CELL_STATUS_SEND_SUCCESS
                                                   clientId:resolvedMessageId
                                                    progress:0];
                }
            } else if (sentStatus.intValue == NCMessageSentStatusFailed) {
                NSNumber *errorCode = statusDic[@"error"];
                NCMessageContent *content = statusMessage.content;
                if (!content && [statusDic[@"content"] isKindOfClass:[NCMessageContent class]]) {
                    content = statusDic[@"content"];
                }
                bool ifResendNotification = [statusDic.allKeys containsObject:@"resend"];
                [self updateForMessageSendError:errorCode.intValue
                                      clientId:resolvedMessageId
                                        content:content
                           ifResendNotification:ifResendNotification];
            } else if (sentStatus.intValue == NCMessageSentStatusCanceled) {
                NCMessageContent *content = statusMessage.content;
                if (!content && [statusDic[@"content"] isKindOfClass:[NCMessageContent class]]) {
                    content = statusDic[@"content"];
                }
                [self updateForMessageSendCanceled:resolvedMessageId content:content];
            }
        }
    }
}

- (void)handleAppResumeNotification {
    self.isConversationAppear = YES;
    [self.messageCollectionView reloadData];
    if ([NCEngine getConnectionStatus] == NCConnectionStatusConnected) {
        [self.util syncReadStatus];
    }
    [self.currentChannel clearUnreadCountWithCompletion:nil];
}

- (void)handleWillResignActiveNotification {
    self.isConversationAppear = NO;
    [self.chatSessionInputBarControl endVoiceRecord];
    
    // Save edit state before the app enters the background.
    [self edit_saveCurrentEditStateIfNeeded];
    
    if (![self edit_isMessageEditing]) {
        // Handle the regular input draft only outside edit mode.
        // Save or clear the draft in case the app is terminated from this page.
        [self.util saveDraftIfNeed];
    }
}

- (void)updateLeftBarUnreadMessageCount:(NCMessage *)deletedMessage {
    NCChannelIdentifier *identifier = deletedMessage.channelIdentifier;
    if (!identifier) {
        return;
    }
    if (identifier.channelType != self.channelType || ![identifier.channelId isEqual:self.channelId]) {
        [self notifyUpdateUnreadMessageCount];
    }
}

- (void)p_removeSelectedMessageModelForDeletedMessage:(NCMessage *)deletedMessage {
    NSArray<NCMessageModel *> *selectedMessages = [[[NCMessageSelectionUtility sharedManager] selectedMessages] copy];
    if (selectedMessages.count == 0) {
        return;
    }
    NCChannelIdentifier *identifier = deletedMessage.channelIdentifier;
    for (NCMessageModel *model in selectedMessages) {
        BOOL sameChannelType = (NCChannelType)model.channelType == identifier.channelType;
        BOOL sameTargetId = [model.channelId isEqualToString:identifier.channelId];
        BOOL sameMessageId = model.clientId == deletedMessage.clientId;
        if (sameChannelType && sameTargetId && sameMessageId) {
            [[NCMessageSelectionUtility sharedManager] removeMessageModel:model];
            break;
        }
    }
}

- (void)stopPlayingVoiceMessage {
    if ([NCVoicePlayer defaultPlayer].isPlaying) {
        [[NCVoicePlayer defaultPlayer] stopPlayVoice];
    }
}

- (void)onConnectionStatusChangedNotification:(NSNotification *)status {
    if (NCConnectionStatusConnected == [status.object integerValue]) {
        [self.util syncReadStatus];
    }
}

#pragma mark - NCConnectionStatusHandler
- (void)onConnectionStatusChanged:(NCConnectionStatusChangedEvent *)event {
    NSNotification *statusNotification = [NSNotification notificationWithName:NCChatUIDispatchConnectionStatusChangedNotification
                                                                       object:@(event.status)];
    [self onConnectionStatusChangedNotification:statusNotification];
}

- (void)currentViewFrameChange:(NSNotification *)notification {
    if(!self.isConversationAppear) {
        return;
    }
    if (![NCChatUIUtility currentDeviceIsIPad]) {
        return;
    }
    [self.chatSessionInputBarControl containerViewSizeChanged];
}

/**
 * Handles a user presence change notification.
 * 
 * @param notification The notification whose userInfo contains NCChatUIUserOnlineStatusChangedUserIdsKey.
 */
- (void)onUserOnlineStatusChanged:(NSNotification *)notification {
    if (![self isDisplayOnlineStatus]) {
        return;
    }
    
    NSArray<NSString *> *changedUserIds = notification.userInfo[NCChatUIUserOnlineStatusChangedUserIdsKey];
    if (!changedUserIds || ![changedUserIds containsObject:self.channelId]) {
        return;
    }
    
    // Refresh presence in the title view.
    [self updateNavigationTitleOnlineStatus];
}

#pragma mark Continuous Voice Playback
- (void)receiveContinuousPlayNotification:(NSNotification *)notification {
    if (!self.enableContinuousReadUnreadVoice) {
        return;
    }
    NCChannelType channelType = (NCChannelType)[notification.userInfo[@"channelType"] longValue];
    NSString *channelId = notification.userInfo[@"channelId"];
    if (channelType != self.channelType || ![channelId isEqualToString:self.channelId]) {
        return;
    }
    if (!self.isContinuousPlaying) {
        return;
    }
    [self performSelector:@selector(playNextVoiceMesage:)
               withObject:notification.object
               afterDelay:0.3f]; // Start the next message after a 0.3-second delay.
}

#pragma mark - Read Receipts V5
- (void)onMessageReceiptResponse:(NCMessageReceiptResponseEvent *)event {
    [self rrs_didReceiveMessageReadReceiptResponses:event.responses];
}


#pragma mark - Mention Input
- (void)showChooseUserViewController:(void (^)(NCChatUIUserInfo *selectedUserInfo))selectedBlock
                              cancel:(void (^)(void))cancelBlock {
    NCBaseNavigationController *rootVC = nil;
    if ([NCChatUI shared].currentDataSourceType == NCDataSourceTypeInfoManagement) {
        NCGroupMentionViewModel *vm = [NCGroupMentionViewModel viewModelWithGroupId:self.channelId
                                                                      selectedBlock:selectedBlock
                                                                             cancel:cancelBlock];
        NCGroupMentionViewController *vc = [[NCGroupMentionViewController alloc] initWithViewModel:vm];
        rootVC = [[NCBaseNavigationController alloc] initWithRootViewController:vc];
    }else {
        NCUserListViewController *userListVC = [[NCUserListViewController alloc] init];
        userListVC.selectedBlock = selectedBlock;
        userListVC.cancelBlock = cancelBlock;
        userListVC.dataSource = self;
        userListVC.navigationTitle = NCUILocalizedString(@"select_mentioned_user");
        userListVC.maxSelectedUserNumber = 1;
        rootVC = [[NCBaseNavigationController alloc] initWithRootViewController:userListVC];
    }
    // Present the mention picker selected for the active data source.
    dispatch_async(dispatch_get_main_queue(), ^{
        [self presentViewController:rootVC functionTag:INPUT_MENTIONED_SELECT_TAG];
    });
}

#pragma mark NCSelectingUserDataSource

- (void)getSelectingUserIdList:(void (^)(NSArray<NSString *> *userIdList))completion {
    [self getSelectingUserIdList:completion functionTag:INPUT_MENTIONED_SELECT_TAG];
}

- (NCChatUIUserInfo *)getSelectingUserInfo:(NSString *)userId {
    if (self.channelType == NCChannelTypeGroup) {
        return [[NCUserInfoCacheManager sharedManager] getUserInfo:userId inGroupId:self.channelId];
    } else {
        return [[NCUserInfoCacheManager sharedManager] getUserInfo:userId];
    }
}

- (NCMentionedInfo *)currentInputBarMentionedInfo {
    NSArray<NSString *> *mentionedUserIdList = self.chatSessionInputBarControl.mentionedUserIdList;
    if (mentionedUserIdList.count == 0) {
        return nil;
    }
    return [[NCMentionedInfo alloc] initWithType:NCMentionedTypeUsers
                                      userIdList:mentionedUserIdList
                                mentionedContent:nil];
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    self.isTouchScrolled = YES;
    if (self.edit_isMessageEditing) {
        [self edit_hideEditBottomPanels];
        return;
    }
    if (self.chatSessionInputBarControl.currentBottomBarStatus != KBottomBarDefaultStatus &&
        self.chatSessionInputBarControl.currentBottomBarStatus != KBottomBarRecordStatus) {
        [self.chatSessionInputBarControl resetToDefaultStatus];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    // Load newer or older messages only after user-initiated scrolling.
    // Layout changes such as reloadData or keyboard presentation must not trigger loading.
    if (scrollView.contentOffset.y <= 0 && !self.dataSource.isIndicatorLoading && !self.dataSource.allMessagesAreLoaded &&
        self.isTouchScrolled) {
        [self.collectionViewHeader startAnimating];
        [self.dataSource scrollToLoadMoreHistoryMessage];
    } else if (scrollView.contentOffset.y + scrollView.frame.size.height >= scrollView.contentSize.height &&
               !self.dataSource.isIndicatorLoading && self.isTouchScrolled) {
        [self.dataSource scrollToLoadMoreNewerMessage];
    }
}

/// Called after a scrollToItemAtIndexPath: animation completes.
- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    [self.dataSource scrollDidEnd];
    /// Update the lower-right unread bubble only after scrolling stops, a scroll animation completes,
    /// while the collection view is off the bottom, or when an unread message is recalled.
    [self updateUnreadMsgCountLabel];
}

/// Called when scrolling stops.
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self.dataSource scrollDidEnd];
    [self updateUnreadMsgCountLabel];
    self.isTouchScrolled = NO;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        self.isTouchScrolled = NO;
    }
    [self.dataSource scrollDidEnd];
}

// Overrides the status-bar tap behavior to scroll to the top and load history.
- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView {
    if ([self.messageCollectionView numberOfItemsInSection:0] > 0) {
        [self.messageCollectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                                                       atScrollPosition:(UICollectionViewScrollPositionTop)
                                                               animated:YES];
    }
    [self.dataSource loadMoreHistoryMessageIfNeed];
    return NO;
}

- (void)scrollToBottomAnimated:(BOOL)animated {
    if ([self.messageCollectionView numberOfSections] == 0) {
        return;
    }
    NSInteger count = [self.messageCollectionView numberOfItemsInSection:0];
    if (count <= 0) {
        return;
    }
    NSUInteger finalRow = count - 1;
    NSIndexPath *finalIndexPath = [NSIndexPath indexPathForItem:finalRow inSection:0];
    [self.messageCollectionView scrollToItemAtIndexPath:finalIndexPath
                                                   atScrollPosition:UICollectionViewScrollPositionBottom
                                                           animated:animated];
    // Hide the lower-right bubble at the newest message.
    [self.dataSource.unreadNewMsgArr removeAllObjects];
    [self updateUnreadMsgCountLabel];
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.channelDataRepository.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    // Guard against external mutation of channelDataRepository.
    if (indexPath.row >= self.channelDataRepository.count) {
        NCMessageBaseCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:ncMessageBaseCellIndentifier forIndexPath:indexPath];
        NCLogD(@"indexPath row out of conversationDataRepository range ");
        return cell;
    }

    NCMessageModel *model = [self.channelDataRepository objectAtIndex:indexPath.row];

    model = [self.dataSource setModelIsDisplayNickName:model];

    NCMessageContent *messageContent = model.content;
    NCMessageBaseCell *cell = nil;
    NSString *objName = model.objectName;
    if (self.cellMsgDict[objName]) {
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:objName forIndexPath:indexPath];
        [cell setDataModel:model];
        [cell setDelegate:self];
    } else if ((!messageContent || [messageContent isKindOfClass:[NCUnknownMessage class]]) && NCChatUIConfigCenter.message.showUnkownMessage) {
        cell = [self ncUnknownChannelCollectionView:collectionView cellForItemAtIndexPath:indexPath];
        [cell setDataModel:model];
        [cell setDelegate:self];
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        cell = [self ncChannelCollectionView:collectionView cellForItemAtIndexPath:indexPath];
#pragma clang diagnostic pop
    }

    // Notify the legacy cell display hook before the current hook.
    [self performSelector:@selector(willDisplayConversationTableCell:atIndexPath:)
               withObject:cell
               withObject:indexPath];
    // The current hook receives the same cell after legacy notification.
    [self willDisplayMessageCell:cell atIndexPath:indexPath];
    [self.dataSource removeMentionedMessage:model.clientId];
    if ([cell isKindOfClass:NCStreamMessageCell.class]) {
        ((NCStreamMessageCell *)cell).hostView = collectionView;
    }
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView
           viewForSupplementaryElementOfKind:(NSString *)kind
                                 atIndexPath:(NSIndexPath *)indexPath {
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        NCChannelCollectionViewHeader *headerView =
            [collectionView dequeueReusableSupplementaryViewOfKind:kind
                                               withReuseIdentifier:@"RefreshHeadView"
                                                      forIndexPath:indexPath];
        self.collectionViewHeader = headerView;
        return headerView;
    }
    return nil;
}

// Avoid an iOS 7 crash during repeated history loading.
- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

#pragma mark - UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    // Guard against external mutation of channelDataRepository.
    if (indexPath.row >= self.channelDataRepository.count) {
        return CGSizeZero;
    }

    NCMessageModel *model = [self.channelDataRepository objectAtIndex:indexPath.row];
    model = [self.dataSource setModelIsDisplayNickName:model];
    // Text messages use their measured size directly.
    if (model.cellSize.height > 0) {
        return model.cellSize; // Return only the measured text size.
    }
    
    NCMessageContent *messageContent = model.content;
    NSString *objectName = model.objectName;
    Class cellClass = self.cellMsgDict[objectName];
    if([cellClass respondsToSelector:@selector(sizeForMessageModel:withCollectionViewWidth:referenceExtraHeight:)]) {
        CGFloat extraHeight = [self.util referenceExtraHeight:cellClass messageModel:model];
        CGSize size = [cellClass sizeForMessageModel:model
                             withCollectionViewWidth:collectionView.frame.size.width
                                referenceExtraHeight:extraHeight];

        if (size.width != 0 && size.height != 0) {
            model.cellSize = size;
            return size;
        }
    }

    if ((!messageContent || [messageContent isKindOfClass:[NCUnknownMessage class]])&& NCChatUIConfigCenter.message.showUnkownMessage) {
        CGSize _size = [self ncUnknownChannelCollectionView:collectionView
                                                         layout:collectionViewLayout
                                         sizeForItemAtIndexPath:indexPath];
        _size.height += [self.util referenceExtraHeight:NCUnknownMessageCell.class messageModel:model];
        model.cellSize = _size;
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        CGSize _size = [self ncChannelCollectionView:collectionView
                                                  layout:collectionViewLayout
                                  sizeForItemAtIndexPath:indexPath];
#pragma clang diagnostic pop
        NCLogD(@"%@", NSStringFromCGSize(_size));
        _size.height += [self.util referenceExtraHeight:NCUnknownMessageCell.class messageModel:model];
        model.cellSize = _size;
    }

    return model.cellSize;
}

- (NCMessageBaseCell *)ncUnknownChannelCollectionView:(UICollectionView *)collectionView
                                   cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    NCMessageModel *model = [self.channelDataRepository objectAtIndex:indexPath.row];
    NCMessageCell *__cell =
        [collectionView dequeueReusableCellWithReuseIdentifier:ncUnknownMessageCellIndentifier forIndexPath:indexPath];
    [__cell setDataModel:model];
    return __cell;
}

- (CGSize)ncUnknownChannelCollectionView:(UICollectionView *)collectionView
                                      layout:(UICollectionViewLayout *)collectionViewLayout
                      sizeForItemAtIndexPath:(NSIndexPath *)indexPath {

    CGFloat __width = CGRectGetWidth(collectionView.frame);
    CGFloat maxMessageLabelWidth = __width - 30 * 2;
    NSString *localizedMessage = NCUILocalizedString(@"unknown_message_cell_tip");
    CGSize __textSize = [NCChatUIUtility getTextDrawingSize:localizedMessage
                                                    font:[[NCChatUIConfig defaultConfig].font fontOfFourthLevel]
                                         constrainedSize:CGSizeMake(maxMessageLabelWidth, 2000)];
    __textSize = CGSizeMake(ceilf(__textSize.width), ceilf(__textSize.height));
    CGSize __labelSize = CGSizeMake(__textSize.width + 5, __textSize.height + 6);
    return CGSizeMake(collectionView.bounds.size.width, __labelSize.height);
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                             layout:(UICollectionViewLayout *)collectionViewLayout
    referenceSizeForHeaderInSection:(NSInteger)section {
    CGFloat width = self.messageCollectionView.frame.size.width;
    CGFloat height = 0;
    // Keep the header at zero when fewer than 10 local messages load but allMessagesAreLoaded is still NO, avoiding an unwanted refresh-control offset.
    if(!self.dataSource.allMessagesAreLoaded) {
        if (self.channelDataRepository.count < self.defaultMessageCount) {
            height = 1;
        } else {
            height = COLLECTION_VIEW_REFRESH_CONTROL_HEIGHT;
        }
    }
    return (CGSize){width, height};
}

#pragma mark <UICollectionViewDelegate>
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row >= self.channelDataRepository.count) {
        return;
    }
    
    NCMessageModel *model = [self.channelDataRepository objectAtIndex:indexPath.row];
    if ([model rrs_shouldRespondReadReceipt] && model.messageId) {
        // Submit V5 read receipt responses through the batch manager.
        [self.readReceiptBatchManager addSubmitTask:model.messageId];
    }
}

- (NCMessageBaseCell *)ncChannelCollectionView:(UICollectionView *)collectionView
                            cellForItemAtIndexPath:(NSIndexPath *)indexPath {

    NCMessageModel *model = [self.channelDataRepository objectAtIndex:indexPath.row];
    // NCMessageContent *messageContent = model.content;
    NCMessageCell *__cell =
        [collectionView dequeueReusableCellWithReuseIdentifier:ncUnknownMessageCellIndentifier forIndexPath:indexPath];
    [__cell setDataModel:model];
    return __cell;
}

- (CGSize)ncChannelCollectionView:(UICollectionView *)collectionView
                                layout:(UICollectionViewLayout *)collectionViewLayout
                sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat __width = CGRectGetWidth(collectionView.frame);
    CGFloat __height = 0;
    CGFloat maxMessageLabelWidth = __width - 30 * 2;
    NSString *localizedMessage = NCUILocalizedString(@"unknown_message_cell_tip");
    CGSize __textSize = [NCChatUIUtility getTextDrawingSize:localizedMessage
                                                    font:[[NCChatUIConfig defaultConfig].font fontOfFourthLevel]
                                         constrainedSize:CGSizeMake(maxMessageLabelWidth, 2000)];
    __textSize = CGSizeMake(ceilf(__textSize.width), ceilf(__textSize.height));
    CGSize __labelSize = CGSizeMake(__textSize.width + 5, __textSize.height + 6);
    __height = __labelSize.height;
    return CGSizeMake(collectionView.bounds.size.width, __height);
}


#pragma mark - Child Pages
/**
 * Opens the image preview. Subclasses may override this method to download and present the image themselves.
 * The default implementation uses the built-in preview controller.
 *
 * @param model The message model for the image being previewed.
 */
- (void)presentImagePreviewController:(NCMessageModel *)model {
    [self presentImagePreviewController:model onlyPreviewCurrentMessage:NO];
}

- (void)presentImagePreviewController:(NCMessageModel *)model
            onlyPreviewCurrentMessage:(BOOL)onlyPreviewCurrentMessage {
    NCImageSlideController *_imagePreviewVC = [[NCImageSlideController alloc] init];
    _imagePreviewVC.messageModel = model;
    _imagePreviewVC.onlyPreviewCurrentMessage = onlyPreviewCurrentMessage;
    NCBaseNavigationController *nav = [[NCBaseNavigationController alloc] initWithRootViewController:_imagePreviewVC];
    if (self.navigationController) {
        // Match the navigation bar colors used by the channel page.
        UIImage *image = [self.navigationController.navigationBar backgroundImageForBarMetrics:UIBarMetricsDefault];
        [nav.navigationBar setBackgroundImage:image forBarMetrics:UIBarMetricsDefault];
    }
    nav.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)pushGIFPreviewViewController:(NCMessageModel *)model {
    NCGIFPreviewViewController *gifPreviewVC = [[NCGIFPreviewViewController alloc] init];
    gifPreviewVC.messageModel = model;
    [self.navigationController pushViewController:gifPreviewVC animated:NO];
}

- (void)pushCombinePreviewViewController:(NCMessageModel *)model {
    NSString *navTitle = NCCombinePreviewNavigationTitle((NCCombineMessage *)model.content);
    NCCombineMessagePreviewViewController *combinePreviewVC =
        [[NCCombineMessagePreviewViewController alloc] initWithMessageModel:model navTitle:navTitle];
    [self.navigationController pushViewController:combinePreviewVC animated:YES];
}

- (void)presentSightViewPreviewViewController:(NCMessageModel *)model {
    NCSightSlideViewController *svc = [[NCSightSlideViewController alloc] init];
    svc.messageModel = model;
    NCBaseNavigationController *navc = [[NCBaseNavigationController alloc] initWithRootViewController:svc];
    navc.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:navc animated:YES completion:nil];
}

- (void)presentFilePreviewViewController:(NCMessageModel *)model {
    NCFilePreviewViewController *fileViewController = [[NCFilePreviewViewController alloc] init];
    fileViewController.messageModel = model;
    [self.navigationController pushViewController:fileViewController animated:YES];
}

#pragma mark - Message Sending
- (void)sendMessage:(NCMessageContent *)messageContent pushContent:(NSString *)pushContent {
    messageContent = [self willSendMessage:messageContent];
    if (messageContent == nil) {
        return;
    }
    [self.util doSendMessage:messageContent pushContent:pushContent];
}

- (void)onlySendMessage:(NCMessageContent *)messageContent pushContent:(NSString *)pushContent {
    messageContent = [self willSendMessage:messageContent];
    if (messageContent == nil) {
        return;
    }
    [self.util doOnlySendMessage:messageContent pushContent:pushContent];
}

- (void)sendMediaMessage:(NCMediaMessageContent *)messageContent pushContent:(NSString *)pushContent {
    NCMessageContent *filteredContent = [self willSendMessage:messageContent];
    if (![filteredContent isKindOfClass:[NCMediaMessageContent class]]) {
        return;
    }
    messageContent = (NCMediaMessageContent *)filteredContent;
    [self.util doSendMessage:messageContent pushContent:pushContent];
}

- (void)sendMediaMessage:(NCMediaMessageContent *)messageContent
             pushContent:(NSString *)pushContent
               appUpload:(BOOL)appUpload {
    if (!appUpload) {
        [self sendMessage:messageContent pushContent:pushContent];
        return;
    }
    // App-managed upload is unsupported; requests with appUpload enabled are ignored.
    return;
}

- (void)uploadMedia:(NCMessage *)message uploadListener:(NCUploadMediaStatusListener *)uploadListener {
    (void)message;
    (void)uploadListener;
    NCLogReleaseW(@"-[NCChannelViewController uploadMedia:uploadListener:] must be overridden by the app to upload media.");
    //        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    //            int i = 0;
    //            for (i = 0; i < 100; i++) {
    //                uploadListener.updateBlock(i);
    //                [NSThread sleepForTimeInterval:0.2];
    //            }
    //            NCImageMessage *imageMsg = (NCImageMessage*)message.content;
    //            uploadListener.successBlock(imageMsg);
    //        });
}

// Image send, resend, and upload hooks.
- (void)sendImageMessage:(NCImageMessage *)imageMessage pushContent:(NSString *)pushContent {
    [self sendMessage:imageMessage pushContent:pushContent];
}

- (void)sendImageMessage:(NCImageMessage *)imageMessage pushContent:(NSString *)pushContent appUpload:(BOOL)appUpload {
    if (!appUpload) {
        [self sendMessage:imageMessage pushContent:pushContent];
        return;
    }
    [self sendMediaMessage:imageMessage pushContent:pushContent appUpload:appUpload];
}

- (void)resendMessageWithModel:(NCMessageModel *)model {
    NCMessageContent *messageContent = model.content;
    if (!messageContent) {
        return;
    }
    if ([messageContent isKindOfClass:[NCMediaMessageContent class]]) {
        NCMediaMessageContent *mediaMessage = (NCMediaMessageContent *)messageContent;
        if (mediaMessage.remoteUrl.length <= 0) {
            [self sendMediaMessage:mediaMessage pushContent:nil];
            return;
        }
    }
    [self sendMessage:messageContent pushContent:nil];
}

- (void)resendMessage:(NCMessageContent *)messageContent {
    if ([messageContent isMemberOfClass:NCImageMessage.class]) {
        NCImageMessage *imageMessage = (NCImageMessage *)messageContent;
        if (imageMessage.localPath.length > 0) {
            imageMessage.originalImage = [UIImage imageWithContentsOfFile:imageMessage.localPath];
        }
        [self sendMessage:imageMessage pushContent:nil];
    } else if ([messageContent isMemberOfClass:NCFileMessage.class]) {
        NCFileMessage *fileMessage = (NCFileMessage *)messageContent;
        [self sendMessage:fileMessage pushContent:nil];
    } else {
        [self sendMessage:messageContent pushContent:nil];
    }
}

- (void)uploadImage:(NCMessage *)message uploadListener:(NCUploadImageStatusListener *)uploadListener {
    (void)message;
    if (!uploadListener) {
        NCLogReleaseW(@"-[NCChannelViewController uploadImage:uploadListener:] must be overridden by the app to upload images.");
        return;
    }
    uploadListener.errorBlock(-1);
    NCLogReleaseW(@"-[NCChannelViewController uploadImage:uploadListener:] must be overridden by the app to upload images.");
    //    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    //        int i = 0;
    //        for (i = 0; i < 100; i++) {
    //            uploadListener.updateBlock(i);
    //            [NSThread sleepForTimeInterval:0.2];
    //        }
    //    });
}
// End image send, resend, and upload hooks.

- (void)cancelUploadMedia:(NCMessageModel *)model {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NCChatUI shared] cancelSendMediaMessage:model.clientId];
    });
}

- (void)cancelResendMessageIfNeed:(NCMessageModel *)model {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([[NCResendManager sharedManager] needResend:model.clientId]) {
            [[NCResendManager sharedManager] removeResendMessage:model.clientId];
        }
    });
}

#pragma mark - Message Editing


#pragma mark - NCChatSessionInputBarControlDelegate

- (void)chatInputBar:(NCChatSessionInputBarControl *)chatInputBar shouldChangeFrame:(CGRect)frame {
    if ([self updateReferenceViewFrame]) {
        return;
    }
    CGRect collectionViewRect = self.messageCollectionView.frame;
    collectionViewRect.size.height = CGRectGetMinY(frame) - collectionViewRect.origin.y;
    if (!chatInputBar.hidden) {
        [self.messageCollectionView setFrame:collectionViewRect];
    }
    if ([NCChatUIUtility isRTL]) {
        [self.unreadRightBottomIcon setFrame:CGRectMake(5.5, self.chatSessionInputBarControl.frame.origin.y - 12 - 35, 35, 35)];
    } else {
        [self.unreadRightBottomIcon setFrame:CGRectMake(self.view.frame.size.width - 5.5 - 35, self.chatSessionInputBarControl.frame.origin.y - 12 - 35, 35, 35)];
    }
    
    if (self.locatedMessageSentTime == 0 || self.isConversationAppear) {
        // Do not scroll to the bottom before viewWillAppear/viewDidLoad when a message location is forced.
        if (self.dataSource.isLoadingHistoryMessage || [self isRemainMessageExisted]) {
            [self loadRemainMessageAndScrollToBottom:YES];
        } else if (self.isConversationAppear || self.chatSessionInputBarControl.currentBottomBarStatus == KBottomBarKeyboardStatus) {
            [self scrollToBottomAnimated:NO];
        }
    }
}

- (void)inputTextViewDidTouchSendKey:(UITextView *)inputTextView {
    if ([self isInputTextTooLong:inputTextView.text]) {
        return;
    }
    if ([self sendReferenceMessage:inputTextView.text]) {
        return;
    }
    NCTextMessage *textMessage = [[NCTextMessage alloc] initWithText:inputTextView.text];
    textMessage.mentionedInfo = [self currentInputBarMentionedInfo];
    [self sendMessage:textMessage pushContent:nil];
}

- (void)inputTextView:(UITextView *)inputTextView
    shouldChangeTextInRange:(NSRange)range
            replacementText:(NSString *)text {
    [self p_sendTypingStatusIfNeedWithText:text];
    
    // Keep text input scrolling correct after loading more than 10 unread messages from the top-right control.
    if (self.dataSource.isLoadingHistoryMessage || [self isRemainMessageExisted]) {
        [self loadRemainMessageAndScrollToBottom:YES];
    }
}

- (void)inputTextViewDidChange:(UITextView *)textView {
    if (!self.placeholderLabel) {
        return;
    }
    if (textView.text.length > 0) {
        self.placeholderLabel.hidden = YES;
    } else {
        self.placeholderLabel.hidden = NO;
    }
}

- (void)inputTextViewDidChangeOnEndVoiceTransfer:(UITextView *)inputTextView {
    // Speech-dictated text also emits the typing indicator when transcription finishes.
    [self p_sendTypingStatusIfNeedWithText:inputTextView.text];
}

- (BOOL)isInputTextTooLong:(NSString *)text {
    if (text.length <= NCMessageTextMaxLength) {
        return NO;
    }
    [NCToastView showToast:NCUILocalizedString(@"nc_message_too_long") rootView:self.view];
    return YES;
}

- (void)p_sendTypingStatusIfNeedWithText:(NSString *)text {
    if (NCChatUIConfigCenter.message.enableTypingStatus && ![text isEqualToString:@"\n"]) {
        NCBaseChannel *channel = self.currentChannel;
        if ([channel isKindOfClass:[NCDirectChannel class]]) {
            [(NCDirectChannel *)channel sendTypingStatusWithTypingMessageType:NCMessageType.text];
        }
    }
}

- (void)pluginBoardView:(NCPluginBoardView *)pluginBoardView clickedItemWithTag:(NSInteger)tag {
    switch (tag) {
    case PLUGIN_BOARD_ITEM_ALBUM_TAG: {
        [self openSystemAlbum];
    } break;
    case PLUGIN_BOARD_ITEM_CAMERA_TAG: {
        [self openSystemCamera];
    } break;
    case PLUGIN_BOARD_ITEM_FILE_TAG: {
        [self openFileSelector];
    } break;
    case PLUGIN_BOARD_ITEM_VOICE_INPUT_TAG: {
        if ([NCChatUIUtility isAudioHolding]) {
            NSString *alertMessage = NCUILocalizedString(@"audio_holding_warning");
            [NCAlertView showAlertController:alertMessage message:nil hiddenAfterDelay:1 inViewController:self];
        } else {
            [self openDynamicFunction:tag];
        }
    } break;
    default: { [self openDynamicFunction:tag]; } break;
    }
}

- (void)presentViewController:(UIViewController *)viewController functionTag:(NSInteger)functionTag {
    switch (functionTag) {
    case PLUGIN_BOARD_ITEM_ALBUM_TAG:
    case PLUGIN_BOARD_ITEM_CAMERA_TAG:
    case PLUGIN_BOARD_ITEM_FILE_TAG:
    case INPUT_MENTIONED_SELECT_TAG: {
        viewController.modalPresentationStyle = UIModalPresentationFullScreen;
        [self.navigationController presentViewController:viewController animated:YES completion:nil];
    } break;
    default: { } break; }
}

#pragma mark Input Bar Extension Actions
// Opens the system photo library.
- (void)openSystemAlbum {
    [self.chatSessionInputBarControl openSystemAlbum];
}
// Opens the camera.
- (void)openSystemCamera {
    [self.chatSessionInputBarControl openSystemCamera];
}

// Opens the file picker.
- (void)openFileSelector {
    [self.chatSessionInputBarControl openFileSelector];
}
// Opens another extension feature, such as audio or video calling.
- (void)openDynamicFunction:(NSInteger)functionTag {
    [self.chatSessionInputBarControl openDynamicFunction:functionTag];
}

- (void)emojiView:(NCEmojiBoardView *)emojiView didTouchedEmoji:(NSString *)touchedEmoji {

    if (NCChatUIConfigCenter.message.enableTypingStatus) {
        NCBaseChannel *channel = self.currentChannel;
        if ([channel isKindOfClass:[NCDirectChannel class]]) {
            [(NCDirectChannel *)channel sendTypingStatusWithTypingMessageType:NCMessageType.text];
        }
    }
    self.placeholderLabel.hidden = self.chatSessionInputBarControl.inputTextView.text.length > 0;
}

- (void)emojiView:(NCEmojiBoardView *)emojiView didTouchSendButton:(UIButton *)sendButton {
    NSString *inputText = self.chatSessionInputBarControl.inputTextView.text;
    if ([self isInputTextTooLong:inputText]) {
        return;
    }
    if ([self sendReferenceMessage:inputText]) {
        return;
    }
    NCTextMessage *textMessage = [[NCTextMessage alloc] initWithText:inputText];
    textMessage.mentionedInfo = [self currentInputBarMentionedInfo];

    [self sendMessage:textMessage pushContent:nil];
    
    self.placeholderLabel.hidden = NO;
}
#pragma mark Voice Recording
// Voice recording began.
- (void)recordDidBegin {
    if (NCChatUIConfigCenter.message.enableTypingStatus) {
        NCBaseChannel *channel = self.currentChannel;
        if ([channel isKindOfClass:[NCDirectChannel class]]) {
            [(NCDirectChannel *)channel sendTypingStatusWithTypingMessageType:NCMessageType.hdVoice];
        }
    }

    [self onBeginRecordEvent];
}

// Voice recording ended.
- (void)recordDidEnd:(NSData *)recordData duration:(long)duration error:(NSError *)error {
    if (error == nil) {
        NSString *path = [self.util getHQVoiceMessageCachePath];
        [recordData writeToFile:path atomically:YES];
        NCHDVoiceMessage *hqVoiceMsg = [[NCHDVoiceMessage alloc] initWithLocalPath:path duration:(int)duration];
        [self sendMessage:hqVoiceMsg pushContent:nil];
    }

    [self onEndRecordEvent];
}

// Voice recording was canceled.
- (void)recordDidCancel {
    [self onCancelRecordEvent];
}

// Recording lifecycle hooks for subclasses.
- (void)onBeginRecordEvent {
}

- (void)onEndRecordEvent {
}

- (void)onCancelRecordEvent {
}
// End recording lifecycle hooks.

#pragma mark Event Callbacks
// Handles selected photo-library media.
- (void)imageDataDidSelect:(NSArray *)selectedImages fullImageRequired:(BOOL)full {
    [self becomeFirstResponder];
    self.isTakeNewPhoto = NO;
    [self.util doSendSelectedMediaMessage:selectedImages fullImageRequired:full];
}

// Handles an image captured by the camera.
- (void)imageDidCapture:(UIImage *)image {
    [self becomeFirstResponder];
    image = [NCChatUIUtility fixOrientation:image];
    NCImageMessage *imageMessage = [[NCImageMessage alloc] initWithImage:image];
    self.isTakeNewPhoto = YES;
    [self sendMessage:imageMessage pushContent:nil];
}
// Handles a completed short-video recording.
- (void)sightDidFinishRecord:(NSString *)url thumbnail:(UIImage *)image duration:(NSUInteger)duration {
    NCShortVideoMessage *sightMessage =
        [[NCShortVideoMessage alloc] initWithLocalPath:url thumbnail:image duration:(int)duration];
    [self sendMessage:sightMessage pushContent:nil];
}

- (void)sightDidRecordFailedWith:(NSError *)error status:(NSInteger)status {
    NCLogE(@"sightDidRecordFailedWith: error %ld status %ld", error.code, status);
}

// Handles selected files.
- (void)fileDidSelect:(NSArray *)filePathList {
    [self becomeFirstResponder];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for (NSString *filePath in filePathList) {
            NCFileMessage *fileMessage = [[NCFileMessage alloc] initWithLocalPath:filePath];
            [self sendMessage:fileMessage pushContent:nil];
            [NSThread sleepForTimeInterval:0.5];
        }
    });
}

#pragma mark <NCChatSessionInputBarControlDataSource>
- (void)getSelectingUserIdList:(void (^)(NSArray<NSString *> *userIdList))completion
                   functionTag:(NSInteger)functionTag {
    switch (functionTag) {
    case INPUT_MENTIONED_SELECT_TAG: {
        if (self.channelType == NCChannelTypeGroup) {
            if ([[NCChatUI shared].groupMemberDataSource respondsToSelector:@selector(getAllMembersOfGroup:result:)]) {
                [[NCChatUI shared]
                        .groupMemberDataSource getAllMembersOfGroup:self.channelId
                                                             result:^(NSArray<NSString *> *userIdList) {
                                                                 if (completion) {
                                                                     completion(userIdList);
                                                                 }
                                                             }];
            } else {
                if (completion) {
                    completion(nil);
                }
            }
        }
    } break;
    default: {
        if (completion) {
            completion(nil);
        }

    } break;
    }
}

- (NSString *)fileSelectorRootPath {
    NSString *documentsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    if (documentsPath.length > 0) {
        return documentsPath;
    }
    return NSTemporaryDirectory();
}

- (CGFloat)inputBarBottomSafeAreaInset {
    return [self getSafeAreaExtraBottomHeight];
}

- (BOOL)inputBarIsAudioHolding:(NCChatSessionInputBarControl *)chatInputBar {
    return [NCChatUIUtility isAudioHolding];
}

- (BOOL)inputBarIsCameraHolding:(NCChatSessionInputBarControl *)chatInputBar {
    return [NCChatUIUtility isCameraHolding];
}


- (NSDictionary *)getDraftExtraInfo {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    if (self.referencingView.referModel) {
        NSString *messageId = [self.referencingView.referModel.messageId copy];
        if (messageId.length) dict[NCUIReferencedMessageUId] = messageId;
    }
    return dict.copy;
}

- (void)didSetDraft:(NSDictionary *)info {
    NSString *referencedMessageUId = info[NCUIReferencedMessageUId];
    if (referencedMessageUId.length) {
        NCGetMessageByIdParams *getParams = [[NCGetMessageByIdParams alloc] initWithMessageId:referencedMessageUId];
        [NCBaseChannel getMessageByIdWithParams:getParams completion:^(NCMessage * _Nullable message, NSError * _Nullable error) {
            if (!message || message.clientId == 0) {
                return;
            }
            for (NCMessageModel *model in self.channelDataRepository) {
                if ([model.messageId isEqualToString:referencedMessageUId]) {
                    self.currentSelectedModel = model;
                    break;
                }
            }
            if (!self.currentSelectedModel) {
                self.currentSelectedModel = [NCMessageModel modelWithNCMessage:message];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [self onReferenceMessageCellAndEditing:NO];
            });
        }];
    }
}

#pragma mark - NCMessagesLoadProtocol
- (void)noMoreMessageToFetch {}

#pragma mark - Individual Message Handling
// Copies message content.
- (void)onCopyMessage:(id)sender {
    // self.msgInputBar.msgColumnTextView.disableActionMenu = NO;
    self.chatSessionInputBarControl.inputTextView.disableActionMenu = NO;
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    // NCMessageCell* cell = _NCMessageCell;
    // Copy only text message content.
    if ([self.currentSelectedModel.content isKindOfClass:[NCTextMessage class]]) {
        NCTextMessage *text = (NCTextMessage *)self.currentSelectedModel.content;
        [pasteboard setString:text.text];
    } else if ([self.currentSelectedModel.content isKindOfClass:[NCReferenceMessage class]]) {
        NCReferenceMessage *refer = (NCReferenceMessage *)self.currentSelectedModel.content;
        [pasteboard setString:refer.content];
    } else if ([self.currentSelectedModel.content isKindOfClass:NCStreamMessage.class]) {
        NCStreamMessage *stream = (NCStreamMessage *)self.currentSelectedModel.content;
        if (stream.sync) {
            NSString *content = stream.content;
            if (stream.content.length > NCStreamMessageTextLimit) {
                content = [content substringToIndex:NCStreamMessageTextLimit];
            }
            [pasteboard setString:content];
            return;
        }
        NCStreamSummaryModel *summary = [NCStreamUtilities parserStreamSummary:self.currentSelectedModel];
        [pasteboard setString:summary.summary];
    }
}
// Deletes message content.
- (void)onDeleteMessage:(id)sender {
    self.chatSessionInputBarControl.inputTextView.disableActionMenu = NO;
    NCMessageModel *model = self.currentSelectedModel;

    // Stop playback when deleting the currently playing message.
    if ([NCVoicePlayer defaultPlayer].messageClientId == model.clientId) {
        [self stopPlayingVoiceMessage];
    }
    NCConnectionStatus currentStatus = [NCEngine getConnectionStatus];
    if (model.messageId.length > 0 && currentStatus == NCConnectionStatusNetworkUnavailable) {
        [NCAlertView showAlertController:nil message:NCUILocalizedString(@"connection_disconnect") cancelTitle:NCUILocalizedString(@"confirm") inViewController:self];
        return;
    }
    [self deleteMessage:model];
}

- (void)onDeleteMessageForAll:(id)sender {
    self.chatSessionInputBarControl.inputTextView.disableActionMenu = NO;
    NCMessageModel *model = self.currentSelectedModel;

    if ([NCVoicePlayer defaultPlayer].messageClientId == model.clientId) {
        [self stopPlayingVoiceMessage];
    }
    NCConnectionStatus currentStatus = [NCEngine getConnectionStatus];
    if (model.messageId.length > 0 && currentStatus == NCConnectionStatusNetworkUnavailable) {
        [NCAlertView showAlertController:nil
                                 message:NCUILocalizedString(@"connection_disconnect")
                             cancelTitle:NCUILocalizedString(@"confirm")
                        inViewController:self];
        return;
    }
    if (![self.util canDeleteMessageForAllOfModel:model]) {
        return;
    }
    [self p_deleteMessageForAll:model.clientId];
}

- (void)p_deleteMessageForAll:(long)clientId {
    NCGetMessageByIdParams *params = [[NCGetMessageByIdParams alloc] initWithMessageClientId:clientId];
    [NCBaseChannel getMessageByIdWithParams:params completion:^(NCMessage * _Nullable msg, NSError * _Nullable error) {
        (void)error;
        if (!msg || (msg.direction != NCMessageDirectionSend && msg.sentStatus != NCMessageSentStatusSent)) {
            return;
        }
        __weak typeof(self) ws = self;
        NCBaseChannel *channel = ws.currentChannel;
        [channel deleteMessageForAll:msg completion:^(NCMessage * _Nullable deletedMessage, NSError * _Nullable error) {
            (void)error;
            if (!deletedMessage) {
                return;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([NCVoicePlayer defaultPlayer].messageClientId == msg.clientId) {
                    [ws stopPlayingVoiceMessage];
                }
                [ws reloadDeletedMessageForAllWithNCMessage:deletedMessage];
            });
        }];
    }];
}

- (void)reloadDeletedMessageForAllWithNCMessage:(NCMessage *)deletedMessage {
    [self.dataSource didDeleteMessageForAll:deletedMessage];
    
    if (self.referencingView && self.referencingView.referModel.clientId == deletedMessage.clientId) {
        [self dismissReferencingView:self.referencingView];
    }
    
    if ([self edit_isMessageEditing]) {
        NCMessageModel *model = [NCMessageModel modelWithNCMessage:deletedMessage];
        if (model) {
            [self edit_refreshEditInputReferenceViewIfNeeded:@[model] status:NCReferenceMessageStatusDeleted];
        }
    }
}

// Reloads messages after deletion for all participants.
- (void)reloadDeletedMessageForAllWithClientId:(long)deletedMessageClientId {
    if ([self edit_isMessageEditing]) {
        NCGetMessageByIdParams *params = [[NCGetMessageByIdParams alloc] initWithMessageClientId:deletedMessageClientId];
        [NCBaseChannel getMessageByIdWithParams:params completion:^(NCMessage * _Nullable message, NSError * _Nullable error) {
            [self reloadDeletedMessageForAllWithNCMessage:message];
        }];
    } else {
        [self reloadDeletedMessageForAllAndReferenceViewWithClientId:deletedMessageClientId];
    }
}

- (void)reloadDeletedMessageForAllAndReferenceViewWithClientId:(long)deletedMessageClientId {
    [self.dataSource didReloadDeletedMessageForAllWithClientId:deletedMessageClientId];
    
    if (self.referencingView && self.referencingView.referModel.clientId == deletedMessageClientId) {
        [self dismissReferencingView:self.referencingView];
    }
}

// Deletes a message.
- (void)deleteMessage:(NCMessageModel *)model {
    [self deleteMessage:model memoryOnly:NO];
}


/// Deletes a message.
/// - Parameters:
///   - model: model
///   - memoryOnly: Whether to remove only the in-memory model.
- (void)deleteMessage:(NCMessageModel *)model memoryOnly:(BOOL)memoryOnly {
    if (self.channelDataRepository.count == 0) {
        return;
    }
    [self.util stopVoiceMessageIfNeed:model];
    
    NSIndexPath *indexPath = [self.util findDataIndexFromMessageList:model];
    if (!indexPath) {
        return;
    } else{
        // If the deleted message shows a timestamp and the next one does not, transfer timestamp display to the next message.
        NCMessageModel *msgModel = self.channelDataRepository[indexPath.row];
        if (msgModel.isDisplayMessageTime) {
            int nextIndex = (int)indexPath.row+1;
            if(nextIndex < self.channelDataRepository.count){
                NCMessageModel *nextModel = self.channelDataRepository[nextIndex];
                if (nextModel && !nextModel.isDisplayMessageTime) {
                    nextModel.isDisplayMessageTime = YES;
                    nextModel.cellSize = CGSizeZero;
                    [self.messageCollectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:nextIndex inSection:0]]];
                }
            }
        }
    }
    
    if ([model.content isKindOfClass:[NCMediaMessageContent class]]) {
        // Cancel media upload and any pending resend.
        [self cancelUploadMedia:model];
    }else {
        // Cancel any pending resend for a non-media message.
        [self cancelResendMessageIfNeed:model];
    }

    long msgId = model.clientId;
    if(!memoryOnly) { // Skip storage deletion when the caller manages it separately, such as during manual resend.
        if (self.needDeleteRemoteMessage && model.messageId.length > 0) {
            // The configuration requests remote deletion.
            NCGetMessageByIdParams *params = [[NCGetMessageByIdParams alloc] initWithMessageClientId:msgId];
            [NCBaseChannel getMessageByIdWithParams:params completion:^(NCMessage * _Nullable delMsg, NSError * _Nullable error) {
                if (delMsg && delMsg.messageId.length > 0) {
                    // Delete the remote message when a server message ID exists.
                    NCBaseChannel *channel = self.currentChannel;
                    if (channel) {
                        [channel deleteMessagesForMe:@[delMsg] completion:nil];
                    } else {
                        [NCBaseChannel deleteLocalMessages:@[@(msgId)] completion:nil];
                    }
                }else {
                    // Messages not sent successfully exist only locally.
                    [NCBaseChannel deleteLocalMessages:@[@(msgId)] completion:nil];
                }
            }];
        }else {
            // Without remote deletion enabled, remove only the local message.
            [NCBaseChannel deleteLocalMessages:@[@(msgId)] completion:nil];
        }
    }
    [self.channelDataRepository removeObjectAtIndex:indexPath.item];
    // Guard against an index path invalidated by an automatic refresh after backgrounding.
    if (indexPath.row < [self.messageCollectionView numberOfItemsInSection:0]) {
        [self.messageCollectionView deleteItemsAtIndexPaths:[NSArray arrayWithObject:indexPath]];
    }
    
    [self deleteOldMessageNotificationMessageIfNeed];
    
    if (model) {
        if ([[NCMessageSelectionUtility sharedManager] isContainMessage:model]) {
            [[NCMessageSelectionUtility sharedManager] removeMessageModel:model];
        }
    }
    // Clear references to the deleted message.
    if (self.referencingView && self.referencingView.referModel.clientId == model.clientId) {
        [self dismissReferencingView:self.referencingView];
    }
    if (model.messageId) {
        [self.dataSource edit_setUIReferenceMessagesEditStatus:NCReferenceMessageStatusDeleted forMessageIds:@[model.messageId]];
        
        [self edit_refreshEditInputReferenceViewIfNeeded:@[model] status:NCReferenceMessageStatusDeleted];
    }
}

- (void)deleteOldMessageNotificationMessageIfNeed {
    // Remove NCOldMessageNotificationMessage when no message remains on either side of the history separator.
    if (self.channelDataRepository.count > 0) {
        NCMessageModel *lastOldModel = self.channelDataRepository[0];
        NCMessageModel *lastNewModel = self.channelDataRepository[self.channelDataRepository.count - 1];

        if ([lastOldModel.objectName isEqualToString:NCOldMessageNotificationMessageTypeIdentifier]) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
            [self.channelDataRepository removeObject:lastOldModel];
            [self.messageCollectionView deleteItemsAtIndexPaths:[NSArray arrayWithObject:indexPath]];

            // After removing the history separator, show a timestamp on the first channel message and adjust its height.
            NCMessageModel *topMsg = (self.channelDataRepository)[0];
            topMsg.isDisplayMessageTime = YES;
            topMsg.cellSize = CGSizeMake(topMsg.cellSize.width, topMsg.cellSize.height + 30);
            NCMessageCell *__cell = (NCMessageCell *)[self.messageCollectionView
                cellForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
            if (__cell) {
                [__cell setDataModel:topMsg];
            }
            [self.messageCollectionView reloadData];
        }
        if ([lastNewModel.objectName isEqualToString:NCOldMessageNotificationMessageTypeIdentifier]) {
            NSIndexPath *indexPath =
                [NSIndexPath indexPathForRow:self.channelDataRepository.count - 1 inSection:0];
            [self.channelDataRepository removeObject:lastNewModel];
            [self.messageCollectionView deleteItemsAtIndexPaths:[NSArray arrayWithObject:indexPath]];
        }
    }
}

- (void)notifyUpdateUnreadMessageCount {
    __weak typeof(self) __weakself = self;
    // Do not update the left bar while messages are selected.
    if (self.allowsMessageCellSelection) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(__weakself) strongSelf = __weakself;
            strongSelf.rightBarButtonItems = strongSelf.navigationItem.rightBarButtonItems;
            strongSelf.leftBarButtonItems = strongSelf.navigationItem.leftBarButtonItems;
            strongSelf.navigationItem.rightBarButtonItems = nil;
            strongSelf.navigationItem.leftBarButtonItems = nil;
            UIBarButtonItem *left =
                [[UIBarButtonItem alloc] initWithTitle:NCUILocalizedString(@"cancel")
                                                 style:UIBarButtonItemStylePlain
                                                target:strongSelf
                                                action:@selector(onCancelMultiSelectEvent:)];

            [left setTintColor:NCChatUIConfigCenter.ui.globalNavigationBarTintColor];
            strongSelf.navigationItem.leftBarButtonItem = left;
        });
    } else {
        if(!self.displayChannelTypeArray) {
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong typeof(__weakself) strongSelf = __weakself;
                strongSelf.navigationItem.leftBarButtonItems = strongSelf.leftBarButtonItems;
                strongSelf.leftBarButtonItems = nil;
                if (strongSelf.rightBarButtonItems) {
                    strongSelf.navigationItem.rightBarButtonItems = strongSelf.rightBarButtonItems;
                    strongSelf.rightBarButtonItems = nil;
                }
            });
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.navigationItem setLeftBarButtonItems:[self getLeftBackButton]];
            self.leftBarButtonItems = nil;
            if (self.rightBarButtonItems) {
                self.navigationItem.rightBarButtonItems = self.rightBarButtonItems;
                self.rightBarButtonItems = nil;
            }
        });
    }
}


#pragma mark override
- (void)didTapImageTxtMsgCell:(NSString *)tapedUrl webViewController:(UIViewController *)webViewController {
    webViewController.modalPresentationStyle = UIModalPresentationFullScreen;
    if ([webViewController isKindOfClass:[SFSafariViewController class]]) {
        [self presentViewController:webViewController animated:YES completion:nil];
    } else {
        UIWindow *window = [NCChatUIUtility getKeyWindow];
        UINavigationController *navigationController = (UINavigationController *)window.rootViewController;
        [navigationController pushViewController:webViewController animated:YES];
    }
}

#pragma mark - Tap Actions
- (BOOL)p_disableTapCell:(NCMessageModel *)model{
    if (nil == model) {
        return YES;
    }

    return NO;
}

// Handles a cell tap.
- (void)didTapMessageCell:(NCMessageModel *)model {
    NCLogD(@"%s", __FUNCTION__);
    
    if([self p_disableTapCell:model]){
        return;
    }

    NCMessageContent *_messageContent = model.content;

    if ([_messageContent isMemberOfClass:[NCImageMessage class]]) {
        [self p_didTapMessageCellForImageMessage:model];
        return;
    }
    
    if ([_messageContent isMemberOfClass:[NCShortVideoMessage class]]) {
        [self p_didTapMessageCellForSightMessage:model];
        return;
    }
    
    if ([_messageContent isMemberOfClass:[NCGIFMessage class]]) {
        [self p_didTapMessageCellForGIFMessage:model];
        return;
    }
    
    if ([_messageContent isMemberOfClass:[NCCombineMessage class]]) {
        [self p_didTapMessageCellForCombineMessage:model];
        return;
    }
    
    if ([_messageContent isMemberOfClass:[NCHDVoiceMessage class]]) {
        [self p_didTapMessageCellForVoiceMessage:model];
        return;
    }
    
    if ([_messageContent isMemberOfClass:[NCTextMessage class]]) {
        [self p_didTapMessageCellForTextMessage:model];
        return;
    }
    
    if ([self isExtensionCell:_messageContent]) {
        [[NCChatUIExtensionManager sharedManager] didTapMessageCell:model];
        return;
    }
    
    if ([_messageContent isMemberOfClass:[NCFileMessage class]]) {
        [self presentFilePreviewViewController:model];
        return;
    }
    
}

// Handles a long press on message content.
- (void)didLongTouchMessageCell:(NCMessageModel *)model inView:(UIView *)view {
    // Stop voice playback before presenting long-press actions.
    [self.util stopVoiceMessageIfNeed:model];
    self.currentSelectedModel = model;
    
    NCTextView *inputTextView;
    if ([self edit_isMessageEditing]) {
        inputTextView = self.editInputBarControl.editInputContainer.inputTextView;
    } else {
        inputTextView = self.chatSessionInputBarControl.inputTextView;
    }
    inputTextView.disableActionMenu = YES;
    if (![inputTextView isFirstResponder]) {
        // UIMenuController requires the channel page to be first responder for message actions.
        // Keep the input text view as first responder when it owns focus so the keyboard remains visible.
        [self becomeFirstResponder];
    }
    NSArray *menuItems = [self getLongTouchMessageCellMenuList:model];
    CGRect rect = [self.view convertRect:view.frame fromView:view.superview];
    [[NCMenuController sharedMenuController] showMenuFromView:view
                                                    menuItems:menuItems
                                                actionHandler:^(NCMenuItem * _Nonnull menuItem, NSInteger index) {
        if ([self respondsToSelector:menuItem.action]) {
            [self performSelector:menuItem.action
                       withObject:[menuItems objectAtIndex:index]];
        }
    }];
}

- (NCMenuItem *)deleteMenuItemForModel:(NCMessageModel *)model {
    BOOL canDeleteForAll = [self.util canDeleteMessageForAllOfModel:model];
    NSString *titleKey = canDeleteForAll ? @"delete_for_everyone" : @"delete_for_me";
    SEL action = canDeleteForAll ? @selector(onDeleteMessageForAll:) : @selector(onDeleteMessage:);
    return [[NCMenuItem alloc] initWithTitle:NCUILocalizedString(titleKey)
                                       image:NCDynamicImage(@"channel_menu_item_delete_img")
                                      action:action];
}

- (NSArray<UIMenuItem *> *)getLongTouchMessageCellMenuList:(NCMessageModel *)model {
    if ([model.content isKindOfClass:NCStreamMessage.class]) {
        return [self getLongTouchStreamMessageCellMenuList:model];
    }
    UIMenuItem *copyItem = [[NCMenuItem alloc] initWithTitle:NCUILocalizedString(@"copy")
                                                       image:NCDynamicImage(@"channel_menu_item_copy_img")
                                                      action:@selector(onCopyMessage:)];
    UIMenuItem *deleteItem = [self deleteMenuItemForModel:model];

    UIMenuItem *multiSelectItem =
        [[NCMenuItem alloc] initWithTitle:NCUILocalizedString(@"message_tap_more")
                                    image:NCDynamicImage(@"channel_menu_item_multiple_img")
                                   action:@selector(onMultiSelectMessageCell:)];

    UIMenuItem *referItem =
        [[NCMenuItem alloc] initWithTitle:NCUILocalizedString(@"reference")
                                    image:NCDynamicImage(@"channel_menu_item_reference_img")
                                   action:@selector(onReferenceMessageCell:)];

    NSMutableArray *items = @[].mutableCopy;
    if ([model.content isMemberOfClass:[NCTextMessage class]] ||
        [model.content isMemberOfClass:[NCReferenceMessage class]]) {
        [items addObject:copyItem];
    }
    [items addObject:deleteItem];
    if ([model edit_isMessageEditable]) {
        UIMenuItem *editItem = [[NCMenuItem alloc] initWithTitle:NCUILocalizedString(@"edit")
                                                           image:NCDynamicImage(@"channel_menu_item_edit_img")
                                                          action:@selector(onEditMessage:)];
        [items addObject:editItem];
    }
    if ([self.util canReferenceMessage:model]) {
        [items addObject:referItem];
    }

    if (self.channelType != NCChannelTypeSystem) {
        [items addObject:multiSelectItem];
    }
    
    return items.copy;
}


- (NSArray<UIMenuItem *> *)getLongTouchStreamMessageCellMenuList:(NCMessageModel *)model {
    
    if (![model.content isKindOfClass:NCStreamMessage.class]) {
        return @[];
    }
    NSMutableArray *items = @[].mutableCopy;
    
    UIMenuItem *copyItem = [[NCMenuItem alloc] initWithTitle:NCUILocalizedString(@"copy")
                                                       image:NCDynamicImage(@"channel_menu_item_copy_img")
                                                      action:@selector(onCopyMessage:)];
    UIMenuItem *deleteItem = [self deleteMenuItemForModel:model];
    [items addObjectsFromArray:@[copyItem, deleteItem]];
    
    NCStreamMessage *stream = (NCStreamMessage *)model.content;
    NCStreamSummaryModel *summary = [NCStreamUtilities parserStreamSummary:model];
    if (stream.sync || summary.isComplete) {
        UIMenuItem *referItem =
        [[NCMenuItem alloc] initWithTitle:NCUILocalizedString(@"reference")
                                    image:NCDynamicImage(@"channel_menu_item_reference_img")
                                   action:@selector(onReferenceMessageCell:)];
        [items addObject:referItem];
    }
    UIMenuItem *multiSelectItem =
    [[NCMenuItem alloc] initWithTitle:NCUILocalizedString(@"message_tap_more")
                                image:NCDynamicImage(@"channel_menu_item_multiple_img")
                               action:@selector(onMultiSelectMessageCell:)];
    [items addObject:multiSelectItem];
    return items;
}

- (void)didTapUrlInMessageCell:(NSString *)url model:(NCMessageModel *)model {
    [NCChatUIUtility openURLInSafariViewOrWebView:url base:self];
}

- (void)didTapReferencedContentView:(NCMessageModel *)model {
    [self previewReferenceView:model];
}

- (void)didTapPhoneNumberInMessageCell:(NSString *)phoneNumber model:(NCMessageModel *)model {
    NSString *phoneStr = [phoneNumber stringByReplacingOccurrencesOfString:@" " withString:@""];
  if (@available(iOS 10.0, *)) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:phoneStr]
                                           options:@{}
                                 completionHandler:^(BOOL success) {
            
        }];
    } else {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:phoneStr]];
    }
}

// Handles an avatar tap.
- (void)didTapCellPortrait:(NSString *)userId {
}

- (void)didLongPressCellPortrait:(NSString *)userId {
    if (!self.chatSessionInputBarControl.isMentionedEnabled ||
        [userId isEqualToString:[NCEngine getCurrentUserId]]) {
        return;
    }
    [self addMentionedUserToCurrentInput:[self getSelectingUserInfo:userId]];
}

- (void)didTapReceiptStatusView:(NCMessageModel *)model {
    NCMessageReadDetailViewModel *viewModel = [[NCMessageReadDetailViewModel alloc] initWithMessageModel:model config:nil];
    NCMessageReadDetailViewController *readReceiptDetailVC = [[NCMessageReadDetailViewController alloc] initWithViewModel:viewModel];
    [self.navigationController pushViewController:readReceiptDetailVC animated:YES];
}

#pragma mark Internal Tap Handlers
- (void)tapRightBottomMsgCountIcon:(UIGestureRecognizer *)gesture {
    [self.dataSource tapRightBottomMsgCountIcon:gesture];
}

- (void)tap4ResetDefaultBottomBarStatus:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        if (self.edit_isMessageEditing) {
            [self edit_hideEditBottomPanels];
            return;
        }
        if (self.chatSessionInputBarControl.currentBottomBarStatus != KBottomBarDefaultStatus &&
            self.chatSessionInputBarControl.currentBottomBarStatus != KBottomBarRecordStatus) {
            [self.chatSessionInputBarControl resetToDefaultStatus];
        }
    }
}

- (void)tapRightTopMsgUnreadButton:(UIButton *)sender {
    // Record that the unread button loaded new messages so subsequent loads can track their count.
    self.unReadButton.selected = YES;
    [self.dataSource tapRightTopMsgUnreadButton];
}

- (void)didTapCancelUploadButton:(NCMessageModel *)model {
    [self cancelUploadMedia:model];
}

- (void)didTapmessageFailedStatusViewForResend:(NCMessageModel *)model {
    // resending message.
    NCLogD(@"%s", __FUNCTION__);

    NCMessageContent *content = model.content;
    
    NSIndexPath *indexPath = [self.util findDataIndexFromMessageList:model];
    if (!indexPath) {
        return;
    }
    if ([content isMemberOfClass:[NCHDVoiceMessage class]] && model.messageDirection == NCMessageDirectionReceive) {
        NCGetMessageByIdParams *params = [[NCGetMessageByIdParams alloc] initWithMessageClientId:model.clientId];
        [NCBaseChannel getMessageByIdWithParams:params completion:^(NCMessage * _Nullable message, NCError * _Nullable error) {
            (void)error;
            if (!message) {
                return;
            }
            [[NCHDVoiceMsgDownloadManager defaultManager] pushVoiceMsgs:@[ message ] priority:NO];
            [self.messageCollectionView reloadItemsAtIndexPaths:[NSArray arrayWithObject:indexPath]];
        }];
    } else {
        // Remove the failed item before manual resend so old and new bubbles are not both displayed.
        [self deleteMessage:model memoryOnly:YES];
        [self.dataSource.cachedReloadMessages removeObject:model];
        if (model.clientId > 0) {
            [NCBaseChannel deleteLocalMessages:@[ @(model.clientId) ] completion:nil];
        }
        [self resendMessageWithModel:model];
    }
}

- (void)onTypingStatusChanged:(NCTypingStatusChangedEvent *)event {
    NCChannelIdentifier *identifier = event.channelIdentifier;
    if (identifier.channelType == self.channelType &&
        [identifier.channelId isEqualToString:self.channelId] &&
        NCChatUIConfigCenter.message.enableTypingStatus) {
        NSArray<NCChannelUserTypingStatusInfo *> *userTypingStatusList = event.userTypingStatus;
        dispatch_async(dispatch_get_main_queue(), ^{
            if (userTypingStatusList.count == 0) {
                // Restore the navigation title.
                [self restoreNavigationTitleForTypingStatusIfNeeded];
            } else {
                // Display the typing indicator.
                NCChannelUserTypingStatusInfo *typingStatus = userTypingStatusList[0];
                NSString *statusText = nil;
                if ([typingStatus.typingMessageType isEqualToString:NCMessageType.text]) {
                    statusText = NCUILocalizedString(@"typing");
                } else if ([typingStatus.typingMessageType isEqualToString:NCMessageType.hdVoice]) {
                    statusText = NCUILocalizedString(@"speaking");
                }
                if (statusText) {
                    [self showTypingNavigationTitle:statusText sentTime:typingStatus.sentTime];
                }
            }
        });
    }
}

- (void)leftBarButtonItemPressed:(id)sender {
    [self quitConversationViewAndClear];
    if (self.navigationController && [self.navigationController.viewControllers.lastObject isEqual:self]) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)customerServiceLeftCurrentViewController{
}

- (void)alertErrorAndLeft:(NSString *)errorInfo {
    [NCAlertView showAlertController:nil message:errorInfo hiddenAfterDelay:1 inViewController:self dismissCompletion:^{
        [self.navigationController popViewControllerAnimated:YES];
    }];
}

#pragma mark - Cell multi select
- (void)setAllowsMessageCellSelection:(BOOL)allowsMessageCellSelection {
    [[NCMessageSelectionUtility sharedManager] clear];
    [[NCMessageSelectionUtility sharedManager] setMultiSelect:allowsMessageCellSelection];
    dispatch_main_async_safe(^{
        [self updateConversationMessageCollectionView];
    });
}

- (BOOL)allowsMessageCellSelection {
    return [NCMessageSelectionUtility sharedManager].multiSelect;
}

- (void)onMultiSelectMessageCell:(id)sender {
    self.allowsMessageCellSelection = YES;
}

- (void)onCancelMultiSelectEvent:(UIBarButtonItem *)item {
    self.allowsMessageCellSelection = NO;
}

- (void)forwardMessageEnd {
    self.allowsMessageCellSelection = NO;
}

- (void)updateConversationMessageCollectionView {
    if ([self edit_updateConversationMessageCollectionView]) {
        return;
    }
    [self updateNavigationBarItem];
    if ([NCMessageSelectionUtility sharedManager].multiSelect) {
        if (self.chatSessionInputBarControl.currentBottomBarStatus != KBottomBarRecordStatus) {
            [self.chatSessionInputBarControl resetToDefaultStatus];
        }
        [[NCMessageSelectionUtility sharedManager] addMessageModel:self.currentSelectedModel];
    } else {
        self.currentSelectedModel = nil;
    }
    [self showToolBar:[NCMessageSelectionUtility sharedManager].multiSelect];
    
    // On Xcode 13 and iOS 15, refresh offscreen cells to avoid issue 44945.
    // Calling reloadItemsAtIndexPaths: and reloadData together can leave some cells stale.
    // A delay of at least 0.3 seconds separates the two reload operations.
    [self.messageCollectionView reloadData];
    [self.messageCollectionView setNeedsLayout];
    [self.messageCollectionView layoutIfNeeded];
}

- (void)showToolBar:(BOOL)show {
    if (show) {
        [self.view addSubview:self.messageSelectionToolbar];
        [self removeReferencingView];
    } else {
        [self.messageSelectionToolbar removeFromSuperview];
    }
}

- (NSArray<NCMessageModel *> *)selectedMessages {
    return [[NCMessageSelectionUtility sharedManager] selectedMessages];
}

- (void)deleteMessages {
    NSArray *tempArray = [self.selectedMessages mutableCopy];
    self.allowsMessageCellSelection = NO;
    
    __block BOOL isAllLocalMessage = YES;
    [tempArray enumerateObjectsUsingBlock:^(NCMessageModel *msg, NSUInteger idx, BOOL * _Nonnull stop) {
        if (msg.messageId.length > 0) {
            isAllLocalMessage = NO;
            *stop = YES;
        }
    }];
    NCChatUINetworkStatus currentStatus = [[NCChatUI shared] getCurrentNetworkStatus];
    if ((!isAllLocalMessage) && currentStatus == NCChatUINetworkStatusNotReachable) {
        [NCAlertView showAlertController:nil message:NCUILocalizedString(@"connection_disconnect") cancelTitle:NCUILocalizedString(@"confirm") inViewController:self];
        return;
    }
    
    for (int i = 0; i < tempArray.count; i++) {
        [self deleteMessage:tempArray[i]];
    }
    // Reset collectionViewNewContentSize after batch deletion to avoid IMSDK-8250.
   NCChannelViewLayout *currentLayout = (NCChannelViewLayout *)self.messageCollectionView.collectionViewLayout;
    currentLayout.collectionViewNewContentSize = CGSizeZero;
    
    // Load the next page automatically when deletion leaves the screen empty.
    if (self.channelDataRepository.count == 0) {
        [self.collectionViewHeader startAnimating];
        [self.dataSource scrollToLoadMoreHistoryMessage];
    }
}

/// NCMessagesMultiSelectedProtocol method
/// @param status The selection or deselection state.
/// @param model The cell data model.
- (BOOL)onMessagesMultiSelectedCountWillChanged:(NCMessageMultiSelectStatus)status model:(NCMessageModel *)model {
    BOOL executed = YES;
    switch (status) {
    case NCMessageMultiSelectStatusSelected:
        executed = [self willSelectMessage:model];
        break;
    case NCMessageMultiSelectStatusCancelSelected:
        executed = [self willCancelSelectMessage:model];
        break;
    default:
        break;
    }
    return executed;
}

- (void)onMessagesMultiSelectedCountDidChanged:(NCMessageMultiSelectStatus)status model:(NCMessageModel *)model {
    if (self.selectedMessages.count == 0) {
        for (UIBarButtonItem *item in self.messageSelectionToolbar.items) {
            item.enabled = NO;
        }
    } else {
        for (UIBarButtonItem *item in self.messageSelectionToolbar.items) {
            item.enabled = YES;
        }
    }
}

#pragma mark - Update Message SendStatus
- (void)updateForMessageSendOut:(NCMessage *)message {
    if ([message.content isKindOfClass:[NCImageMessage class]]) {
        NCImageMessage *img = (NCImageMessage *)message.content;
        img.originalImage = nil;
    }
    NCMessage *filteredMessage = [self willAppendAndDisplayMessage:message];
    if (!filteredMessage) {
        return;
    }
    [self.dataSource appendSendOutMessage:filteredMessage];
}

- (void)updateForMessageSendProgress:(int)progress clientId:(long)clientId {
    [self.util sendMessageStatusNotification:CONVERSATION_CELL_STATUS_SEND_PROGRESS clientId:clientId progress:progress];
}

- (void)updateForMessageSendSuccess:(NCMessage *)message {
    [self updateForMessageSendSuccess:message sourceClientId:(long)message.clientId];
}

- (void)updateForMessageSendSuccess:(NCMessage *)message sourceClientId:(long)sourceClientId {
    long clientId = sourceClientId > 0 ? sourceClientId : (long)message.clientId;
    NCMessageContent *content = message.content;
    NCLogD(@"message<%ld> send succeeded ", clientId);

    dispatch_async(dispatch_get_main_queue(), ^{
        NCMessage *latestMessage = message;
        if ([latestMessage.content isKindOfClass:[NCReferenceMessage class]]) {
            NCReferenceMessage *refMessage = (NCReferenceMessage *)latestMessage.content;
            NCMessageModel *uiMessageModel = [self.util modelByMessageUId:refMessage.referMsgId];
            if (uiMessageModel && uiMessageModel.hasChanged) {
                refMessage.referMsgStatus = NCReferenceMessageStatusUpdated;
            }
        }
        NCMessageModel *latestMessageModel = [NCMessageModel modelWithNCMessage:latestMessage];
        NSArray *conversationDataRepository = self.channelDataRepository.copy;
        for (NCMessageModel *model in conversationDataRepository) {
            if (model.clientId == clientId) {
                model.sentStatus = NCMessageSentStatusSent;
                if (model.clientId > 0) {
                    model.clientId = latestMessageModel.clientId;
                    model.sentTime = latestMessageModel.sentTime;
                    model.messageId = latestMessageModel.messageId;
                    model.content = latestMessageModel.content;
                }
                break;
            }
        }
        for(NCMessageModel *model in self.dataSource.cachedReloadMessages){
            if (model.clientId == clientId) {
                model.sentStatus = NCMessageSentStatusSent;
                if (model.clientId > 0) {
                    model.clientId = latestMessageModel.clientId;
                    model.sentTime = latestMessageModel.sentTime;
                    model.messageId = latestMessageModel.messageId;
                    model.content = latestMessageModel.content;
                }
                break;
            }
        }
        long notifyClientId = latestMessageModel.clientId > 0 ? latestMessageModel.clientId : clientId;
        [self.util sendMessageStatusNotification:CONVERSATION_CELL_STATUS_SEND_SUCCESS clientId:notifyClientId progress:0];
    });
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [self didSendMessage:0 content:content];
#pragma clang diagnostic pop
    [self didSendMessageModel:0 model:[NCMessageModel modelWithNCMessage:message]];

    if ([content isKindOfClass:[NCImageMessage class]]) {
        NCImageMessage *imageMessage = (NCImageMessage *)content;
        if (self.enableSaveNewPhotoToLocalSystem && self.isTakeNewPhoto) {
            UIImage *image = [UIImage imageWithContentsOfFile:imageMessage.localPath];
            [self saveNewPhotoToLocalSystemAfterSendingSuccess:image];
        }
    }
}

- (void)updateLastMessageReadReceiptStatus:(long)clientId {
    dispatch_after(
        // Reload again after 0.3 seconds to cover delayed cell rendering.
        dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.util sendMessageStatusNotification:CONVERSATION_CELL_STATUS_SEND_SUCCESS clientId:clientId progress:0];
        });
}

- (void)updateForMessageSendError:(NCChatUIErrorCode)nErrorCode
                        clientId:(long)clientId
                          content:(NCMessageContent *)content
             ifResendNotification:(bool)ifResendNotification{
    NCLogD(@"message<%ld> send failed error code %d", clientId, (int)nErrorCode);


    __weak typeof(self) __weakself = self;
    dispatch_after(
        // After a send failure, reload again after 0.3 seconds to cover delayed cell rendering.
        dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 0.3f), dispatch_get_main_queue(), ^{
            __strong typeof(__weakself) strongSelf = __weakself;
            for (NCMessageModel *model in strongSelf.channelDataRepository) {
                if (model.clientId == clientId) {
                    model.sentStatus = NCMessageSentStatusFailed;
                    break;
                }
            }
            for (NCMessageModel *model in strongSelf.dataSource.cachedReloadMessages) {
                if (model.clientId == clientId) {
                    model.sentStatus = NCMessageSentStatusFailed;
                    break;
                }
            }
            [strongSelf.util sendMessageStatusNotification:CONVERSATION_CELL_STATUS_SEND_FAILED clientId:clientId progress:0];
        });
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [self didSendMessage:nErrorCode content:content];
#pragma clang diagnostic pop

    NCMessageModel *failedModel = [self.util modelByMessageID:clientId];
    if (!failedModel) {
        for (NCMessageModel *cachedModel in self.dataSource.cachedReloadMessages) {
            if (cachedModel.clientId == clientId) {
                failedModel = cachedModel;
                break;
            }
        }
    }
    if (failedModel) {
        [self didSendMessageModel:nErrorCode model:failedModel];
    }

    NCInformationNotificationMessage *informationNotifiMsg = [self.util getInfoNotificationMessageByErrorCode:nErrorCode];
    if (nil != informationNotifiMsg && !ifResendNotification) {
        long long baseSentTime = failedModel ? failedModel.sentTime : (long long)([[NSDate date] timeIntervalSince1970] * 1000);
        NCBaseChannel *channel = self.currentChannel;
        NCChannelIdentifier *channelIdentifier = self.currentChannelIdentifier;
        if (channel && channelIdentifier) {
            NCInsertMessageParams *insertParams = [[NCInsertMessageParams alloc] initWithContent:informationNotifiMsg];
            insertParams.direction = NCMessageDirectionSend;
            insertParams.sentStatus = NCMessageSentStatusSent;
            insertParams.sentTime = baseSentTime + 1;
            __weak typeof(self) weakSelf = self;
            [channel insertMessagesWithParams:@[ insertParams ] completion:^(BOOL isInserted, NCError * _Nullable error) {
                if (!isInserted || error) {
                    return;
                }
                NCLocalMessagesByTimeQueryParams *queryParams = [[NCLocalMessagesByTimeQueryParams alloc] init];
                queryParams.channelIdentifier = channelIdentifier;
                queryParams.pageSize = 10;
                queryParams.sentTime = baseSentTime;
                queryParams.isAscending = YES;
                queryParams.messageTypes = @[ NCInformationNotificationMessageIdentifier ];
                NCLocalMessagesByTimeQuery *messagesQuery =
                    [NCBaseChannel createLocalMessagesByTimeQueryWithParams:queryParams];
                [messagesQuery loadNextPageWithCompletion:^(NSArray<NCMessage *> * _Nullable messages, NCError * _Nullable queryError) {
                    if (queryError || messages.count == 0) {
                        return;
                    }
                    __strong typeof(weakSelf) strongSelf = weakSelf;
                    if (!strongSelf) {
                        return;
                    }
                    NCMessage *tempNCMessage = nil;
                    for (NCMessage *message in messages.reverseObjectEnumerator) {
                        if (![message.content isKindOfClass:[NCInformationNotificationMessage class]]) {
                            continue;
                        }
                        if (message.sentTime < insertParams.sentTime) {
                            continue;
                        }
                        tempNCMessage = message;
                        break;
                    }
                    if (!tempNCMessage) {
                        tempNCMessage = [messages lastObject];
                    }
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NCMessage *displayMessage = [strongSelf willAppendAndDisplayMessage:tempNCMessage];
                        if (displayMessage) {
                            [strongSelf appendAndDisplayMessage:displayMessage];
                        }
                    });
                }];
            }];
        }
    }
    if (nErrorCode == NCChatUIErrorCodeMediaException) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *alertMessage = NCUILocalizedString(@"cannot_upload_files");
            [NCAlertView showAlertController:nil message:alertMessage hiddenAfterDelay:1 inViewController:self];
        });
    }
}

- (void)updateForMessageSendCanceled:(long)clientId content:(NCMessageContent *)content {
    NCLogD(@"message<%ld> canceled", clientId);

    __weak typeof(self) __weakself = self;
    dispatch_after(
        // After a send failure, reload again after 0.3 seconds to cover delayed cell rendering.
        dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 0.3f), dispatch_get_main_queue(), ^{
            __strong typeof(__weakself) strongSelf = __weakself;
            for (NCMessageModel *model in strongSelf.channelDataRepository) {
                if (model.clientId == clientId) {
                    model.sentStatus = NCMessageSentStatusCanceled;
                    break;
                }
            }

            [strongSelf.util sendMessageStatusNotification:CONVERSATION_CELL_STATUS_SEND_CANCELED clientId:clientId progress:0];
        });

    [self didCancelMessage:content];
}

#pragma mark - download
- (void)updateDownloadStatus:(NSNotification *)noti {
    NCHDVoiceMsgDownloadInfo *info = noti.object;
    NCMessageModel *model;
    NCHDVoiceMessage *message;
    if (info.status == NCHQDownloadStatusSuccess) {
        for (int i = (int)self.channelDataRepository.count - 1; i >= 0; i--) {
            model = self.channelDataRepository[i];
            if (model.clientId == info.hqVoiceMsg.clientId &&
                [model.content isKindOfClass:[NCHDVoiceMessage class]]) {
                message = (NCHDVoiceMessage *)model.content;
                message.localPath = ((NCHDVoiceMessage *)info.hqVoiceMsg.content).localPath;
                if (self.isContinuousPlaying && model.clientId == [NCVoicePlayer defaultPlayer].messageClientId) {
                    [self startPlayAudio:model];
                }
                break;
            }
        }
    }
}

- (void)downloadMediaNotification:(NSNotification *)noti {
    NSDictionary *info = noti.userInfo;
    if ([[info objectForKey:@"type"] isEqualToString:@"success"]) {
        NSInteger messageid = [[info objectForKey:@"clientId"] integerValue];
        NCMessageModel *model;
        NCGIFMessage *message;
        for (int i = 0; i < self.channelDataRepository.count; i++) {
            model = self.channelDataRepository[i];
            if (model.clientId == messageid && [model.content isKindOfClass:[NCGIFMessage class]]) {
                message = (NCGIFMessage *)model.content;
                message.localPath = [info objectForKey:@"mediaPath"];
                break;
            }
        }
    }
}

- (void)updateNavigationBarItem {
    [self notifyUpdateUnreadMessageCount];
}

- (void)forwardMessages {
    [self showForwardActionSheet];
}

- (void)showForwardActionSheet {
    NSMutableArray *titleArray = [[NSMutableArray alloc]
        initWithObjects:NCUILocalizedString(@"one_by_one_forward"), nil];
    if (NCChatUIConfigCenter.message.enableSendCombineMessage &&
        (self.channelType == NCChannelTypeDirect || self.channelType == NCChannelTypeGroup)) {
        [titleArray addObject:NCUILocalizedString(@"combine_and_forward")];
    }
    [NCActionSheetView showActionSheetView:nil
                                 cellArray:titleArray
                               cancelTitle:NCUILocalizedString(@"cancel")
                             selectedBlock:^(NSInteger index) {
        if (index == 0) {
            if ([NCCombineMessageUtility allSelectedOneByOneForwordMessagesAreLegal:self.selectedMessages]) {
                // Forward messages individually.
                [self forwardMessage:0
                           completed:^(NSArray<NCBaseChannel *> *conversationList) {
                    NSArray *selectedMessage = [NSArray arrayWithArray:self.selectedMessages];
                    if (conversationList.count > 0 && selectedMessage.count > 0) {
                        [[NCForwardManager sharedInstance] doForwardMessageList:selectedMessage
                                                               conversationList:conversationList
                                                                      isCombine:NO
                                                        forwardConversationType:self.channelType
                                                                      completed:^(BOOL success){
                        }];
                        [self forwardMessageEnd];
                    }
                }];
            } else {
                [NCAlertView showAlertController:nil message:NCUILocalizedString(@"one_by_one_forwarding_not_supported") cancelTitle:NCUILocalizedString(@"ok") inViewController:self];
            }
            
        } else if (index == 1) {
            if ([NCCombineMessageUtility allSelectedCombineForwordMessagesAreLegal:self.selectedMessages]) {
                [self forwardMessage:1
                           completed:^(NSArray<NCBaseChannel *> *conversationList) {
                    NSArray *selectedMessage = [NSArray arrayWithArray:self.selectedMessages];
                    if (conversationList.count > 0 && selectedMessage.count > 0) {
                        [[NCForwardManager sharedInstance] doForwardMessageList:selectedMessage
                                                               conversationList:conversationList
                                                                      isCombine:YES
                                                        forwardConversationType:self.channelType
                                                                      completed:^(BOOL success){
                        }];
                        [self forwardMessageEnd];
                    }
                }];
            } else {
                [NCAlertView showAlertController:nil message:NCUILocalizedString(@"combine_forwarding_not_supported") cancelTitle:NCUILocalizedString(@"ok") inViewController:self];
            }
        }
    }cancelBlock:^{
        
    }];
}

- (void)forwardMessage:(NSInteger)index
             completed:(void (^)(NSArray<NCBaseChannel *> *conversationList))completedBlock {
    NCSelectChannelViewController *forwardSelectedVC = [[NCSelectChannelViewController alloc]
        initSelectConversationViewControllerCompleted:^(NSArray<NCBaseChannel *> *conversationList) {
            completedBlock(conversationList);
        }];
    [self.navigationController pushViewController:forwardSelectedVC animated:NO];
}
#pragma mark -- Emoji

/*!
 Disables system emoji.

 @discussion Only custom emoji remain visible after this is called.
 */
- (void)disableSystemDefaultEmoji {
    [self.chatSessionInputBarControl.emojiBoardView disableSystemDefaultEmoji];
}
/*!
 Indicates whether system emoji are disabled.

 @discussion Returns the current disabled state.
 */
- (BOOL)isSystemEmojiDisable {
    return self.chatSessionInputBarControl.emojiBoardView.isSystemEmojiDisable;
}
#pragma mark - Helper
- (void)registerSectionHeaderView {
    [self.messageCollectionView registerClass:[NCChannelCollectionViewHeader class]
                               forSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                                      withReuseIdentifier:@"RefreshHeadView"];
}


#pragma mark - dark
- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    [self fitDarkMode];
}

- (void)fitDarkMode {
    if (!NCChatUIConfigCenter.ui.enableDarkMode) {
        return;
    }
    if (@available(iOS 13.0, *)) {
        if (self.unReadButton) {
            [self.unReadButton setBackgroundImage:NCDynamicImage(@"channel_unread_button_bg_img") forState:UIControlStateNormal];
        }
        if (self.unReadMentionedButton) {
            [self.unReadMentionedButton setBackgroundImage:NCDynamicImage(@"channel_unread_button_bg_img") forState:UIControlStateNormal];
        }
        [self.messageCollectionView reloadData];
    }
}

#pragma mark - Reference
- (void)onReferenceMessageCell:(id)sender {
    if ([self edit_onReferenceMessageCell:sender])  {
        return;
    }
    // Switch the regular input bar to reference mode.
    [self onReferenceMessageCellAndEditing:YES];
}

- (void)onReferenceMessageCellAndEditing:(BOOL)editing {
    [self removeReferencingView];
    self.referencingView = [[NCReferencingView alloc] initWithModel:self.currentSelectedModel inView:self.view];
    self.referencingView.delegate = self;
    [self.view addSubview:self.referencingView];
    [self.referencingView
        setOffsetY:CGRectGetMinY(self.chatSessionInputBarControl.frame) - self.referencingView.frame.size.height];
    if (editing) {
        [self.chatSessionInputBarControl.inputTextView becomeFirstResponder];
    }
    [self updateReferenceViewFrame];
}

#pragma mark NCReferencingViewDelegate
- (void)dismissReferencingView:(NCReferencingView *)referencingView {
    [self removeReferencingView];
    __block CGRect messageCollectionView = self.messageCollectionView.frame;
    [UIView animateWithDuration:0.25
                     animations:^{
        if (self.chatSessionInputBarControl) {
            messageCollectionView.size.height =
            CGRectGetMinY(self.chatSessionInputBarControl.frame) - messageCollectionView.origin.y;
            self.messageCollectionView.frame = messageCollectionView;
        }
        
    }];
}

- (void)previewReferenceView:(NCMessageModel *)messageModel {
    if ([self disableReferencedPreview:messageModel]) {
        return;
    }
    
    NCMessageContent *msgContent = messageModel.content;
    if ([messageModel.content isKindOfClass:[NCReferenceMessage class]]) {
        NCReferenceMessage *refer = (NCReferenceMessage *)messageModel.content;
        msgContent = refer.referMsg;
    }

    if ([msgContent isKindOfClass:[NCImageMessage class]]) {
        NCMessageModel *imageModel = [[NCMessageModel alloc] init];
        imageModel.channelType = messageModel.channelType;
        imageModel.channelId = messageModel.channelId;
        imageModel.clientId = messageModel.clientId;
        imageModel.messageDirection = messageModel.messageDirection;
        imageModel.senderUserId = messageModel.senderUserId;
        imageModel.sentStatus = messageModel.sentStatus;
        imageModel.receivedStatusInfo = messageModel.receivedStatusInfo;
        imageModel.receivedTime = messageModel.receivedTime;
        imageModel.sentTime = messageModel.sentTime;
        imageModel.objectName = messageModel.objectName;
        imageModel.content = msgContent;
        imageModel.userInfo = messageModel.userInfo;
        imageModel.messageId = messageModel.messageId;
        [self presentImagePreviewController:imageModel onlyPreviewCurrentMessage:YES];
    } else if ([msgContent isKindOfClass:[NCFileMessage class]]) {
        [self presentFilePreviewViewController:messageModel];
    } else if ([msgContent isKindOfClass:[NCTextMessage class]]|| [msgContent isKindOfClass:[NCReferenceMessage class]]){
        if ([self.chatSessionInputBarControl.inputTextView isFirstResponder]) {
            [self.chatSessionInputBarControl.inputTextView resignFirstResponder];
        }
        BOOL isEdited = NO;
        if ([messageModel.content isKindOfClass:[NCReferenceMessage class]]) {
            isEdited = ((NCReferenceMessage *)messageModel.content).referMsgStatus == NCReferenceMessageStatusUpdated;
        }
        NSString *showText = [NCChatUIUtility formatMessage:msgContent
                                                channelId:self.channelId
                                        channelType:messageModel.channelType
                                            isAllMessage:YES];
        [NCTextPreviewView edit_showText:showText clientId:messageModel.clientId edited:isEdited delegate:self];
    } else if ([msgContent isKindOfClass:[NCStreamMessage class]]){
         if ([self.chatSessionInputBarControl.inputTextView isFirstResponder]) {
             [self.chatSessionInputBarControl.inputTextView resignFirstResponder];
         }
        NCStreamMessage *stream = (NCStreamMessage *)msgContent;
        [NCTextPreviewView showText:stream.content clientId:messageModel.clientId  delegate:self];
     }
}

- (BOOL)updateReferenceViewFrame {
    if (self.referencingView) {
        UIButton *recordBtn = (UIButton *)self.chatSessionInputBarControl.recordButton;
        UIButton *emojiBtn = (UIButton *)self.chatSessionInputBarControl.emojiButton;
        UIButton *additionalBtn = (UIButton *)self.chatSessionInputBarControl.additionalButton;
        // Reference messages can be sent only from text or emoji input states.
        if ((recordBtn.hidden || emojiBtn.state == UIControlStateHighlighted) &&
            additionalBtn.state == UIControlStateNormal) {
            [self.referencingView setOffsetY:CGRectGetMinY(self.chatSessionInputBarControl.frame) -
                                             self.referencingView.frame.size.height];

            __block CGRect messageCollectionView = self.messageCollectionView.frame;
            [UIView
                animateWithDuration:0.25
                         animations:^{
                             messageCollectionView.size.height =
                                 CGRectGetMinY(self.referencingView.frame) - messageCollectionView.origin.y;
                             self.messageCollectionView.frame = messageCollectionView;
                             if (self.messageCollectionView.contentSize.height >
                                 messageCollectionView.size.height) {
                                 [self.messageCollectionView
                                     setContentOffset:CGPointMake(
                                                          0, self.messageCollectionView.contentSize.height -
                                                                 messageCollectionView.size.height)
                                             animated:NO];
                                 // When the reference view appears, scroll to the newest message and hide the lower-right bubble.
                                 [self.dataSource.unreadNewMsgArr removeAllObjects];
                                 [self updateUnreadMsgCountLabel];
                             }
                         }];
            return YES;
        } else {
            [self removeReferencingView];
        }
    }
    return NO;
}

- (BOOL)sendReferenceMessage:(NSString *)content {
    if (self.referencingView.referModel) {
        NCReferenceMessage *reference = [[NCReferenceMessage alloc] init];
        reference.content = content;
        reference.referMsg = self.referencingView.referModel.content;
        reference.referMsgSenderId = self.referencingView.referModel.senderUserId;
        reference.mentionedInfo = [self currentInputBarMentionedInfo];
        reference.referMsgId = self.referencingView.referModel.messageId;
        if (self.referencingView.referModel.hasChanged) {
            reference.referMsgStatus = NCReferenceMessageStatusUpdated;
        }
        [self sendMessage:reference pushContent:nil];
        [self dismissReferencingView:self.referencingView];
        return YES;
    }
    return NO;
}

- (void)removeReferencingView {
    if (self.referencingView) {
        [self.referencingView removeFromSuperview];
        self.referencingView = nil;
        [self updateUnreadMsgCountLabelFrame];
    }
}

#pragma mark - Config
- (void)setDefaultInputType:(NCChatSessionInputBarInputType)defaultInputType {
    if (_defaultInputType != defaultInputType) {
        _defaultInputType = defaultInputType;
        if (self.chatSessionInputBarControl) {
            [self.chatSessionInputBarControl setDefaultInputType:defaultInputType];
        }
    }
}

- (void)setLocatedMessageSentTime:(long long)locatedMessageSentTime {
    _locatedMessageSentTime = locatedMessageSentTime;
}

- (void)setDefaultLocalHistoryMessageCount:(int)count {
    self.defaultMessageCount = count;
}

- (void)setDefaultRemoteHistoryMessageCount:(int)count {
    self.defaultMessageCount = count;
}

- (void)setDefaultMessageCount:(int)count {
    if (count > 100) {
        _defaultMessageCount = 100;
    }else if(count < 2){
        _defaultMessageCount = 10;
    } else {
        _defaultMessageCount = count;
    }
}

- (int)defaultMessageCount {
    return _defaultMessageCount;
}

- (int)defaultLocalHistoryMessageCount {
    return self.defaultMessageCount;
}

- (int)defaultRemoteHistoryMessageCount {
    return self.defaultMessageCount;
}
// Sets the avatar style.
- (void)setMessageAvatarStyle:(NCUserAvatarStyle)avatarStyle {
    NCChatUIConfigCenter.ui.globalMessageAvatarStyle = avatarStyle;
}

// Sets the avatar size.
- (void)setMessagePortraitSize:(CGSize)size {
    NCChatUIConfigCenter.ui.globalMessagePortraitSize = size;
}

#pragma mark - Util
- (void)refreshVisibleCells {
    // Reload currently visible cells.
    NSMutableArray *indexPathes = [[NSMutableArray alloc] init];
    for (NCMessageCell *cell in self.messageCollectionView.visibleCells) {
        NSIndexPath *indexPath = [self.messageCollectionView indexPathForCell:cell];
        [indexPathes addObject:indexPath];
    }
    [self.messageCollectionView reloadItemsAtIndexPaths:[indexPathes copy]];
}

- (void)playNextVoiceMesage:(NSNumber *)msgId {
    dispatch_async(dispatch_get_main_queue(), ^{
        long clientId = [msgId longValue];
        NCMessageModel *messageModel;
        NCMessageModel *nextVoiceMessage;
        long long currentVoiceSentTime = 0;
        for (int i = 0; i < self.channelDataRepository.count; i++) {
            messageModel = [self.channelDataRepository objectAtIndex:i];
            // Find the currently playing voice message.
            if(currentVoiceSentTime == 0){
                if(clientId == messageModel.clientId) {
                    currentVoiceSentTime = messageModel.sentTime; // Save its send timestamp.
                }
                continue;
            }
            // Find the voice message nearest to that send timestamp.
            if (currentVoiceSentTime < messageModel.sentTime && [messageModel.content isMemberOfClass:[NCHDVoiceMessage class]] &&
                NO == messageModel.receivedStatusInfo.isListened && messageModel.messageDirection == NCMessageDirectionReceive) {
                nextVoiceMessage = messageModel;
                break;
            }
        }
        
        if (!nextVoiceMessage) {
            self.isContinuousPlaying = NO;
            return;
        }
        [self startPlayAudio:nextVoiceMessage];
    });
}

- (void)startPlayAudio:(NCMessageModel *)model {
    [self markMessageListened:model];
    [[NCVoicePlayer defaultPlayer] playAudio:model];
}

- (void)markMessageListened:(NCMessageModel *)model {
    if (model.receivedStatusInfo.isListened) {
        return;
    }
    model.receivedStatusInfo.isListened = YES;
    if (model.clientId <= 0) {
        return;
    }
    NCGetMessageByIdParams *params = [[NCGetMessageByIdParams alloc] initWithMessageClientId:model.clientId];
    [NCBaseChannel getMessageByIdWithParams:params completion:^(NCMessage * _Nullable message, NCError * _Nullable error) {
        if (!message || error) {
            return;
        }
        [message setReceivedStatusInfo:model.receivedStatusInfo completion:nil];
    }];
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    return [super canPerformAction:action withSender:sender];
}

- (BOOL)resignFirstResponder {
    // Clear UIMenuController items when NCChannelViewController resigns first responder.
    // This prevents message-cell actions from appearing in the input menu.
    UIMenuController *menu = [UIMenuController sharedMenuController];
    
    // Clear only a nonempty menu to avoid unnecessary UI updates.
    if (menu.menuItems.count > 0) {
        // Use the menu dismissal API available for the current iOS version.
        if (@available(iOS 13.0, *)) {
            // On iOS 13 and later, hide the menu before clearing its items.
            [menu hideMenuFromView:self.view];
            [menu setMenuItems:nil];
        } else {
            // Earlier versions use the legacy visibility API.
            [menu setMenuItems:nil];
            [menu setMenuVisible:NO animated:NO];
        }
    }
    [[NCMenuController sharedMenuController] hideMenuAnimated:NO];

    return [super resignFirstResponder];
}

- (float)getSafeAreaExtraBottomHeight {
    return [NCChatUIUtility getWindowSafeAreaInsets].bottom;
}

- (BOOL)isExtensionCell:(NCMessageContent *)messageContent {
    NSString *messageType = [NCMessageContent messageTypeForContent:messageContent];
    if (messageType.length == 0) {
        return NO;
    }
    for (NCChatUIExtensionMessageCellInfo *cellInfo in self.extensionMessageCellInfoList) {
        if ([cellInfo.messageType isEqualToString:messageType]) {
            return YES;
        }
    }
    return NO;
}

// Releases channel-page resources and event handlers.
- (void)quitConversationViewAndClear {
    [self invalidateTypingStatusRestoreTimer];

    [[NCChatUIExtensionManager sharedManager] containerViewWillDestroy:self.channelType
                                                               channelId:self.channelId];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [NCEngine removeMessageHandlerForIdentifier:NCConversationReadReceiptHandlerIdentifier(self)];
    [NCEngine removeConnectionStatusHandlerForIdentifier:NCConversationConnectionStatusHandlerIdentifier(self)];
    
    // Stop batched read receipt submission.
    [self.readReceiptBatchManager invalidate];

}

- (BOOL)isRemainMessageExisted {
    return self.locatedMessageSentTime != 0;
}

- (void)addMentionedUserToCurrentInput:(NCChatUIUserInfo *)userInfo {
    if ([self edit_addMentionedUserToCurrentInput:userInfo]) {
        return;
    }
    // Add the mention to the regular input bar.
    if (self.chatSessionInputBarControl.isMentionedEnabled) {
        [self.chatSessionInputBarControl addMentionedUser:userInfo];
        [self.chatSessionInputBarControl.inputTextView becomeFirstResponder];
    }
}

- (BOOL)isDisplayOnlineStatus {
    NSString *userId = [NCEngine getCurrentUserId];
    // Presence is displayed only for other users in direct channels with the custom title view.
    return self.channelType == NCChannelTypeDirect
            && [NCUserOnlineStatusUtil shouldDisplayOnlineStatus]
            && !([userId isEqualToString:self.channelId]);
}

#pragma mark - Title Management
/**
 * Overrides setTitle: so external callers can continue setting self.title.
 * 
 * @param title The navigation title text.
 * 
 * @discussion
 *   - Updates the custom title view when one is installed.
 *   - Otherwise uses the default navigation title behavior.
 */
- (void)setTitle:(NSString *)title {
    [super setTitle:title];
    
    // Keep the custom title view synchronized when installed.
    if (self.conversationTitleView) {
        [self.conversationTitleView setTitle:title];
    }
}

/**
 * Returns the current navigation title.
 * 
 * @return The current title text.
 */
- (NSString *)currentNavigationTitle {
    if (self.conversationTitleView) {
        return self.conversationTitleView.titleLabel.text;
    } else {
        return self.navigationItem.title;
    }
}

/// Updates presence displayed in the navigation title.
- (void)updateNavigationTitleOnlineStatus {
    // Leave a title view supplied by a subclass unchanged.
    if (![self isDisplayOnlineStatus]
        || !self.conversationTitleView
        || ![self.navigationItem.titleView isKindOfClass:[self.conversationTitleView class]]) {
        return;
    }
    
    NCSubscribeUserOnlineStatus *onlineStatus = [[NCUserOnlineStatusManager sharedManager] getCachedOnlineStatus:self.channelId];
    // Keep the status icon visible for both online and offline states.
    [self.conversationTitleView updateOnlineStatus:onlineStatus.isOnline];
    if (!onlineStatus) {
        [[NCUserOnlineStatusManager sharedManager] fetchOnlineStatus:self.channelId processSubscribeLimit:NO];
    }
}

- (void)updateNavigationTitle:(NSString *)title {
    if (self.conversationTitleView) {
        self.conversationTitleView.titleLabel.text = title;
    } else {
        self.navigationItem.title = title;
    }
}

- (void)showTypingNavigationTitle:(NSString *)title sentTime:(long long)sentTime {
    if (!self.displayingTypingStatus) {
        self.navigationTitle = [self currentNavigationTitle];
        self.displayingTypingStatus = YES;
    }
    [self updateNavigationTitle:title];
    [self scheduleTypingStatusRestoreWithSentTime:sentTime];
}

- (void)scheduleTypingStatusRestoreWithSentTime:(long long)sentTime {
    [self invalidateTypingStatusRestoreTimer];

    NSTimeInterval delay = NCTypingStatusTimeoutInterval;
    if (sentTime > 0) {
        long long now = (long long)([[NSDate date] timeIntervalSince1970] * 1000);
        long long expireTime = sentTime + (long long)(NCTypingStatusTimeoutInterval * 1000);
        delay = MIN(NCTypingStatusTimeoutInterval, MAX(0.1, (expireTime - now) / 1000.0));
    }

    __weak typeof(self) weakSelf = self;
    self.typingStatusRestoreTimer =
        [NSTimer timerWithTimeInterval:delay
                               repeats:NO
                                 block:^(NSTimer * _Nonnull timer) {
                                     (void)timer;
                                     [weakSelf restoreNavigationTitleForTypingStatusIfNeeded];
                                 }];
    [[NSRunLoop mainRunLoop] addTimer:self.typingStatusRestoreTimer forMode:NSRunLoopCommonModes];
}

- (void)restoreNavigationTitleForTypingStatusIfNeeded {
    [self invalidateTypingStatusRestoreTimer];
    if (!self.displayingTypingStatus) {
        return;
    }
    self.displayingTypingStatus = NO;
    [self updateNavigationTitle:self.navigationTitle];
}

- (void)invalidateTypingStatusRestoreTimer {
    [self.typingStatusRestoreTimer invalidate];
    self.typingStatusRestoreTimer = nil;
}

#pragma mark - Hooks
- (NCMessageContent *)willSendMessage:(NCMessageContent *)message {
    NCLogD(@"super %s", __FUNCTION__);
    return message;
}

- (NCMessage *)willAppendAndDisplayMessage:(NCMessage *)message {
    NCLogD(@"super %s", __FUNCTION__);
    return message;
}

- (void)appendAndDisplayMessage:(NCMessage *)message{
    [self.dataSource appendAndDisplayMessage:message];
}

- (void)didSendMessage:(NSInteger)status content:(NCMessageContent *)messageContent {
    NCLogD(@"super %s, %@", __FUNCTION__, messageContent);
}

- (void)didSendMessageModel:(NSInteger)status model:(NCMessageModel *)messageModel {
    NCLogD(@"super %s, %@", __FUNCTION__, messageModel);
}

- (void)didCancelMessage:(NCMessageContent *)messageContent {
    NCLogD(@"super %s, %@", __FUNCTION__, messageContent);
}

- (BOOL)willSelectMessage:(NCMessageModel *)model {
    NCLogD(@"super %s, %@", __FUNCTION__, model);
    return YES;
}

- (BOOL)willCancelSelectMessage:(NCMessageModel *)model {
    NCLogD(@"super %s, %@", __FUNCTION__, model);
    return YES;
}

- (void)saveNewPhotoToLocalSystemAfterSendingSuccess:(UIImage *)newImage {
}

- (void)willDisplayMessageCell:(NCMessageBaseCell *)cell atIndexPath:(NSIndexPath *)indexPath {
}

// Legacy cell display callback hook retained for subclasses.
- (void)willDisplayConversationTableCell:(NCMessageBaseCell *)cell atIndexPath:(NSIndexPath *)indexPath {
}

#pragma mark - Getter & Setter
- (NCBaseImageView *)unreadRightBottomIcon {
    if (!_unreadRightBottomIcon) {
        UIImage *msgCountIcon = NCDynamicImage(@"channel_unread_button_bubble_img");
        CGRect frame = CGRectMake(self.view.frame.size.width - 5.5 - 35, self.chatSessionInputBarControl.frame.origin.y - 12 - 35, 35, 35);
        if ([NCChatUIUtility isRTL]) {
            frame.origin.x = 5.5;
        }
        _unreadRightBottomIcon = [[NCBaseImageView alloc] initWithFrame:frame];
        _unreadRightBottomIcon.userInteractionEnabled = YES;
        _unreadRightBottomIcon.image = msgCountIcon;
        //        _unreadRightBottomIcon.translatesAutoresizingMaskIntoConstraints = NO;
        UITapGestureRecognizer *tap =
            [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapRightBottomMsgCountIcon:)];
        [_unreadRightBottomIcon addGestureRecognizer:tap];
        _unreadRightBottomIcon.hidden = YES;
        [self.view addSubview:_unreadRightBottomIcon];
    }
    return _unreadRightBottomIcon;
}

- (UILabel *)unReadNewMessageLabel {
    if (!_unReadNewMessageLabel) {
        _unReadNewMessageLabel = [[UILabel alloc] initWithFrame:_unreadRightBottomIcon.bounds];
        _unReadNewMessageLabel.backgroundColor = [UIColor clearColor];
        _unReadNewMessageLabel.font = [[NCChatUIConfig defaultConfig].font fontOfAnnotationLevel];
        _unReadNewMessageLabel.textAlignment = NSTextAlignmentCenter;
        _unReadNewMessageLabel.textColor = NCDynamicColor(@"control_title_white_color");
        _unReadNewMessageLabel.center = CGPointMake(_unReadNewMessageLabel.frame.size.width / 2,
                                                    _unReadNewMessageLabel.frame.size.height / 2 - 2.5);
        [self.unreadRightBottomIcon addSubview:_unReadNewMessageLabel];
    }
    return _unReadNewMessageLabel;
}


- (UITapGestureRecognizer *)resetBottomTapGesture {
    if (!_resetBottomTapGesture) {
        _resetBottomTapGesture =
            [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap4ResetDefaultBottomBarStatus:)];
        [_resetBottomTapGesture setDelegate:self];
        _resetBottomTapGesture.cancelsTouchesInView = NO;
        _resetBottomTapGesture.delaysTouchesEnded = NO;
    }
    return _resetBottomTapGesture;
}


- (NCBaseButton *)unReadButton {
    if (!_unReadButton) {
        _unReadButton = [NCBaseButton new];
        CGFloat extraHeight = 0;
        if ([self getSafeAreaExtraBottomHeight] > 0) {
            extraHeight = 24; // A full-width sensor housing increases navigation height from 20 to 44 points.
        }
        CGFloat height = 32;
        _unReadButton.frame = CGRectMake(0, [NCChatUIUtility getWindowSafeAreaInsets].top + self.navigationController.navigationBar.frame.size.height + 14, 0, height);
        [_unReadButton setBackgroundImage:NCDynamicImage(@"channel_unread_button_bg_img") forState:UIControlStateNormal];
        [_unReadButton addSubview:self.unReadMessageLabel];
        [_unReadButton addTarget:self
                          action:@selector(tapRightTopMsgUnreadButton:)
                forControlEvents:UIControlEventTouchUpInside];
    }
    return _unReadButton;
}

- (UILabel *)unReadMessageLabel {
    if (!_unReadMessageLabel) {
        _unReadMessageLabel =
            [[UILabel alloc] initWithFrame:CGRectZero];
        NSString *newMessageCount = [NSString stringWithFormat:@"%ld", (long)_unReadMessage];
        if (_unReadMessage > UNREAD_MESSAGE_MAX_COUNT) {
            newMessageCount = [NSString stringWithFormat:@"%d+", UNREAD_MESSAGE_MAX_COUNT];
        }
        NSString *stringUnread = [NSString
            stringWithFormat:NCUILocalizedString(@"right_un_read_message"), newMessageCount];
        _unReadMessageLabel.text = stringUnread;
        _unReadMessageLabel.font = [[NCChatUIConfig defaultConfig].font fontOfAnnotationLevel];
        _unReadMessageLabel.textColor = NCDynamicColor(@"primary_color");
        _unReadMessageLabel.textAlignment = NSTextAlignmentCenter;
        _unReadMessageLabel.tag = 1001;
    }
    return _unReadMessageLabel;
}

- (NCBaseButton *)unReadMentionedButton {
    if (_unReadMentionedButton == nil) {
        _unReadMentionedButton = [NCBaseButton new];
        CGFloat height = 32;
        _unReadMentionedButton.frame = CGRectMake(0, CGRectGetMaxY(self.unReadButton.frame) + 15, 0, height);
        [_unReadMentionedButton setBackgroundImage:NCDynamicImage(@"channel_unread_button_bg_img") forState:UIControlStateNormal];
        [_unReadMentionedButton addTarget:self action:@selector(tapRightTopUnReadMentionedButton:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:_unReadMentionedButton];
        [_unReadMentionedButton addSubview:self.unReadMentionedLabel];
        [_unReadMentionedButton bringSubviewToFront:self.messageCollectionView];
    }
    return _unReadMentionedButton;
}

- (UILabel *)unReadMentionedLabel {
    if (!_unReadMentionedLabel) {
        _unReadMentionedLabel = [[UILabel alloc] initWithFrame:CGRectMake(17 + 9 + 6, 0, 0, 48)];
        _unReadMentionedLabel.font = [[NCChatUIConfig defaultConfig].font fontOfFourthLevel];
        _unReadMentionedLabel.textColor = NCDynamicColor(@"hint_color");
        _unReadMentionedLabel.textAlignment = NSTextAlignmentCenter;
        _unReadMentionedLabel.tag = 1002;
    }
    return _unReadMentionedLabel;
}

- (UIToolbar *)messageSelectionToolbar {
    if (!_messageSelectionToolbar) {
        _messageSelectionToolbar = [[UIToolbar alloc] init];
        [_messageSelectionToolbar setShadowImage:[UIImage new] forToolbarPosition:UIBarPositionAny];
        _messageSelectionToolbar.backgroundColor =  NCDynamicColor(@"common_background_color");
        _messageSelectionToolbar.barTintColor = NCDynamicColor(@"common_background_color");

        NCButton *forwardBtn = [[NCButton alloc] initWithFrame:CGRectMake(0, 0, 32, 32)];
        [forwardBtn setImage:NCDynamicImage(@"forward_message") forState:UIControlStateNormal];
        [forwardBtn addTarget:self action:@selector(forwardMessages) forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem *forwardBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:forwardBtn];

        UIBarButtonItem *spaceItem =
            [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                          target:nil
                                                          action:nil];

        NSArray *items = @[ spaceItem, forwardBarButtonItem, spaceItem ];
        
        if ([NCChatUIUtility isRTL]){
            _messageSelectionToolbar.semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;
        }else{
            _messageSelectionToolbar.semanticContentAttribute = UISemanticContentAttributeForceLeftToRight;
        }

        [_messageSelectionToolbar setItems:items animated:YES];
        _messageSelectionToolbar.translucent = NO;

    }
    return _messageSelectionToolbar;
}

- (NSArray *)getLeftBackButton {
    int count = NCUnreadCountForDisplayConversationTypes(self.displayChannelTypeArray);
    
    NSString *backString = nil;
    if (count > 0 && count < 100) {
        backString = [NSString
            stringWithFormat:@"%@(%d)", NCUILocalizedString(@"back"), count];
    } else if (count >= 100 && count < 1000) {
        backString = [NSString
            stringWithFormat:@"%@(99+)", NCUILocalizedString(@"back")];
    } else if (count >= 1000) {
        backString =
            [NSString stringWithFormat:@"%@(...)", NCUILocalizedString(@"back")];
    } else {
        backString = NCUILocalizedString(@"back");
    }
    NSArray *items;
    UIImage *imgMirror = NCDynamicImage(@"navigation_bar_btn_back_img");
    imgMirror = [NCSemanticContext imageflippedForRTL:imgMirror];
    items = [NCChatUIUtility getLeftNavigationItems:imgMirror title:backString target:self action:@selector(leftBarButtonItemPressed:)];
    return items;
}

- (UIView *)extensionView {
    if (!_extensionView) {
        _extensionView = [[UIView alloc] init];
        [self.view addSubview:_extensionView];
    }
    return _extensionView;
}

- (void)setIsTouchScrolled:(BOOL)isTouchScrolled {
    if (isTouchScrolled != self.isTouchScrolled) {
        _isTouchScrolled = isTouchScrolled;
        [[NSNotificationCenter defaultCenter] postNotificationName:NCConversationViewScrollNotification object:@(isTouchScrolled)];
    }
}

#pragma -mark private method
- (void)p_didTapMessageCellForImageMessage:(NCMessageModel *)model {
    NCMessageContent *_messageContent = model.content;
    NCImageMessage *imageMsg = (NCImageMessage *)_messageContent;
    [self presentImagePreviewController:model];
}

- (void)p_didTapMessageCellForSightMessage:(NCMessageModel *)model {
    NCMessageContent *_messageContent = model.content;
    if ([NCChatUIUtility isCameraHolding]) {
        NSString *alertMessage = NCUILocalizedString(@"voip_video_call_existed_warning");
        [NCAlertView showAlertController:nil message:alertMessage hiddenAfterDelay:1 inViewController:self];
        return;
    }
    if ([NCChatUIUtility isAudioHolding]) {
        NSString *alertMessage = NCUILocalizedString(@"voip_audio_call_existed_warning");
        [NCAlertView showAlertController:nil message:alertMessage hiddenAfterDelay:1 inViewController:self];
        return;
    }
    NCShortVideoMessage *sightMsg = (NCShortVideoMessage *)_messageContent;
    [self presentSightViewPreviewViewController:model];
}

- (void)p_didTapMessageCellForGIFMessage:(NCMessageModel *)model {
    NCMessageContent *_messageContent = model.content;
    NCGIFMessage *gifMsg = (NCGIFMessage *)_messageContent;
    [self pushGIFPreviewViewController:model];
}

- (void)p_didTapMessageCellForCombineMessage:(NCMessageModel *)model {
    [self pushCombinePreviewViewController:model];
}

- (void)p_didTapMessageCellForVoiceMessage:(NCMessageModel *)model {
    if ([NCChatUIUtility isAudioHolding]) {
        NSString *alertMessage = NCUILocalizedString(@"audio_holding_warning");
        [NCAlertView showAlertController:nil message:alertMessage hiddenAfterDelay:1 inViewController:self];
        return;
    }
    if (model.messageDirection == NCMessageDirectionReceive && NO == model.receivedStatusInfo.isListened) {
        self.isContinuousPlaying = YES;
    } else {
        self.isContinuousPlaying = NO;
    }
    if ([NCVoicePlayer defaultPlayer].isPlaying && model.clientId == [NCVoicePlayer defaultPlayer].messageClientId) {
        [[NCVoicePlayer defaultPlayer] stopPlayVoice];
    } else {
        [self startPlayAudio:model];
    }
}

- (void)p_didTapMessageCellForTextMessage:(NCMessageModel *)model {
    NCMessageContent *_messageContent = model.content;
    // link
    NCTextMessage *textMsg = (NCTextMessage *)(_messageContent);
    // phoneNumber
}

#pragma mark - Edit Message

- (BOOL)disableReferencedPreview:(NCMessageModel *)messageModel {
    if ([messageModel.content isKindOfClass:[NCReferenceMessage class]]) {
        NCReferenceMessage *refMsg = (NCReferenceMessage *)messageModel.content;
        if (refMsg.referMsgStatus == NCReferenceMessageStatusDeleted
            || refMsg.referMsgStatus == NCReferenceMessageStatusRecalled) {
            return YES;
        }
    }
    return NO;
}

- (void)onEditMessage:(id)sender {
    [self edit_onEditMessage:sender];
}

- (void)didTapEditRetryButton:(NCMessageModel *)model {
    [self edit_didTapEditRetryButton:model];
}

#pragma mark NCEditInputBarControlDelegate

- (void)editInputBarControl:(NCEditInputBarControl *)editInputBarControl didConfirmWithText:(NSString *)text {
    [self edit_editInputBarControl:editInputBarControl didConfirmWithText:text];
}

- (void)editInputBarControlDidCancel:(NCEditInputBarControl *)editInputBarControl {
    [self edit_editInputBarControlDidCancel:editInputBarControl];
}

- (void)editInputBarControl:(NCEditInputBarControl *)editInputBarControl shouldChangeFrame:(CGRect)frame {
    [self edit_editInputBarControl:editInputBarControl shouldChangeFrame:frame];
}

- (void)editInputBarControl:(NCEditInputBarControl *)editInputBarControl
           showUserSelector:(void (^)(NCChatUIUserInfo *selectedUser))selectedBlock
                     cancel:(void (^)(void))cancelBlock {
    [self edit_editInputBarControl:editInputBarControl showUserSelector:selectedBlock cancel:cancelBlock];
}

- (void)editInputBarControlRequestFullScreenEdit:(NCEditInputBarControl *)editInputBarControl {
    [self edit_editInputBarControlRequestFullScreenEdit:editInputBarControl];
}

#pragma mark FullScreenEditViewDelegate

- (void)fullScreenEditViewCollapse:(NCFullScreenEditView *)fullScreenEditView {
    [self edit_fullScreenEditViewCollapse:fullScreenEditView];
}

- (void)fullScreenEditViewCancel:(NCFullScreenEditView *)fullScreenEditView {
    [self edit_fullScreenEditViewCancel:fullScreenEditView];
}

- (void)fullScreenEditView:(NCFullScreenEditView *)fullScreenEditView didConfirmWithText:(NSString *)text {
    [self edit_fullScreenEditView:fullScreenEditView didConfirmWithText:text];
}

- (void)fullScreenEditView:(NCFullScreenEditView *)fullScreenEditView showUserSelector:(void (^)(NCChatUIUserInfo * _Nonnull))selectedBlock cancel:(void (^)(void))cancelBlock {
    [self edit_fullScreenEditView:fullScreenEditView showUserSelector:selectedBlock cancel:cancelBlock];
}

#pragma mark NCEditInputBarControlDataSource

- (nullable NCChatUIUserInfo *)editInputBarControl:(NCEditInputBarControl *)editInputBarControl
                            getUserInfo:(NSString *)userId {
    return [self edit_editInputBarControl:editInputBarControl getUserInfo:userId];
}


@end
