//
//  KJHelper.m
//  QingLi
//
//  Created by wangkejie on 2024/12/18.
//

#import "KJHelper.h"

@implementation KJHelper
+(CGFloat)fitScaleSize:(CGFloat)size {
    return size * UIScreen.mainScreen.bounds.size.width / 390.0;
}
@end
