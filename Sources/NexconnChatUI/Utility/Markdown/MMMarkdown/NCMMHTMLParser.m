//
//  MMHTMLParser.m
//  MMMarkdown
//
//  Adapted from MMMarkdown: https://github.com/mdiep/MMMarkdown
//  Original copyright (c) 2012-2013 Matt Diephouse.
//  Modified by Nexconn in 2026.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

#import "NCMMHTMLParser.h"

#import "NCMMElement.h"
#import "NCMMScanner.h"

@implementation NCMMHTMLParser

#pragma mark - Public Methods

- (NCMMElement *)parseBlockTagWithScanner:(NCMMScanner *)scanner {
    [scanner beginTransaction];
    NCMMElement *element = [self _parseStrictBlockTagWithScanner:scanner];
    [scanner commitTransaction:element != nil];
    if (element)
        return element;

    return [self _parseLenientBlockTagWithScanner:scanner];
}

- (NCMMElement *)parseCommentWithScanner:(NCMMScanner *)scanner {
    if (![scanner matchString:@"<!--"])
        return nil;

    NSCharacterSet *setToSkip =
        [[NSCharacterSet characterSetWithCharactersInString:@"-"] invertedSet];
    while (!scanner.atEndOfString) {
        if (scanner.atEndOfLine)
            [scanner advanceToNextLine];
        else {
            [scanner skipCharactersFromSet:setToSkip];
            if ([scanner matchString:@"-->"]) {
                NCMMElement *element = [NCMMElement new];
                element.type = MMElementTypeHTML;
                element.range =
                    NSMakeRange(scanner.startLocation, scanner.location - scanner.startLocation);

                return element;
            }
            [scanner advance];
        }
    }

    return nil;
}

- (NCMMElement *)parseInlineTagWithScanner:(NCMMScanner *)scanner {
    if (scanner.nextCharacter != '<')
        return nil;
    [scanner advance];

    if (scanner.nextCharacter == '/')
        [scanner advance];

    NSRange tagNameRange = [self _parseNameWithScanner:scanner];
    if (tagNameRange.length == 0)
        return nil;

    [self _parseAttributesWithScanner:scanner];
    [scanner skipWhitespace];

    if (scanner.nextCharacter == '/')
        [scanner advance];

    if (scanner.nextCharacter != '>')
        return nil;
    [scanner advance];

    NCMMElement *element = [NCMMElement new];
    element.type = MMElementTypeHTML;
    element.range = NSMakeRange(scanner.startLocation, scanner.location - scanner.startLocation);
    element.stringValue = [scanner.string substringWithRange:tagNameRange];

    return element;
}

#pragma mark - Private Methods

- (NCMMElement *)_parseStrictBlockTagWithScanner:(NCMMScanner *)scanner {
    // which starts with a '<'
    if (scanner.nextCharacter != '<')
        return nil;
    [scanner advance];

    NSSet *htmlBlockTags =
        [NSSet setWithObjects:@"p", @"div", @"h1", @"h2", @"h3", @"h4", @"h5", @"h6", @"blockquote",
                              @"pre", @"table", @"dl", @"ol", @"ul", @"script", @"noscript",
                              @"form", @"fieldset", @"iframe", @"math", @"ins", @"del", nil];
    NSString *tagName = [scanner nextWord];
    if (![htmlBlockTags containsObject:tagName])
        return nil;
    scanner.location += tagName.length;

    [self _parseAttributesWithScanner:scanner];
    [scanner skipWhitespace];

    if (scanner.nextCharacter != '>')
        return nil;
    [scanner advance];

    NSCharacterSet *boringChars =
        [[NSCharacterSet characterSetWithCharactersInString:@"<"] invertedSet];
    while (1) {
        if (scanner.atEndOfString)
            return nil;

        [scanner skipCharactersFromSet:boringChars];
        if (scanner.atEndOfLine) {
            [scanner advanceToNextLine];
            continue;
        }

        [scanner beginTransaction];
        if ([self _parseEndTag:tagName withScanner:scanner]) {
            [scanner commitTransaction:YES];
            break;
        }
        [scanner commitTransaction:NO];

        NCMMElement *element;

        [scanner beginTransaction];
        element = [self _parseStrictBlockTagWithScanner:scanner];
        [scanner commitTransaction:element != nil];
        if (element)
            continue;

        [scanner beginTransaction];
        element = [self parseCommentWithScanner:scanner];
        [scanner commitTransaction:element != nil];
        if (element)
            continue;

        [scanner beginTransaction];
        element = [self parseInlineTagWithScanner:scanner];
        [scanner commitTransaction:element != nil];
        if (element)
            continue;

        return nil;
    }

    NCMMElement *element = [NCMMElement new];
    element.type = MMElementTypeHTML;
    element.range = NSMakeRange(scanner.startLocation, scanner.location - scanner.startLocation);

    return element;
}

