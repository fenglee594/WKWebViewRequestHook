//
//  ViewController.m
//  WKwebviewRequestHook
//
//  Created by 李峰 on 2019/7/9.
//  Copyright © 2019 feng. All rights reserved.
//

#import "ViewController.h"
#import <WebKit/WebKit.h>
#import <objc/runtime.h>
#import "CustomURLProtocol.h"
#import "WebViewPostHandler.h"

@interface ViewController ()
@property (nonatomic, strong) WKWebView *webview;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (_openHook) {
        [self registerClass];
    } else {
        [self unregisterClass];
    }
    
    WKWebViewConfiguration *config = [WKWebViewConfiguration new];
    
     //将js脚本注入,然后通过WebViewPostHandler方法拿到从网页端发送过来的数据
    NSString *jspath = [[NSBundle mainBundle] pathForResource:@"ajaxhook.min.js" ofType:nil];
    NSString *ajaxhook = [NSString stringWithContentsOfFile:jspath encoding:NSUTF8StringEncoding error:nil];
    WKUserScript *sc = [[WKUserScript alloc] initWithSource:ajaxhook injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:NO];
    [[config userContentController] addUserScript:sc];
    
    jspath = [[NSBundle mainBundle] pathForResource:@"jquery.min.js" ofType:nil];
    NSString *jquery = [NSString stringWithContentsOfFile:jspath encoding:NSUTF8StringEncoding error:nil];
    WKUserScript *jqsc = [[WKUserScript alloc] initWithSource:jquery injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:NO];
    [[config userContentController] addUserScript:jqsc];
    
    jspath = [[NSBundle mainBundle] pathForResource:@"xhrhook.js" ofType:nil];
    NSString *xhrhook = [NSString stringWithContentsOfFile:jspath encoding:NSUTF8StringEncoding error:nil];
    WKUserScript *xhrhooksc = [[WKUserScript alloc] initWithSource:xhrhook injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:NO];
    [[config userContentController] addUserScript:xhrhooksc];
    
    WebViewPostHandler *postHandler = [WebViewPostHandler new];
    [[config userContentController] addScriptMessageHandler:postHandler name:@"save"];
    
//    */
    //不缓存webview的数据
    config.websiteDataStore = [WKWebsiteDataStore nonPersistentDataStore];
    self.webview = [[WKWebView alloc] initWithFrame:self.view.frame configuration:config];

    [self.view addSubview:_webview];
    
    //加载网址
    [_webview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:_urlString]]];
    
}


- (void) registerClass
{
    NSString *className = @"WKBrowsingContextController";
    Class cls = NSClassFromString(className);
    SEL sel = NSSelectorFromString(@"registerSchemeForCustomProtocol:");
    if ([cls respondsToSelector:sel]) {
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [cls performSelector:sel withObject:@"http"];
        [cls performSelector:sel withObject:@"https"];
        #pragma clang diagnostic pop
    }
    
    [NSURLProtocol registerClass:[CustomURLProtocol class]];
}

- (void) unregisterClass
{
    [NSURLProtocol unregisterClass:[CustomURLProtocol class]];
}

@end
