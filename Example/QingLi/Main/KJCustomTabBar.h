//
//  KJCustomTabBar.h
//  QingLi_Example
//
//  Created by wangkejie on 2024/12/18.
//  Copyright © 2024 wangkejie. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@protocol KJCustomTabBarDelegate <NSObject>

- (void)tabBarDidSelectButtonAtIndex:(NSInteger)index;

@end

@interface KJCustomTabBar : UIView

@property (nonatomic, weak) id<KJCustomTabBarDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
