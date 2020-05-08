//
//  YHRouter.m
//  MoreCoin
//
//  Created by 林宁宁 on 2019/9/19.
//  Copyright © 2019 MoreCoin. All rights reserved.
//

#import "YHRouter.h"

#import <objc/runtime.h>

#define YHRouterLog(format, ...) NSLog((@"YHRouter >>> " format), ##__VA_ARGS__)

#pragma mark - UINavigationController+YHRouter


UIViewController * YHCurrentViewController(void){
    UIWindow * window = [[UIApplication sharedApplication] keyWindow];
    if (window.windowLevel != UIWindowLevelNormal){
        NSArray *windows = [[UIApplication sharedApplication] windows];
        for(UIWindow * tmpWin in windows){
            if (tmpWin.windowLevel == UIWindowLevelNormal){
                window = tmpWin;
                break;
            }
        }
    }
    UIViewController *result = window.rootViewController;
    while (result.presentedViewController) {
        result = result.presentedViewController;
    }
    if ([result isKindOfClass:[UITabBarController class]]) {
        result = [(UITabBarController *)result selectedViewController];
    }
    if ([result isKindOfClass:[UINavigationController class]]) {
        result = [(UINavigationController *)result topViewController];
    }
    return result;
}

BOOL IsNull(id obj){
    if(!obj){
        return YES;
    }
    if(obj == nil || [obj isEqual:[NSNull class]] || [obj isKindOfClass:[NSNull class]]){
        return YES;
    }
    if([obj isKindOfClass:[NSString class]]){
        NSString * str = (NSString *)obj;
        if([str isEqualToString:@""]){
            return YES;
        }
        if ([[str stringByReplacingOccurrencesOfString:@" " withString:@""] isEqualToString:@""]){
            return YES;
        }
    }
    return NO;
}

void YHRouter_swizzleMethod(Class class, SEL originalSelector, SEL swizzledSelector) {
    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);

    BOOL didAddMethod = class_addMethod(class,
                                        originalSelector,
                                        method_getImplementation(swizzledMethod),
                                        method_getTypeEncoding(swizzledMethod));

    if (didAddMethod) {
        class_replaceMethod(class, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
    }else{
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}


@interface UINavigationController (YHRouter)

@end

@implementation UINavigationController (YHRouter)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];
        YHRouter_swizzleMethod(class, @selector(viewWillAppear:), @selector(router_navigationViewWillAppear:));
    });
}

- (void)router_navigationViewWillAppear:(BOOL)animation {
    [self router_navigationViewWillAppear:animation];
    
    if([YHRouter sharedRouter].currentNavigationController){
        [[YHRouter sharedRouter] setValue:[YHRouter sharedRouter].currentNavigationController forKey:@"preNavc"];
    }
    [YHRouter sharedRouter].currentNavigationController = self;
    
}


@end



@implementation UIViewController(YHBRouter)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];
        YHRouter_swizzleMethod(class, @selector(viewWillAppear:), @selector(router_ViewWillAppear:));
    });
}

- (void)router_ViewWillAppear:(BOOL)animation {
    [self router_ViewWillAppear:animation];
    
    if(self.navigationController){
        if([YHRouter sharedRouter].currentNavigationController){
            [[YHRouter sharedRouter] setValue:[YHRouter sharedRouter].currentNavigationController forKey:@"preNavc"];
        }
        [YHRouter sharedRouter].currentNavigationController = self.navigationController;
    }
}

-(YHRouterCallBlock)routerCallBlock{
    return objc_getAssociatedObject(self, @selector(routerCallBlock));
}

-(void)setRouterCallBlock:(YHRouterCallBlock)routerCallBlock{
    objc_setAssociatedObject(self, @selector(routerCallBlock), routerCallBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

@end






#pragma mark - YHRouter

@interface YHRouter()

@property (weak, nonatomic) UINavigationController * preNavc;

@property (retain, nonatomic) NSMutableDictionary <NSString *, id> * mapper;

@end


@implementation YHRouter


+ (instancetype)sharedRouter {
    static YHRouter *router = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        if (!router) {
            router = [[YHRouter alloc] init];
            router.url_scheme = @"";
            router.mapper = [NSMutableDictionary new];
        }
    });
    return router;
}

-(UIViewController *)currentViewController{
    return YHCurrentViewController();
}

