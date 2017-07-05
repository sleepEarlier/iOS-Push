//
//  ViewController.m
//  GodPush
//
//  Created by kimiLin on 2017/5/24.
//  Copyright © 2017年 KimiLin. All rights reserved.
//

#import "ViewController.h"
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
#import <UserNotifications/UserNotifications.h>
#endif
@interface ViewController ()
@property (weak, nonatomic) IBOutlet UITextView *textField;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.textField.text  =@"";
    self.view.backgroundColor = [UIColor lightGrayColor];
}

//- (void)viewDidAppear:(BOOL)animated
//{
//    [super viewDidAppear:animated];
//    NSLog(@"%s",__func__);
//#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
//    
//    UNNotificationAction *action1 = [UNNotificationAction actionWithIdentifier:@"" title:@"回复" options:UNNotificationActionOptionDestructive];
//    
//    NSURL *URL = [[NSBundle mainBundle] URLForResource:@"emotionthumb" withExtension:@"png"];
//    UNNotificationAttachment *atm1 = [UNNotificationAttachment attachmentWithIdentifier:@"" URL:URL options:nil error:nil];
//    URL = [[NSBundle mainBundle] URLForResource:@"sharedImg_thumb" withExtension:@"jpg"];
//    UNNotificationAttachment *atm2 = [UNNotificationAttachment attachmentWithIdentifier:@"" URL:URL options:nil error:nil];
//    UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc]init];
//    content.title = @"通知";
//    content.body = @"你收到了一条新的本地消息";
//    content.badge = @([UIApplication sharedApplication].applicationIconBadgeNumber + 1);
//    content.sound = [UNNotificationSound defaultSound];
//    // 两个ImageAttachment只会显示第一个
//    content.attachments = @[atm1];
//    content.launchImageName = @"sharedImg.jpg";
//    
//    UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:2 repeats:NO];
//    // request必须有identifier
//    UNNotificationRequest *req = [UNNotificationRequest requestWithIdentifier:@"12312" content:content trigger:trigger];
//    [[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:req withCompletionHandler:^(NSError * _Nullable error) {
//        if (error) {
//            [self showJson:@{@"Certer add req err:":error.localizedDescription}];
//        }
//        else {
//            [self showJson:@{@"Certer add req suc:":@"Not error"}];
//        }
//    }];
//#endif
//}

- (void)showJson:(NSDictionary *)json {
    if (!json) {
        json = @{};
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.textField) {
            self.view.backgroundColor = [UIColor lightGrayColor];
        }
        NSData *data = [NSJSONSerialization dataWithJSONObject:json options:NSJSONWritingPrettyPrinted error:nil];
        NSString *text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSString *content = self.textField.text;
        content = [content stringByAppendingFormat:@"\n%@",text];
        self.textField.text = content;
    });
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
    });
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
