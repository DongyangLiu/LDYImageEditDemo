//
//  ACEDrawingScrollView.m
//  ACEDrawingViewDemo
//
//  Created by yang on 16/1/13.
//  Copyright © 2016年 Stefano Acerbetti. All rights reserved.
//

#import "ACEDrawingScrollView.h"
@interface ACEDrawingScrollView()<UIScrollViewDelegate>
@property (nonatomic, assign)   CGSize          mainSize;
@property (nonatomic, assign)   CGFloat         scale;
@property (nonatomic, strong)   ACEDrawingView            *drawingBGView;

@end

@implementation ACEDrawingScrollView
- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
//        _mainSize = [[[UIApplication sharedApplication] delegate] window].bounds.size;
        _mainSize = frame.size;
        _scale = 2;
        self.maximumZoomScale = _scale;
        self.minimumZoomScale = 1.0;
        self.delegate = self;
        [self setImageView];
    }
    return self;
}
-(void)layoutSubviews{
    [super layoutSubviews];
    _drawingBGView.frame = _drawingView.frame;
}
- (void)setImageView
{
    if (!_drawingView) {
        _drawingBGView = [[ACEDrawingView alloc]initWithFrame:CGRectMake(0, 0, self.frame.size.width, 200)];
        _drawingBGView.center = CGPointMake(CGRectGetWidth(self.frame) / 2.0, CGRectGetHeight(self.frame) / 2.0);
        _drawingBGView.clipsToBounds = YES;
        _drawingBGView.userInteractionEnabled = NO;
        _drawingBGView.drawMode = ACEDrawingModeScale;
        [self addSubview:_drawingBGView];
        
        _drawingView = [[ACEDrawingView alloc]initWithFrame:CGRectMake(0, 0, self.frame.size.width, 200)];
        _drawingView.center = CGPointMake(CGRectGetWidth(self.frame) / 2.0, CGRectGetHeight(self.frame) / 2.0);
        _drawingView.clipsToBounds = YES;
        _drawingView.drawMode = ACEDrawingModeScale;
        [self addSubview:_drawingView];

        
//        UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(doubleTap:)];
//        doubleTap.numberOfTapsRequired = 2;
//        doubleTap.numberOfTouchesRequired = 1;
//        [self addGestureRecognizer:doubleTap];
    }
    [self recoverNormalScale];
}
- (void)loadingImage:(UIImage *)image
{
    CGFloat factor = 1;
    if (image != nil) {
        factor = image.size.width / image.size.height;
    }
    CGFloat x;
    CGFloat y;
    CGFloat width;
    CGFloat height;
    if (factor > _mainSize.width / _mainSize.height ) {
        width = _mainSize.width;
        height = _mainSize.width / factor;
        x = 0.0;
        y = _mainSize.height / 2.0 - height / 2.0;
    }else{
        height = _mainSize.width / factor;
        width = _mainSize.width;
        x = _mainSize.width / 2.0 - width / 2.0;
        y = 0.0;
    }
    _drawingView.frame = CGRectMake(x, y, width, height);
    _drawingBGView.frame = CGRectMake(x, y, width, height);

    self.contentSize = CGSizeMake(MAX(self.frame.size.width, _drawingView.frame.size.width), MAX(self.frame.size.height, _drawingView.frame.size.height));
    _drawingView.center = CGPointMake(CGRectGetWidth(self.frame) / 2.0, CGRectGetHeight(self.frame) / 2.0);
    _drawingBGView.center = CGPointMake(CGRectGetWidth(self.frame) / 2.0, CGRectGetHeight(self.frame) / 2.0);
    
    [_drawingView loadImage:image];
    [_drawingBGView loadImage:image];
}
#pragma mark - tap

