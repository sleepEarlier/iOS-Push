//
//  NotificationViewController.m
//  ContentExtension
//
//  Created by kimiLin on 2017/5/26.
//  Copyright © 2017年 KimiLin. All rights reserved.
//

#import "NotificationViewController.h"
#import <UserNotifications/UserNotifications.h>
#import <UserNotificationsUI/UserNotificationsUI.h>
#import <AVFoundation/AVFoundation.h>

@interface NotificationViewController () <UNNotificationContentExtension>

@property IBOutlet UILabel *label;

@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@property (nonatomic, strong) AVPlayerLayer *layer;

@property (nonatomic, strong) AVPlayer *player;

@property (nonatomic, assign) UNNotificationContentExtensionMediaPlayPauseButtonType mediaPlayPauseButtonType;

@property (nonatomic, assign) CGRect mediaPlayPauseButtonFrame;

@property (nonatomic, copy) UIColor *mediaPlayPauseButtonTintColor;

@end

@implementation NotificationViewController

#pragma mark - UNNotificationContentExtension Protocol
- (void)didReceiveNotification:(UNNotification *)notification {
    NSLog(@"%s",__func__);
    self.label.text = notification.request.content.body;
    UNNotificationAttachment *atm = notification.request.content.attachments.firstObject;
    if ([atm.URL startAccessingSecurityScopedResource]) {
        [self setVideoPlaerWithAttachment:atm];
        [atm.URL stopAccessingSecurityScopedResource];
    }
}

- (void)didReceiveNotificationResponse:(UNNotificationResponse *)response completionHandler:(void (^)(UNNotificationContentExtensionResponseOption))completion {
    if ([response isKindOfClass:[UNTextInputNotificationResponse class]]) {
        completion(UNNotificationContentExtensionResponseOptionDoNotDismiss);
    } else {
        completion(UNNotificationContentExtensionResponseOptionDismissAndForwardAction);
    }
}

// 暂停、播放按钮类型
- (UNNotificationContentExtensionMediaPlayPauseButtonType)mediaPlayPauseButtonType {
    /*
     无播放、暂停按钮
     UNNotificationContentExtensionMediaPlayPauseButtonTypeNone,
     默认样式，按钮一直展示
     UNNotificationContentExtensionMediaPlayPauseButtonTypeDefault,
     按钮展示在内容上方，播放时自动隐藏，点击内容暂停
     UNNotificationContentExtensionMediaPlayPauseButtonTypeOverlay,
     */
    return UNNotificationContentExtensionMediaPlayPauseButtonTypeOverlay;
}

- (CGRect)mediaPlayPauseButtonFrame {
    CGPoint center = self.imageView.center;
    return CGRectMake(center.x - 25, center.y - 25, 50, 50);
}

- (void)mediaPlay {
    [self.player play];
}

- (void)mediaPause {
    [self.player pause];
}

#pragma mark - UIViewController relative
- (void)viewDidLoad {
    [super viewDidLoad];
}

- (CGSize)preferredContentSize {
    return CGSizeMake([UIScreen mainScreen].bounds.size.width, 300);
}

#pragma mark - setup player
- (void)setVideoPlaerWithAttachment:(UNNotificationAttachment *)atm {
    self.player = [AVPlayer playerWithURL:atm.URL];
    self.layer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    self.layer.frame = self.imageView.bounds;
    self.layer.videoGravity = AVLayerVideoGravityResize;
    [self.imageView.layer addSublayer:self.layer];
    
}

@end
