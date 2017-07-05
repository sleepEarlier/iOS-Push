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

- (UNNotificationContentExtensionMediaPlayPauseButtonType)mediaPlayPauseButtonType {
    return UNNotificationContentExtensionMediaPlayPauseButtonTypeOverlay;
}

- (CGRect)mediaPlayPauseButtonFrame {
    CGPoint center = self.imageView.center;
    return CGRectMake(center.x - 25, center.y - 25, 50, 50);
}

- (UIColor *)mediaPlayPauseButtonTintColor {
    return [UIColor lightGrayColor];
}

- (void)mediaPlay {
    [self.player play];
}

- (void)mediaPause {
    [self.player pause];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.preferredContentSize = CGSizeMake([UIScreen mainScreen].bounds.size.width, 300);
    NSLog(@"%s",__func__);
    
    // Do any required interface initialization here.
}

- (void)didReceiveNotification:(UNNotification *)notification {
    NSLog(@"%s",__func__);
    self.label.text = notification.request.content.body;
    UNNotificationAttachment *atm = notification.request.content.attachments.firstObject;
    if ([atm.URL startAccessingSecurityScopedResource]) {
        [self setVideoWithAtm:atm];
        [atm.URL stopAccessingSecurityScopedResource];
    }
}

- (void)setVideoWithAtm:(UNNotificationAttachment *)atm {
//    AVURLAsset *asset = [[AVURLAsset alloc]initWithURL:atm.URL options:nil];
//    AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc]initWithAsset:asset];
//    generator.appliesPreferredTrackTransform = YES;
//    CMTime time = CMTimeMake(1, 10);
//    NSError *error = nil;
//    CMTime actualTime;
//    CGImageRef imageRef = [generator copyCGImageAtTime:time actualTime:&actualTime error:&error];
//    if (error) {
//        NSLog(@"error:%@",error.localizedDescription);
//        return;
//    }
//    UIImage *thumb = [UIImage imageWithCGImage:imageRef];
//    CGImageRelease(imageRef);
//    self.imageView.image = thumb;
    
    self.player = [AVPlayer playerWithURL:atm.URL];
    self.layer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    self.layer.frame = self.imageView.bounds;
    self.layer.videoGravity = AVLayerVideoGravityResize;
    [self.imageView.layer addSublayer:self.layer];
    
}

- (void)setImageWithAtm:(UNNotificationAttachment *)atm {
    NSString *path = atm.URL.path;
    NSData *data = [NSData dataWithContentsOfFile:path];
    UIImage *image = [UIImage imageWithData:data];
    self.imageView.image = image;
}

@end
