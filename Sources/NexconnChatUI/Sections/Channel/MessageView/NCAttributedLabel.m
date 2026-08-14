//
//  NCAttributedLabel.m
//  iOS-IMKit
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCAttributedLabel.h"
#import "NCChatUICommonDefine.h"
#import <CoreText/CoreText.h>
#import "NCChatUIUtility.h"
#import "NCMessageEditUtil.h"

@interface NCAttributedLabel ()

@property (nonatomic, copy) NSString *originalString;
@property (nonatomic, assign) BOOL dataDetectorEnabled;
@property (nonatomic, assign) BOOL needGenerateAttributed;
@property (nonatomic, assign) NSRange rangeOfTextHighlighted;
@property (nonatomic, strong) UITapGestureRecognizer *tapGestureRecognizer;
@property (nonatomic, assign) NSTextCheckingType currentTextCheckingType;
@property (nonatomic, assign) NSRange nc_editedSuffixRange;

@end

@implementation NCAttributedLabel

- (void)layoutSubviews {
    [self generateAttributed];
    [super layoutSubviews];
}

#pragma mark - Public Methods

- (void)setTextHighlighted:(BOOL)highlighted atPoint:(CGPoint)point {
    if (highlighted == NO) {
        self.rangeOfTextHighlighted = NSMakeRange(0, 0);
    } else {
        self.rangeOfTextHighlighted = [self textRangeAtPoint:point];
    }
    [self generateAttributedString];
}

#pragma mark - NCAttributedDataSource
- (NSDictionary *)attributeDictionaryForTextType:(NSTextCheckingTypes)textType {
    if (self.attributeDictionary) {
        NSNumber *textCheckingTypesNumber = [NSNumber numberWithUnsignedLongLong:textType];
        return [self.attributeDictionary objectForKey:textCheckingTypesNumber];
    }
    if (self.attributeDataSource) {
        return [self.attributeDataSource attributeDictionaryForTextType:textType];
    }
    UIColor * linkColor = NCDynamicColor(@"link_color");
    if (!linkColor) {
        linkColor = [NCChatUIUtility generateDynamicColor:[UIColor blueColor] darkColor:HEXCOLOR(0xFFBE6a)];
    }
    switch (textType) {
    case NSTextCheckingTypePhoneNumber: {
        _currentTextCheckingType = NSTextCheckingTypePhoneNumber;
        return @{
            NSForegroundColorAttributeName :linkColor
                ,
            NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle),
            NSUnderlineColorAttributeName : linkColor
        };
    }
    case NSTextCheckingTypeLink: {
        _currentTextCheckingType = NSTextCheckingTypeLink;
        return @{
            NSForegroundColorAttributeName :linkColor,
            NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle),
            NSUnderlineColorAttributeName :linkColor
        };
    }
    default:
        break;
    }
    return nil;
}

- (NSDictionary *)highlightedAttributeDictionaryForTextType:(NSTextCheckingType)textType {
    if (self.attributeDictionary) {
        NSNumber *textCheckingTypesNumber = [NSNumber numberWithUnsignedLongLong:textType];
        return [self.attributeDictionary objectForKey:textCheckingTypesNumber];
    }
    if (self.attributeDataSource) {
        return [self.attributeDataSource highlightedAttributeDictionaryForTextType:textType];
    }
    UIColor * linkColor = NCDynamicColor(@"link_color");
    if (!linkColor) {
        linkColor = [UIColor yellowColor];
    }
    switch (textType) {
    case NSTextCheckingTypePhoneNumber: {
        _currentTextCheckingType = NSTextCheckingTypePhoneNumber;
        if (NC_IOS_SYSTEM_VERSION_LESS_THAN(@"7.0")) {
            return @{
                NSForegroundColorAttributeName : linkColor,
                NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle)
            };
        } else {
            return @{
                NSForegroundColorAttributeName : linkColor,
                NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle),
                NSUnderlineColorAttributeName : linkColor
            };
        }
    }
    case NSTextCheckingTypeLink: {
        _currentTextCheckingType = NSTextCheckingTypeLink;
        if (NC_IOS_SYSTEM_VERSION_LESS_THAN(@"7.0")) {
            return @{
                NSForegroundColorAttributeName : linkColor,
                NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle)
            };
        } else {
            return @{
                NSForegroundColorAttributeName : linkColor,
                NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle),
                NSUnderlineColorAttributeName : linkColor
            };
        }
    }
    default:
        break;
    }
    return nil;
}

