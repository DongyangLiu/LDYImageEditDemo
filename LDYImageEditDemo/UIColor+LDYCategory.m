//
//  UIColor+LDYCategory.m
//  LDYCalendarDemo
//
//  Created by yang on 2017/6/4.
//  Copyright © 2017年 com.tixa.SealChat. All rights reserved.
//

#import "UIColor+LDYCategory.h"

@implementation UIColor (LDYCategory)
/*由16进制字符串获取颜色*/
+ (UIColor *)colorWithHexRGB:(NSString *)hexRGBString
{
    unsigned int colorCode = 0;
    unsigned char redByte, greenByte, blueByte;
    
    if (hexRGBString) {
        NSScanner *scanner = [NSScanner scannerWithString:hexRGBString];
        [scanner scanHexInt:&colorCode];
    }
    blueByte = (unsigned char) (colorCode); // masks off high bits
    greenByte = (unsigned char) (colorCode >> 8);
    redByte = (unsigned char) (colorCode >> 16);
    
    return [UIColor colorWithRed:(float)redByte/0xff green:(float)greenByte/0xff blue:(float)blueByte/0xff alpha:1.0];
}
@end
