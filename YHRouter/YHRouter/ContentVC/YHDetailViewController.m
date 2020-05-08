//
//  YHDetailViewController.m
//  YHRouter
//
//  Created by 林宁宁 on 2020/5/8.
//  Copyright © 2020 林宁宁. All rights reserved.
//

#import "YHDetailViewController.h"
#import "YHRouter.h"

@interface YHDetailViewController ()

@end

@implementation YHDetailViewController

-(void)yh_routerPassParamViewController:(id)parameters{
    
    NSLog(@"接收到的参数 信息 是 : %@", parameters);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor blueColor];
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
