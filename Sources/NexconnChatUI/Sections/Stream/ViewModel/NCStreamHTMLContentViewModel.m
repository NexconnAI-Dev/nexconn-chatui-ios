//
//  NCStreamHTMLContentViewModel.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCStreamHTMLContentViewModel.h"
#import "NCChatUICommonDefine.h"
#import "NCChatUIConfig.h"

@interface NCStreamMarkdownContentViewModel()
- (NSString *)coverHtmlContent;

@end

@implementation NCStreamHTMLContentViewModel

- (NSString *)coverHtmlContent {
    return self.content;
}

- (NSString *)javascriptStringForHeight {
    NSString *js = @"(function() { "
                   "var body = document.body;"
                   "var html = document.documentElement;"
                   "return Math.max("
                   "body.scrollHeight, body.offsetHeight,"
                   "html.offsetHeight"
                   ");"
                   "})();";
    return js;
}
@end
