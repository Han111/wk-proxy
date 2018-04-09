//
//  ViewController.m
//  proxy-browser
//
//  Created by melo的苹果本 on 2018/4/8.
//  Copyright © 2018年 com. All rights reserved.
//

#import "ViewController.h"
#import "ProtocolCustom.h"
#import "SSZipArchive.h"
#import "zlib.h"
#import <WebKit/WebKit.h>



@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    Class cls = NSClassFromString(@"WKBrowsingContextController");
    SEL sel = NSSelectorFromString(@"registerSchemeForCustomProtocol:");
    if ([(id)cls respondsToSelector:sel]) {
        [(id)cls performSelector:sel withObject:@"http"];
        [(id)cls performSelector:sel withObject:@"https"];

    }
    
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)clearBrowserCache {
    NSSet *websiteDataTypes = [WKWebsiteDataStore allWebsiteDataTypes];
    //// Date from
    NSDate *dateFrom = [NSDate dateWithTimeIntervalSince1970:0];
    //// Execute
    [[WKWebsiteDataStore defaultDataStore] removeDataOfTypes:websiteDataTypes modifiedSince:dateFrom completionHandler:^{
        // Done
    }];
}

- (IBAction)downloadSource:(id)sender {
    NSDictionary *_headers;
    NSURLSession *_session = [self sessionWithHeaders:_headers];
    NSURL *url = [NSURL URLWithString: @"http://10.2.138.225:3238/dist.zip"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    //初始化cachepath
    NSString *cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    NSFileManager *fm = [NSFileManager defaultManager];
    
    //删除之前已有的文件
    [fm removeItemAtPath:[cachePath stringByAppendingPathComponent:@"dist.zip"] error:nil];
    
    NSURLSessionDownloadTask *downloadTask=[_session downloadTaskWithRequest:request completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
        if (!error) {
            
            NSError *saveError;
            
            NSURL *saveUrl = [NSURL fileURLWithPath: [cachePath stringByAppendingPathComponent:@"dist.zip"]];
            
            //location是下载后的临时保存路径,需要将它移动到需要保存的位置
            [[NSFileManager defaultManager] copyItemAtURL:location toURL:saveUrl error:&saveError];
            if (!saveError) {
                NSLog(@"task ok");
                if([SSZipArchive unzipFileAtPath:
                    [cachePath stringByAppendingPathComponent:@"dist.zip"]
                                   toDestination:cachePath]) {
                    NSLog(@"unzip ok");//解压成功
                }
                else {
                    NSLog(@"unzip err");//解压失败
                }
            }
            else {
                NSLog(@"task err");
            }
        }
        else {
            NSLog(@"error is :%@", error.localizedDescription);
        }
    }];
    
    [downloadTask resume];
}




- (IBAction)regist:(id)sender {
    [self clearBrowserCache];
    [NSURLProtocol registerClass:[FilteredProtocol class]];
}

- (IBAction)unregist:(id)sender {
    [self clearBrowserCache];
    [NSURLProtocol unregisterClass:[FilteredProtocol class]];
}

- (IBAction)browserHandler:(id)sender {
    NSLog(@"open browser");
    [super viewDidLoad];

    NSURL *nsurl=[NSURL URLWithString:@"http://10.2.138.225:3233/index.html"];

    NSURLRequest *nsrequest=[NSURLRequest requestWithURL:nsurl];

    [self.wk loadRequest: nsrequest];
}

static NSUInteger const TIMEOUT = 300;

- (NSURLSession *)sessionWithHeaders: (NSDictionary *)headers {
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    configuration.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    configuration.timeoutIntervalForRequest = TIMEOUT;
    configuration.timeoutIntervalForResource = TIMEOUT;
    if (headers) {
        [configuration setHTTPAdditionalHeaders:headers];
    }
    
    return [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
}

@end
