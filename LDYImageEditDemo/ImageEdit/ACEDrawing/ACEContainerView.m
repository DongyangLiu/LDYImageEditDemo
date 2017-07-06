//
//  ACEContainerView.m
//  ACEDrawingViewDemo
//
//  Created by yang on 16/1/14.
//  Copyright © 2016年 Stefano Acerbetti. All rights reserved.
//

#import "ACEContainerView.h"
#import "ACEDrawingScrollView.h"
#import "UIColor+LDYCategory.h"

#define kActionSheetColor       100
#define kActionSheetTool        101
#define IOS8_OR_ABOVE [[[UIDevice currentDevice] systemVersion] integerValue] >= 8.0

@interface ACEContainerView()<ACEDrawingViewDelegate,UIActionSheetDelegate>
@property (nonatomic, strong) UIImage                   *image;
@property (nonatomic, strong) ACEDrawingScrollView      *drawingScrollView;
@property (nonatomic, strong) UISlider                  *lineWidthSlider;
@property (nonatomic, strong) UISlider                  *lineAlphaSlider;
@property (nonatomic, strong) UIImageView               *previewImageView;

@property (nonatomic, strong) UIView                    *toolBarView;
@property (nonatomic, strong) UIView                    *funcBarView;
@property (nonatomic, strong) UIButton                  *undoButton;
@property (nonatomic, strong) UIButton                  *redoButton;
@property (nonatomic, strong) UIButton                  *colorButton;
@property (nonatomic, strong) UIButton                  *toolButton;
@property (nonatomic, strong) UIButton                  *alphaButton;
@property (nonatomic, strong) UIButton                  *moveButton;
@property (nonatomic, assign) CGFloat                   originalFrameYPos;
@property (nonatomic, strong) UIView                    *contentView;
@property (nonatomic, assign) ACEContainerViewType      containerViewType;

@end

@implementation ACEContainerView

- (instancetype)initWithFrame:(CGRect)frame withImage:(UIImage *)image
{
    self = [super initWithFrame:frame];
    if (self) {
        _image = image;
        [self showDrawingScrollView];
//        [self createSubView];
        self.layer.masksToBounds = YES;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardWillHideNotification object:nil];
    }
    return self;
}
- (UIImage *)drawingEndImage
{
    return [_drawingScrollView drawingEndImage];//_drawingScrollView.drawingView.image;
}

#pragma mark - Keyboard Events

- (void)keyboardDidShow:(NSNotification *)notification
{
    self.originalFrameYPos = _drawingScrollView.frame.origin.y;
    
    if (IOS8_OR_ABOVE) {
        [self adjustFramePosition:notification];
    }
    else {
        if (UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
            [self landscapeChanges:notification];
        } else {
            [self adjustFramePosition:notification];
        }
    }
}

- (void)landscapeChanges:(NSNotification *)notification {
    CGPoint textViewBottomPoint = [_drawingScrollView.drawingView convertPoint:_drawingScrollView.drawingView.textView.frame.origin toView:self];
    CGFloat textViewOriginY = textViewBottomPoint.y;
    CGFloat textViewBottomY = textViewOriginY + _drawingScrollView.drawingView.textView.frame.size.height;
    
    CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    CGFloat offset = (_drawingScrollView.frame.size.height - keyboardSize.width) - textViewBottomY;
    
    if (offset < 0) {
        CGFloat newYPos = _drawingScrollView.frame.origin.y + offset - 15;
        [UIView animateWithDuration:0.2 animations:^{
            
            _drawingScrollView.frame = CGRectMake(_drawingScrollView.frame.origin.x,newYPos, _drawingScrollView.frame.size.width, _drawingScrollView.frame.size.height);
        }];
        
    }
}
- (void)adjustFramePosition:(NSNotification *)notification {
    CGPoint textViewBottomPoint = [_drawingScrollView.drawingView convertPoint:_drawingScrollView.drawingView.textView.frame.origin toView:self];
    textViewBottomPoint.y += _drawingScrollView.drawingView.textView.frame.size.height;
    
    CGRect screenRect = [[UIScreen mainScreen] bounds];

    
    CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    CGFloat offset = (screenRect.size.height - keyboardSize.height) - textViewBottomPoint.y;
    
    if (offset < 0) {
        CGFloat newYPos = _drawingScrollView.frame.origin.y + offset - 15;
        [UIView animateWithDuration:0.2 animations:^{
            
            _drawingScrollView.frame = CGRectMake(_drawingScrollView.frame.origin.x,newYPos, _drawingScrollView.frame.size.width, _drawingScrollView.frame.size.height);
        }];
        
    }
}

