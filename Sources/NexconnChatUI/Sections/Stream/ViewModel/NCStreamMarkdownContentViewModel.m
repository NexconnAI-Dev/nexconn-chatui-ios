//
//  NCStreamMarkdownContentViewModel.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCStreamMarkdownContentViewModel.h"
#import "NCChatUICommonDefine.h"
#import "NCChatUIConfig.h"
#import "NCMMMarkdown.h"
#import "NCMessageCellTool.h"
#import "NCStreamMarkdownContentView.h"
#import "NCStreamMessageCellViewModel+internal.h"

@interface NCStreamMarkdownContentViewModel ()

@end
@implementation NCStreamMarkdownContentViewModel
- (void)reloadContentHeight:(CGFloat)height {
    if (height == self.contentSize.height) {
        return;
    }
    // Update the web view height.
    self.contentSize = CGSizeMake([self contentMaxWidth], height);
    if ([self.delegate respondsToSelector:@selector(streamContentLayoutWillUpdate)]) {
        [self.delegate streamContentLayoutWillUpdate];
    }
}

#pragma mark-- NCStreamViewModelProtocol

- (CGSize)calculateContentSize {
    if (self.contentSize.height == 0) {
        return [self quickCoreText];
    }
    return self.contentSize;
}

- (void)streamContentDidUpdate:(nonnull NSString *)content {
    if ([self.content isEqualToString:content]) {
        return;
    }
    self.content = content;
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      NSString *htmlContent = [weakSelf coverHtmlContent];
      dispatch_async(dispatch_get_main_queue(), ^{
        weakSelf.htmlContent = htmlContent;
        if ([weakSelf.delegate respondsToSelector:@selector(streamContentLayoutWillUpdate)]) {
            [weakSelf.delegate streamContentLayoutWillUpdate];
        }
      });
    });
}

- (NCStreamContentView *)streamContentView {
    return [NCStreamMarkdownContentView new];
}

- (NSString *)javascriptStringForHeight {
    NSString *js = @"(function() { return Math.max(document.body.scrollHeight, "
                   @"document.body.offsetHeight); })();";
    return js;
}
#pragma mark-- private

- (CGSize)quickCoreText {
    CGFloat maxWidth = [self contentMaxWidth];
    NSString *content = self.content;
    if (!content) {
        return CGSizeMake(maxWidth, NCChatUIConfigCenter.ui.globalMessagePortraitSize.height);
    }
    CGSize maxSize = CGSizeMake(maxWidth, CGFLOAT_MAX); // Allow unbounded height.
    NSMutableAttributedString *attributedString =
        [[NSMutableAttributedString alloc] initWithString:self.content];
    // Calculate the required height with boundingRectWithSize:options:attributes:context:.
    CGRect textRect = [attributedString
        boundingRectWithSize:maxSize
                     options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                     context:nil];
    CGFloat height =
        MAX(ceilf(textRect.size.height), NCChatUIConfigCenter.ui.globalMessagePortraitSize.height);
    return CGSizeMake(maxWidth, height);
}

- (NSString *)coverHtmlContent {
    NSString *content = self.content;
    if (!content) {
        return nil;
    }
    NSString *str = [NCMMMarkdown HTMLStringWithMarkdown:content
                                              extensions:MMMarkdownExtensionsGitHubFlavored
                                                   error:NULL];
    NSString *cssFileName = @"markdown-white.css";
    if ([NCChatUIUtility isDarkMode]) {
        cssFileName = @"markdown-dark.css";
    }
    NSString *htmlBase = @"<!DOCTYPE html>"
                          "<html>"
                          "<head>"
                          "<link href='%@' rel='stylesheet' type='text/css'>"
                          "</head>"
                          "<body>"
                          "%@"
                          "<script>"
                          "   document.addEventListener('DOMContentLoaded', function() {"
                          "      var noSelectElements = document.querySelectorAll('.no-select');"
                          "      noSelectElements.forEach(function(element) {"
                          "          element.addEventListener('contextmenu', function(e) {"
                          "              e.preventDefault();"
                          "          }, false);"
                          "          element.addEventListener('selectstart', function(e) {"
                          "              e.preventDefault();"
                          "          }, false);"
                          "          element.addEventListener('touchstart', function(e) {"
                          "              this.touchStartTime = Date.now();"
                          "          }, false);"
                          "          element.addEventListener('touchend', function(e) {"
                          "              var touchEndTime = Date.now();"
                          "              if (touchEndTime - this.touchStartTime > 500) {"
                          "                  e.preventDefault();"
                          "              }"
                          "          }, false);"
                          "      });"
                          "  });"
                          "</script>"
                          "</body>"
                          "</html>";
    NSString *htmlContent = [NSString stringWithFormat:htmlBase, cssFileName, str];
    return htmlContent;
}

- (CGSize)coreText:(NSAttributedString *)attributedContent {
    CGFloat maxWidth = [self contentMaxWidth];
    CGSize maxSize = CGSizeMake(maxWidth, CGFLOAT_MAX); // Allow unbounded height.

    // Calculate the required height with boundingRectWithSize:options:attributes:context:.
    CGRect textRect = [attributedContent boundingRectWithSize:maxSize
                                                      options:NSStringDrawingUsesLineFragmentOrigin
                                                      context:nil];
    return CGSizeMake(maxWidth, ceilf(textRect.size.height));
}

@end
