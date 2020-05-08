//
//  YHHomeViewController.m
//  YHChart
//
//  Created by 林宁宁 on 2020/4/29.
//  Copyright © 2020 林宁宁. All rights reserved.
//

#import "YHHomeViewController.h"
#import "YHRouter.h"
#import "YHBaseNavigationViewController.h"

@interface YHCellItem : NSObject

@property (copy, nonatomic) NSString * title;
@property (copy, nonatomic) NSString * subTitle;
/// cell点击
@property (copy, nonatomic) void(^clickBlock)(__kindof YHCellItem * passItem);

@end

@implementation YHCellItem

@end



@interface YHHomeViewController ()<UITableViewDelegate, UITableViewDataSource>

@property (retain, nonatomic) UITableView * tableView;

@property (retain, nonatomic) NSMutableArray <YHCellItem *>* dataList;


@end

@implementation YHHomeViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title = @"YHRouter路由跳转";
    [self.navigationController.navigationBar setTranslucent:NO];
    
    
    /// - YHRouter 配置
    YHRouter * router = [YHRouter sharedRouter];
    router.url_scheme = @"YHRouter";
    router.linkURLPageKey = @"page";
    router.presentNavcClass = [YHBaseNavigationViewController class];
    [router setNeedLoginBlock:^BOOL{
        NSLog(@"做登录判断, 未登录去做登录操作, 这里返回YES表示 已登录");
        
        return YES;
    }];
    //外部链接打开 判断是否单独做处理 YES继续下一步跳转处理
    [router setURLOpenHostContinuePushBlock:^BOOL(NSString * _Nonnull vchost, NSDictionary * _Nonnull params) {
        if([vchost isEqualToString:@"tabbar"]){
            NSLog(@"假设是tabbar 标签栏切换操作 不做下一步处理 : %@",params);
            return NO;
        }
        return YES;
    }];
    
    [router addMapperDic:@{
        @"YHColorViewController":@"color",
        @"YHScrollViewController":@(1000),
        @"YHTableViewController":@[@"table",@(1001)],
        @"YHDetailViewController":@[@"detail",@(1002)],
        @"YHOrderViewController":@"order",
        @"Main.YHDebugSBViewController":@"debug"
    }];
    
    /// -
    
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.rowHeight = 50;
    [self.view addSubview:self.tableView];
    
    self.dataList = [NSMutableArray new];
    
    YHCellItem * item = [YHCellItem new];
    item.title = @"Push - vc";
    [item setClickBlock:^(__kindof YHCellItem *passItem) {
        [YHRouter yh_pushVCName:@"YHColorViewController"].
        title = passItem.title;
    }];
    [self.dataList addObject:item];
    
    item = [YHCellItem new];
    item.title = @"Push - vc from storyboard";
    [item setClickBlock:^(__kindof YHCellItem *passItem) {
        [YHRouter yh_pushVCName:@"Main.YHDebugSBViewController"].
        title = passItem.title;
    }];
    [self.dataList addObject:item];
    
    item = [YHCellItem new];
    item.title = @"Present - vc";
    [item setClickBlock:^(__kindof YHCellItem *passItem) {
        [YHRouter yh_presentVCName:@"YHTableViewController"].
        title = passItem.title;
    }];
    [self.dataList addObject:item];
    
    item = [YHCellItem new];
    item.title = @"Present - vc from storyboard";
    [item setClickBlock:^(__kindof YHCellItem *passItem) {
        [YHRouter yh_presentVCName:@"Main.YHDebugSBViewController"].
        title = passItem.title;
    }];
    [self.dataList addObject:item];
    
    item = [YHCellItem new];
    item.title = @"Scheme link open";
    [item setClickBlock:^(__kindof YHCellItem *passItem) {
        [YHRouter yh_openSchemeURL:@"YHRouter://detail?id=12&type=22"].
        title = passItem.title;
    }];
    [self.dataList addObject:item];
    
    item = [YHCellItem new];
    item.title = @"Scheme tabbar select change";
    [item setClickBlock:^(__kindof YHCellItem *passItem) {
        [YHRouter yh_openSchemeURL:@"YHRouter://tabbar?index=2"].
        title = passItem.title;
    }];
    [self.dataList addObject:item];
    
    item = [YHCellItem new];
    item.title = @"URL link open test 1";
    [item setClickBlock:^(__kindof YHCellItem *passItem) {
        [YHRouter yh_openLinkURL:@"https://1002?orderID=10086"].
        title = passItem.title;
    }];
    [self.dataList addObject:item];
    
    item = [YHCellItem new];
    item.title = @"URL link open test 2";
    [item setClickBlock:^(__kindof YHCellItem *passItem) {
        [YHRouter yh_openLinkURL:@"https://haha?orderID=10010&page=detail"].
        title = passItem.title;
    }];
    [self.dataList addObject:item];
    
    //参数传递
    item = [YHCellItem new];
    item.title = @"parameter passing";
    [item setClickBlock:^(__kindof YHCellItem *passItem) {
        [YHRouter yh_pushVCName:@"order"
                         params:@{@"orderID":@(9999)}
                      callBlock:nil].
                      title = passItem.title;
    }];
    [self.dataList addObject:item];
    
    item = [YHCellItem new];
    item.title = @"call back";
    [item setClickBlock:^(__kindof YHCellItem *passItem) {
        [YHRouter yh_pushVCName:@"order"
                         params:@{@"orderID":@(8888)}
                      callBlock:^(id  _Nullable passResult) {
            NSLog(@"%@",passResult);
        }].
        title = passItem.title;
    }];
    [self.dataList addObject:item];
    
    item = [YHCellItem new];
    item.title = @"need login in first";
    [item setClickBlock:^(__kindof YHCellItem *passItem) {
        [YHRouter yh_pushVCName:@"YHUserCenterViewController"].
        title = passItem.title;
    }];
    [self.dataList addObject:item];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.dataList.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"CellIdentifyPage"];
    if(!cell){
        cell = [[UITableViewCell alloc] initWithStyle:(UITableViewCellStyleDefault) reuseIdentifier:@"CellIdentifyPage"];
    }
    
    cell.textLabel.text = [NSString stringWithFormat:@"%zd: %@",indexPath.row+1,self.dataList[indexPath.row].title];
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    YHCellItem * item = self.dataList[indexPath.row];
    
    if(item.clickBlock){
        item.clickBlock(item);
    }
}


@end
