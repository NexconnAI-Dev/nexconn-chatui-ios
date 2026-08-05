//
//  NCSightViewController+ChatUI.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#ifndef NCSightViewController_ChatUI_h
#define NCSightViewController_ChatUI_h

#if __has_include("NCSightViewController.h")
#import "NCSightViewController.h"
#else
@interface NCSightViewController : NCBaseViewController
@property (nonatomic, weak, nullable) id delegate;
@end
#endif

#endif /* NCSightViewController_ChatUI_h */
