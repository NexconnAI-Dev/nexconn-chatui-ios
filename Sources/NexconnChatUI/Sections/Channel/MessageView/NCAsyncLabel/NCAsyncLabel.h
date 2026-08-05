//
//  NCAsyncLabel.h
//  CartoonTest
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@protocol NCAsyncLabelDelegate;

@interface NCAsyncLabel : UIView
@property (nonatomic, copy) NSString *text;
@property (nonatomic, strong) UIFont *font;
@property (nonatomic, weak) id<NCAsyncLabelDelegate> delegate;

/**
 *  attributeDictionary
 */
@property (nonatomic, strong) NSDictionary *attributeDictionary;
/**
 *  highlightedAttributeDictionary
 */
@property (nonatomic, strong) NSDictionary *highlightedAttributeDictionary;
 
- (void)clean;
@end


/*!
 NCAttributedLabel tap callback.
 */
@protocol NCAsyncLabelDelegate <NSObject>
@optional


- (NSDictionary *)textAttributesInfo;


/// Whether to detect special text such as phone numbers and links.
- (BOOL)shouldDetectText;
/*!
 Callback for tapping a URL.

 - Parameter label: The current label.
 - Parameter url:   The tapped URL.
 */
- (void)asyncLabel:(NCAsyncLabel *)label didSelectLinkWithURL:(NSURL *)url;

/*!
 Callback for tapping a phone number.

 - Parameter label:       The current label.
 - Parameter phoneNumber: The tapped phone number.
 */
- (void)asyncLabel:(NCAsyncLabel *)label didSelectLinkWithPhoneNumber:(NSString *)phoneNumber;

/*!
 Callback for tapping the label.

 - Parameter label:   The current label.
 - Parameter content: The tapped content.
 */
- (void)didTapAsyncLabel:(NCAsyncLabel *)label;
@end
NS_ASSUME_NONNULL_END
