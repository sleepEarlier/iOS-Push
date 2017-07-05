//
//  AppDelegate.m
//  GodPush
//
//  Created by kimiLin on 2017/5/24.
//  Copyright © 2017年 KimiLin. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
#import <UserNotifications/UserNotifications.h>
#endif

@interface AppDelegate ()<UNUserNotificationCenterDelegate>
@property (nonatomic, weak) ViewController *controller;
@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    ViewController *vc = (ViewController *)[self.window rootViewController];
    self.controller = vc;
    NSDictionary *json = @{
                           @"LaunchOptions":launchOptions?:@{}
                           };
    [vc showJson:json];
    NSLog(@"launchOp:%@",launchOptions);
    
    
    CGFloat sysVersion = [UIDevice currentDevice].systemVersion.floatValue;
    if (sysVersion >= 10.0) {
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        center.delegate = self;
        [center removeAllDeliveredNotifications];
        [center getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
            UNAuthorizationStatus status = settings.authorizationStatus;
            if (status == UNAuthorizationStatusNotDetermined) {
                UNAuthorizationOptions options = UNAuthorizationOptionBadge | UNAuthorizationOptionAlert | UNAuthorizationOptionSound;
                [center requestAuthorizationWithOptions:options completionHandler:^(BOOL granted, NSError * _Nullable error) {
                    if (granted) {
                        NSLog(@"Auth suc");
                        UNNotificationAction *action1 = [UNNotificationAction actionWithIdentifier:@"checkoutAction" title:@"查看" options:UNNotificationActionOptionAuthenticationRequired|UNNotificationActionOptionForeground];
                        UNTextInputNotificationAction *action2 = [UNTextInputNotificationAction actionWithIdentifier:@"replyAction" title:@"回复" options:0 textInputButtonTitle:@"发送" textInputPlaceholder:@"回复消息"];
                        
                        UNNotificationCategory *cat = [UNNotificationCategory categoryWithIdentifier:@"action1" actions:@[action1,action2] intentIdentifiers:@[] options:UNNotificationCategoryOptionNone];
                        
                        [center setNotificationCategories:[NSSet setWithObjects:cat, nil]];
                        
                        [center getNotificationCategoriesWithCompletionHandler:^(NSSet<UNNotificationCategory *> * _Nonnull categories) {
                            NSLog(@"get categories:%@",categories);
                        }];
                        [application registerForRemoteNotifications];
                    } else {
                        NSLog(@"Auth fail:%@",error.localizedDescription);
                    }
                }];
            }
            else if (status == UNAuthorizationStatusDenied) {
                NSLog(@"用户关闭了通知，询问用户跳转设置开启通知");
                [application openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
            }
            else {
                NSLog(@"已经开启了通知");
                NSLog(@"Auth settings:%@",settings);
                UNNotificationAction *action1 = [UNNotificationAction actionWithIdentifier:@"checkoutAction" title:@"查看" options:UNNotificationActionOptionAuthenticationRequired|UNNotificationActionOptionForeground];
                UNTextInputNotificationAction *action2 = [UNTextInputNotificationAction actionWithIdentifier:@"replyAction" title:@"回复" options:0 textInputButtonTitle:@"发送" textInputPlaceholder:@"回复消息"];
                
                UNNotificationCategory *cat = [UNNotificationCategory categoryWithIdentifier:@"action1" actions:@[action1,action2] intentIdentifiers:@[] options:UNNotificationCategoryOptionNone];
                
                [center setNotificationCategories:[NSSet setWithObjects:cat, nil]];
                
                [center getNotificationCategoriesWithCompletionHandler:^(NSSet<UNNotificationCategory *> * _Nonnull categories) {
                    NSLog(@"get cat:%@",categories);
                }];
                [application registerForRemoteNotifications];
            }
            
        }];
        
        
    }
    else if (sysVersion >= 8.0) {
        UIUserNotificationType type = UIUserNotificationTypeAlert|UIUserNotificationTypeBadge|UIUserNotificationTypeSound;
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:type categories:nil];
        [application registerUserNotificationSettings:settings];
    }
    else {
        [application registerForRemoteNotificationTypes:UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound];
    }
    
    
    
    return YES;
}

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
    // iOS 8及以上会调用
    NSLog(@"%s",__func__);
    UIUserNotificationType type = notificationSettings.types;
    if ((type & UIUserNotificationTypeSound) == UIUserNotificationTypeSound) {
        NSLog(@"UIUserNotificationTypeSound");
    }
    if ((type & UIUserNotificationTypeBadge) == UIUserNotificationTypeBadge) {
        NSLog(@"UIUserNotificationTypeBadge");
    }
    if ((type & UIUserNotificationTypeAlert) == UIUserNotificationTypeAlert) {
        NSLog(@"UIUserNotificationTypeAlert");
    }
    [application registerForRemoteNotifications];
//    [application unregisterForRemoteNotifications];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSString *tokenStr = [NSString stringWithFormat:@"%@",deviceToken];
    tokenStr = [tokenStr stringByReplacingOccurrencesOfString:@"<" withString:@""];
    tokenStr = [tokenStr stringByReplacingOccurrencesOfString:@">" withString:@""];
    tokenStr = [tokenStr stringByReplacingOccurrencesOfString:@" " withString:@""];
    [self.controller showJson:@{@"DeviceToken":tokenStr}];
    NSLog(@"token:%@",tokenStr);
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSLog(@"register noti failed:%@",error.localizedDescription);
    [self.controller showJson:@{@"FailReg":error.localizedDescription}];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    NSLog(@"%@",userInfo);
    [self.controller showJson:@{@"didRecRN":userInfo}];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    NSLog(@"bg:%@",userInfo);
    [self.controller showJson:@{@"ftDidRecRN":userInfo}];
    completionHandler(UIBackgroundFetchResultNewData);
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    NSLog(@"local noti:%@",notification.alertBody);
}

// 实现此方法，在前台推送也会展示
-(void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {
    completionHandler(UNNotificationPresentationOptionBadge|UNNotificationPresentationOptionSound|UNNotificationPresentationOptionAlert);
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(nonnull UNNotificationResponse *)response withCompletionHandler:(nonnull void (^)())completionHandler {
    NSLog(@"actionIdentifier:%@",response.actionIdentifier);
    if ([response isKindOfClass:[UNTextInputNotificationResponse class]]) {
        NSString *content = ((UNTextInputNotificationResponse *)response).userText;
        NSLog(@"userText:%@",content);
        [self.controller showJson:@{@"用户输入:":content}];
    }
    completionHandler();
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