- (void)doubleTap:(UITapGestureRecognizer *)tap
{
    UIImage *dealImage = _drawingView.image;
    if (dealImage != nil) {//图片加载成功
        //判定触摸点是否在图片内部
        CGPoint point = _drawingView.center;
        if (tap) {
            point = [tap locationInView:_drawingView];//获取触摸点相对于image的坐标
        }
        CGFloat tempX = _drawingView.frame.size.width;
        CGFloat tempY = _drawingView.frame.size.height;
        
        CGFloat pointX = point.x * self.zoomScale;
        CGFloat pointY = point.y * self.zoomScale;
        
        if (pointX > 0.0 && pointY > 0.0 && pointX < tempX && pointY < tempY) {
            if (self.zoomScale >= _scale) {//当前图片已经最大化
                [self zoomToRect:[self getRectWithScale:1 andCenter:point] animated:YES];
            } else {//当前图片未最大化
                [self zoomToRect:[self getRectWithScale:_scale andCenter:point] animated:YES];
            }
        }
    }
}

#pragma mark - UIScrollViewDelegate
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return _drawingView;
}
- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    if (scrollView.zoomScale <= 1.0) {
        CGFloat tempX = 0.0;
        CGFloat tempY = 0.0;
        CGFloat tempW = _drawingView.bounds.size.width * scrollView.zoomScale;
        CGFloat tempH = _drawingView.bounds.size.height * scrollView.zoomScale;
        
        if (tempW <= _mainSize.width) {
            tempX = _mainSize.width / 2.0 - tempW / 2.0;
        }
        if (tempH <= _mainSize.height) {
            tempY = _mainSize.height / 2.0 - tempH / 2.0;
        }
        _drawingView.frame = CGRectMake(tempX, tempY, tempW, tempH);
        _drawingBGView.frame = CGRectMake(tempX, tempY, tempW, tempH);
    }else{
        CGFloat tempX = 0.0;
        CGFloat tempY = 0.0;
        CGFloat tempW = _drawingView.bounds.size.width * scrollView.zoomScale;
        CGFloat tempH = _drawingView.bounds.size.height * scrollView.zoomScale;
        
        if (tempW <= _mainSize.width){
            tempX = _mainSize.width/2 - tempW/2.0;
        }
        
        if (tempH <= _mainSize.height){
            tempY = _mainSize.height/2 - tempH/2.0;
        }
        
        _drawingView.frame = CGRectMake(tempX, tempY, tempW, tempH);
        _drawingBGView.frame = CGRectMake(tempX, tempY, tempW, tempH);
    }
    
}
- (CGRect)getRectWithScale:(CGFloat)scale andCenter:(CGPoint)center
{
    CGRect rect;
    rect.size.width = self.frame.size.width / scale;
    rect.size.height = self.frame.size.height / scale;
    rect.origin.x = center.x - rect.size.width / 2.0;
    rect.origin.y = center.y - rect.size.height / 2.0;
    return rect;
}
- (void)recoverNormalScale
{
    if (self.zoomScale == 1.0) {
        return;
    }
    UIImage *dealImage = _drawingView.image;
    if (dealImage != nil) {//图片加载成功
        //判定触摸点是否在图片内部
        CGPoint point = CGPointMake(_drawingView.bounds.size.width / 2.0, _drawingView.bounds.size.height / 2.0);
        CGFloat tempX = _drawingView.frame.size.width;
        CGFloat tempY = _drawingView.frame.size.height;
        
        CGFloat pointX = point.x * self.zoomScale;
        CGFloat pointY = point.y * self.zoomScale;
        
        if (pointX > 0.0 && pointY > 0.0 && pointX < tempX && pointY < tempY) {
            [self zoomToRect:[self getRectWithScale:1.0 andCenter:point] animated:YES];
        }
    }
}

- (UIImage *)drawingEndImage{
    UIGraphicsBeginImageContextWithOptions(_drawingView.image.size, NO, [UIScreen mainScreen].scale);
    CGRect rect = CGRectMake(0, 0, _drawingView.image.size.width, _drawingView.image.size.height);
    [_drawingBGView.image drawInRect:rect];
    [[_drawingView drawingEndImage] drawInRect:rect];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

@end