/// 跳转控制器映射
- (void)addMapperVC:(NSString *)vcName mapKey:(id)mapKey{
    if(IsNull(vcName) || IsNull(mapKey)){
        return;
    }
    self.mapper[vcName] = mapKey;
}
- (void)addMapperDic:(NSDictionary<NSString *, id> *)mapperDic{
    [self.mapper addEntriesFromDictionary:mapperDic];
}

#pragma mark - key mapper

- (NSString *)mapperController:(NSString *)mapper{
    
    __block NSString * reslutMapper = mapper;
    
    NSDictionary * customMapper = self.mapper;
    [customMapper enumerateKeysAndObjectsUsingBlock:^(NSString *propertyName, NSString *mappedToKey, BOOL *stop) {

        if ([mappedToKey isKindOfClass:[NSString class]]) {
            
            if([mappedToKey isEqualToString:mapper]){
                reslutMapper = propertyName;
                return;
            }
            
        } else if ([mappedToKey isKindOfClass:[NSArray class]]) {

            for (NSString *oneKey in ((NSArray *)mappedToKey)) {
                if([oneKey isKindOfClass:[NSString class]]){
                    if([oneKey isEqualToString:mapper]){
                        reslutMapper = propertyName;
                        return;
                    }
                }else if ([oneKey isKindOfClass:[NSNumber class]]){
                    NSNumber * oneKeyNum = (NSNumber *)oneKey;
                    if([oneKeyNum.stringValue isEqualToString:mapper]){
                        reslutMapper = propertyName;
                        return;
                    }
                }
            }
        }
    }];
    
    return reslutMapper;
}


#pragma mark - 



//=================== Push

+ (UIViewController *)yh_pushVCName:(NSString *)vcName{
    
    return [YHRouter yh_pushVCName:vcName params:nil callBlock:nil];
}

+ (UIViewController *)yh_pushVCName:(NSString *)vcName params:(id)passParams callBlock:(YHRouterCallBlock)callBlock{
    if(vcName && vcName.length > 0){
        UIViewController * vc = [[YHRouter sharedRouter] yh_getControllerByVCName:vcName queryParams:passParams];
        vc.routerCallBlock = callBlock;
        if (!vc) {
            YHRouterLog(@"没有 实现 %@",vcName);
            return nil;
        }
        
        void (^push)(void) = ^void () {
            YHRouter * router = [YHRouter sharedRouter];
            if(router.currentNavigationController){
                [router.currentNavigationController pushViewController:vc animated:YES];
            }else if ([router valueForKey:@"preNavc"]){
                UINavigationController * navc = [router valueForKey:@"preNavc"];
                [navc pushViewController:vc animated:YES];
            }else if (router.currentViewController.navigationController){
                UINavigationController * navc = router.currentViewController.navigationController;
                [navc pushViewController:vc animated:YES];
            } else{
                YHRouterLog(@"没有找到导航控制器");
            }
        };
        SEL selectorLogin = NSSelectorFromString(@"yh_routerNeedLogin");
        if([vc respondsToSelector:selectorLogin]){
            BOOL needLogin = [vc yh_routerNeedLogin];
            
            if (needLogin &&
                [YHRouter sharedRouter].needLoginBlock &&
                ![YHRouter sharedRouter].needLoginBlock()) {
                
                return vc;
            }
        }
        push();
        
        return vc;
    }else{
        YHRouterLog(@"没有控制器 %@ 的实现",vcName);
        return nil;
    }
}

+ (UIViewController *)yh_presentVCName:(NSString *)vcName{
    return [YHRouter yh_presentVCName:vcName params:nil callBlock:nil];
}

+ (UIViewController *)yh_presentVCName:(NSString *)vcName params:(id)passParams callBlock:(YHRouterCallBlock)callBlock{

    if(vcName && vcName.length > 0){
        
        YHRouter * router = [YHRouter sharedRouter];
        
        UIViewController * vc = [router yh_getControllerByVCName:vcName queryParams:passParams];
        vc.routerCallBlock = callBlock;
        
        UINavigationController * navc;
        if(router.presentNavcClass &&
           [router.presentNavcClass isSubclassOfClass:[UINavigationController class]]
           ){
            navc = [router.presentNavcClass new];
        }else{
            navc = [UINavigationController new];
        }
        [navc setViewControllers:@[vc] animated:NO];
        
        if(router.currentNavigationController){
            [router.currentNavigationController presentViewController:navc animated:YES completion:nil];
        }else{
            [router.currentViewController presentViewController:navc animated:YES completion:nil];
        }

        return vc;
    }else{
        YHRouterLog(@"没有控制器 %@ 的实现",vcName);
        return nil;
    }
}


