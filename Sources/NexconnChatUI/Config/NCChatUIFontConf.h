//
//  NCChatUIFontConf.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <UIKit/UIKit.h>

/// ChatUI font configuration.
/// All internal fonts are constructed through this class instead of using UIFont directly, for centralized management.
@interface NCChatUIFontConf : NSObject

/// First level heading, default fontSize is 18.
@property (nonatomic, assign) CGFloat firstLevel;
/// Second level heading, default fontSize is 17 (text message, quote message content, channel list title).
@property (nonatomic, assign) CGFloat secondLevel;
/// Third level heading, default fontSize is 15.
@property (nonatomic, assign) CGFloat thirdLevel;
/// Fourth level heading, default fontSize is 14 (rich text message title, info tip message, quote message referenced content).
@property (nonatomic, assign) CGFloat fourthLevel;
/// Guide text, default fontSize is 13.
@property (nonatomic, assign) CGFloat guideLevel;
/// Annotation text, default fontSize is 12 (rich text message content).
@property (nonatomic, assign) CGFloat annotationLevel;
/// Auxiliary text, default fontSize is 10 (GIF message size).
@property (nonatomic, assign) CGFloat assistantLevel;

/// Font for firstLevel, default fontSize is 18.
- (UIFont *)fontOfFirstLevel;

/// Font for secondLevel, default fontSize is 17.
- (UIFont *)fontOfSecondLevel;

/// Font for thirdLevel, default fontSize is 15.
- (UIFont *)fontOfThirdLevel;

/// Font for fourthLevel, default fontSize is 14.
- (UIFont *)fontOfFourthLevel;

/// Font for guideLevel, default fontSize is 13.
- (UIFont *)fontOfGuideLevel;

/// Font for annotationLevel, default fontSize is 12.
- (UIFont *)fontOfAnnotationLevel;

/// Font for assistantLevel, default fontSize is 10.
- (UIFont *)fontOfAssistantLevel;

/// Custom font with a given size.
/// @param size The font size.
- (UIFont *)fontOfSize:(CGFloat)size;
@end
