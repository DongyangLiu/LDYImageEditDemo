//
//  LXImageEditViewController.m
//  SealChat
//
//  Created by yang on 16/8/18.
//  Copyright © 2016年 Lianxi.com. All rights reserved.
//

#import "LXImageEditViewController.h"
#import "ACEContainerView.h"
#import "PECropContainerView.h"
#import <objc/runtime.h>

#define kDoneButtonTag 201

NSString *EditSourceImageBoolKey = @"EditSourceImageBoolKey";

@interface LXImageEditViewController ()<UIAlertViewDelegate>

@property (nonatomic, strong) ACEContainerView      *drawingContainerView;
@property (nonatomic, strong) PECropContainerView   *cropContainerView;
@property (nonatomic, strong) NSMutableArray        *editImageOriginalArys;
@property (nonatomic, assign) NSInteger             assetIndex;
@property (nonatomic, strong) UIView                *doCancellView;
@property (nonatomic, strong) UIView                *changeView;
@property (nonatomic, strong) NSMutableArray        *changeButtonArray;
@property (nonatomic, assign) NSInteger             editType; //默认 0， 涂鸦画笔， 1， 涂鸦文字 2,裁剪
@property (nonatomic, strong) NSMutableDictionary   *acePathDict;
@property (nonatomic, strong) NSMutableDictionary   *pecPathDict;
@property (nonatomic, strong) NSMutableDictionary   *textPathDict;
@property (nonatomic, strong) UIScrollView          *scrollView;

@end

@implementation LXImageEditViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.assetIndex = 0;
        _changeButtonArray = [NSMutableArray array];
        _acePathDict = [NSMutableDictionary dictionary];
        _pecPathDict = [NSMutableDictionary dictionary];
        _textPathDict = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    [self createChangeView];
    [self createDoCancellView];
    [self initSetUpInfo];
    _editImageOriginalArys = [NSMutableArray arrayWithArray:_editImageArys];
}
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = YES;
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
}
- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.navigationController.navigationBarHidden = NO;
}

- (void)initSetUpInfo{
    [self.view addSubview:[self drawingContainerView:[self.editImageArys objectAtIndex:0] drawingPath:NO]];
    [_drawingContainerView refreshSubViewWithType:ACEContainerViewTypeGraf];
    [self refreshScrollView];
}
- (void)refreshScrollView
{
    CGFloat width = 44.0;
    CGFloat height = 44.0;
    if (!_scrollView) {
        _scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0.0, 30.0, self.view.frame.size.width, height)];
        _scrollView.contentSize = CGSizeMake(self.editImageArys.count * (width + 10.0), width);
        [self.view addSubview:_scrollView];
    }
    [_scrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    for (NSInteger i = 0 ; i < self.editImageArys.count; i ++) {
        UIImage *image = [self.editImageArys objectAtIndex:i];
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(5.0 + i * (width + 10.0), 0, width, height)];
        imageView.tag = i;
        imageView.image = image;
        imageView.userInteractionEnabled = YES;
        [_scrollView addSubview:imageView];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tag:)];
        [imageView addGestureRecognizer:tap];
    }

}
- (void)tag:(UITapGestureRecognizer *)tap
{
    UIImageView *imageView = (UIImageView *)tap.view;
    UIImage *assetImage = [self.editImageOriginalArys objectAtIndex:imageView.tag];
    NSInteger index = [self.editImageOriginalArys indexOfObject:assetImage];
    
    if (_editType == 2) {
        assetImage = [self.editImageArys objectAtIndex:imageView.tag];
    }

    if (index == self.assetIndex) {
        NSLog(@"已经是当前的 %@",assetImage);
        return;
    }
    else{
        [self refreshEditImage:self.assetIndex];
        [self reloadIndex:index assetImage:assetImage];

    }
}
//更新编辑后图片到数组
- (void)refreshEditImage:(NSInteger)index
{
    UIImage *assetImage = [self.editImageArys objectAtIndex:index];
    if (_drawingContainerView) {
        assetImage = [self.drawingContainerView drawingEndImage];
    }
    if (_cropContainerView) {
        assetImage = [self.cropContainerView cropEndImage];
    }
    [self.editImageArys replaceObjectAtIndex:index withObject:assetImage];
}
//更新图片
- (void)reloadIndex:(NSInteger)index assetImage:(UIImage *)assetImage
{
    if (_editType == 1) {
        [_drawingContainerView endTextEdit];
    }
    if (_drawingContainerView) {
        [self saveAcePath];
        [self saveTextPath];
    }
    self.assetIndex = index;

    if (_drawingContainerView) {
        //涂鸦状态下切换图片
        [self removeDrawingContainerView];
        [self.view addSubview:[self drawingContainerView:assetImage drawingPath:YES]];
        if (_editType == 0) {
            [_drawingContainerView refreshSubViewWithType:ACEContainerViewTypeGraf];
            [_drawingContainerView setDrawTool:ACEDrawingToolTypePen];
            
        }
        if (_editType == 1) {
            [_drawingContainerView refreshSubViewWithType:ACEContainerViewTypeText];
            [_drawingContainerView setDrawTool:ACEDrawingToolTypeText];
        }
    }
    if (_cropContainerView) {
        //裁剪状态下切换图片
        [self removeCropContainerView];
        [self.view addSubview:[self cropContainerView:assetImage]];
    }
    
    NSNumber *number =  objc_getAssociatedObject(assetImage, &EditSourceImageBoolKey);
    _drawingContainerView.userInteractionEnabled = ![number boolValue];
    _cropContainerView.userInteractionEnabled = ![number boolValue];
    [self refreshScrollView];
}
#pragma mark - ACEContainerView、PECropContainerView

