/*
 * ACEDrawingView: https://github.com/acerbetti/ACEDrawingView
 *
 * Copyright (c) 2013 Stefano Acerbetti
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 */

#import "ACEDrawingView.h"
#import "ACEDrawingTools.h"

#import "ZDStickerView.h"
#import <QuartzCore/QuartzCore.h>

#define kDefaultLineColor       [UIColor blackColor]
#define kDefaultTextColor       [UIColor blackColor]
#define kDefaultLineWidth       6.0f;
#define kDefaultLineAlpha       1.0f

// experimental code
#define PARTIAL_REDRAW          0
#define IOS8_OR_ABOVE [[[UIDevice currentDevice] systemVersion] integerValue] >= 8.0

@interface ACEDrawingView ()<ZDStickerViewDelegate> {
    CGPoint currentPoint;
    CGPoint previousPoint1;
    CGPoint previousPoint2;
}


@property (nonatomic, strong) id<ACEDrawingTool> currentTool;
@property (nonatomic, strong) UIImage *image;
//@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, assign) CGFloat originalFrameYPos;
@property (nonatomic, strong) UITapGestureRecognizer    *tapGesture;
@property (nonatomic, strong) NSString                  *placeholder;
@property (nonatomic, assign) NSInteger                 stickerIndex;
@end
#pragma mark -

@implementation ACEDrawingView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self configure];
        _canDrawing = YES;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self configure];
    }
    return self;
}

- (void)configure
{
    // init the private arrays
    self.pathArray = [NSMutableArray array];
    self.bufferArray = [NSMutableArray array];
    self.zdViewsArray = [NSMutableArray array];
    self.textRecordDict = [NSMutableDictionary dictionary];
    // set the default values for the public properties
    self.lineColor = kDefaultLineColor;
    self.lineWidth = kDefaultLineWidth;
    self.lineAlpha = kDefaultLineAlpha;
    self.textColor = kDefaultTextColor;
    _placeholder = @"点击输入文字";
    self.drawMode = ACEDrawingModeOriginalSize;
    
    // set the transparent background
    self.backgroundColor = [UIColor clearColor];
    
    self.originalFrameYPos = self.frame.origin.y;
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
}

- (UIImage *)prev_image {
    return self.backgroundImage;
}

- (void)setPrev_image:(UIImage *)prev_image {
    [self setBackgroundImage:prev_image];
}


#pragma mark - Drawing

- (void)drawRect:(CGRect)rect
{
#if PARTIAL_REDRAW
    // TODO: draw only the updated part of the image
    [self drawPath];
#else
    switch (self.drawMode) {
        case ACEDrawingModeOriginalSize:
            [self.image drawAtPoint:CGPointZero];
            break;
            
        case ACEDrawingModeScale:
            [self.image drawInRect:self.bounds];
            break;
    }
    [self.currentTool draw];
#endif
}

- (void)commitAndDiscardToolStack
{
    [self updateCacheImage:YES];
    self.backgroundImage = self.image;
    [self.pathArray removeAllObjects];
}

- (void)updateCacheImage:(BOOL)redraw
{
    // init a context
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, 0.0);
    
    if (redraw) {
        // erase the previous image
        self.image = nil;
        
        // load previous image (if returning to screen)
        
        switch (self.drawMode) {
            case ACEDrawingModeOriginalSize:
                [[self.backgroundImage copy] drawAtPoint:CGPointZero];
                break;
            case ACEDrawingModeScale:
                [[self.backgroundImage copy] drawInRect:self.bounds];
                break;
        }
        
        // I need to redraw all the lines
        for (id<ACEDrawingTool> tool in self.pathArray) {
            [tool draw];
        }
        
    } else {
        // set the draw point
        [self.image drawAtPoint:CGPointZero];
        [self.currentTool draw];
    }
    
    // store the image
    self.image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
}

- (void)finishDrawing
{
    // update the image
    [self updateCacheImage:NO];
    
    // clear the redo queue
    [self.bufferArray removeAllObjects];
    
    // call the delegate
    if ([self.delegate respondsToSelector:@selector(drawingView:didEndDrawUsingTool:)]) {
        [self.delegate drawingView:self didEndDrawUsingTool:self.currentTool];
    }
    
    // clear the current tool
    self.currentTool = nil;
}

