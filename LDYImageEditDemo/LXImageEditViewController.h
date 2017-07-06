//
//  LXImageEditViewController.h
//  SealChat
//
//  Created by yang on 16/8/18.
//  Copyright © 2016年 Lianxi.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <objc/runtime.h>

extern NSString *EditSourceImageBoolKey;
typedef void(^EditedFinishedBlock)(NSMutableArray *editImageArys);

/*!
 *  @author Lianxi.com
 *
 *  编辑 和 涂鸦
 */
@interface LXImageEditViewController : UIViewController

@property (nonatomic, strong) NSMutableArray *editImageArys;
@property (nonatomic, copy) EditedFinishedBlock editedBlock;

@end