#pragma mark - UIGestureRecognizer
- (void)handleTap:(UITapGestureRecognizer *)gestureRecognizer {
    if ([gestureRecognizer state] != UIGestureRecognizerStateEnded) {
        return;
    }
    NSTextCheckingResult *result = [self linkAtPoint:[gestureRecognizer locationInView:self]];
    if (!result) {
        if (self.delegate != nil) {
            if ([self.delegate respondsToSelector:@selector(attributedLabel:didTapLabel:)]) {
                [self.delegate attributedLabel:self didTapLabel:self.originalString];
            }
        }
        return;
    }

    switch (result.resultType) {
    case NSTextCheckingTypeLink:
        if ([self.delegate respondsToSelector:@selector(attributedLabel:didSelectLinkWithURL:)]) {
            [self.delegate attributedLabel:self didSelectLinkWithURL:result.URL];
        }
        break;
    case NSTextCheckingTypePhoneNumber:
        if ([self.delegate respondsToSelector:@selector(attributedLabel:didSelectLinkWithPhoneNumber:)]) {
            [self.delegate attributedLabel:self didSelectLinkWithPhoneNumber:result.phoneNumber];
        }
        break;
    default:
        break;
    }
}

#pragma mark - Private Methods
- (NSRange)textRangeAtPoint:(CGPoint)point {
    if (self.dataDetectorEnabled == NO) {
        return NSMakeRange(0, 0);
    }
    CFIndex charIndex = [self characterIndexAtPoint:point];
    for (NSTextCheckingResult *textCheckingResult in self.attributedStrings) {
        for (int i = 0; i < textCheckingResult.numberOfRanges; i++) {
            NSRange range = [textCheckingResult rangeAtIndex:i];
            if (NSLocationInRange(charIndex, range)) {
                return range;
            }
        }
    }
    return NSMakeRange(0, 0);
}

- (NSTextCheckingResult *)linkAtCharacterIndex:(CFIndex)idx {
    for (NSTextCheckingResult *result in self.attributedStrings) {
        NSRange range = result.range;
        if ((CFIndex)range.location <= idx && idx <= (CFIndex)(range.location + range.length)) {
            return result;
        }
    }

    return nil;
}

- (void)generateAttributed {
    if (self.dataDetectorEnabled && self.needGenerateAttributed) {
        self.needGenerateAttributed = NO;
        [self generateAttributedStrings];
    }
}

- (void)generateAttributedStrings {
    if (!self.originalString) {
        return;
    }
    NSError *error = nil;
    NSDataDetector *dataDetector = [[NSDataDetector alloc] initWithTypes:self.textCheckingTypes error:&error];
    if (error != nil) {
        NCLogD(@"data detector error %@", error.localizedDescription);
        [super setText:self.originalString];
        return;
    }
    // Collect all matches before generating attributes once, including when there are no matches, so suffix styles are still applied.
    if (self.originalString.length < 500) {
        NSMutableArray *allResults = [NSMutableArray array];
        [dataDetector enumerateMatchesInString:self.originalString
                                       options:kNilOptions
                                         range:NSMakeRange(0, self.originalString.length)
                                    usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
                                        if (result) {
                                            [allResults addObject:result];
                                        }
                                    }];
        self.attributedStrings = allResults;
        [self generateAttributedString];
    } else {
        // 后台检测。捕获当前文本快照，检测和回落都以快照为准；回到主线程后校验
        // label 的 originalString 是否仍是同一份文本，若因 cell 复用已切换到别的消息，
        // 则丢弃这次结果，避免把旧消息的匹配 range 错套到新消息上（下划线错位）。
        NSString *capturedString = self.originalString;
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            NSMutableArray *allResults = [NSMutableArray array];
            [dataDetector enumerateMatchesInString:capturedString
                                           options:kNilOptions
                                             range:NSMakeRange(0, capturedString.length)
                                        usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
                                            if (result) {
                                                [allResults addObject:result];
                                            }
                                        }];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (![self.originalString isEqualToString:capturedString]) {
                    return;
                }
                self.attributedStrings = allResults;
                [self generateAttributedString];
            });
        });
    }
}

- (void)updateTextCheckingResult:(NSTextCheckingResult *)result{
    self.currentTextCheckingType = result.resultType;
    [self.attributedStrings addObject:result];
    [self generateAttributedString];
}

