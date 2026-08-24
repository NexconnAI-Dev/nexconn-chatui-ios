//
//  NCSightModel.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCSightModel.h"
#import "NCMessageModel.h"
#import "NCSightPlayerController+ChatUI.h"

@interface NCSightModel ()
@property (nonatomic, strong) NCSightPlayerController *playerController;
@end

@implementation NCSightModel
- (instancetype)initWithMessageModel:(NCMessageModel *)messageModel {
    self = [super init];
    if (self) {
        self.messageModel = messageModel;
        NCShortVideoMessage *sightMessage = (NCShortVideoMessage *)messageModel.content;
        self.playerController = [[NCSightPlayerController alloc] init];
        self.playerController.preferredDownloadFileName = sightMessage.name;
        [self.playerController setFirstFrameThumbnail:sightMessage.thumbnailImage];
        // Prefer a valid localPath so locally inserted sight messages can use their local media.
        if (sightMessage.localPath &&
            [[NSFileManager defaultManager] fileExistsAtPath:sightMessage.localPath]) {
            self.playerController.sightURL =
                [[NSURL alloc] initFileURLWithPath:sightMessage.localPath];
            [self.playerController setFirstFrameThumbnail:self.playerController.firstFrameImage];
        } else if (sightMessage.remoteUrl.length > 0) {
            self.playerController.sightURL = [NSURL URLWithString:sightMessage.remoteUrl];
        } else {
            NCLogD(@"LocalPath and sightUrl are nil");
        }
    }
    return self;
}
@end
