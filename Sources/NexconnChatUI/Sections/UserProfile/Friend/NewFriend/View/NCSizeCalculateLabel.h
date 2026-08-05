//
//  NCSizeCalculateLabel.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@protocol NCSizeCalculateLabelDelegate <NSObject>

- (void)labelLayoutFinished:(UILabel *)label
                 natureSize:(CGSize)natureSize;

@end
@interface NCSizeCalculateLabel : UILabel
@property (nonatomic, weak) id<NCSizeCalculateLabelDelegate> delegate;
@end

NS_ASSUME_NONNULL_END
