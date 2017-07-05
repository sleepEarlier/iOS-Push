//
//  NotificationService.m
//  NotificationService
//
//  Created by kimiLin on 2017/5/25.
//  Copyright © 2017年 KimiLin. All rights reserved.
//

#import "NotificationService.h"

@interface NotificationService ()

@property (nonatomic, strong) void (^contentHandler)(UNNotificationContent *contentToDeliver);
@property (nonatomic, strong) UNMutableNotificationContent *bestAttemptContent;

@end

@implementation NotificationService

- (void)didReceiveNotificationRequest:(UNNotificationRequest *)request withContentHandler:(void (^)(UNNotificationContent * _Nonnull))contentHandler {
    NSLog(@"%s",__func__);
    self.contentHandler = contentHandler;
    self.bestAttemptContent = [request.content mutableCopy];
    
    // Modify the notification content here...
    self.bestAttemptContent.title = [NSString stringWithFormat:@"%@ [modified]", self.bestAttemptContent.title];
//    self.bestAttemptContent.title = request.content.title;
//    self.bestAttemptContent.subtitle = @"点击查看";
    self.bestAttemptContent.body = request.content.body;
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"WeChatSight4" withExtension:@"mp4"];
    NSError *error = nil;
    NSDictionary *options = @{
                              UNNotificationAttachmentOptionsThumbnailTimeKey:@1
                              };
    UNNotificationAttachment *atm = [UNNotificationAttachment attachmentWithIdentifier:@"" URL:url options:options error:&error];
    
    if (error) {
        NSLog(@"error:%@",error.localizedDescription);
    }
    self.bestAttemptContent.attachments = @[atm];
    
    self.bestAttemptContent.categoryIdentifier = request.content.userInfo[@"aps"][@"catId"];
    NSLog(@"UserInfo:%@",request.content.userInfo);
    NSLog(@"categoryIdentifier:%@",self.bestAttemptContent.categoryIdentifier);
//    self.bestAttemptContent.launchImageName = @"emotionthumb.png";
    
    self.contentHandler(self.bestAttemptContent);
}

- (void)serviceExtensionTimeWillExpire {
    // Called just before the extension will be terminated by the system.
    // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
    NSLog(@"%s",__func__);
    self.contentHandler(self.bestAttemptContent);
}

@end
