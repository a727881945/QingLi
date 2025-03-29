//
//  KJTools.m
//  QingLi_Example
//
//  Created by wangkejie on 2024/12/23.
//  Copyright © 2024 wangkejie. All rights reserved.
//

#import "KJTools.h"

CGFloat fitScale(CGFloat size) {
    CGFloat screenWidth = UIScreen.mainScreen.bounds.size.width;
    return size * screenWidth / 375.0;
}

CGFloat getStatusBarHeight() {
    return [[UIApplication sharedApplication] statusBarFrame].size.height;
}

@implementation KJTools

@end