#pragma mark - URL route

/** 通过URL跳转 内部含 控制器名称的参数信息*/
+ (UIViewController *)yh_openSchemeURL:(NSString *)routePattern{

    NSURLComponents *components = [NSURLComponents componentsWithString:routePattern];
    NSString *scheme = components.scheme;
    
    //scheme规则自己添加
    if([YHRouter sharedRouter].url_scheme){
        if (![scheme isEqualToString:[YHRouter sharedRouter].url_scheme]) {
            YHRouterLog(@"scheme规则不匹配");
            return nil;
        }
    }
    
    NSString * vcHost = nil;
    
    if (components.host.length > 0 && (![components.host isEqualToString:@"localhost"] && [components.host rangeOfString:@"."].location == NSNotFound)) {
        vcHost = [components.percentEncodedHost copy];
        components.host = @"/";
        components.percentEncodedPath = [vcHost stringByAppendingPathComponent:(components.percentEncodedPath ?: @"")];
    }
    
    NSString *path = [components percentEncodedPath];
    
    if (components.fragment != nil) {
        BOOL fragmentContainsQueryParams = NO;
        NSURLComponents *fragmentComponents = [NSURLComponents componentsWithString:components.percentEncodedFragment];
        
        if (fragmentComponents.query == nil && fragmentComponents.path != nil) {
            fragmentComponents.query = fragmentComponents.path;
        }
        
        if (fragmentComponents.queryItems.count > 0) {
            fragmentContainsQueryParams = fragmentComponents.queryItems.firstObject.value.length > 0;
        }
        
        if (fragmentContainsQueryParams) {
            components.queryItems = [(components.queryItems ?: @[]) arrayByAddingObjectsFromArray:fragmentComponents.queryItems];
        }
        
        if (fragmentComponents.path != nil && (!fragmentContainsQueryParams || ![fragmentComponents.path isEqualToString:fragmentComponents.query])) {
            path = [path stringByAppendingString:[NSString stringWithFormat:@"#%@", fragmentComponents.percentEncodedPath]];
        }
    }
    
    if (path.length > 0 && [path characterAtIndex:0] == '/') {
        path = [path substringFromIndex:1];
    }
    
    if (path.length > 0 && [path characterAtIndex:path.length - 1] == '/') {
        path = [path substringToIndex:path.length - 1];
    }
    
    //获取queryItem
    NSArray <NSURLQueryItem *> *queryItems = [components queryItems] ?: @[];
    NSMutableDictionary *queryParams = [NSMutableDictionary dictionary];
    for (NSURLQueryItem *item in queryItems) {
        if (item.value == nil) {
            continue;
        }
        
        if (queryParams[item.name] == nil) {
            queryParams[item.name] = item.value;
        } else if ([queryParams[item.name] isKindOfClass:[NSArray class]]) {
            NSArray *values = (NSArray *)(queryParams[item.name]);
            queryParams[item.name] = [values arrayByAddingObject:item.value];
        } else {
            id existingValue = queryParams[item.name];
            queryParams[item.name] = @[existingValue, item.value];
        }
    }
    
    NSDictionary *params = queryParams.copy;
    if(!vcHost && [params isKindOfClass:[NSDictionary class]]){
        vcHost = params[@"vc"];
    }
    
    //判断是否需要单独处理
    if([YHRouter sharedRouter].URLOpenHostContinuePushBlock){
        BOOL continuePush = [YHRouter sharedRouter].URLOpenHostContinuePushBlock(vcHost, params);
        if(!continuePush){
            return nil;
        }
    }
    
    return [YHRouter yh_pushVCName:vcHost params:params callBlock:nil];
}

