//
//  NCStreamMarkdownContentView.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <WebKit/WebKit.h>

#import "NCChatUICommonDefine.h"
#import "NCChatUIConfig.h"
#import "NCChatUIUtility.h"
#import "NCStreamMarkdownContentView.h"
#import "NCStreamMarkdownContentViewModel.h"

extern NSString *const NCConversationViewScrollNotification;

@interface WeakScriptMessageHandler : NSObject <WKScriptMessageHandler>
@property (nonatomic, weak) id<WKScriptMessageHandler> delegate;
- (instancetype)initWithDelegate:(id<WKScriptMessageHandler>)delegate;
@end

@implementation WeakScriptMessageHandler
- (instancetype)initWithDelegate:(id<WKScriptMessageHandler>)delegate {
    self = [super init];
    if (self) {
        _delegate = delegate;
    }
    return self;
}

- (void)userContentController:(WKUserContentController *)userContentController
      didReceiveScriptMessage:(WKScriptMessage *)message {
    [self.delegate userContentController:userContentController didReceiveScriptMessage:message];
}
@end

@interface NCStreamMarkdownContentView () <WKNavigationDelegate, WKScriptMessageHandler,
                                           WKUIDelegate>

@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, weak) NCStreamMarkdownContentViewModel *viewModel;

@end

@implementation NCStreamMarkdownContentView

- (instancetype)init {
    self = [super init];
    if (self) {
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.webView.frame = self.bounds;
}

- (void)configViewModel:(NCStreamContentViewModel *)contentViewModel {
    [super configViewModel:contentViewModel];
    if (![contentViewModel isKindOfClass:NCStreamMarkdownContentViewModel.class]) {
        return;
    }
    NCStreamMarkdownContentViewModel *viewModel =
        (NCStreamMarkdownContentViewModel *)contentViewModel;
    self.viewModel = viewModel;
    [self loadWebView];
}

- (void)cleanView {
    [super cleanView];
    [self.webView removeFromSuperview];
    self.webView = nil;
}

- (void)dealloc {
    NCLogD(@"dealloc");
    [self.webView.configuration.userContentController
        removeScriptMessageHandlerForName:@"longpress"];
    [self.webView.configuration.userContentController
        removeScriptMessageHandlerForName:@"heightChanged"];
    [self.webView.configuration.userContentController removeAllUserScripts];

    self.webView.navigationDelegate = nil;
    self.webView.UIDelegate = nil;
    [self.webView stopLoading];
    self.webView = nil;
}

#pragma mark-- private

- (void)loadWebView {
    if (!self.webView) {
        WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
        [config.userContentController
            addScriptMessageHandler:[[WeakScriptMessageHandler alloc] initWithDelegate:self]
                               name:@"heightChanged"];

        // Set the viewport before loading; repeated loadHTMLString: calls can otherwise produce an
        // incorrect web view size.
        NSString *viewportScript =
            @"var meta = document.createElement('meta'); meta.setAttribute('name', 'viewport'); "
            @"meta.setAttribute('content', 'width=device-width, initial-scale=1.0, "
            @"maximum-scale=1.0, user-scalable=no'); "
            @"document.getElementsByTagName('head')[0].appendChild(meta);";
        WKUserScript *script =
            [[WKUserScript alloc] initWithSource:viewportScript
                                   injectionTime:WKUserScriptInjectionTimeAtDocumentEnd
                                forMainFrameOnly:YES];
        [config.userContentController addUserScript:script];

        self.webView = [[WKWebView alloc] initWithFrame:self.bounds configuration:config];
        self.webView.backgroundColor = [UIColor clearColor];
        self.webView.autoresizingMask =
            UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.webView setOpaque:NO];
        self.webView.scrollView.scrollEnabled = NO;
        self.webView.navigationDelegate = self;
        self.webView.UIDelegate = self;
        [self addSubview:self.webView];
    }
    NSString *bundlePath = [NCChatUIUtility bundlePathWithName:@"NCChatUI"];

    [self.webView loadHTMLString:self.viewModel.htmlContent
                         baseURL:[NSURL fileURLWithPath:bundlePath]];
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView
    decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction
                    decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    // Navigation outside the main frame generally represents a link tap.
    if (navigationAction.navigationType == WKNavigationTypeLinkActivated) {
        NSURL *url = navigationAction.request.URL;
        if ([self.delegate respondsToSelector:@selector(streamContentViewDidClickUrl:)]) {
            [self.delegate streamContentViewDidClickUrl:url.absoluteString];
        }
        // Allow other links to load in the WKWebView.
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    // Allow the default behavior for other navigation actions.
    decisionHandler(WKNavigationActionPolicyAllow);
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    NSString *js = [self.viewModel javascriptStringForHeight];
    [webView evaluateJavaScript:js
              completionHandler:^(id _Nullable result, NSError *_Nullable error) {
                // Handle the result the same way as above.
                CGFloat height = [result floatValue];
                [self.viewModel reloadContentHeight:height];
              }];
}

#pragma mark-- WKScriptMessageHandler

- (void)userContentController:(WKUserContentController *)userContentController
      didReceiveScriptMessage:(WKScriptMessage *)message {
    if ([message.name isEqualToString:@"heightChanged"]) {
        NSNumber *height = message.body;
        if (height.floatValue > 0) {
            [self.viewModel reloadContentHeight:height.floatValue];
        }
    }
}
@end
