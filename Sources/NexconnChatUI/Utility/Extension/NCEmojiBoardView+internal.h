//
//  NCEmojiBoardView+internal.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#ifndef NCEmojiBoardView_internal_h
#define NCEmojiBoardView_internal_h

@interface NCEmojiBoardView ()
/// Updates the selected emoji page and total page count.
- (void)setCurrentIndex:(int)index withTotalPages:(int)totalPageNum;

@end

#endif /* NCEmojiBoardView_internal_h */