- (BOOL)_parseEndTag:(NSString *)tagName withScanner:(NCMMScanner *)scanner {
    if (scanner.nextCharacter != '<')
        return NO;
    [scanner advance];

    if (scanner.nextCharacter != '/')
        return NO;
    [scanner advance];

    [scanner skipWhitespace];
    if (![scanner matchString:tagName])
        return NO;
    [scanner skipWhitespace];

    if (scanner.nextCharacter != '>')
        return NO;
    [scanner advance];

    return YES;
}

- (NCMMElement *)_parseLenientBlockTagWithScanner:(NCMMScanner *)scanner {
    // which starts with a '<'
    if (scanner.nextCharacter != '<')
        return nil;
    [scanner advance];

    NSSet *htmlBlockTags =
        [NSSet setWithObjects:@"p", @"div", @"h1", @"h2", @"h3", @"h4", @"h5", @"h6", @"blockquote",
                              @"pre", @"table", @"dl", @"ol", @"ul", @"script", @"noscript",
                              @"form", @"fieldset", @"iframe", @"math", @"ins", @"del", nil];
    NSString *tagName = scanner.nextWord;
    if (![htmlBlockTags containsObject:tagName])
        return nil;
    scanner.location += tagName.length;

    // Find a '>'
    while (scanner.nextCharacter != '>') {
        if (scanner.atEndOfString)
            return nil;
        else if (scanner.atEndOfLine)
            [scanner advanceToNextLine];
        else
            [scanner advance];
    }

    // Skip lines until we come across a blank line
    while (!scanner.atEndOfLine) {
        [scanner advanceToNextLine];
    }

    NCMMElement *element = [NCMMElement new];
    element.type = MMElementTypeHTML;
    element.range = NSMakeRange(scanner.startLocation, scanner.location - scanner.startLocation);

    return element;
}

- (NSRange)_parseNameWithScanner:(NCMMScanner *)scanner {
    NSMutableCharacterSet *nameSet = [NSMutableCharacterSet alphanumericCharacterSet];
    [nameSet addCharactersInString:@":-"];

    NSRange result = NSMakeRange(scanner.location, 0);
    result.length = [scanner skipCharactersFromSet:nameSet];

    return result;
}

- (BOOL)_parseStringWithScanner:(NCMMScanner *)scanner {
    unichar nextChar = [scanner nextCharacter];
    if (nextChar != '"' && nextChar != '\'')
        return NO;
    [scanner advance];

    while (scanner.nextCharacter != nextChar) {
        if (scanner.atEndOfString)
            return NO;
        else if (scanner.atEndOfLine)
            [scanner advanceToNextLine];
        else
            [scanner advance];
    }

    // skip over the closing quotation mark
    [scanner advance];

    return YES;
}

- (BOOL)_parseAttributeValueWithScanner:(NCMMScanner *)scanner {
    NSMutableCharacterSet *characters =
        [[NSCharacterSet.whitespaceCharacterSet invertedSet] mutableCopy];
    [characters removeCharactersInString:@"\"'=><`"];

    return [scanner skipCharactersFromSet:characters] > 0;
}

- (void)_parseAttributesWithScanner:(NCMMScanner *)scanner {
    while ([scanner skipWhitespaceAndNewlines] > 0) {
        NSRange range;

        range = [self _parseNameWithScanner:scanner];
        if (range.length == 0)
            break;

        [scanner beginTransaction];
        [scanner skipWhitespace];

        if (scanner.nextCharacter == '=') {
            [scanner commitTransaction:YES];
            [scanner advance];

            [scanner skipWhitespace];

            if ([self _parseStringWithScanner:scanner])
                ;
            else if ([self _parseAttributeValueWithScanner:scanner])
                ;
            else
                break;
        } else {
            [scanner commitTransaction:NO];
        }
    }
}

@end
