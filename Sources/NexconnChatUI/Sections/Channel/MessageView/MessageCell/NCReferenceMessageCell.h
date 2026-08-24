//
//  NCReferenceMessageCell.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCAttributedLabel.h"
#import "NCReferencedContentView.h"
#import "NexconnChatUI.h"
NS_ASSUME_NONNULL_BEGIN

@interface NCReferenceMessageCell : NCMessageCell
/// Container for the referenced content
@property (nonatomic, strong) NCReferencedContentView *referencedContentView;

/// Label for the text content
@property (nonatomic, strong) NCAttributedLabel *contentLabel;

@end

NS_ASSUME_NONNULL_END
