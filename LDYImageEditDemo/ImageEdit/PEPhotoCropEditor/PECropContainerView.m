//
//  PECropContainerView.m
//  PEPhotoCropEditor
//
//  Created by yang on 16/1/20.
//  Copyright © 2016年 kishikawa katsumi. All rights reserved.
//

#import "PECropContainerView.h"
#import "PECropView.h"
#import "UIColor+LDYCategory.h"

@interface PECropContainerView ()
@property (nonatomic, strong) PECropView        *cropView;
@property (nonatomic, strong) UIImage           *image;
@property (nonatomic, strong) NSArray           *buttonInfoArray;
@property (nonatomic, assign) NSInteger         angleValue;
@property (nonatomic, assign) BOOL              isChange;
@end

@implementation PECropContainerView
@synthesize rotationEnabled = _rotationEnabled;

- (instancetype)initWithFrame:(CGRect)frame withImage:(UIImage *)image
{
    self = [super initWithFrame:frame];
    if (self) {
        [self createCropView];
        self.image = image;
        self.layer.masksToBounds = YES;

        _buttonInfoArray = @[@{@"title":@"撤销",@"img" : @"100"},
                             @{@"title":@"左90",@"img" : @"21"},
                             @{@"title":@"右90",@"img" : @"22"},
                             @{@"title":@"方",@"img" : @"23"},
                             ];
        [self createButtons];
    }
    return self;
}
- (void)createCropView
{
    if (!_cropView) {
        _cropView = [[PECropView alloc] initWithFrame:self.bounds];
        _cropView.square = NO;
        [self addSubview:_cropView];
    }
}
- (UIImage *)cropEndImage
{
    return self.cropView.croppedImage;
}
- (void)createButtons
{
    
    UIView *contentView = [[UIView alloc]initWithFrame:CGRectMake(20.0, self.frame.size.height - 60.0, self.frame.size.width - 40.0, 60.0)];
    contentView.layer.cornerRadius = 5.0;
    contentView.layer.masksToBounds = YES;
    contentView.backgroundColor = [UIColor colorWithHexRGB:@"333338"];
    [self addSubview:contentView];
    
    CGFloat buttonBGW = contentView.frame.size.width / _buttonInfoArray.count;
    CGFloat buttonH = 50;
    CGFloat buttonW = buttonH;
    CGFloat buttonY = (contentView.frame.size.height - buttonH) / 2.0;
    CGFloat buttonX;
    
    for (NSInteger i = 0; i < _buttonInfoArray.count; i++) {
        buttonX = buttonBGW * i + (buttonBGW - buttonW) / 2.0;
        UIButton *button = [[UIButton alloc]initWithFrame:CGRectMake(buttonX, buttonY, buttonW, buttonH)];
//        [button setTitle:_buttonInfoArray[i][@"title"] forState:UIControlStateNormal];
//        button.titleLabel.font = [UIFont systemFontOfSize:15];
        [button setImage:[UIImage imageNamed:[NSString stringWithFormat:@"image_scrawl_%@_n",_buttonInfoArray[i][@"img"]]] forState:UIControlStateNormal];
        button.tag = 100 + i;
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
        [contentView addSubview:button];
    }
    
//    UIButton *cancelButton = [[UIButton alloc]initWithFrame:CGRectMake(0, 20, 50, 44)];
//    [cancelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
//    [cancelButton setTitle:@"取消" forState:UIControlStateNormal];
//    cancelButton.titleLabel.font = [UIFont systemFontOfSize:15];
//    cancelButton.tag = 1001;
//    [cancelButton addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
//    [self addSubview:cancelButton];
//    
//    UIButton *doneButton = [[UIButton alloc]initWithFrame:CGRectMake(self.frame.size.width - 50, 20, 50, 44)];
//    [doneButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
//    [doneButton setTitle:@"完成" forState:UIControlStateNormal];
//    doneButton.titleLabel.font = [UIFont systemFontOfSize:15];
//    doneButton.tag = 1002;
//    [doneButton addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
//    [self addSubview:doneButton];
}
- (void)buttonClicked:(UIButton *)button
{
    _isChange = YES;
    if (button.tag == 100) {
        [_cropView setRotationAngle:0];
    }

    if (button.tag == 101) {
        _angleValue --;
        _angleValue = _angleValue % 4;
        [_cropView setRotationAngle:-0.5 * _angleValue * M_PI];
    }
    if (button.tag == 102) {
        _angleValue ++;
        _angleValue = _angleValue % 4;
        [_cropView setRotationAngle:0.5 * _angleValue * M_PI];
    }
    if (button.tag == 103) {
        _cropView.square = !_cropView.square;
        [_cropView layoutSubviews];
    }
    if (button.tag == 1001) {
        [self cancel:button];
    }
    if (button.tag == 1002) {
        [self done:button];
    }
}
- (void)setImage:(UIImage *)image
{
    _image = image;
    _cropView.image = image;
}
- (void)setKeepingCropAspectRatio:(BOOL)keepingCropAspectRatio
{
    _keepingCropAspectRatio = keepingCropAspectRatio;
    self.cropView.keepingCropAspectRatio = self.keepingCropAspectRatio;
}