-(void)keyboardDidHide:(NSNotification *)notification
{
    _drawingScrollView.frame = CGRectMake(_drawingScrollView.frame.origin.x,self.originalFrameYPos,_drawingScrollView.frame.size.width,_drawingScrollView.frame.size.height);
}
- (void)showDrawingScrollView
{
    if (!_drawingScrollView) {
        _drawingScrollView = [[ACEDrawingScrollView alloc]initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height - 80)];
        
        _drawingScrollView.drawingView.delegate = self;
        _drawingScrollView.scrollEnabled = NO;
//        _drawingScrollView.drawingView.drawMode = ACEDrawingModeScale;
        //_drawingScrollView.center = CGPointMake(CGRectGetWidth(self.frame) / 2.0, CGRectGetHeight(self.frame) / 2.0);
        _drawingScrollView.backgroundColor = [UIColor clearColor];
    }
    [self addSubview:_drawingScrollView];
    [_drawingScrollView loadingImage:_image];
}
- (void)loadingImage:(UIImage *)image
{
    [_drawingScrollView loadingImage:_image];
}
- (void)refreshSubViewWithType:(ACEContainerViewType)containerViewType
{
    _containerViewType = containerViewType;
    self.colorButton = nil;
    NSArray *tools = nil;
    if (containerViewType == ACEContainerViewTypeGraf) {
        tools = @[
                  @{@"n":@"撤销",@"img":@"100"},
                  @{@"n":@"橡皮",@"img":@"4",@"lw":@(6), @"t":@(ACEDrawingToolTypeEraser)},
                  @{@"n":@"马赛克",@"img":@"5",@"lw":@(10), @"t":@(ACEDrawingToolTypeMosaic)},
                  @{@"n":@"红",@"c":[UIColor colorWithHexRGB:@"F9364F"]},
                  @{@"n":@"绿",@"c":[UIColor colorWithHexRGB:@"FED233"]},
                  @{@"n":@"兰",@"c":[UIColor colorWithHexRGB:@"4C91FF"]},
                  @{@"n":@"黄",@"c":[UIColor colorWithHexRGB:@"54CF66"]},
                  @{@"n":@"橙",@"c":[UIColor colorWithHexRGB:@"FD6F21"]},
//                  @{@"n":@"移动",@"img":@"move"},
                  ];
        
    }
    if (containerViewType == ACEContainerViewTypeText) {
        tools = @[
                  @{@"n":@"红",@"c":[UIColor colorWithHexRGB:@"F9364F"]},
                  @{@"n":@"绿",@"c":[UIColor colorWithHexRGB:@"FED233"]},
                  @{@"n":@"兰",@"c":[UIColor colorWithHexRGB:@"4C91FF"]},
                  @{@"n":@"黄",@"c":[UIColor colorWithHexRGB:@"54CF66"]},
                  @{@"n":@"橙",@"c":[UIColor colorWithHexRGB:@"FD6F21"]},
                  ];
    }
    if (!_contentView) {
        _contentView = [[UIView alloc]initWithFrame:CGRectMake(20.0, self.frame.size.height - 60.0, self.frame.size.width - 40.0, 60.0)];
        _contentView.layer.cornerRadius = 5.0;
        _contentView.layer.masksToBounds = YES;
        _contentView.backgroundColor = [UIColor colorWithHexRGB:@"333338"];
        [self addSubview:_contentView];
    }
    [_contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    CGFloat w = 25.0;
    CGFloat h = 25.0;
    CGFloat space = _contentView.frame.size.width/tools.count-w;
    CGFloat y = (_contentView.frame.size.height - h) / 2.0;
    
    for(NSInteger i=0; i<tools.count; i++){
        NSDictionary *info = [tools objectAtIndex:i];
        CGFloat x = space/2+i*(w+space);
        UIButton * funcBtn = [[UIButton alloc]initWithFrame:CGRectMake(x, y, w, h)];
        [funcBtn setTitle:[info valueForKey:@"n"] forState:UIControlStateNormal];
        if([info valueForKey:@"c"]){
            //颜色按钮
            UIColor *color = [info valueForKey:@"c"];
            [funcBtn setTitleColor:color forState:UIControlStateNormal];
            
            // 使用颜色创建UIImage
            CGSize imageSize = CGSizeMake(funcBtn.frame.size.width, funcBtn.frame.size.height);
            UIGraphicsBeginImageContextWithOptions(imageSize, 0, [UIScreen mainScreen].scale);
            [color set];
            UIRectFill(CGRectMake(0, 0, imageSize.width, imageSize.height));
            UIImage *pressedColorImg = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
            [funcBtn setImage:pressedColorImg forState:UIControlStateNormal];
            [funcBtn setImage:pressedColorImg forState:UIControlStateSelected];
            funcBtn.layer.cornerRadius = funcBtn.frame.size.width / 2.0;
            funcBtn.clipsToBounds = YES;
            [funcBtn addTarget:self action:@selector(selectColor:) forControlEvents:UIControlEventTouchUpInside];
            
            if(self.colorButton == nil){
                [self selectColor:funcBtn];
            }
            
        }
        else{
            NSString *imageName = [info valueForKey:@"img"];
            [funcBtn setImage:[UIImage imageNamed:[NSString stringWithFormat:@"image_scrawl_%@_n",imageName]] forState:UIControlStateNormal];
            [funcBtn setImage:[UIImage imageNamed:[NSString stringWithFormat:@"image_scrawl_%@_s",imageName]] forState:UIControlStateSelected];
            if ([funcBtn.titleLabel.text isEqualToString:@"撤销"]) {
                [funcBtn addTarget:self action:@selector(selectFunc:) forControlEvents:UIControlEventTouchUpInside];
            }else{
                NSInteger toolType = [[info valueForKey:@"t"] integerValue];
                funcBtn.tag = toolType;

                [funcBtn addTarget:self action:@selector(selectTool:) forControlEvents:UIControlEventTouchUpInside];
            }
        }
        [_contentView addSubview:funcBtn];
    }
    
}
- (void)createSubView
{
    //创建toolBar
//    NSArray *tools = @[
//                       @{@"n":@"笔刷", @"img":@"brush", @"lw":@(6), @"t":@(ACEDrawingToolTypePen)},
//                       @{@"n":@"箭头",@"img":@"arrow",@"lw":@(6), @"t":@(ACEDrawingToolTypeArrow)},
//                       @{@"n":@"矩形",@"img":@"rect",@"lw":@(6), @"t":@(ACEDrawingToolTypeRectagleStroke)},
//                       @{@"n":@"椭圆",@"img":@"ellipse",@"lw":@(6), @"t":@(ACEDrawingToolTypeEllipseStroke)},
//                       @{@"n":@"橡皮",@"img":@"eraser",@"lw":@(6), @"t":@(ACEDrawingToolTypeEraser)},
//                       @{@"n":@"马赛克",@"img":@"mosaic",@"lw":@(10), @"t":@(ACEDrawingToolTypeMosaic)},
//                       @{@"n":@"文字",@"img":@"text",@"lw":@(6), @"t":@(ACEDrawingToolTypeText)},
//                       ];
    NSArray *tools = @[
                       @{@"n":@"笔刷", @"img":@"0", @"lw":@(6), @"t":@(ACEDrawingToolTypePen)},
                       @{@"n":@"箭头",@"img":@"1",@"lw":@(6), @"t":@(ACEDrawingToolTypeArrow)},
                       @{@"n":@"矩形",@"img":@"2",@"lw":@(6), @"t":@(ACEDrawingToolTypeRectagleStroke)},
                       @{@"n":@"椭圆",@"img":@"3",@"lw":@(6), @"t":@(ACEDrawingToolTypeEllipseStroke)},
                       @{@"n":@"橡皮",@"img":@"4",@"lw":@(6), @"t":@(ACEDrawingToolTypeEraser)},
                       @{@"n":@"马赛克",@"img":@"5",@"lw":@(10), @"t":@(ACEDrawingToolTypeMosaic)},
                       @{@"n":@"文字",@"img":@"6",@"lw":@(6), @"t":@(ACEDrawingToolTypeText)},
                       ];
    
    CGFloat y = self.frame.size.height-100;
    
    _toolBarView = [[UIView alloc] initWithFrame:CGRectMake(0, y, self.frame.size.width, 50)];
    _toolBarView.backgroundColor = [UIColor whiteColor];
    [self addSubview:_toolBarView];
    
    CGFloat w = 25.0;
    CGFloat h = 25.0;
    CGFloat space = self.frame.size.width/tools.count-w;
    for(NSInteger i=0; i<tools.count; i++){
        NSDictionary *info = [tools objectAtIndex:i];
        NSString *imageName = [info valueForKey:@"img"];
        NSInteger toolType = [[info valueForKey:@"t"] integerValue];
        CGFloat x = space/2+i*(w+space);
        UIButton * toolBtn = [[UIButton alloc]initWithFrame:CGRectMake(x, (50.0 - 25.0) / 2.0, w, h)];
        [toolBtn setImage:[UIImage imageNamed:[NSString stringWithFormat:@"image_scrawl_%@_n",imageName]] forState:UIControlStateNormal];
        [toolBtn setImage:[UIImage imageNamed:[NSString stringWithFormat:@"image_scrawl_%@_s",imageName]] forState:UIControlStateSelected];
        toolBtn.tag = toolType;
        [toolBtn addTarget:self action:@selector(selectTool:) forControlEvents:UIControlEventTouchUpInside];
        [_toolBarView addSubview:toolBtn];
        if(self.toolButton == nil){
            [self selectTool:toolBtn];
        }
    }
    
    //创建funcBar
    NSArray *funcs = @[
                       @{@"n":@"撤销",@"img":@"undo"},
                       @{@"n":@"红",@"c":[UIColor colorWithHexRGB:@"F9364F"]},
                       @{@"n":@"绿",@"c":[UIColor colorWithHexRGB:@"FED233"]},
                       @{@"n":@"兰",@"c":[UIColor colorWithHexRGB:@"4C91FF"]},
                       @{@"n":@"黄",@"c":[UIColor colorWithHexRGB:@"54CF66"]},
                       @{@"n":@"橙",@"c":[UIColor colorWithHexRGB:@"FD6F21"]},
                       @{@"n":@"移动",@"img":@"move"},
                       ];
    
    y = self.frame.size.height- 50;
    
    _funcBarView = [[UIView alloc] initWithFrame:CGRectMake(0, y, self.frame.size.width, 50)];
    _funcBarView.backgroundColor = [UIColor whiteColor];
    [self addSubview:_funcBarView];
    
    space = self.frame.size.width/funcs.count-w;
    for(NSInteger i=0; i<funcs.count; i++){
        NSDictionary *info = [funcs objectAtIndex:i];
        CGFloat x = space/2+i*(w+space);
        UIButton * funcBtn = [[UIButton alloc]initWithFrame:CGRectMake(x, (50.0 - 25.0) / 2.0, w, h)];
        [funcBtn setTitle:[info valueForKey:@"n"] forState:UIControlStateNormal];
        if([info valueForKey:@"c"]){
            //颜色按钮
            UIColor *color = [info valueForKey:@"c"];
            [funcBtn setTitleColor:color forState:UIControlStateNormal];
            
            // 使用颜色创建UIImage
            CGSize imageSize = CGSizeMake(funcBtn.frame.size.width, funcBtn.frame.size.height);
            UIGraphicsBeginImageContextWithOptions(imageSize, 0, [UIScreen mainScreen].scale);
            [color set];
            UIRectFill(CGRectMake(0, 0, imageSize.width, imageSize.height));
            UIImage *pressedColorImg = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
            [funcBtn setImage:pressedColorImg forState:UIControlStateNormal];
            [funcBtn setImage:pressedColorImg forState:UIControlStateSelected];
            funcBtn.layer.cornerRadius = 4;
            funcBtn.clipsToBounds = YES;
            [funcBtn addTarget:self action:@selector(selectColor:) forControlEvents:UIControlEventTouchUpInside];
            
            if(self.colorButton == nil){
                [self selectColor:funcBtn];
            }

        }
        else{
            NSString *imageName = [info valueForKey:@"img"];
            [funcBtn setImage:[UIImage imageNamed:[NSString stringWithFormat:@"image_scrawl_%@_n",imageName]] forState:UIControlStateNormal];
            [funcBtn setImage:[UIImage imageNamed:[NSString stringWithFormat:@"image_scrawl_%@_s",imageName]] forState:UIControlStateSelected];
            [funcBtn addTarget:self action:@selector(selectFunc:) forControlEvents:UIControlEventTouchUpInside];
        }
        [_funcBarView addSubview:funcBtn];
    }
    
//    CGFloat width = 40;
//    CGFloat height = 30;
//    CGFloat boomHeight = 40;
//    if (!_undoButton) {
//        _undoButton = [[UIButton alloc]initWithFrame:CGRectMake(10, self.frame.size.height - boomHeight, width, height)];
//        [_undoButton setTitle:@"undo" forState:UIControlStateNormal];
//        _undoButton.titleLabel.font = [UIFont systemFontOfSize:16];
//        [_undoButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
//        [_undoButton setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
//        _undoButton.enabled = NO;
//        [self addSubview:_undoButton];
//        [_undoButton addTarget:self action:@selector(undo:) forControlEvents:UIControlEventTouchUpInside];
//    }
//    
//    if (!_redoButton) {
//        _redoButton = [[UIButton alloc]initWithFrame:CGRectMake(CGRectGetMaxX(_undoButton.frame) + 10, self.frame.size.height - boomHeight, width, height)];
//        [_redoButton setTitle:@"redo" forState:UIControlStateNormal];
//        _redoButton.titleLabel.font = [UIFont systemFontOfSize:16];
//        [_redoButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
//        [_redoButton setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
//        _redoButton.enabled = NO;
//        [self addSubview:_redoButton];
//        [_redoButton addTarget:self action:@selector(redo:) forControlEvents:UIControlEventTouchUpInside];
//    }
//    if (!_colorButton) {
//        _colorButton = [[UIButton alloc]initWithFrame:CGRectMake(CGRectGetMaxX(_redoButton.frame) + 10, self.frame.size.height - boomHeight, width, height)];
//        [_colorButton setTitle:@"color" forState:UIControlStateNormal];
//        _colorButton.titleLabel.font = [UIFont systemFontOfSize:16];
//        [_colorButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
//        [self addSubview:_colorButton];
//        [_colorButton addTarget:self action:@selector(colorChange:) forControlEvents:UIControlEventTouchUpInside];
//    }
//    if (!_toolButton) {
//        _toolButton = [[UIButton alloc]initWithFrame:CGRectMake(CGRectGetMaxX(_colorButton.frame) + 10, self.frame.size.height - boomHeight, width, height)];
//        [_toolButton setTitle:@"tool" forState:UIControlStateNormal];
//        _toolButton.titleLabel.font = [UIFont systemFontOfSize:16];
//        [_toolButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
//        [self addSubview:_toolButton];
//        [_toolButton addTarget:self action:@selector(toolChange:) forControlEvents:UIControlEventTouchUpInside];
//    }
//    if (!_alphaButton) {
//        _alphaButton = [[UIButton alloc]initWithFrame:CGRectMake(CGRectGetMaxX(_toolButton.frame) + 10, self.frame.size.height - boomHeight, width, height)];
//        [_alphaButton setTitle:@"alpha" forState:UIControlStateNormal];
//        _alphaButton.titleLabel.font = [UIFont systemFontOfSize:16];
//        [_alphaButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
//        [self addSubview:_alphaButton];
//        [_alphaButton addTarget:self action:@selector(toggleAlphaSlider:) forControlEvents:UIControlEventTouchUpInside];
//    }
//    if (!_moveButton) {
//        _moveButton = [[UIButton alloc]initWithFrame:CGRectMake(CGRectGetMaxX(_alphaButton.frame) + 10, self.frame.size.height - boomHeight, width, height)];
//        [_moveButton setTitle:@"move" forState:UIControlStateNormal];
//        _moveButton.titleLabel.font = [UIFont systemFontOfSize:16];
//        [_moveButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
//        [_moveButton setTitleColor:[UIColor grayColor] forState:UIControlStateSelected];
//        [_moveButton addTarget:self action:@selector(moveButton:) forControlEvents:UIControlEventTouchUpInside];
//        [self addSubview:_moveButton];
//    }
//    if (!_lineAlphaSlider) {
//        _lineAlphaSlider = [[UISlider alloc]initWithFrame:CGRectMake(10, self.frame.size.height - boomHeight - 20, self.frame.size.width - 20, 20)];
//        [_lineAlphaSlider addTarget:self action:@selector(alphaChange:) forControlEvents:UIControlEventValueChanged];
//        _lineAlphaSlider.value = _drawingScrollView.drawingView.lineAlpha;
//        _lineAlphaSlider.hidden = YES;
//        [self addSubview:_lineAlphaSlider];
//    }
//    if (!_lineWidthSlider) {
//        _lineWidthSlider = [[UISlider alloc]initWithFrame:CGRectMake(10, self.frame.size.height - boomHeight - 20, self.frame.size.width - 20, 20)];
//        [_lineWidthSlider addTarget:self action:@selector(alphaChange:) forControlEvents:UIControlEventValueChanged];
//        _lineWidthSlider.value = _drawingScrollView.drawingView.lineWidth;
//        _lineWidthSlider.hidden = YES;
//        [self addSubview:_lineWidthSlider];
//    }
}
#pragma mark - actions
- (void)setDrawTool:(ACEDrawingToolType)doawTool
{
    _drawingScrollView.drawingView.drawTool = doawTool;
}
- (void) selectTool:(id)sender{
    if(self.colorButton){
        [self.colorButton setSelected:NO];
        self.colorButton.layer.borderWidth = 0;
        self.colorButton.layer.borderColor = [UIColor clearColor].CGColor;
    }
    if(self.toolButton){
        [self.toolButton setSelected:NO];
        self.toolButton.layer.borderWidth = 0;
        self.toolButton.layer.borderColor = [UIColor clearColor].CGColor;
    }
    UIButton *button = (UIButton *)sender;
    [button setSelected:YES];
    button.layer.borderWidth = 1;
    button.layer.borderColor = [UIColor whiteColor].CGColor;
    self.toolButton = button;
    
    ACEDrawingToolType toolType = (ACEDrawingToolType)button.tag;
     _drawingScrollView.drawingView.drawTool = toolType;
    if(toolType == ACEDrawingToolTypeMosaic || toolType == ACEDrawingToolTypeEraser){
        _drawingScrollView.drawingView.lineWidth = 10;
    }
    else{
        _drawingScrollView.drawingView.lineWidth = 6;
    }
}

- (void) selectColor:(id)sender{
    if(self.toolButton){
        [self.toolButton setSelected:NO];
        self.toolButton.layer.borderWidth = 0;
        self.toolButton.layer.borderColor = [UIColor clearColor].CGColor;
    }
    if(self.colorButton){
        [self.colorButton setSelected:NO];
        self.colorButton.layer.borderWidth = 0;
        self.colorButton.layer.borderColor = [UIColor clearColor].CGColor;
    }
    UIButton *button = (UIButton *)sender;
    [button setSelected:YES];
    button.layer.borderWidth = 1;
    button.layer.borderColor = [UIColor whiteColor].CGColor;
    self.colorButton = button;
    
    UIColor *color = [button titleColorForState:UIControlStateNormal];
    if (_containerViewType == ACEContainerViewTypeGraf) {
        [self setDrawTool:ACEDrawingToolTypePen];
        _drawingScrollView.drawingView.lineColor = color;
    }else{
        _drawingScrollView.drawingView.textColor = color;
    }
}

- (void) selectFunc:(id)sender{
    UIButton *button = (UIButton *)sender;
    NSString *title = [button titleForState:UIControlStateNormal];
    if([title isEqualToString:@"撤销"]){
        [_drawingScrollView.drawingView undoLatestStep];
    }
    if([title isEqualToString:@"移动"]){
        if (button.selected == NO) {
            _drawingScrollView.scrollEnabled = YES;
            _drawingScrollView.drawingView.canDrawing = NO;
            button.selected = YES;
        }else{
            _drawingScrollView.scrollEnabled = NO;
            _drawingScrollView.drawingView.canDrawing = YES;
            button.selected = NO;
        }
    }
}

- (void)moveButton:(id)sender
{
    UIButton *button = (UIButton *)sender;
    if (button.selected == NO) {
        _drawingScrollView.scrollEnabled = YES;
        _drawingScrollView.drawingView.canDrawing = NO;
        button.selected = YES;
    }else{
        _drawingScrollView.scrollEnabled = NO;
        _drawingScrollView.drawingView.canDrawing = YES;
        button.selected = NO;
    }
}
- (void)updateButtonStatus
{
    self.undoButton.enabled = [_drawingScrollView.drawingView canUndo];
    self.redoButton.enabled = [_drawingScrollView.drawingView canRedo];
}

//- (void)takeScreenshot:(id)sender
//{
//    // show the preview image
//    self.previewImageView.image = _drawingScrollView.drawingView.image;
//    self.previewImageView.hidden = NO;
//    
//    // close it after 3 seconds
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC), dispatch_get_current_queue(), ^{
//        self.previewImageView.hidden = YES;
//    });
//}

- (void)undo:(id)sender
{
    [_drawingScrollView.drawingView undoLatestStep];
    [self updateButtonStatus];
}

- (void)redo:(id)sender
{
    [_drawingScrollView.drawingView redoLatestStep];
    [self updateButtonStatus];
}

- (void)clear:(id)sender
{
    [_drawingScrollView.drawingView clear];
    [self updateButtonStatus];
}


#pragma mark - ACEDrawing View Delegate

- (void)drawingView:(ACEDrawingView *)view didEndDrawUsingTool:(id<ACEDrawingTool>)tool;
{
    [self updateButtonStatus];
}


#pragma mark - Action Sheet Delegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (actionSheet.cancelButtonIndex != buttonIndex) {
        if (actionSheet.tag == kActionSheetColor) {
            
            self.colorButton.titleLabel.text = [actionSheet buttonTitleAtIndex:buttonIndex];
            switch (buttonIndex) {
                case 0:
                    _drawingScrollView.drawingView.lineColor = [UIColor blackColor];
                    break;
                    
                case 1:
                    _drawingScrollView.drawingView.lineColor = [UIColor redColor];
                    break;
                    
                case 2:
                    _drawingScrollView.drawingView.lineColor = [UIColor greenColor];
                    break;
                    
                case 3:
                    _drawingScrollView.drawingView.lineColor = [UIColor blueColor];
                    break;
            }
            
        } else {
            
            self.toolButton.titleLabel.text = [actionSheet buttonTitleAtIndex:buttonIndex];
            switch (buttonIndex) {
                case 0:
                    _drawingScrollView.drawingView.drawTool = ACEDrawingToolTypePen;
                    break;
                    
                case 1:
                    _drawingScrollView.drawingView.drawTool = ACEDrawingToolTypeLine;
                    break;
                    
                case 2:
                    _drawingScrollView.drawingView.drawTool = ACEDrawingToolTypeRectagleStroke;
                    break;
                    
                case 3:
                    _drawingScrollView.drawingView.drawTool = ACEDrawingToolTypeRectagleFill;
                    break;
                    
                case 4:
                    _drawingScrollView.drawingView.drawTool = ACEDrawingToolTypeEllipseStroke;
                    break;
                    
                case 5:
                    _drawingScrollView.drawingView.drawTool = ACEDrawingToolTypeEllipseFill;
                    break;
                    
                case 6:
                    _drawingScrollView.drawingView.drawTool = ACEDrawingToolTypeEraser;
                    break;
                    
                case 7:
                    _drawingScrollView.drawingView.drawTool = ACEDrawingToolTypeText;
                    break;
                    
                case 8:
                    _drawingScrollView.drawingView.drawTool = ACEDrawingToolTypeMultilineText;
                    break;
                case 9:
                    _drawingScrollView.drawingView.drawTool = ACEDrawingToolTypeMosaic;
                    break;
                case 10:
                    _drawingScrollView.drawingView.drawTool = ACEDrawingToolTypeArrow;
                    break;
            }
            
            // if eraser, disable color and alpha selection
            self.colorButton.enabled = self.alphaButton.enabled = buttonIndex != 6;
        }
    }
}

