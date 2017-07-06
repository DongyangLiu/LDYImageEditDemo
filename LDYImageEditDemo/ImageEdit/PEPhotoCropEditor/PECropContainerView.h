//
//  PECropContainerView.h
//  PEPhotoCropEditor
//
//  Created by yang on 16/1/20.
//  Copyright © 2016年 kishikawa katsumi. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PECropContainerView;

@protocol PECropContainerViewDelegate <NSObject>
- (void)cropContainerView:(PECropContainerView *)containerView didFinishCroppingImage:(UIImage *)croppedImage;
- (void)cropContainerView:(PECropContainerView *)containerView didFinishCroppingImage:(UIImage *)croppedImage transform:(CGAffineTransform)transform cropRect:(CGRect)cropRect;
- (void)cropContainerViewDidCancel:(PECropContainerView *)containerView;
@end

@interface PECropContainerView : UIView
@property (nonatomic, weak) id <PECropContainerViewDelegate> delegate;
@property (nonatomic, assign) BOOL keepingCropAspectRatio;
@property (nonatomic, assign) CGFloat cropAspectRatio;
@property (nonatomic, assign) CGRect cropRect;
@property (nonatomic, assign) CGRect imageCropRect;
@property (nonatomic, assign, getter = isRotationEnabled) BOOL rotationEnabled;
@property (nonatomic, readonly) CGAffineTransform rotationTransform;
@property (nonatomic, readonly) CGRect zoomedCropRect;

- (instancetype)initWithFrame:(CGRect)frame withImage:(UIImage *)image;
- (UIImage *)cropEndImage;
- (BOOL)isEdited;
@end
