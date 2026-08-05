//
//  NCTextView.h
//  NCExtensionKit
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NCTextView;

@protocol NCTextViewDelegate <NSObject>

@optional
- (void)nctextView:(NCTextView *)textView textDidChange:(NSString *)text;

@end

/// Text input view.
@interface NCTextView : UITextView

/*!
 Whether to disable the menu

  Defaults to NO.
 */
@property (nonatomic, assign) BOOL disableActionMenu;

@property (nonatomic, weak) id<NCTextViewDelegate> textChangeDelegate;

@end