- (void)setCustomDrawTool:(id<ACEDrawingTool>)customDrawTool
{
    _customDrawTool = customDrawTool;
    
    if (customDrawTool != nil) {
        self.drawTool = ACEDrawingToolTypeCustom;
    }
}

- (id<ACEDrawingTool>)toolWithCurrentSettings
{
    switch (self.drawTool) {
        case ACEDrawingToolTypePen:
        {
            return ACE_AUTORELEASE([ACEDrawingPenTool new]);
        }
            
        case ACEDrawingToolTypeLine:
        {
            return ACE_AUTORELEASE([ACEDrawingLineTool new]);
        }
            
        case ACEDrawingToolTypeText:
        {
            return ACE_AUTORELEASE([ACEDrawingTextTool new]);
        }

        case ACEDrawingToolTypeMultilineText:
        {
            return ACE_AUTORELEASE([ACEDrawingMultilineTextTool new]);
        }

        case ACEDrawingToolTypeRectagleStroke:
        {
            ACEDrawingRectangleTool *tool = ACE_AUTORELEASE([ACEDrawingRectangleTool new]);
            tool.fill = NO;
            return tool;
        }
            
        case ACEDrawingToolTypeRectagleFill:
        {
            ACEDrawingRectangleTool *tool = ACE_AUTORELEASE([ACEDrawingRectangleTool new]);
            tool.fill = YES;
            return tool;
        }
            
        case ACEDrawingToolTypeEllipseStroke:
        {
            ACEDrawingEllipseTool *tool = ACE_AUTORELEASE([ACEDrawingEllipseTool new]);
            tool.fill = NO;
            return tool;
        }
            
        case ACEDrawingToolTypeEllipseFill:
        {
            ACEDrawingEllipseTool *tool = ACE_AUTORELEASE([ACEDrawingEllipseTool new]);
            tool.fill = YES;
            return tool;
        }
            
        case ACEDrawingToolTypeEraser:
        {
            return ACE_AUTORELEASE([ACEDrawingEraserTool new]);
        }
        case ACEDrawingToolTypeMosaic:
        {
            ACEDrawingMosaicTool *tool = ACE_AUTORELEASE([ACEDrawingMosaicTool new]);
            tool.drawingView = self;
            return tool;
        }
        case ACEDrawingToolTypeArrow:
        {
            return ACE_AUTORELEASE([ACEDrawingArrowTool new]);
        }
            
        case ACEDrawingToolTypeCustom:
        {
            return self.customDrawTool;
        }
    }
}


