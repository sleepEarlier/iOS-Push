//
//  ViewController.m
//  GodPush
//
//  Created by kimiLin on 2017/5/24.
//  Copyright © 2017年 KimiLin. All rights reserved.
//

#import "ViewController.h"
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
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