- (void)generateAttributedString {
    if (!self.originalString) {
        return;
    }
    NSMutableAttributedString *attributedString =
        [[NSMutableAttributedString alloc] initWithString:self.originalString];
    for (NSTextCheckingResult *textCheckingResult in self.attributedStrings) {
        for (int i = 0; i < textCheckingResult.numberOfRanges; i++) {
            NSRange range = [textCheckingResult rangeAtIndex:i];
            NSDictionary *attributeDictionary = [self attributeDictionaryForTextType:textCheckingResult.resultType];

            if (NSEqualRanges(range, self.rangeOfTextHighlighted))
                attributeDictionary = [self highlightedAttributeDictionaryForTextType:textCheckingResult.resultType];
            if (attributeDictionary) {
                if (self.originalString.length >= (range.location + range.length)) {
                    NSAttributedString *subString =
                        [[NSAttributedString alloc] initWithString:[self.originalString substringWithRange:range]
                                                        attributes:attributeDictionary];
                    [attributedString replaceCharactersInRange:range withAttributedString:subString];
                }
            }
        }
    }
    // Apply the edited-suffix style only to the externally supplied range so matching user-entered text is not misclassified.
    @try {
        if (self.nc_editedSuffixRange.location != NSNotFound &&
            NSMaxRange(self.nc_editedSuffixRange) <= self.originalString.length) {
            NSString *editedSuffix = [NCMessageEditUtil editedSuffix];
            NSString *actual = [self.originalString substringWithRange:self.nc_editedSuffixRange];
            if ([actual isEqualToString:editedSuffix]) {
                UIColor *editedColor = [NCMessageEditUtil editedTextColor];
                [attributedString addAttribute:NSForegroundColorAttributeName value:editedColor range:self.nc_editedSuffixRange];
            }
        }
    } @catch (__unused NSException *exception) {}
    self.attributedText = attributedString;
}

- (NSUInteger)characterIndexAtPoint:(CGPoint)p {
    if (!CGRectContainsPoint(self.bounds, p)) {
        return NSNotFound;
    }
    p = CGPointMake(p.x - self.bounds.origin.x, self.bounds.size.height - p.y);

    NSMutableAttributedString *optimizedAttributedText = [self.attributedText mutableCopy];
    /**
     Core Text's suggested frame height does not include the empty final line represented by a single trailing newline.
     Append another newline so the suggested height and generated frame include that final line during hit testing.
     */
    if (optimizedAttributedText.string.length > 0 && [[optimizedAttributedText.string substringFromIndex:optimizedAttributedText.string.length - 1]
            isEqualToString:@"\n"]) {
        [optimizedAttributedText appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
    }
    // use label's font and lineBreakMode properties in case the attributedText does not contain such attributes
    [optimizedAttributedText
        enumerateAttributesInRange:NSMakeRange(0, [optimizedAttributedText length])
                           options:0
                        usingBlock:^(NSDictionary *attrs, NSRange range, BOOL *stop) {
                            if (!attrs[(NSString *)kCTFontAttributeName]) {
                                [optimizedAttributedText addAttribute:(NSString *)kCTFontAttributeName
                                                                value:self.font
                                                                range:NSMakeRange(0, [optimizedAttributedText length])];
                            }

                            if (!attrs[(NSString *)kCTParagraphStyleAttributeName]) {
                                NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
                                [paragraphStyle setLineBreakMode:self.lineBreakMode];
                                [optimizedAttributedText addAttribute:(NSString *)kCTParagraphStyleAttributeName
                                                                value:paragraphStyle
                                                                range:range];
                            }
                        }];

    // modify kCTLineBreakByTruncatingTail lineBreakMode to NSLineBreakByWordWrapping
    [optimizedAttributedText
        enumerateAttribute:(NSString *)kCTParagraphStyleAttributeName
                   inRange:NSMakeRange(0, [optimizedAttributedText length])
                   options:0
                usingBlock:^(id value, NSRange range, BOOL *stop) {
                    NSMutableParagraphStyle *paragraphStyle = [value mutableCopy];
                    if (paragraphStyle.lineBreakMode == NSLineBreakByTruncatingTail) {
                        [paragraphStyle setLineBreakMode:NSLineBreakByWordWrapping];
                    }
                    [paragraphStyle setAlignment:self.textAlignment];
                    [optimizedAttributedText removeAttribute:(NSString *)kCTParagraphStyleAttributeName range:range];
                    [optimizedAttributedText addAttribute:(NSString *)kCTParagraphStyleAttributeName
                                                    value:paragraphStyle
                                                    range:range];
                }];

    CTFramesetterRef framesetter =
        CTFramesetterCreateWithAttributedString((CFAttributedStringRef)optimizedAttributedText);

    CGRect textRect = UIEdgeInsetsInsetRect(self.bounds, UIEdgeInsetsZero);
    CGSize textSize =
        CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, [optimizedAttributedText length]),
                                                     NULL, CGSizeMake(self.bounds.size.width, CGFLOAT_MAX), NULL);
    textSize = CGSizeMake(ceil(textSize.width), ceil(textSize.height));
    textRect.origin.y += floor((self.bounds.size.height - textSize.height) / 2.0f);
    textRect.size.height = textSize.height;
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, textRect);
    CTFrameRef frame =
        CTFramesetterCreateFrame(framesetter, CFRangeMake(0, [optimizedAttributedText length]), path, NULL);
    if (frame == NULL) {
        if (framesetter != NULL) {
            CFRelease(framesetter);
        }
        if (path != NULL) {
            CFRelease(path);
        }
        return NSNotFound;
    }

    CFArrayRef lines = CTFrameGetLines(frame);
    NSUInteger numberOfLines = CFArrayGetCount(lines);
    if (numberOfLines == 0) {
        if (framesetter != NULL) {
            CFRelease(framesetter);
        }
        if (frame != NULL) {
            CFRelease(frame);
        }
        if (path != NULL) {
            CFRelease(path);
        }
        return NSNotFound;
    }

    CGPoint lineOrigins[numberOfLines];
    CTFrameGetLineOrigins(frame, CFRangeMake(0, numberOfLines), lineOrigins);

    NSUInteger lineIndex;
    for (lineIndex = 0; lineIndex < numberOfLines; lineIndex++) {
        if (lineIndex == numberOfLines - 1) {
            break;
        } else {
            CGPoint lineOrigin = lineOrigins[lineIndex];
            if (lineOrigin.y <= p.y) {
                break;
            }
        }
    }

    if (lineIndex >= numberOfLines) {
        if (framesetter != NULL) {
            CFRelease(framesetter);
        }
        if (frame != NULL) {
            CFRelease(frame);
        }
        if (path != NULL) {
            CFRelease(path);
        }
        return NSNotFound;
    }

    CGPoint lineOrigin = lineOrigins[lineIndex];
    CTLineRef line = CFArrayGetValueAtIndex(lines, lineIndex);
    // Convert CT coordinates to line-relative coordinates
    CGPoint relativePoint = CGPointMake(p.x - lineOrigin.x, p.y - lineOrigin.y);
    CFIndex idx = CTLineGetStringIndexForPosition(line, relativePoint);

    if (framesetter != NULL) {
        CFRelease(framesetter);
    }
    if (frame != NULL) {
        CFRelease(frame);
    }
    if (path != NULL) {
        CFRelease(path);
    }
    return idx;
}