- (void)setCropAspectRatio:(CGFloat)cropAspectRatio
{
    _cropAspectRatio = cropAspectRatio;
    self.cropView.cropAspectRatio = self.cropAspectRatio;
}

- (void)setCropRect:(CGRect)cropRect
{
    _cropRect = cropRect;
    _imageCropRect = CGRectZero;
    
    CGRect cropViewCropRect = self.cropView.cropRect;
    cropViewCropRect.origin.x += cropRect.origin.x;
    cropViewCropRect.origin.y += cropRect.origin.y;
    
    CGSize size = CGSizeMake(fmin(CGRectGetMaxX(cropViewCropRect) - CGRectGetMinX(cropViewCropRect), CGRectGetWidth(cropRect)),
                             fmin(CGRectGetMaxY(cropViewCropRect) - CGRectGetMinY(cropViewCropRect), CGRectGetHeight(cropRect)));
    cropViewCropRect.size = size;
    self.cropView.cropRect = cropViewCropRect;
}

- (void)setImageCropRect:(CGRect)imageCropRect
{
    _imageCropRect = imageCropRect;
    _cropRect = CGRectZero;
    
    self.cropView.imageCropRect = imageCropRect;
}

- (BOOL)isRotationEnabled
{
    return _rotationEnabled;
}

- (void)setRotationEnabled:(BOOL)rotationEnabled
{
    _rotationEnabled = rotationEnabled;
    self.cropView.rotationGestureRecognizer.enabled = _rotationEnabled;
}

- (CGAffineTransform)rotationTransform
{
    return self.cropView.rotation;
}

- (CGRect)zoomedCropRect
{
    return self.cropView.zoomedCropRect;
}

- (void)resetCropRect
{
    [self.cropView resetCropRect];
}

- (void)resetCropRectAnimated:(BOOL)animated
{
    [self.cropView resetCropRectAnimated:animated];
}

#pragma mark -

- (void)cancel:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(cropContainerViewDidCancel:)]) {
        [self.delegate cropContainerViewDidCancel:self];
    }
}

- (void)done:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(cropContainerView:didFinishCroppingImage:transform:cropRect:)]) {
        [self.delegate cropContainerView:self didFinishCroppingImage:self.cropView.croppedImage transform: self.cropView.rotation cropRect: self.cropView.zoomedCropRect];
    } else if ([self.delegate respondsToSelector:@selector(cropContainerView:didFinishCroppingImage:)]) {
        [self.delegate cropContainerView:self didFinishCroppingImage:self.cropView.croppedImage];
    }
}
- (BOOL)isEdited
{
    return _isChange || [_cropView isCrop];
}
@end
