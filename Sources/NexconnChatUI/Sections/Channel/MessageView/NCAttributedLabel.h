//
//  NCAttributedLabel.h
//  iOS-IMKit
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NCBaseLabel.h"
/**
 *  NCAttributedDataSource
 */
@protocol NCAttributedDataSource <NSObject>
/**
 *  attributeDictionaryForTextType
 *
 *  @param textType textType
 *
 *  @return return NSDictionary
 */
- (NSDictionary *)attributeDictionaryForTextType:(NSTextCheckingTypes)textType;
/**
 *  highlightedAttributeDictionaryForTextType
 *
 *  @param textType textType
 *
 *  @return NSDictionary
 */
- (NSDictionary *)highlightedAttributeDictionaryForTextType:(NSTextCheckingType)textType;

@end

@protocol NCAttributedLabelDelegate;

/**
 *  Override UILabel @property to accept both NSString and NSAttributedString
 */
@protocol NCAttributedLabel <NSObject>

/**
 *  text
 */
@property (nonatomic, copy) id text;

@end

/**
 *  NCAttributedLabel
 */
@interface NCAttributedLabel : NCBaseLabel <NCAttributedDataSource, UIGestureRecognizerDelegate>
/**
 * Customize text font colors by setting attributeDataSource, attributeDictionary, or highlightedAttributeDictionary
 */
@property (nonatomic, strong) id<NCAttributedDataSource> attributeDataSource;
/**
 * Use attributedStrings to add tap events to specific characters, e.g. to modify text message content in the channel list
 *  -(void)willDisplayConversationTableCell:(NCMessageBaseCell *)cell atIndexPath:(NSIndexPath *)indexPath{
 *
 *   if ([cell isKindOfClass:[NCTextMessageCell class]]) {
 *      NCTextMessageCell *newCell = (NCTextMessageCell *)cell;
 *      if (newCell.textLabel.text.length>3) {
 *          NSTextCheckingResult *textCheckingResult = [NSTextCheckingResult linkCheckingResultWithRange:(NSMakeRange(0,
 *3)) URL:[NSURL URLWithString:@"http://www.baidu.com"]]; [newCell.textLabel.attributedStrings
 *addObject:textCheckingResult]; [newCell.textLabel setTextHighlighted:YES atPoint:CGPointMake(0, 3)];
 *       }
 *    }
 *}
 *
 */
@property (nonatomic, strong) NSMutableArray *attributedStrings;
/*!
 Tap callback
 */
@property (nonatomic, weak) id<NCAttributedLabelDelegate> delegate;
/**
 *  attributeDictionary
 */
@property (nonatomic, strong) NSDictionary *attributeDictionary;
/**
 *  highlightedAttributeDictionary
 */
@property (nonatomic, strong) NSDictionary *highlightedAttributeDictionary;
/**
 *  NSTextCheckingTypes format types
 */
@property (nonatomic, assign) NSTextCheckingTypes textCheckingTypes;
/**
 *  Current NSTextCheckingTypes format types
 */
@property (nonatomic, readonly, assign) NSTextCheckingType currentTextCheckingType;
/**
 *  Range marker for the "edited" suffix. Defaults to {NSNotFound, 0}.
 *  Set by the Edit category when the system-appended "(edited)" suffix needs coloring;
 *  the text generation phase renders it in gray based on this range
 */
@property (nonatomic, assign, readonly) NSRange nc_editedSuffixRange;
/**
 *  setTextdataDetectorEnabled
 *
 *  @param text                text
 *  @param dataDetectorEnabled dataDetectorEnabled
 */
- (void)setText:(NSString *)text dataDetectorEnabled:(BOOL)dataDetectorEnabled;

/**
 *  setTextHighlighted
 *
 *  @param highlighted highlighted
 *  @param point       point
 */
- (void)setTextHighlighted:(BOOL)highlighted atPoint:(CGPoint)point;

@end

/*!
 NCAttributedLabel tap callback
 */
@protocol NCAttributedLabelDelegate <NSObject>
@optional

/*!
 Callback for tapping a URL

 @param label Current label
 @param url   Tapped URL
 */
- (void)attributedLabel:(NCAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url;

/*!
 Callback for tapping a phone number

 @param label       Current label
 @param phoneNumber Tapped URL
 */
- (void)attributedLabel:(NCAttributedLabel *)label didSelectLinkWithPhoneNumber:(NSString *)phoneNumber;

/*!
 Callback for tapping the label

 @param label   Current label
 @param content Tapped content
 */
- (void)attributedLabel:(NCAttributedLabel *)label didTapLabel:(NSString *)content;

@end
