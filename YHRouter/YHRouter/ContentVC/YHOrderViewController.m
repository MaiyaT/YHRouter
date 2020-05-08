//
//  YHOrderViewController.m
//  YHRouter
//
//  Created by 林宁宁 on 2020/5/8.
//  Copyright © 2020 林宁宁. All rights reserved.
//

#import "YHOrderViewController.h"
#import "YHRouter.h"
#import <Masonry.h>

@interface YHOrderViewController ()

@property (assign, nonatomic) NSInteger orderID;

@property (retain, nonatomic) UILabel * orderInfo;

@end

@implementation YHOrderViewController

-(void)yh_routerPassParamViewController:(id)parameters{
    NSLog(@"接收到的参数 ： %@",parameters);
    
    if([parameters isKindOfClass:[NSDictionary class]] &&
       parameters[@"orderID"]){
        self.orderID = [parameters[@"orderID"] integerValue];
    }
}

- (BOOL)yh_routerReloadViewController_shoudShowNext:(id)parameters{
    if([parameters isKindOfClass:[NSDictionary class]] &&
       parameters[@"orderID"]){
        NSInteger orderID = [parameters[@"orderID"] integerValue];
        if(orderID == self.orderID){
            NSLog(@"同样的订单ID 刷新当前界面");
            return NO;
        }
    }
    return YES;
}



- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.orderInfo = [UILabel new];
    self.orderInfo.numberOfLines = 0;
    self.orderInfo.textAlignment = NSTextAlignmentCenter;
    self.orderInfo.text = @(self.orderID).stringValue;
    self.orderInfo.textColor = [UIColor blackColor];
    self.orderInfo.font = [UIFont boldSystemFontOfSize:20];
    [self.view addSubview:self.orderInfo];
    [self.orderInfo mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.centerY.equalTo(self.view).multipliedBy(0.7);
    }];
    
    
    UIButton * nextvc = [UIButton buttonWithType:UIButtonTypeCustom];
    [nextvc setTitle:@"其他订单" forState:UIControlStateNormal];
    nextvc.backgroundColor = [[UIColor orangeColor] colorWithAlphaComponent:0.3];
    [nextvc addTarget:self action:@selector(pushEvent) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:nextvc];
    [nextvc mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.top.equalTo(self.orderInfo.mas_bottom).offset(20);
        make.size.mas_equalTo(CGSizeMake(100, 44));
    }];
    
    UIButton * samevc = [UIButton buttonWithType:UIButtonTypeCustom];
    [samevc setTitle:@"同一个订单" forState:UIControlStateNormal];
    samevc.backgroundColor = [[UIColor greenColor] colorWithAlphaComponent:0.3];
    [samevc addTarget:self action:@selector(sameEvent) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:samevc];
    [samevc mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.top.equalTo(nextvc.mas_bottom).offset(20);
        make.size.mas_equalTo(CGSizeMake(100, 44));
    }];
    
    UIButton * callbackvc = [UIButton buttonWithType:UIButtonTypeCustom];
    [callbackvc setTitle:@"callback" forState:UIControlStateNormal];
    callbackvc.backgroundColor = [[UIColor greenColor] colorWithAlphaComponent:0.3];
    [callbackvc addTarget:self action:@selector(callbackEvent) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:callbackvc];
    [callbackvc mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.top.equalTo(samevc.mas_bottom).offset(20);
        make.size.mas_equalTo(CGSizeMake(100, 44));
    }];
}

-(void)setOrderID:(NSInteger)orderID{
    _orderID = orderID;
    
    self.orderInfo.text = @(orderID).stringValue;
}

- (void)pushEvent{
    
    __weak typeof(&*self)weakSelf = self;
    
    [YHRouter yh_pushVCName:@"order"
                     params:@{@"orderID":@(arc4random()%1000+1000)}
                  callBlock:^(id  _Nullable passResult) {
        
        self.orderInfo.text = [NSString stringWithFormat:@"%@\n%@",passResult,@(weakSelf.orderID).stringValue];
    }];
}

- (void)sameEvent{
    
    __weak typeof(&*self)weakSelf = self;
    
    [YHRouter yh_pushVCName:@"order"
                     params:@{@"orderID":@(self.orderID)}
                  callBlock:^(id  _Nullable passResult) {
        
        self.orderInfo.text = [NSString stringWithFormat:@"%@\n%@",passResult,@(weakSelf.orderID).stringValue];
    }];
}

- (void)callbackEvent{
    
    if(self.routerCallBlock){
        self.routerCallBlock([NSString stringWithFormat:@"call back other order ID: %zd",self.orderID]);
    }
    
    [self.navigationController popViewControllerAnimated:YES];
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