/** 通过URL跳转 内部含 控制器名称的参数信息*/
+ (UIViewController *)yh_openLinkURL:(NSString *)routePattern {

    NSURLComponents *components = [NSURLComponents componentsWithString:routePattern];
    
    //获取queryItem
    NSArray <NSURLQueryItem *> *queryItems = [components queryItems] ?: @[];
    NSMutableDictionary *queryParams = [NSMutableDictionary dictionary];
    for (NSURLQueryItem *item in queryItems) {
        if (item.value == nil) {
            continue;
        }
        
        if (queryParams[item.name] == nil) {
            queryParams[item.name] = item.value;
        } else if ([queryParams[item.name] isKindOfClass:[NSArray class]]) {
            NSArray *values = (NSArray *)(queryParams[item.name]);
            queryParams[item.name] = [values arrayByAddingObject:item.value];
        } else {
            id existingValue = queryParams[item.name];
            queryParams[item.name] = @[existingValue, item.value];
        }
    }
    
    NSDictionary *params = queryParams.copy;
    
    NSString * page = nil;
    if (components.host.length > 0 && (![components.host isEqualToString:@"localhost"] && [components.host rangeOfString:@"."].location == NSNotFound)) {
        page = [components.percentEncodedHost copy];
    }
    
    NSString * pageKey = [YHRouter sharedRouter].linkURLPageKey;
    if([params isKindOfClass:[NSDictionary class]] &&
       pageKey &&
       [params objectForKey:pageKey]){
        page = params[pageKey];
    }
    if (IsNull(page)) {
        page = [components.path stringByReplacingOccurrencesOfString:@"/" withString:@""];
    }
    
    //判断是否需要单独处理
    if([YHRouter sharedRouter].URLOpenHostContinuePushBlock){
        BOOL continuePush = [YHRouter sharedRouter].URLOpenHostContinuePushBlock(page, params);
        if(!continuePush){
            return nil;
        }
    }
    
    return [YHRouter yh_pushVCName:page params:params callBlock:nil];
}


#pragma mark - privite

//界面跳转
- (UIViewController *)yh_getControllerByVCName:(NSString *)targetName queryParams:(NSDictionary *)queryParams {
    if(!targetName || targetName.length == 0){
        return nil;
    }

    targetName = [self mapperController:targetName];
    NSString * sbName = nil;
    NSString * vcName = targetName;
    if([targetName containsString:@"."]){
        sbName = [targetName componentsSeparatedByString:@"."].firstObject;
        vcName = [targetName componentsSeparatedByString:@"."].lastObject;
    }
    Class vcClass = NSClassFromString(vcName);
    if(!vcClass){
        YHRouterLog(@"没有控制器 %@ 的实现",vcName);
        return nil;
    }
    //是同一个控制器
    UIViewController * currentVC = [[YHRouter sharedRouter] currentViewController];
    if([currentVC isKindOfClass:vcClass]){
        SEL selectorShow = NSSelectorFromString(@"yh_routerReloadViewController_shoudShowNext:");
        if([currentVC respondsToSelector:selectorShow]){
            if(![currentVC yh_routerReloadViewController_shoudShowNext:queryParams]){
                //不做跳转
                YHRouterLog(@"同一个控制器 %@ 不做跳转 刷新当前界面",vcName);
                return nil;
            }
        }
    }
    
    SEL selectorCreate = NSSelectorFromString(@"yh_routerCreateViewController:");
    UIViewController *targetController;
    if(sbName){
        targetController = [[UIStoryboard storyboardWithName:sbName bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:vcName];
        if(!targetController){
            YHRouterLog(@"在 storyboard %@ 中没有找到该控制器 %@ ",sbName,vcName);
            return nil;
        }
        if(queryParams){
            SEL selectorConfig = NSSelectorFromString(@"yh_routerPassParamViewController:");
            if([targetController respondsToSelector:selectorConfig]){
                [targetController yh_routerPassParamViewController:queryParams];
            }
        }
    }else{
        if ([vcClass respondsToSelector:selectorCreate]) {
            targetController = [vcClass yh_routerCreateViewController:queryParams];
        }else{
            targetController = [vcClass new];
            
            if(queryParams){
                SEL selectorConfig = NSSelectorFromString(@"yh_routerPassParamViewController:");
                if([targetController respondsToSelector:selectorConfig]){
                    [targetController yh_routerPassParamViewController:queryParams];
                }
            }
        }
    }
    
    if(![targetController isKindOfClass:[UIViewController class]]){
        YHRouterLog(@"不是控制器 %@ ",targetName);
        return nil;
    }
    
    return targetController;
}




@end
