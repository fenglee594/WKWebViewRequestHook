//
//  MainViewController.m
//  WKwebviewRequestHook
//
//  Created by 李峰 on 2019/12/19.
//  Copyright © 2019 feng. All rights reserved.
//

#import "MainViewController.h"
#import "ViewController.h"


#define Baidu @"https://www.baidu.com"
#define WangYi @"https://www.163.com"

@interface MainViewController ()
@property (weak, nonatomic) IBOutlet UISwitch *hookSwitch;
@property (nonatomic, assign) BOOL shouldHook;

@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.hookSwitch addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
    
    self.hookSwitch.on = false;
    _shouldHook = self.hookSwitch.isOn;

}

- (IBAction)loadBaiDuAction:(id)sender {
    
    ViewController *vc = [ViewController new];
    //设置vc需要访问的网址和hook的状态
    vc.openHook = _shouldHook;
    vc.urlString = Baidu;
    [self.navigationController pushViewController:vc animated:YES];

}

- (IBAction)loadSouHuAction:(id)sender {
    
    ViewController *vc = [ViewController new];
    //设置vc需要访问的网址和hook的状态
    vc.openHook = _shouldHook;
    vc.urlString = WangYi;
    [self.navigationController pushViewController:vc animated:YES];

}


- (void) switchChanged:(id) sender
{
    UISwitch *control = (UISwitch *) sender;
    _shouldHook = control.isOn;
}


@end
