> 将界面的跳转操作都放在一个地方统一处理
> 不用关心当前控制器是什么，不用繁琐的引用文件，
> 将各模块之间隔离开来
> 接收参数的属性不需要暴露在h文件中

### 用途
通过控制器的 类名字符串 来索引 打开该控制器

### 路由支持
- push
- present
- push storyboard的vc
- present storyboard的vc
- scheme 链接打开vc
- link 链接打开vc
- 参数传递
- 数据回调上一个界面
- 登录状态判断
- 同一个界面是刷新还是重新打开
- 控制器映射表

### 实现
##### 初始配置
```
    YHRouter * router = [YHRouter sharedRouter];
    router.url_scheme = @"YHRouter";
    打开链接 可通过该key查找控制器名字 如果为空取链接的host信息
    router.linkURLPageKey = @"page";
    present出来的vc加载在该控制器上
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
    
    //key是控制器的名字 如果是Storyboard 带上SB的名字 
    //value 可以是字符串 可以是 number类型 可以是包含字符串和number的数组
    [router addMapperDic:@{
        @"YHColorViewController":@"color",
        @"YHScrollViewController":@(1000),
        @"YHTableViewController":@[@"table",@(1001)],
        @"YHDetailViewController":@[@"detail",@(1002)],
        @"YHOrderViewController":@"order",
        @"Main.YHDebugSBViewController":@"debug"
    }];
```

##### Push
```
[YHRouter yh_pushVCName:@"YHColorViewController"]
[YHRouter yh_pushVCName:@"Main.YHDebugSBViewController"]
```
#### Present
```
[YHRouter yh_presentVCName:@"YHTableViewController"]
[YHRouter yh_presentVCName:@"Main.YHDebugSBViewController"]
```
#### Scheme
```
[YHRouter yh_openSchemeURL:@"YHRouter://detail?id=12&type=22"].
```
#### Link
```
[YHRouter yh_openLinkURL:@"https://order?orderID=10086"].
```
####  参数传递 及回调
```
[YHRouter yh_pushVCName:@"order"
                         params:@{@"orderID":@(8888)}
                      callBlock:^(id  _Nullable passResult) {
            NSLog(@"%@",passResult);
        }]

回调
if(self.routerCallBlock){
        self.routerCallBlock([NSString stringWithFormat:@"call back other order ID: %zd",self.orderID]);
    }
```

---
## 控制器中YHRouterProtocol设置
#### 接收参数
```
- (void)yh_routerPassParamViewController:(id)parameters;
```
####  该页面是否要显示 将要显示控制器 配置参数
比如：如果当前再订单详情页 当前订单界面是否刷新还是再叠加一个新的界面
```
- (BOOL)yh_routerReloadViewController_shoudShowNext:(id)parameters;
```
####  是否需要登录
```
- (BOOL)yh_routerNeedLogin;
```
例子：
```
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

....
..
.

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
```


