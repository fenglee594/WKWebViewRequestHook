//
//  WebViewPostHandler.m
//  WKwebviewRequestHook
//
//  Created by 李峰 on 2019/12/20.
//  Copyright © 2019 feng. All rights reserved.
//

#import "WebViewPostHandler.h"

@implementation WebViewPostHandler

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
    NSLog(@"request data:%@",message.body);
    NSDictionary *dic = (NSDictionary *)message.body;
    //    NSLog(@"req: %@",dic);
    [self saveData:dic];
    
}


//保存body数据
- (void) saveData:(NSDictionary *)data
{
    if (!data) {
        return;
    }
    
    NSString *urlkey = [data[@"key"] lowercaseString];
    NSString *urlvalue = data[@"value"][0];
    [[NSUserDefaults standardUserDefaults] setObject:urlvalue forKey:urlkey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
