//
//  CustomURLProtocol.m
//  WKwebviewRequestHook
//
//  Created by 李峰 on 2019/7/9.
//  Copyright © 2019 feng. All rights reserved.
//

#import "CustomURLProtocol.h"


static NSString *const HookPropertyKey = @"HookPropertyKey";

@interface CustomURLProtocol ()<NSURLSessionDataDelegate>
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSURLSessionTask *task;
@end

@implementation CustomURLProtocol

/**
 判断是不是需要hook请求
 */
+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    //    NSLog(@"%s: %@",__func__, request.URL.absoluteString);
    NSString *scheme = [[request URL] scheme];
    if ([scheme caseInsensitiveCompare: @"http"] == NSOrderedSame || [scheme caseInsensitiveCompare:@"https"] == NSOrderedSame) {
        //o判断是否已经处理过
        if ([NSURLProtocol propertyForKey:HookPropertyKey inRequest:request]) {
            return NO;
        }

    }
    return YES;
}

+ (NSURLRequest *) canonicalRequestForRequest:(NSURLRequest *)request {

    NSMutableURLRequest *mutableReqeust = [request mutableCopy];
    // 执行自定义操作，例如添加统一的请求头等
    return mutableReqeust;
}


+ (BOOL)requestIsCacheEquivalent:(NSURLRequest *)a toRequest:(NSURLRequest *)b
{
    return [super requestIsCacheEquivalent:a toRequest:b];
}

- (void)startLoading
{
    //    NSLog(@"%s: %@",__func__, self.request.URL.absoluteString);
    NSMutableURLRequest *request = [[self request] mutableCopy];
    // 标示改request已经处理过了，防止无限循环
    [NSURLProtocol setProperty:@(YES) forKey:HookPropertyKey inRequest:request];


    if ([request.URL.absoluteString isEqualToString:@"https://www.baidu.com/"]) {
        request.URL = [NSURL URLWithString:@"https://news.qq.com"];
    }
    else if ([request.URL.absoluteString containsString:@"https://www.163.com/"]) {
        request.URL = [NSURL URLWithString:@"https://news.sina.com.cn"]; //跳转网易
    }
    
    [self requestData:request];
}


- (void)stopLoading
{
    [self.task cancel];
    self.session = nil;
}


- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    if (error != nil) {
        [self.client URLProtocol:self didFailWithError:error];
    }else
    {
        [self.client URLProtocolDidFinishLoading:self];
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler
{
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];

    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    [self.client URLProtocol:self didLoadData:data];
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask willCacheResponse:(NSCachedURLResponse *)proposedResponse completionHandler:(void (^)(NSCachedURLResponse * _Nullable))completionHandler
{
    completionHandler(proposedResponse);
}

//TODO: 重定向
//- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)newRequest completionHandler:(void (^)(NSURLRequest *))completionHandler
//{
//    NSMutableURLRequest*    redirectRequest;
//    redirectRequest = [newRequest mutableCopy];
//    [[self class] removePropertyForKey:HookPropertyKey inRequest:redirectRequest];
//    [[self client] URLProtocol:self wasRedirectedToRequest:redirectRequest redirectResponse:response];
//
//    [self.task cancel];
//    [[self client] URLProtocol:self didFailWithError:[NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil]];
//}


-(void) requestData:(NSMutableURLRequest *) request {

    NSInputStream *bodyStream = [request HTTPBodyStream];
    [bodyStream open];
    /*
     一般的post请求在这边使用这个判断加操作就可以拿到body的数据,但是因为wkwebview在post请求的时候会自动丢掉body,
     所以我们才需要script文件夹中的脚本去hook wkwebview的body数据
     */
    
    //判断body里面是不是有数据,有数据就copy一份出来,处理一般的session post请求是可以的
    if ([bodyStream hasBytesAvailable]) {
        NSMutableData *data = [[NSMutableData alloc] init];
        uint8_t buffer[1024] = {0};
        while ([bodyStream hasBytesAvailable]) {
            NSInteger len = [bodyStream read:buffer maxLength:1024];
            if (len > 0 && bodyStream.streamError == nil) {
                [data appendBytes:(void *)buffer length:len];
            }
            memset(buffer, 0, 1024);
        }
        request.HTTPBody = [data copy];
        [bodyStream close];
    }
    else {
        //body里面没有数据就说明可能是wkwebview的post,我们就去我们之前的缓存里面拿数据
        NSString *key = [[[request URL] absoluteString] lowercaseString];
        NSString *data = [[NSUserDefaults standardUserDefaults] objectForKey:key];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        if (data != nil) {//缓存有数据
            NSDictionary *dataJson = [NSJSONSerialization JSONObjectWithData: [data dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
            if (dataJson != nil) {
                [request setHTTPBody: [NSJSONSerialization dataWithJSONObject:dataJson options:0 error:nil]];
            }
            else {//没有数据就直接把data原封不动的放到body里面去请求就完事了
                [request setHTTPBody: [data dataUsingEncoding:NSUTF8StringEncoding]];
            }
        }
    }
    //利用session把请求转发出去
    NSURLSessionConfiguration *configure = [NSURLSessionConfiguration defaultSessionConfiguration];
    self.session  = [NSURLSession sessionWithConfiguration:configure delegate:self delegateQueue:[NSOperationQueue new]];
    self.task = [self.session dataTaskWithRequest:request];
    [self.task resume];
}


@end
