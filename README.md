# iOS推送小结
介绍普通推送、多媒体推送等推送的开发。<br>

# 普通推送基本设置
### 1. 创建项目，开启远程推送功能

在Cababilities中打开Push Notification开关
![PushNotificationSwitch](https://github.com/sleepEarlier/iOS-Push/raw/master/images/00-pushconfig.png)

### 2. 编码
注册通知<br>
```
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
#import <UserNotifications/UserNotifications.h>
#endif

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	CGFloat sysVersion = [UIDevice currentDevice].systemVersion.floatValue;
    if (sysVersion >= 10.0) {
	UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
	center.delegate = self;
	[center getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
	    UNAuthorizationStatus status = settings.authorizationStatus;
	    if (status == UNAuthorizationStatusNotDetermined) {
		UNAuthorizationOptions options = UNAuthorizationOptionBadge | UNAuthorizationOptionAlert | UNAuthorizationOptionSound;
		[center requestAuthorizationWithOptions:options completionHandler:^(BOOL granted, NSError * _Nullable error) {
		    if (granted) {
			NSLog(@"Auth suc");
			[application registerForRemoteNotifications];
		    } else {
			NSLog(@"Auth fail:%@",error.localizedDescription);
		    }
		}];
	    }
	    else if (status == UNAuthorizationStatusDenied) {
		NSLog(@"用户关闭了通知，请求用户跳转设置开启通知");
		[application openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
	    }
	    else {
		NSLog(@"已经开启了通知");
		NSLog(@"Auth settings:%@",settings);
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
```

```Objective-C
- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
	// 此代理方法iOS8及以上会调用，iOS10 使用UNNotification.framewrok不会调用
	[application registerForRemoteNotifications];
}
```

注册通知失败

```Objective-C
- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
  // 处理注册通知失败
}
```

获取token
```Objective-C
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
  // 上报token给服务端
}
```

接收通知

```Objective-C
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
 // 收到通知
}
```

到此，初步完成了推送功能，后端可以使用客户端上报的token给客户端推送消息了。
此时，客户端接收推送的情况是：
	
	1. 客户端在前台运行，屏幕/通知中心不会出现推送Banner，程序会执行`application:didReceiveRemoteNotification:` 方法
	2. 客户端不在前台，屏幕/通知中心出现推送Banner，程序不执行`application:didReceiveRemoteNotification:` 方法

此时，点击推送启动App的情况是：
	1. `application:didFinishLaunchingWithOptions:`的`launchOptions`中会包含`UIApplicationLaunchOptionsRemoteNotificationKey`，内容是通知的`UserInfo`
	2. `application:didReceiveRemoteNotification:` 在启动过程中不会被调用


# 静默推送<br>

有一些场景下，我们希望App在后台收到推送时，能知道收到了推送，并做出一些反应（比如UI上的变动）。这就需要开启静默推送。

### 工程配置
在Cababilities中打开Background Modes的Remote Notifications(静默推送)，Info中会有对应的KeyValue自动添加。
![BackgroundMode](https://github.com/sleepEarlier/iOS-Push/raw/master/images/01-pushconfig.png)

### 编码

实现后台获取的对应方法

```
/*! This delegate method offers an opportunity for applications with the "remote-notification" background mode to fetch appropriate new data in response to an incoming remote notification. You should call the fetchCompletionHandler as soon as you're finished performing that operation, so the system can accurately estimate its power and data cost.
 
 This method will be invoked even if the application was launched or resumed because of the remote notification. The respective delegate methods will be invoked first. Note that this behavior is in contrast to application:didReceiveRemoteNotification:, which is not called in those cases, and which will not be invoked if this method is implemented. !*/
 
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler {
	// 处理获取到的通知
	...
	completionHandler(UIBackgroundFetchResultNewData);
}
```
实现了此方法，则`application:didReceiveRemoteNotification:` 不会被调用。而且这个方法在App因为通知启动或者`resumed`的时候也会被调用。

### 推送内容设置

```
{
  "aps" : {
    "alert" : {
      "title" : "Message",
      "body" : "Your message Here"
    },
    "badge" : 1,
    "content-available" : 1
  }
}
```
`aps` 字段中需要包含有`"content-available" : 1`，否则App在后台无法感知收到推送，也就是上面的方法`application:didReceiveRemoteNotification:fetchCompletionHandler:`不会调用

完成以上，程序可以在后台通过上面的方法获取到通知的内容了。


# 前台展示推送

以上，代码中并没有实现`UNUserNotificationCenterDelegate` 协议中的方法。当我们实现协议中`userNotificationCenter:willPresentNotification:withCompletionHandler:` 方法时，程序在前台收到推送也会展示Banner。

```
// The method will be called on the delegate only if the application is in the foreground. If the method is not implemented or the handler is not called in a timely manner then the notification will not be presented. The application can choose to have the notification presented as a sound, badge, alert and/or in the notification list. This decision should be based on whether the information in the notification is otherwise visible to the user.

-(void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {
	completionHandler(UNNotificationPresentationOptionBadge|
				      UNNotificationPresentationOptionSound|
					  UNNotificationPresentationOptionAlert);
}
```

# Notification Service Extension

iOS 10后新增了Notification Service Extension，开发者可以对推送进行预处理，以展示更丰富的推送内容，比如附加图片，或者根据当前用户来修改推送消息等。

### 创建Notification Service Extension

在工程中原开发工程中新建一个Target，选择`Notification Service Extension` ，并根据Xcode提示激活此Target。新Target的Bundle Id应该在原工程Bundle Id的命名空间下，如原工程Bundle Id为com.demo.push，新Target的Bundle Id应为com.demo.push.xxx，如com.demo.push.notificationServiceExtension
![CreateServiceExtension](https://github.com/sleepEarlier/iOS-Push/raw/master/images/03-serveive%20Extension.png)

完成后工程中会生成对应的文件，在.m中有两个方法:
一是对收到的推送进行处理的方法，在这个方法中主要对`UNNotificationContent` 进行修改，最后必须调用`contentHandler` 。下面是默认的实现，只是对推送的`title` 进行了修改。

```
- (void)didReceiveNotificationRequest:(UNNotificationRequest *)request withContentHandler:(void (^)(UNNotificationContent * _Nonnull))contentHandler{
	// Modify the notification content here...
	self.contentHandler = contentHandler;
    self.bestAttemptContent = [request.content mutableCopy];
	self.bestAttemptContent.title = [NSString stringWithFormat:@"%@ [modified]", self.bestAttemptContent.title];
	self.contentHandler(self.bestAttemptContent);
}
```

为了能在Notification Service Extension中去下载其他附件，我们必须去按照如下的要求去设置推送通知，使推送通知是动态可变的。

```
{
    aps: {
        alert : {……}
        mutable-content : 1
    }
    my-attachment : https://example.com/example.jpg"
}
```
必须在`aps` 中包含`mutable-content : 1` 的内容，推送才会进入Service Extension中被处理，`my-attachment` 是自定义字段。这样我们就可以在Notification Service Extension 中，下载`my-attachment` 中URL的图片，添加到推送内容中再展示。

```
- (void)didReceiveNotificationRequest:(UNNotificationRequest *)request withContentHandler:(void (^)(UNNotificationContent * _Nonnull))contentHandler{
	...
	// UNNotificationAttachment中的URL为文件URL，形如 file://xxx/xxx/x.png
	[self downloadImageFinished:^(NSURL *fileURL){
		UNNotificationAttachment *atm = [UNNotificationAttachment attachmentWithIdentifier:@"" 
					 URL:url 
				 options:nil error:&error];
		self.bestAttemptContent.attachments = @[atm];
	}];
	...
}
```

效果示例:

 <img src="https://github.com/sleepEarlier/iOS-Push/raw/master/images/05-service.gif" width = "220" height = "388" alt="showImageInNotification" align=center />
 

开发者总共有**30秒**的时间来对推送内容进行处理，可以在这个过程中下载图片、小视频等。如果超过时间还没有在上面方法中调用`contentHandler` ，系统会在另一个线程调用下面的方法给开发者最后调用`contentHandler` 的机会，如果在这个方法中`contentHandler`还是 没有被调用，推送会以原来的内容被展示到手机上。

```
- (void)serviceExtensionTimeWillExpire {
    // Called just before the extension will be terminated by the system.
    // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
    self.contentHandler(self.bestAttemptContent);
}
```


### 调试Notification Service Extension

运行的Scheme选择新建的Service Extension，选择关联的App运行，这样断点可以在Service Extension生效。
![RunServiceExtension](https://github.com/sleepEarlier/iOS-Push/raw/master/images/08--run.png)

![RunServiceExtensionWithApp](https://github.com/sleepEarlier/iOS-Push/raw/master/images/09-RunAs.png)


### 打包

打包时，选择App对应的Scheme即可，与正常打包流程没有差别（CI打包也无差别）。使用Xcode打包过程中可以看到Extension已经被包含在其中:

![Archive](https://github.com/sleepEarlier/iOS-Push/raw/master/images/10-archive.png)


# Notification Content Extension

`Notification Content Extension` 是一个定制化展示本地和远程通知的插件，开发者可以自定义其中展示的内容，常常会结合上面的Notification Service Extension插件和`UNNotificationCategory` 、 `UNNotificationAction` 使用做成带有交互的推送内容。

 <img src="https://github.com/sleepEarlier/iOS-Push/raw/master/images/13-example.png" width = "220" height = "388" alt="Example" align=center />


<br>

整体流程为：

 1. 注册`Notification Category` ，其中包含Action.
 2. 推送Mutable-Content的通知，在Service Extension中下载对应的多媒体消息，重新生成通知内容，并指定通知的`categoryIdentifier`。
 3. 用户3D-Touch推送会启动`Notification Content Extension`，在其中进行通知的定制化展示。
 4. 用户触发交互（即`UNNotificationAction`）后，在`UNUserNotificationCenter` 代理方法中进行处理。在`Notification Content Extension`中也可以进行初步处理，并决定是否将Action转发到`UNUserNotificationCenter`。

整体效果：

<img src="https://github.com/sleepEarlier/iOS-Push/raw/master/images/06-content.gif" width = "220" height = "388" alt="Example" align=center />


<br>


Demo推送内容：

```
{
  "aps" : {
    "alert" : {
      "title" : "Message",
      "body" : "Your message Here"
    },
    "badge" : 1,
    "content-available" : 1,
    "mutable-content" : 1,
    "catId" : "action1" // 自定义字段,
    }
}
```

### 1. 创建Notification Content Extension

新建一个Target，选择`Notification Content Extension`，其BundleId应该在原项目BundleId的命名空间下。
![CreateContentExtension](https://github.com/sleepEarlier/iOS-Push/raw/master/images/04-content%20Extension.png)

创建后会增加Target的文件：
![ContentExtensionFiles](https://github.com/sleepEarlier/iOS-Push/raw/master/images/10-contentExtension.png)


在`.h`中可以看到其实这是一个`UIViewController`子类，我们可以添加各种视图。

```
// NotificationViewController.h
#import <UIKit/UIKit.h>

@interface NotificationViewController : UIViewController

@end
```


```
// NotificationViewController.m
@interface NotificationViewController () <UNNotificationContentExtension>
```

在`.m`中可以看到这个控制器遵守`UNNotificationContentExtension`协议，协议中有如下方法和属性:

```
@protocol UNNotificationContentExtension <NSObject>

// This will be called to send the notification to be displayed by
// the extension. If the extension is being displayed and more related
// notifications arrive (eg. more messages for the same conversation)
// the same method will be called for each new notification.
- (void)didReceiveNotification:(UNNotification *)notification;

@optional

// If implemented, the method will be called when the user taps on one
// of the notification actions. The completion handler can be called
// after handling the action to dismiss the notification and forward the
// action to the app if necessary.
- (void)didReceiveNotificationResponse:(UNNotificationResponse *)response completionHandler:(void (^)(UNNotificationContentExtensionResponseOption option))completion;

// Implementing this method and returning a button type other that "None" will
// make the notification attempt to draw a play/pause button correctly styled
// for that type.
@property (nonatomic, readonly, assign) UNNotificationContentExtensionMediaPlayPauseButtonType mediaPlayPauseButtonType;

// Implementing this method and returning a non-empty frame will make
// the notification draw a button that allows the user to play and pause
// media content embedded in the notification.
@property (nonatomic, readonly, assign) CGRect mediaPlayPauseButtonFrame;

// The tint color to use for the button.
@property (nonatomic, readonly, copy) UIColor *mediaPlayPauseButtonTintColor;

// Called when the user taps the play or pause button.
- (void)mediaPlay;
- (void)mediaPause;

@end


@interface NSExtensionContext (UNNotificationContentExtension)

// Call these methods when the playback state changes in the content
// extension to update the state of the media control button.
- (void)mediaPlayingStarted __IOS_AVAILABLE(10_0) __TVOS_UNAVAILABLE __WATCHOS_UNAVAILABLE __OSX_UNAVAILABLE;
- (void)mediaPlayingPaused __IOS_AVAILABLE(10_0) __TVOS_UNAVAILABLE __WATCHOS_UNAVAILABLE __OSX_UNAVAILABLE;

@end
```


除了Require的方法之外，`didReceiveNotificationResponse:completionHandler:`负责处理推送Action交互，而其他的用来控制视频的播放。下面的示例中会使用到。

最下方还有一个`NSExtesnsionContext`类，暂时不清楚它怎么使用。

Content Extension的Info.plist中的内容：
![Info](https://github.com/sleepEarlier/iOS-Push/raw/master/images/11-contentInfo.png)

`UNNotificationExtensionDefaultContentHidden`，插件默认会展示推送的内容（Title、subtitle、body，不展示`Attachment`），通过这对键值来控制是否隐藏原始内容。

`UNNotificationExtensionCategory` ，值类型可以为String/Array，通知的类别，只有类别ID在此之中的通知才会进入`Notification Content Extension`中被处理。

`UNNotificationExtensionInitialContentSizeRatio` , 视图的宽高比。视图的最终大小（主要是高度），会受VC的`preferredContentSize` 、sb中的约束和视图高度、这个比例3者的影响。优先级从前到后下降。

### 2. 编码
首先在申请通知权限成功后，设置通知的类别和Action

```
UNNotificationAction *action1 = [UNNotificationAction actionWithIdentifier:@"checkoutAction" title:@"查看" options:UNNotificationActionOptionAuthenticationRequired|UNNotificationActionOptionForeground];

UNTextInputNotificationAction *action2 = [UNTextInputNotificationAction actionWithIdentifier:@"replyAction" title:@"回复" options:0 textInputButtonTitle:@"发送" textInputPlaceholder:@"回复消息"];

// 此处categoryIdentifier应该是上面Info.plist中UNNotificationExtensionCategory包含的值
UNNotificationCategory *cat = [UNNotificationCategory categoryWithIdentifier:@"action1" actions:@[action1,action2] intentIdentifiers:@[] options:UNNotificationCategoryOptionNone];
                        
[center setNotificationCategories:[NSSet setWithObjects:cat, nil]];
                        
[center getNotificationCategoriesWithCompletionHandler:^(NSSet<UNNotificationCategory *> * _Nonnull categories) {
	NSLog(@"get cat:%@",categories);
}];
```

在`Notification Service Extension` 中设置推送的`categoryIdentifier`，如果应用采用了多种Category，一般应该这个标识符包含在推送内容中。

```
- (void)didReceiveNotificationRequest:(UNNotificationRequest *)request withContentHandler:(void (^)(UNNotificationContent * _Nonnull))contentHandler {
	self.contentHandler = contentHandler;
    self.bestAttemptContent = [request.content mutableCopy];
    // 此处省略推送内容的其他修改和附件的下载
    // 下载完成后，使用fileUrl创建附件
    UNNotificationAttachment *atm = [UNNotificationAttachment attachmentWithIdentifier:@"" URL:url options:options error:&error];
	self.bestAttemptContent.attachments = @[atm];
	// 设置categoryIdentifier
	self.bestAttemptContent.categoryIdentifier = request.content.userInfo[@"aps"][@"catId"];
	self.contentHandler(self.bestAttemptContent);
}
```

在`Notification Content Extension` 中定制视图，展示推送内容，此处以视频附件为例。


声明协议中与视频播放相关的属性，实现对应的方法。

```
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

- (void)viewDidLoad {
    [super viewDidLoad];
    // 设置ContentSize
    self.preferredContentSize = CGSizeMake([UIScreen mainScreen].bounds.size.width, 300);
}

- (void)didReceiveNotification:(UNNotification *)notification {
	// 
    self.label.text = notification.request.content.body;
    UNNotificationAttachment *atm = notification.request.content.attachments.firstObject;
    if ([atm.URL startAccessingSecurityScopedResource]) {
        self.player = [AVPlayer playerWithURL:atm.URL];
	    self.layer = [AVPlayerLayer playerLayerWithPlayer:self.player];
	    self.layer.frame = SomeRect;// frame自行计算，此处仅为示例
	    self.layer.videoGravity = AVLayerVideoGravityResizeAspectFill;
	    [self.view.layer addSublayer:self.layer];
        [atm.URL stopAccessingSecurityScopedResource];
    }
}

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

@end
```

由于在视图初始化时，还不能知道推送内容的最终高度，因此最好以一个固定的高度呈现。上面在代码中使用preferredContentSize来设置。
代码中使用AVPlayer和AVPlayerLayer来展示视频附件，其中获取视频URL时，由于Attachment是由系统管理，在沙盒之外，我们访问URL内容时候需要先获取使用权限：

```
if ([atm.URL startAccessingSecurityScopedResource]) {
	...
    [atm.URL stopAccessingSecurityScopedResource];
}
```
