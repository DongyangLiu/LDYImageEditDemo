//
//  ACEContainerView.h
//  ACEDrawingViewDemo
//
//  Created by yang on 16/1/14.
//  Copyright © 2016年 Stefano Acerbetti. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ACEDrawingScrollView.h"

typedef NS_ENUM(NSInteger, ACEContainerViewType) {
    ///涂鸦
    ACEContainerViewTypeGraf,
    ///文字
    ACEContainerViewTypeText
};
@interface ACEContainerView : UIView

- (instancetype)initWithFrame:(CGRect)frame withImage:(UIImage *)image;
- (UIImage *)drawingEndImage;
- (void)loadingImage:(UIImage *)image;
- (void)refreshSubViewWithType:(ACEContainerViewType)containerViewType;
- (void)setDrawTool:(ACEDrawingToolType)doawTool;
- (BOOL)isEdited;

- (NSMutableArray *)pathArray;
- (void)setPathArray:(NSMutableArray *)pathArray;
- (void)endTextEdit;

- (NSMutableDictionary *)textPathDict;
- (void)setTextPathDict:(NSMutableDictionary *)textPathDict;
@end