static CGFloat needHeight = 20 + 64.0;
static CGFloat bottomHeight = 115.0;
- (ACEContainerView *)drawingContainerView:(UIImage *)assetImage drawingPath:(BOOL)drawingPath
{
    if (!self.editImageArys) {
        return nil;
    }    
    if (!_drawingContainerView)
    {
        UIImage *image = nil;

        if (assetImage) {
            image = assetImage;
        }else{
            image = [self.editImageOriginalArys objectAtIndex:_assetIndex];
        }
        _drawingContainerView = [[ACEContainerView alloc]initWithFrame:CGRectMake(0, needHeight, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame) - needHeight - bottomHeight) withImage:image];
        _drawingContainerView.backgroundColor = [UIColor blackColor];
        if (drawingPath) {
            [_drawingContainerView setPathArray:[_acePathDict valueForKey:[NSString stringWithFormat:@"%ld",(unsigned long)self.assetIndex]]];
            [_drawingContainerView setTextPathDict:[_textPathDict valueForKey:[NSString stringWithFormat:@"%ld",(unsigned long)self.assetIndex]]];
            
        }
    }
    return _drawingContainerView;
}


- (PECropContainerView *)cropContainerView:(UIImage *)assetImage
{
    if (!_cropContainerView)
    {
        UIImage *image = nil;
        if (_drawingContainerView) {
            image = [_drawingContainerView drawingEndImage];
        }else{
            image = assetImage;
        }
        _cropContainerView = [[PECropContainerView alloc]initWithFrame:CGRectMake(0, needHeight, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame) - needHeight - bottomHeight) withImage:image];
        _cropContainerView.backgroundColor = [UIColor blackColor];
    }
    return _cropContainerView;
}

#pragma mark - remove
- (void)removeDrawingContainerView
{
    if (_drawingContainerView) {
        [_drawingContainerView removeFromSuperview];
        _drawingContainerView = nil;
    }
}
- (void)saveAcePath
{
    [_acePathDict setValue:[_drawingContainerView pathArray] forKey:[NSString stringWithFormat:@"%ld",(unsigned long)self.assetIndex]];
}
- (void)clearAcePath
{
    [_acePathDict setValue:nil forKey:[NSString stringWithFormat:@"%ld",(unsigned long)self.assetIndex]];
}
- (void)saveTextPath
{
    [_textPathDict setValue:[_drawingContainerView textPathDict] forKey:[NSString stringWithFormat:@"%ld",(unsigned long)self.assetIndex]];
}
- (void)clearTextPath
{
    [_textPathDict removeObjectForKey:[NSString stringWithFormat:@"%ld",(unsigned long)self.assetIndex]];
}
- (void)reloadOriginalImageArys:(NSInteger)index
{
    if (index < self.editImageArys.count) {
        UIImage *assetImage = [self.editImageArys objectAtIndex:index];
        [self.editImageOriginalArys replaceObjectAtIndex:index withObject:assetImage];
    }
}
- (void)removeCropContainerView
{
    if (_cropContainerView) {
        [_cropContainerView removeFromSuperview];
        _cropContainerView = nil;
    }
}

