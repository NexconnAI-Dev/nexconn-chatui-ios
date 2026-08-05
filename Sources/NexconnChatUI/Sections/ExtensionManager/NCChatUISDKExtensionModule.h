//
//  NCChatUISDKExtensionModule.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCChatUIExtensionMessageCellInfo.h"
#import "NCChatUIExtensionModule.h"
#import "NCMessageModel.h"
#import <Foundation/Foundation.h>

/// Extension module protocol for NexconnChatUI.
@protocol NCChatUISDKExtensionModule <NCChatUIExtensionModule>

@optional

#pragma mark - Cell
/// Get the cell info list for the channel page.
///
/// @param channelType  Channel type.
/// @param channelId          Channel ID.
/// @return A list of cell info objects.
///
/// When entering the channel page, the SDK needs the extension module's MessageCell class and messageType.
- (NSArray<NCChatUIExtensionMessageCellInfo *> *)getMessageCellInfoList:(NCChannelType)channelType
                                                         channelId:(NSString *)channelId;

/// Called when a MessageCell is tapped.
///
/// @param messageModel   The data model of the tapped MessageCell.
- (void)didTapMessageCell:(NCMessageModel *)messageModel;

/// Called when the channel page triggers viewWillAppear. You can modify the extensionView frame and content.
///
/// @param channelType Channel type.
/// @param channelId         Channel ID.
/// @param extensionView    The extension view.
- (void)extensionViewWillAppear:(NCChannelType)channelType
                       channelId:(NSString *)channelId
                  extensionView:(UIView *)extensionView;

/// Called when the channel page triggers viewWillDisappear. If your extension module modifies the channel page's
/// extensionView, stop modifications after receiving this callback.
///
/// @param channelType Channel type.
/// @param channelId         Channel ID.
- (void)extensionViewWillDisappear:(NCChannelType)channelType channelId:(NSString *)channelId;

/// Called when the channel page is about to be destroyed (triggered by tapping the back button).
///
/// @param channelType Channel type.
/// @param channelId Channel ID.
- (void)containerViewWillDestroy:(NCChannelType)channelType channelId:(NSString *)channelId;

@end
