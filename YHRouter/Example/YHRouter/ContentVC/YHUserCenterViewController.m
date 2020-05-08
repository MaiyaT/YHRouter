//
//  YHUserCenterViewController.m
//  YHRouter
//
//  Created by 林宁宁 on 2020/5/8.
//  Copyright © 2020 林宁宁. All rights reserved.
//

#import "YHUserCenterViewController.h"
#import "YHRouter.h"

@interface YHUserCenterViewController ()

@end

@implementation YHUserCenterViewController

/// 需要登录
-(BOOL)yh_routerNeedLogin{
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor redColor];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
