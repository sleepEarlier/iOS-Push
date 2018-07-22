//
//  NotificationService.m
//  NotificationService
//
//  Created by kimiLin on 2017/5/25.
//  Copyright © 2017年 KimiLin. All rights reserved.
//

#import "NotificationService.h"
#import <UIKit/UIKit.h>
#import<MobileCoreServices/MobileCoreServices.h>

typedef void(^DownLoadComplete)(NSURL *fileURL);

@interface NotificationService ()

@property (nonatomic, strong) void (^contentHandler)(UNNotificationContent *contentToDeliver);
@property (nonatomic, strong) UNMutableNotificationContent *bestAttemptContent;

@end

@implementation NotificationService

- (void)didReceiveNotificationRequest:(UNNotificationRequest *)request withContentHandler:(void (^)(UNNotificationContent * _Nonnull))contentHandler {
    
    self.contentHandler = contentHandler;
    self.bestAttemptContent = [request.content mutableCopy];
    
    // Modify the notification content here...
    self.bestAttemptContent.title = [NSString stringWithFormat:@"%@ [modified]", self.bestAttemptContent.title];
    self.bestAttemptContent.body = request.content.body;
    
    NSString *imagePath = @"http://iobs.pingan.com.cn/download/szsc-smt-app-dmz-prd/3a569cfc-4ad2-4c8d-afda-e8c081fffcc2_1527225669710";
    [self downLoadImageFromURLPath:imagePath complete:^(NSURL *fileURL) {
        [self setupAttachmentWithFileURL:fileURL];
    }];
}

- (void)setupAttachmentWithFileURL:(NSURL *)fileURL {
    NSError *error = nil;
    UNNotificationAttachment *atm = nil;
    NSDictionary *options = @{
                              UNNotificationAttachmentOptionsTypeHintKey:(__bridge id _Nullable)(kUTTypeImage)
                              };
    atm = [UNNotificationAttachment attachmentWithIdentifier:@"" URL:fileURL options:options error:&error];
    if (error) {
        NSLog(@"error:%@",error);
    }
    
    if (atm) {
        self.bestAttemptContent.title = @"多媒体推送";
        self.bestAttemptContent.attachments = @[atm];
        NSLog(@"categoryIdentifier:%@",self.bestAttemptContent.categoryIdentifier);
        self.bestAttemptContent.launchImageName = @"emotionthumb.png";
    }
    
    self.contentHandler(self.bestAttemptContent);
}

- (void)downLoadImageFromURLPath:(NSString *)urlPath complete:(DownLoadComplete)complete {
    NSURL *url = [NSURL URLWithString:urlPath];
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            self.bestAttemptContent.title = @"download error";
            self.bestAttemptContent.body = error.localizedDescription;
            self.contentHandler(self.bestAttemptContent);
        }
        if (data) {
            NSString *filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"noti.png"];
            if ([data writeToFile:filePath atomically:YES]) {
                NSURL *fileURL = [NSURL fileURLWithPath:filePath];
                dispatch_async(dispatch_get_main_queue(), ^{
                    complete(fileURL);
                });
            }
        }
    }];
    [task resume];
}

- (void)serviceExtensionTimeWillExpire {
    // Called just before the extension will be terminated by the system.
    // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
    self.bestAttemptContent.title = @"last change";
    self.bestAttemptContent.body = @"serviceExtensionTimeWillExpire";
    self.contentHandler(self.bestAttemptContent);
}

@end