- (NSTextCheckingResult *)linkAtPoint:(CGPoint)p {
    CFIndex idx = [self characterIndexAtPoint:p];
    return [self linkAtCharacterIndex:idx];
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

#pragma mark - Getters and Setters
- (void)setText:(NSString *)text {
    [self setText:text dataDetectorEnabled:YES];
}

- (void)setText:(NSString *)text dataDetectorEnabled:(BOOL)dataDetectorEnabled {
    self.dataDetectorEnabled = dataDetectorEnabled;
    if (self.dataDetectorEnabled == NO) {
        [super setText:text];
        return;
    }
    self.originalString = text;
    // Generate detector-backed attributes immediately when the text changes.
    [super setText:text];
    self.needGenerateAttributed = YES;
    [self generateAttributed];

    self.tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [self.tapGestureRecognizer setDelegate:self];
    [self addGestureRecognizer:self.tapGestureRecognizer];
}

- (void)setAttributeDictionary:(NSDictionary *)attributeDictionary {
    _attributeDictionary = attributeDictionary;
    self.needGenerateAttributed = YES;
}

- (void)setHighlightedAttributeDictionary:(NSDictionary *)highlightedAttributeDictionary {
    _highlightedAttributeDictionary = highlightedAttributeDictionary;
    self.needGenerateAttributed = YES;
}

- (void)setAttributeDataSource:(id<NCAttributedDataSource>)attributeDataSource {
    _attributeDataSource = attributeDataSource;
    self.needGenerateAttributed = YES;
}

- (NSString *)text {
    [self generateAttributed];
    return [super text];
}

- (NSAttributedString *)attributedText {
    [self generateAttributed];
    return [super attributedText];
}

- (NSTextCheckingTypes)textCheckingTypes {
    if (_textCheckingTypes) {
        return _textCheckingTypes;
    }
    return NSTextCheckingTypeLink | NSTextCheckingTypePhoneNumber;
}
@end
