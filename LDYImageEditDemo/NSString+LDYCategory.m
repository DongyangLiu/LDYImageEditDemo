//
//  NSString+LDYCategory.m
//  LDYCalendarDemo
//
//  Created by yang on 2017/6/4.
//  Copyright © 2017年 com.tixa.SealChat. All rights reserved.
//

#import "NSString+LDYCategory.h"

@implementation NSString (LDYCategory)
-(CGSize)safeSizeWithFont:(UIFont *)font{
    return [self sizeWithAttributes:[NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, nil]];
}
- (CGSize)safeSizeWithFont:(UIFont *)font forWidth:(CGFloat)width lineBreakMode:(NSLineBreakMode)lineBreakMode{
    CGSize size = CGSizeMake(width, 1000000);
    return [self safeSizeWithFont:font constrainedToSize:size lineBreakMode:lineBreakMode];
}
- (CGSize)safeSizeWithFont:(UIFont *)font constrainedToSize:(CGSize)size lineBreakMode:(NSLineBreakMode)lineBreakMode {
    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.lineBreakMode = lineBreakMode;
    
    NSDictionary *attributes = @{ NSFontAttributeName: font,
                                  NSParagraphStyleAttributeName: paragraphStyle };
    CGSize retSize = [self boundingRectWithSize:CGSizeMake(size.width, size.height) options:NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin attributes:attributes context:nil].size;
    return retSize;
}
@end