#pragma mark - view
- (void)createDoCancellView
{
    if (!_doCancellView) {
        _doCancellView = [[UIView alloc]initWithFrame:CGRectMake(0, self.view.frame.size.height - 55, self.view.frame.size.width, 55.0)];
        
        UIButton *cancellButton = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, _doCancellView.bounds.size.width / 2.0, _doCancellView.bounds.size.height)];
        [cancellButton setTitle:@"取消" forState:UIControlStateNormal];
        [cancellButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        cancellButton.titleLabel.font = [UIFont systemFontOfSize:14];
        cancellButton.tag = 1001;
        [cancellButton addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
        [_doCancellView addSubview:cancellButton];
        
        UIButton *sureButton = [[UIButton alloc]initWithFrame:CGRectMake(_doCancellView.bounds.size.width / 2.0, 0, _doCancellView.bounds.size.width / 2.0, _doCancellView.bounds.size.height)];
        [sureButton setTitle:@"完成" forState:UIControlStateNormal];
        [sureButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        sureButton.titleLabel.font = [UIFont systemFontOfSize:14];
        [sureButton setImage:[UIImage imageNamed:@"image_edite_success"] forState:UIControlStateNormal];
        
        CGSize iSize = sureButton.imageView.image.size;
        CGSize tSize = sureButton.titleLabel.frame.size;
        
        [sureButton setTitleEdgeInsets:UIEdgeInsetsMake(0, -iSize.width - tSize.width, 0, 0)];
        [sureButton setImageEdgeInsets:UIEdgeInsetsMake(0, tSize.width + iSize.width * 2, 0, 0)];
        sureButton.tag = 1002;
        [sureButton addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
        [_doCancellView addSubview:sureButton];
    }
    [self.view addSubview:_doCancellView];
}
- (void)createChangeView
{
    if (!_changeView) {
        _changeView = [[UIView alloc]initWithFrame:CGRectMake(0, self.view.frame.size.height - 115.0, self.view.frame.size.width, 60.0)];
        
        NSArray *infoArray = @[@{@"title" : @"切换",@"img" : @"11"},
                               @{@"title" : @"涂鸦",@"img" : @"12"},
                               @{@"title" : @"文字",@"img" : @"13"}];
        CGFloat cW = _changeView.frame.size.width / infoArray.count;
        CGFloat cY = 0;
        CGFloat cH = _changeView.frame.size.height;
        CGFloat cX = 0;
        for (NSInteger i = 0; i < infoArray.count; i++) {
            cX = i * cW;
            UIButton *button = [[UIButton alloc]initWithFrame:CGRectMake(cX, cY, cW, cH)];
            [button setImage:[UIImage imageNamed:[NSString stringWithFormat:@"image_scrawl_%@_n",infoArray[i][@"img"]]] forState:UIControlStateNormal];
            [button setImage:[UIImage imageNamed:[NSString stringWithFormat:@"image_scrawl_%@_s",infoArray[i][@"img"]]] forState:UIControlStateSelected];
            [button addTarget:self action:@selector(changeButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
            button.tag = 2000 + i;
            [_changeButtonArray addObject:button];
            [_changeView addSubview:button];
        }
        UILabel *line = [[UILabel alloc]initWithFrame:CGRectMake(20.0, _changeView.frame.size.height - 1.0, _changeView.frame.size.width - 40.0, 1.0)];
        line.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.2];
        [_changeView addSubview:line];
    }
    [self.view addSubview:_changeView];
}
#pragma mark - action
- (void)changeButtonClicked:(UIButton *)button
{
    if (button.isSelected == YES) {
        return;
    }
    for (UIButton *object in _changeButtonArray) {
        object.selected = NO;
    }

    button.selected = YES;
    if (_editType == 1) {
        [_drawingContainerView endTextEdit];
        [self refreshEditImage:self.assetIndex];
    }
    if (_drawingContainerView) {
        [self saveAcePath];
        [self saveTextPath];
    }
    if (button.tag % 2000 == 0) {
        _editType = 2;
        [self.view addSubview:[self cropContainerView:nil]];
        [self removeDrawingContainerView];
    }
    if (button.tag % 2000 == 1) {
        _editType = 0;
        if (_drawingContainerView) {
            
        }else{
            [self.view addSubview:[self drawingContainerView:nil drawingPath:YES]];
            [self removeCropContainerView];
        }
        [_drawingContainerView refreshSubViewWithType:ACEContainerViewTypeGraf];
        [_drawingContainerView setDrawTool:ACEDrawingToolTypePen];
    }
    if (button.tag % 2000 == 2) {
        _editType = 1;
        if (_drawingContainerView) {
            
        }else{
            [self.view addSubview:[self drawingContainerView:nil drawingPath:YES]];
            [self removeCropContainerView];
        }
        [_drawingContainerView refreshSubViewWithType:ACEContainerViewTypeText];
         [_drawingContainerView setDrawTool:ACEDrawingToolTypeText];

    }
}
- (void)buttonClicked:(UIButton *)button
{
    if (button.tag == 1001) {
        [self cancleButtonClicked:button];
    }
    if (button.tag == 1002) {
        [self doneButtonClicked:button];
    }
}
- (void)cancleButtonClicked:(UIButton *)item
{
    if (self.navigationController.viewControllers.count > 1) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        if (self.presentingViewController) {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
}

- (void)doneButtonClicked:(UIButton *)item
{
    //完成时保存最后一张的编辑
    [self refreshEditImage:self.assetIndex];
    //返回最后结果
    if (self.editedBlock) {
        self.editedBlock(self.editImageArys);
    }
}
@end
