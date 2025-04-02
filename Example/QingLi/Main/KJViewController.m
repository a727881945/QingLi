//
//  KJViewController.m
//  QingLi
//
//  Created by wangkejie on 12/08/2024.
//  Copyright (c) 2024 wangkejie. All rights reserved.
//

#import "KJViewController.h"
#import "KJCustomTabBar.h"
#import "KJHomeViewController.h"
#import "KJContactsViewController.h"
#import "KJProfileViewController.h"

@interface KJViewController ()<KJCustomTabBarDelegate>

@property (nonatomic, strong) KJCustomTabBar *customTabBar;
@property (nonatomic, strong) KJHomeViewController *homeViewController;
@property (nonatomic, strong) KJContactsViewController *callViewController;
@property (nonatomic, strong) KJProfileViewController *profileViewController;
@property (nonatomic, strong) UIViewController *currentViewController;
//@property (nonatomic, strong) DisposeBag *disposeBag;

@end

@implementation KJViewController

- (BOOL)preferredNavigationBarHidden {
    return YES;
}

- (BOOL)shouldCustomizeNavigationBarTransitionIfHideable {
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupTabBar];
    self.customTabBar.delegate = self;
    // 默认显示第一个控制器
    [self switchToViewController:self.homeViewController];
    
    // Uncomment to present GuideViewController
    // GuideViewController *vc = [[GuideViewController alloc] init];
    // vc.modalPresentationStyle = UIModalPresentationFullScreen;
    // [self presentViewController:vc animated:YES completion:nil];
}



- (void)setupTabBar {
    [self.view addSubview:self.customTabBar];
    [self.customTabBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.mas_equalTo(0);
        make.bottom.mas_equalTo(0);
        make.height.mas_equalTo(88);
    }];

    self.customTabBar.backgroundColor = [UIColor whiteColor];
    self.customTabBar.layer.shadowColor = [UIColor blackColor].CGColor;
    self.customTabBar.layer.shadowOpacity = 0.2;
    self.customTabBar.layer.shadowOffset = CGSizeMake(0, 1);
    self.customTabBar.layer.shadowRadius = 9;
}

- (void)tabBarDidSelectButtonAtIndex:(NSInteger)index {
    switch (index) {
        case 0:
            [self switchToViewController:self.homeViewController];
            break;
        case 1:
            [self switchToViewController:self.callViewController];
            break;
        case 2:
            [self switchToViewController:self.profileViewController];
            break;
        default:
            break;
    }
}

- (void)switchToViewController:(UIViewController *)viewController {
    QMUINavigationController *nav = [[QMUINavigationController alloc] initWithRootViewController:viewController];
    nav.delegate = self;
    // 移除当前控制器视图
    [self.currentViewController.view removeFromSuperview];
    [self.currentViewController removeFromParentViewController];

    // 添加新的控制器视图
    [self addChildViewController:nav];
    [self.view insertSubview:nav.view belowSubview:self.customTabBar];
    [nav.view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    self.currentViewController = nav;
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if (navigationController.viewControllers.count > 1) {
        self.customTabBar.hidden = YES;
    } else {
        self.customTabBar.hidden = NO;
    }
}


- (KJHomeViewController *)homeViewController {
    if (!_homeViewController) {
        _homeViewController = [KJHomeViewController new];
    }
    return _homeViewController;
}

- (KJContactsViewController *)callViewController {
    if (!_callViewController) {
        _callViewController = KJContactsViewController.new;
    }
    return _callViewController;
}

- (KJProfileViewController *)profileViewController {
    if (!_profileViewController) {
        _profileViewController = KJProfileViewController.new;
    }
    return _profileViewController;
}

-(KJCustomTabBar *)customTabBar {
    if (!_customTabBar) {
        _customTabBar = [[KJCustomTabBar alloc] initWithFrame:CGRectZero];
    }
    return _customTabBar;
}

@end
