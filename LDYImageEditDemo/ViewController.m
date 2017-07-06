//
//  ViewController.m
//  LDYImageEditDemo
//
//  Created by yang on 2017/7/6.
//  Copyright © 2017年 Lianxi.com. All rights reserved.
//

#import "ViewController.h"
#import "ACEContainerView.h"
#import "PECropContainerView.h"
#import "LXImageEditViewController.h"

@interface ViewController ()
@property (nonatomic, strong) ACEContainerView      *drawingContainerView;
@property (nonatomic, strong) PECropContainerView   *cropContainerView;
@property (nonatomic, strong) NSMutableArray *editImageArys;
@property (nonatomic, strong) NSMutableArray        *editImageOriginalArys;

@property (nonatomic, assign) NSInteger             editType; //默认 0， 涂鸦画笔， 1， 涂鸦文字 2,裁剪
@property (nonatomic, strong) NSMutableDictionary   *acePathDict;
@property (nonatomic, strong) NSMutableDictionary   *pecPathDict;
@property (nonatomic, strong) NSMutableDictionary   *textPathDict;
@property (nonatomic, strong) UIScrollView          *scrollView;
@property (nonatomic, assign) NSInteger             assetIndex;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIButton *button = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, 100, 50)];
    [button setTitle:@"编辑" forState:UIControlStateNormal];
    [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:15];
    button.center = CGPointMake(self.view.bounds.size.width / 2.0, self.view.bounds.size.height / 2.0);
    [button addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
}
- (void)buttonClicked:(UIButton *)button
{
    NSMutableArray *array = [NSMutableArray array];
    for (int i = 0; i < 9; i++) {
        UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"image_%d",i]];
        [array addObject:image];
        
    }
    LXImageEditViewController *editVC = [[LXImageEditViewController alloc]init];
    editVC.editImageArys = array;
    editVC.editedBlock = ^(NSMutableArray *editImageArys){
        NSLog(@"编辑后图片");
    };
    UINavigationController *navVC = [[UINavigationController alloc] initWithRootViewController:editVC];
    [self presentViewController:navVC animated:YES completion:nil];
    
}
@end