#pragma mark - Touch Methods

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (_zdViewsArray.count) {
        for (ZDStickerView *stiker in _zdViewsArray) {
            if (![stiker isEditingHandlesHidden]) {
                [stiker contentViewResignFirstResponder];
                [self refreshTextRecordInfoValue:[stiker textInfo] key:[NSString stringWithFormat:@"%ld",(unsigned long)stiker.tag]];
                return;
            }
        }
    }
    if (!_canDrawing) {
        return;
    }
    if (self.textView && !self.textView.hidden) {
        [self commitAndHideTextEntry];
        return;
    }
    if (touches.count > 1 || [event allTouches].count > 1) {
        return;
    }
    

    
    // add the first touch
    UITouch *touch = [touches anyObject];
    previousPoint1 = [touch previousLocationInView:self];
    currentPoint = [touch locationInView:self];
    
    // init the bezier path
    self.currentTool = [self toolWithCurrentSettings];
    self.currentTool.lineWidth = self.lineWidth;
    self.currentTool.lineColor = self.lineColor;
    self.currentTool.lineAlpha = self.lineAlpha;
    
    if ([self.currentTool class] == [ACEDrawingTextTool class]) {
//        [self initializeTextBox:currentPoint WithMultiline:NO];
        CGRect frame = CGRectMake(currentPoint.x - ZD_TEXT_WIDTH / 2.0, currentPoint.y - ZD_TEXT_HEIGHT / 2.0, ZD_TEXT_WIDTH, ZD_TEXT_HEIGHT);

        ZDStickerView *userResizableView = [[ZDStickerView alloc] initWithFrame:frame];
        
        frame = CGRectInset(self.bounds,
                            kSPUserResizableViewGlobalInset + kSPUserResizableViewInteractiveBorderSize/2,
                            kSPUserResizableViewGlobalInset + kSPUserResizableViewInteractiveBorderSize/2);
        
        UITextView *_zdTextView = [[UITextView alloc]initWithFrame:frame];
        _zdTextView.textContainer.lineBreakMode = NSLineBreakByWordWrapping;

        _zdTextView.font = [UIFont systemFontOfSize:ZD_TEXT_FONT];
        _zdTextView.textColor = _textColor;
        _zdTextView.text = _placeholder;
        _zdTextView.backgroundColor = [UIColor clearColor];
        _zdTextView.tag = _stickerIndex;
        userResizableView.tag = _stickerIndex;
        _stickerIndex++;
        userResizableView.stickerViewDelegate = self;
        userResizableView.contentView = _zdTextView;
        userResizableView.preventsPositionOutsideSuperview = NO;
        userResizableView.preventsCustomButton = NO;
        [userResizableView setButton:ZDSTICKERVIEW_BUTTON_CUSTOM
                                image:[UIImage imageNamed:@"image_text_rotate"]];
        userResizableView.preventsResizing = NO;
        [userResizableView showEditingHandles];
        [self addSubview:userResizableView];
        [_zdViewsArray addObject:userResizableView];
        
    } else if([self.currentTool class] == [ACEDrawingMultilineTextTool class]) {
        [self initializeTextBox:currentPoint WithMultiline:YES];
    } else {
        [self.pathArray addObject:self.currentTool];
        
        [self.currentTool setInitialPoint:currentPoint];
    }
    
    // call the delegate
    if ([self.delegate respondsToSelector:@selector(drawingView:willBeginDrawUsingTool:)]) {
        [self.delegate drawingView:self willBeginDrawUsingTool:self.currentTool];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    // save all the touches in the path
    if (touches.count > 1 || [event allTouches].count > 1) {
        return;
    }
    UITouch *touch = [touches anyObject];
    
    previousPoint2 = previousPoint1;
    previousPoint1 = [touch previousLocationInView:self];
    currentPoint = [touch locationInView:self];
    
    if ([self.currentTool isKindOfClass:[ACEDrawingPenTool class]]) {
        CGRect bounds = [(ACEDrawingPenTool*)self.currentTool addPathPreviousPreviousPoint:previousPoint2 withPreviousPoint:previousPoint1 withCurrentPoint:currentPoint];
        
        CGRect drawBox = bounds;
        drawBox.origin.x -= self.lineWidth * 2.0;
        drawBox.origin.y -= self.lineWidth * 2.0;
        drawBox.size.width += self.lineWidth * 4.0;
        drawBox.size.height += self.lineWidth * 4.0;
        
        [self setNeedsDisplayInRect:drawBox];
    }
    else if ([self.currentTool isKindOfClass:[ACEDrawingTextTool class]]) {
        [self resizeTextViewFrame: currentPoint];
    }
    else {
        [self.currentTool moveFromPoint:previousPoint1 toPoint:currentPoint];
        [self setNeedsDisplay];
    }
    
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    // make sure a point is recorded
    if (touches.count > 1 || [event allTouches].count > 1) {
        return;
    }
    [self touchesMoved:touches withEvent:event];
    
    if ([self.currentTool isKindOfClass:[ACEDrawingTextTool class]]) {
        [self startTextEntry];
    }
    else {
        [self finishDrawing];
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    // make sure a point is recorded
    [self touchesEnded:touches withEvent:event];
}

#pragma mark - Text Entry

- (void)initializeTextBox:(CGPoint)startingPoint WithMultiline:(BOOL)multiline {
    if (!self.textView) {
        self.textView = [[UITextView alloc] init];
        self.textView.delegate = self;
        if(!multiline) {
            self.textView.returnKeyType = UIReturnKeyDone;
        }
        self.textView.autocorrectionType = UITextAutocorrectionTypeNo;
        self.textView.backgroundColor = [UIColor clearColor];
        self.textView.layer.borderWidth = 1.0f;
        self.textView.layer.borderColor = [[UIColor grayColor] CGColor];
        self.textView.layer.cornerRadius = 8;
        [self.textView setContentInset: UIEdgeInsetsZero];
        
        
        [self addSubview:self.textView];
    }
    
    int calculatedFontSize = self.lineWidth * 3; //3 is an approximate size factor
    
    [self.textView setFont:[UIFont systemFontOfSize:calculatedFontSize]];
    self.textView.textColor = self.textColor;
    self.textView.alpha = self.lineAlpha;
    
    int defaultWidth = 200;
    int defaultHeight = calculatedFontSize * 2;
    int initialYPosition = startingPoint.y - (defaultHeight/2);
    
    CGRect frame = CGRectMake(startingPoint.x, initialYPosition, defaultWidth, defaultHeight);
    frame = [self adjustFrameToFitWithinDrawingBounds:frame];
    
    self.textView.frame = frame;
    self.textView.text = @"";
    self.textView.hidden = NO;
}

- (void) startTextEntry {
    if (!self.textView.hidden) {
        [self.textView becomeFirstResponder];
    }
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if(([self.currentTool class] == [ACEDrawingTextTool  class]) && [text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        return NO;
    }
    return YES;
}

-(void)textViewDidChange:(UITextView *)textView {
    CGRect frame = self.textView.frame;
    if (self.textView.contentSize.height > frame.size.height) {
        frame.size.height = self.textView.contentSize.height;
    }
    
    self.textView.frame = frame;
}

- (void)textViewDidEndEditing:(UITextView *)textView{
    [self commitAndHideTextEntry];
}

-(void)resizeTextViewFrame: (CGPoint)adjustedSize {
    
    int minimumAllowedHeight = self.textView.font.pointSize * 2;
    int minimumAllowedWidth = self.textView.font.pointSize * 0.5;
    
    CGRect frame = self.textView.frame;
    
    //adjust height
    int adjustedHeight = adjustedSize.y - self.textView.frame.origin.y;
    if (adjustedHeight > minimumAllowedHeight) {
        frame.size.height = adjustedHeight;
    }
    
    //adjust width
    int adjustedWidth = adjustedSize.x - self.textView.frame.origin.x;
    if (adjustedWidth > minimumAllowedWidth) {
        frame.size.width = adjustedWidth;
    }
    frame = [self adjustFrameToFitWithinDrawingBounds:frame];
    
    self.textView.frame = frame;
}

- (CGRect)adjustFrameToFitWithinDrawingBounds: (CGRect)frame {
    
    //check that the frame does not go beyond bounds of parent view
    if ((frame.origin.x + frame.size.width) > self.frame.size.width) {
        frame.size.width = self.frame.size.width - frame.origin.x;
    }
    if ((frame.origin.y + frame.size.height) > self.frame.size.height) {
        frame.size.height = self.frame.size.height - frame.origin.y;
    }
    return frame;
}

- (void)commitAndHideTextEntry {
    [self.textView resignFirstResponder];
    
    if ([self.textView.text length]) {
        UIEdgeInsets textInset = self.textView.textContainerInset;
        CGFloat additionalXPadding = 5;
        CGPoint start = CGPointMake(self.textView.frame.origin.x + textInset.left + additionalXPadding, self.textView.frame.origin.y + textInset.top);
        CGPoint end = CGPointMake(self.textView.frame.origin.x + self.textView.frame.size.width - additionalXPadding, self.textView.frame.origin.y + self.textView.frame.size.height);
        
        ((ACEDrawingTextTool*)self.currentTool).attributedText = [self.textView.attributedText copy];
        
        [self.pathArray addObject:self.currentTool];
        
        [self.currentTool setInitialPoint:start]; //change this for precision accuracy of text location
        [self.currentTool moveFromPoint:start toPoint:end];
        [self setNeedsDisplay];
        
        [self finishDrawing];
        
    }
    
    self.currentTool = nil;
    self.textView.hidden = YES;
    self.textView = nil;
}

#pragma mark - Keyboard Events

- (void)keyboardDidShow:(NSNotification *)notification
{
    self.originalFrameYPos = self.frame.origin.y;

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
    CGPoint textViewBottomPoint = [self convertPoint:self.textView.frame.origin toView:self];
    CGFloat textViewOriginY = textViewBottomPoint.y;
    CGFloat textViewBottomY = textViewOriginY + self.textView.frame.size.height;

    CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;

    CGFloat offset = (self.frame.size.height - keyboardSize.width) - textViewBottomY;

    if (offset < 0) {
        CGFloat newYPos = self.frame.origin.y + offset;
        self.frame = CGRectMake(self.frame.origin.x,newYPos, self.frame.size.width, self.frame.size.height);

    }
}
- (void)adjustFramePosition:(NSNotification *)notification {
    CGPoint textViewBottomPoint = [self convertPoint:self.textView.frame.origin toView:nil];
    textViewBottomPoint.y += self.textView.frame.size.height;

    CGRect screenRect = [[UIScreen mainScreen] bounds];

    CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;

    CGFloat offset = (screenRect.size.height - keyboardSize.height) - textViewBottomPoint.y;

    if (offset < 0) {
        CGFloat newYPos = self.frame.origin.y + offset;
        self.frame = CGRectMake(self.frame.origin.x,newYPos, self.frame.size.width, self.frame.size.height);

    }
}

-(void)keyboardDidHide:(NSNotification *)notification
{
    self.frame = CGRectMake(self.frame.origin.x,self.originalFrameYPos,self.frame.size.width,self.frame.size.height);
}


#pragma mark - Load Image

- (void)loadImage:(UIImage *)image
{
    self.originalImage = image;
    self.image = image;
    
    //save the loaded image to persist after an undo step
    self.backgroundImage = [image copy];
    
    // when loading an external image, I'm cleaning all the paths and the undo buffer
    [self.bufferArray removeAllObjects];
    [self.pathArray removeAllObjects];
    [self updateCacheImage:YES];
    [self setNeedsDisplay];
}

- (void)loadImageData:(NSData *)imageData
{
    CGFloat imageScale;
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
        imageScale = [[UIScreen mainScreen] scale];
        
    } else {
        imageScale = 1.0;
    }
    
    UIImage *image = [UIImage imageWithData:imageData scale:imageScale];
    [self loadImage:image];
}

- (void)resetTool
{
    if ([self.currentTool isKindOfClass:[ACEDrawingTextTool class]]) {
        self.textView.text = @"";
        [self commitAndHideTextEntry];
    }
    self.currentTool = nil;
}

#pragma mark - Actions

- (void)clear
{
    [self resetTool];
    [self.bufferArray removeAllObjects];
    [self.pathArray removeAllObjects];
    self.backgroundImage = self.originalImage;
    [self updateCacheImage:YES];
    [self setNeedsDisplay];
}


#pragma mark - Undo / Redo

- (NSUInteger)undoSteps
{
    return self.bufferArray.count;
}

- (BOOL)canUndo
{
    return self.pathArray.count > 0;
}

- (void)undoLatestStep
{
    if ([self canUndo]) {
        [self resetTool];
        id<ACEDrawingTool>tool = [self.pathArray lastObject];
        [self.bufferArray addObject:tool];
        [self.pathArray removeLastObject];
        [self updateCacheImage:YES];
        [self setNeedsDisplay];
    }
}

- (BOOL)canRedo
{
    return self.bufferArray.count > 0;
}

- (void)redoLatestStep
{
    if ([self canRedo]) {
        [self resetTool];
        id<ACEDrawingTool>tool = [self.bufferArray lastObject];
        [self.pathArray addObject:tool];
        [self.bufferArray removeLastObject];
        [self updateCacheImage:YES];
        [self setNeedsDisplay];
    }
}
- (void)drawingViewWithPath:(NSMutableArray *)pathArray
{
    if (pathArray.count > 0) {
        [self updateCacheImage:YES];
        [self setNeedsDisplay];
    }
}

- (void)dealloc
{
    self.pathArray = nil;
    self.bufferArray = nil;
    self.currentTool = nil;
    self.image = nil;
    self.backgroundImage = nil;
    self.customDrawTool = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidHideNotification object:nil];
    
#if !ACE_HAS_ARC
    
    [super dealloc];
#endif
}
- (void)setTextColor:(UIColor *)textColor
{
    _textColor = textColor;
    self.textView.textColor = textColor;
    for (ZDStickerView *sticker in _zdViewsArray) {
        ((UITextView *)sticker.contentView).textColor = textColor;
    }
}
- (void)stickerViewDidClose:(ZDStickerView *)sticker
{
    [_textRecordDict removeObjectForKey:[NSString stringWithFormat:@"%ld",(unsigned long)sticker.tag]];
    [_zdViewsArray removeObject:sticker];
    
}
- (void)stickerViewDidBeginEditing:(ZDStickerView *)sticker
{
    if (_zdViewsArray.count) {
        for (ZDStickerView *stiker in _zdViewsArray) {
            [stiker hideEditingHandles];
        }
    }
    if ([((UITextView *)sticker.contentView).text isEqualToString:_placeholder]) {
        ((UITextView *)sticker.contentView).text = @"";
    }
    [sticker showEditingHandles];
}
- (void)stickerViewDidEndEditing:(ZDStickerView *)sticker
{
    if (((UITextView *)sticker.contentView).text.length == 0) {
        ((UITextView *)sticker.contentView).text = _placeholder;
    }
}
- (void)endTextEdit
{
    if (_zdViewsArray.count) {
        for (ZDStickerView *stiker in _zdViewsArray) {
            [stiker contentViewResignFirstResponder];
            [self refreshTextRecordInfoValue:[stiker textInfo] key:[NSString stringWithFormat:@"%ld",(unsigned long)stiker.tag]];
        }
//        self.image = [self drawingEndImage];
//        [self setNeedsDisplay];
//        [_zdViewsArray removeAllObjects];
    }
}
- (void)refreshTextRecordInfoValue:(id)value key:(NSString *)key
{
    [_textRecordDict setValue:value forKey:key];
}
- (UIImage *)drawingEndImage{
    UIGraphicsBeginImageContextWithOptions(self.image.size, NO, [UIScreen mainScreen].scale);
    CGRect rect = CGRectMake(0, 0, self.image.size.width, self.image.size.height);
    [self.image drawInRect:rect];
    if (_zdViewsArray.count) {
        for (ZDStickerView *stiker in _zdViewsArray) {
            CGRect frame = [stiker.contentView convertRect:stiker.contentView.frame toView:self];
            [((UITextView *)stiker.contentView).text drawInRect:frame withAttributes:((UITextView *)stiker.contentView).typingAttributes];
        }
    }
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}
- (void)refreshZDStikerView:(NSMutableDictionary *)textRecordDict
{
    if (textRecordDict) {
        _textRecordDict = textRecordDict;
        for (NSString *key in textRecordDict) {
            NSMutableDictionary *info = textRecordDict[key];
            ZDStickerView *userResizableView = [[ZDStickerView alloc] initWithFrame:CGRectFromString(info[@"frame"])];
            
            UITextView *_zdTextView = [[UITextView alloc]initWithFrame:userResizableView.bounds];
            _zdTextView.textContainer.lineBreakMode = NSLineBreakByWordWrapping;
            _zdTextView.font = info[@"font"];;
            _zdTextView.textColor = info[@"textColor"];;
            _zdTextView.text = info[@"text"];;
            _zdTextView.backgroundColor = [UIColor clearColor];
            _zdTextView.tag = _zdViewsArray.count;
            
            userResizableView.tag = _zdViewsArray.count;
            userResizableView.stickerViewDelegate = self;
            userResizableView.contentView = _zdTextView;
            userResizableView.preventsPositionOutsideSuperview = NO;
            userResizableView.preventsCustomButton = NO;
            [userResizableView setButton:ZDSTICKERVIEW_BUTTON_CUSTOM
                                   image:[UIImage imageNamed:@"image_text_rotate"]];
            userResizableView.preventsResizing = NO;
            [userResizableView hideEditingHandles];
            [self addSubview:userResizableView];
            [_zdViewsArray addObject:userResizableView];
            _stickerIndex = _zdViewsArray.count;
        }
    }
    
}
- (BOOL)canTextEdit
{
    if (_drawTool == ACEDrawingToolTypeText || _drawTool == ACEDrawingToolTypeMultilineText) {
        return YES;
    }
    return NO;
}
@end
