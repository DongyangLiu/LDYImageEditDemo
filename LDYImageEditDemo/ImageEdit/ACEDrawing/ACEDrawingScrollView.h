//
//  ACEDrawingScrollView.h
//  ACEDrawingViewDemo
//
//  Created by yang on 16/1/13.
//  Copyright © 2016年 Stefano Acerbetti. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ACEDrawingView.h"

@interface ACEDrawingScrollView : UIScrollView
@property (nonatomic, strong) ACEDrawingView            *drawingView;
//对ACEDrawingView的loadingImage进行处理 增加根据图片大小设置ACEDrawingView的大小
- (void)loadingImage:(UIImage *)image;

- (UIImage *)drawingEndImage;
@end