#pragma mark - Settings

- (void)colorChange:(id)sender
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Selet a color"
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:@"Black", @"Red", @"Green", @"Blue", nil];
    
    [actionSheet setTag:kActionSheetColor];
    [actionSheet showInView:self];
}

- (void)toolChange:(id)sender
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Selet a tool"
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:@"Pen", @"Line",
                                  @"Rect (Stroke)", @"Rect (Fill)",
                                  @"Ellipse (Stroke)", @"Ellipse (Fill)",
                                  @"Eraser", @"Text", @"Text (Multiline)",
                                  @"Mosaic",@"Arrow",
                                  nil];
    
    [actionSheet setTag:kActionSheetTool];
    [actionSheet showInView:self];
}

- (void)toggleWidthSlider:(id)sender
{
    // toggle the slider
    self.lineWidthSlider.hidden = !self.lineWidthSlider.hidden;
    self.lineAlphaSlider.hidden = YES;
}


- (void)widthChange:(UISlider *)sender
{
    _drawingScrollView.drawingView.lineWidth = sender.value;
}

- (void)toggleAlphaSlider:(id)sender
{
    // toggle the slider
    self.lineAlphaSlider.hidden = !self.lineAlphaSlider.hidden;
    self.lineWidthSlider.hidden = YES;
}

- (void)alphaChange:(UISlider *)sender
{
    _drawingScrollView.drawingView.lineAlpha = sender.value;
}
- (BOOL)isEdited
{
    return _drawingScrollView.drawingView.canUndo;
}
- (NSMutableArray *)pathArray
{
    if (_drawingScrollView.drawingView.pathArray.count) {
        return _drawingScrollView.drawingView.pathArray;
    }
    return nil;
}
- (void)setPathArray:(NSMutableArray *)pathArray
{
    if (_drawingScrollView.drawingView) {
        [_drawingScrollView.drawingView.pathArray addObjectsFromArray:pathArray];
        [_drawingScrollView.drawingView drawingViewWithPath:pathArray];
    }
}
- (NSMutableDictionary *)textPathDict
{
    if (_drawingScrollView.drawingView.textRecordDict.allKeys.count) {
        return _drawingScrollView.drawingView.textRecordDict;
    }
    return nil;
}
- (void)setTextPathDict:(NSMutableDictionary *)textPathDict
{
    if (_drawingScrollView.drawingView) {
        [_drawingScrollView.drawingView refreshZDStikerView:textPathDict];
    }
}
- (void)endTextEdit
{
    [_drawingScrollView.drawingView endTextEdit];
}
@end
