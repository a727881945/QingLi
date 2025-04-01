//
//  KJSmartCleanViewController.h
//  QingLi_Example
//
//  Created by wangkejie on 2024/12/26.
//  Copyright © 2024 wangkejie. All rights reserved.
//

#import "KJBaseViewController.h"
#import "KJMediaCleanViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface KJSmartCleanViewController : KJBaseViewController

@property (nonatomic, assign, readonly) KJMediaType mediaType;

- (instancetype)initWithMediaType:(KJMediaType)mediaType;

@end

NS_ASSUME_NONNULL_END
