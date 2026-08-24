//
//  NCTextPreviewView+Edit.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCTextPreviewView.h"

NS_ASSUME_NONNULL_BEGIN

@interface NCTextPreviewView (Edit)

+ (void)edit_showText:(NSString *)text
             clientId:(long)clientId
               edited:(BOOL)edited
             delegate:(id<NCTextPreviewViewDelegate>)delegate;

- (NSString *)edit_copyText;

@end

NS_ASSUME_NONNULL_END
