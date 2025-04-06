//
//  KJIAPViewController.m
//  QingLi_Example
//
//  Created by wangkejie on 2025/4/6.
//  Copyright © 2025 wangkejie. All rights reserved.
//

#import "KJIAPViewController.h"
#import <StoreKit/StoreKit.h>

@interface KJIAPViewController () <SKProductsRequestDelegate, SKPaymentTransactionObserver>

@property (nonatomic, strong) UIImageView *iconImageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UIView *featuresContainer;
@property (nonatomic, strong) UIButton *weeklyButton;
@property (nonatomic, strong) UIButton *monthlyButton;
@property (nonatomic, strong) UIButton *trialButton;
@property (nonatomic, strong) UIButton *restoreButton;
@property (nonatomic, strong) UIButton *closeButton;

@property (nonatomic, strong) NSArray<SKProduct *> *products;
@property (nonatomic, strong) SKProduct *selectedProduct;
@property (nonatomic, assign) BOOL isWeeklySelected;

@end

@implementation KJIAPViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupUI];
    [self setupIAP];
}

- (void)setupUI {
    self.view.backgroundColor = [UIColor whiteColor];
    {
        UIImageView *topBg = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.width)];
        topBg.image = [UIImage imageNamed:@"iap_topbg"];
        [self.view addSubview:topBg];
    }
    CGFloat top = IS_NOTCHED_SCREEN ? SafeAreaInsetsConstantForDeviceWithNotch.top : 43;
    
    // 恢复购买按钮
    self.restoreButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.restoreButton.frame = CGRectMake(14, top, 70, 26);
    self.restoreButton.layer.cornerRadius = 13;
    self.restoreButton.layer.masksToBounds = YES;
    self.restoreButton.backgroundColor = [[UIColor qmui_colorWithHexString:@"#ffffff"] colorWithAlphaComponent:0.76];
    [self.restoreButton setTitle:@"Restore" forState:UIControlStateNormal];
    [self.restoreButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    self.restoreButton.titleLabel.font = [UIFont systemFontOfSize:12];
    [self.restoreButton addTarget:self action:@selector(restoreButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.restoreButton];
   
    // 关闭按钮
    self.closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.closeButton.frame = CGRectZero;
    [self.closeButton setTitle:@"Close" forState:UIControlStateNormal];
    [self.closeButton setTitleColor:[UIColor qmui_colorWithHexString:@"#666666"] forState:UIControlStateNormal];
    self.closeButton.titleLabel.font = [UIFont systemFontOfSize:12];
    [self.closeButton addTarget:self action:@selector(closeButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.closeButton];
    [self.closeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(self.view).mas_offset(-14);
        make.top.mas_equalTo(top);
        make.height.mas_equalTo(26);
        make.centerY.mas_equalTo(self.restoreButton.mas_centerY);
        make.width.mas_greaterThanOrEqualTo(1);
    }];
    
    // 图标
    self.iconImageView = [[UIImageView alloc] initWithFrame:CGRectMake((self.view.bounds.size.width - 184) / 2, 46, 184, 184)];
    self.iconImageView.image = [UIImage imageNamed:@"iap_avatar"];
    self.iconImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.iconImageView.layer.cornerRadius = 20;
    self.iconImageView.clipsToBounds = YES;
    [self.view addSubview:self.iconImageView];
    
    UIImageView *star = [[UIImageView alloc] initWithFrame:CGRectMake(self.view.qmui_width - 32 - 41, 217.5, 32, 30)];
    star.image = [UIImage imageNamed:@"iap_star"];
    [self.view addSubview:star];
    
    // 标题
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(36, 224, self.view.bounds.size.width - 36 - 95.5, 60)];
    NSString *titleString = @"Unlock All Feature Free for 3 days";
    NSMutableAttributedString *attString = [[NSMutableAttributedString alloc] initWithString:titleString];
//    {
//        // 基础段落样式
//        NSMutableParagraphStyle *baseStyle = [[NSMutableParagraphStyle alloc] init];
//        [baseStyle setParagraphSpacing:25];    // 段后间距
//        [baseStyle setLineSpacing:10];         // 行间距
//    }
    [attString addAttribute:NSForegroundColorAttributeName value:[UIColor qmui_colorWithHexString:@"#0069FF"] range:NSMakeRange(0, 6)];
    [attString addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:21] range:NSMakeRange(0, titleString.length)];
    self.titleLabel.numberOfLines = 0;
    self.titleLabel.attributedText = attString;
    self.titleLabel.textAlignment = NSTextAlignmentLeft;
    self.titleLabel.font = [UIFont boldSystemFontOfSize:24];
    [self.view addSubview:self.titleLabel];
    
    // 副标题
//    self.subtitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 240, self.view.bounds.size.width - 40, 30)];
//    self.subtitleLabel.text = @"for 3 days";
//    self.subtitleLabel.textAlignment = NSTextAlignmentCenter;
//    self.subtitleLabel.font = [UIFont systemFontOfSize:20];
//    [self.view addSubview:self.subtitleLabel];
    
//    // 功能列表容器
//    self.featuresContainer = [[UIView alloc] initWithFrame:CGRectMake(40, 292, self.view.bounds.size.width - 80, 150)];
//    [self.view addSubview:self.featuresContainer];
//    
    // 添加功能列表
    NSArray *features = @[
        @"Smart Cleaning of duplicate photos",
        @"Smart Management of videos, live photos and screenshots",
        @"Smart Management of contacts"
    ];
//    
//    for (NSInteger i = 0; i < features.count; i++) {
//        UILabel *featureLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, i * 40, self.featuresContainer.bounds.size.width - 25, 30)];
//        featureLabel.text = features[i];
//        featureLabel.font = [UIFont systemFontOfSize:14];
//        featureLabel.textColor = [UIColor qmui_colorWithHexString:@"#457387"];
//        [self.featuresContainer addSubview:featureLabel];
//        
//        // 添加小圆点
//        UIView *dotView = [[UIView alloc] initWithFrame:CGRectMake(0, i * 40 + 6, 4, 4)];
//        dotView.backgroundColor = [UIColor qmui_colorWithHexString:@"#0069FF"];
//        dotView.layer.cornerRadius = 5;
//        [self.featuresContainer addSubview:dotView];
//    }
    UIView *mas_view = nil;
    {
        // 添加小圆点
        UIView *dotView = [[UIView alloc] initWithFrame:CGRectZero];
        [self.view addSubview:dotView];
        [dotView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(35.5);
            make.top.mas_equalTo(self.titleLabel.mas_bottom).mas_offset(14);
            make.width.height.mas_equalTo(4);
        }];
        dotView.backgroundColor = [UIColor qmui_colorWithHexString:@"#0069FF"];
        dotView.layer.cornerRadius = 2;
        
        UILabel *featureLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        featureLabel.text = features[0];
        featureLabel.font = [UIFont systemFontOfSize:14];
        featureLabel.textColor = [UIColor qmui_colorWithHexString:@"#457387"];
        [self.view addSubview:featureLabel];
        [featureLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(dotView.mas_right).mas_offset(6);
            make.centerY.mas_equalTo(dotView.mas_centerY);
            make.width.mas_greaterThanOrEqualTo(1);
            make.right.mas_equalTo(self.view.mas_right).mas_offset(-25);
        }];
        mas_view = featureLabel;
    }
    
    {
        UILabel *featureLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        featureLabel.text = features[1];
        featureLabel.numberOfLines = 0;
        featureLabel.font = [UIFont systemFontOfSize:14];
        featureLabel.textColor = [UIColor qmui_colorWithHexString:@"#457387"];
        [self.view addSubview:featureLabel];
        [featureLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(45.5);
            make.top.mas_equalTo(mas_view.mas_bottom).mas_offset(10);
            make.width.mas_greaterThanOrEqualTo(1);
            make.height.mas_greaterThanOrEqualTo(1);
            make.right.mas_equalTo(self.view.mas_right).mas_offset(-25);
        }];
        
        // 添加小圆点
        UIView *dotView = [[UIView alloc] initWithFrame:CGRectZero];
        [self.view addSubview:dotView];
        [dotView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(35.5);
//            make.top.mas_equalTo(mas_view.mas_bottom).mas_offset(10);
            make.width.height.mas_equalTo(4);
            make.centerY.mas_equalTo(featureLabel.mas_centerY);
        }];
        dotView.backgroundColor = [UIColor qmui_colorWithHexString:@"#0069FF"];
        dotView.layer.cornerRadius = 2;
        mas_view = featureLabel;
    }
    
    {
        UILabel *featureLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        featureLabel.text = features[2];
        featureLabel.numberOfLines = 0;
        featureLabel.font = [UIFont systemFontOfSize:14];
        featureLabel.textColor = [UIColor qmui_colorWithHexString:@"#457387"];
        [self.view addSubview:featureLabel];
        [featureLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(45.5);
            make.top.mas_equalTo(mas_view.mas_bottom).mas_offset(10);
            make.width.mas_greaterThanOrEqualTo(1);
            make.height.mas_greaterThanOrEqualTo(1);
            make.right.mas_equalTo(self.view.mas_right).mas_offset(-25);
        }];
        
        // 添加小圆点
        UIView *dotView = [[UIView alloc] initWithFrame:CGRectZero];
        [self.view addSubview:dotView];
        [dotView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(35.5);
//            make.top.mas_equalTo(mas_view.mas_bottom).mas_offset(10);
            make.width.height.mas_equalTo(4);
            make.centerY.mas_equalTo(featureLabel.mas_centerY);
        }];
        dotView.backgroundColor = [UIColor qmui_colorWithHexString:@"#0069FF"];
        dotView.layer.cornerRadius = 2;
        mas_view = featureLabel;
    }
    
    // 周订阅按钮
    {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.backgroundColor = [UIColor qmui_colorWithHexString:@"#E8F5FF"];
        button.layer.cornerRadius = 20;
        [self.view addSubview:button];
        [button mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(25.5);
            make.right.mas_equalTo(-25.5);
            make.height.mas_equalTo(40);
            make.top.mas_equalTo(mas_view.mas_bottom).mas_offset(50);
        }];
        // 创建一个圆形选择指示器
        UIView *indicatorView = [[UIView alloc] initWithFrame:CGRectZero];
        indicatorView.layer.cornerRadius = 8;
        indicatorView.layer.borderWidth = 0.5;
        indicatorView.layer.borderColor = [UIColor qmui_colorWithHexString:@"#B3D7F4"].CGColor;
        indicatorView.tag = 200;
        [button addSubview:indicatorView];
        [indicatorView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.height.mas_equalTo(16);
            make.left.mas_equalTo(14);
            make.top.mas_equalTo(12);
        }];
        
        // 创建一个圆形内选择指示器
        UIView *indicatorViewInner = [[UIView alloc] initWithFrame:CGRectZero];
        indicatorViewInner.backgroundColor = [UIColor qmui_colorWithHexString:@"#28A8FF"];
        indicatorViewInner.layer.cornerRadius = 3.5;
        indicatorViewInner.tag = 201;
        [indicatorView addSubview:indicatorViewInner];
        [indicatorViewInner mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.height.mas_equalTo(7);
            make.left.mas_equalTo(4.5);
            make.top.mas_equalTo(4.5);
        }];
        // 添加标题标签
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        titleLabel.text = @"Three Days Free Trial   then ＄0.99/week";
        titleLabel.font = [UIFont systemFontOfSize:15];
        titleLabel.textColor = [UIColor qmui_colorWithHexString:@"#457387"];
        [button addSubview:titleLabel];
        [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(38);
            make.top.bottom.mas_equalTo(0);
            make.right.mas_equalTo(10);
        }];
        self.weeklyButton = button;
        [self.weeklyButton addTarget:self action:@selector(weeklyButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    }
    
    // 月订阅按钮
    {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.backgroundColor = [UIColor qmui_colorWithHexString:@"#E8F5FF"];
        button.layer.cornerRadius = 20;
        [self.view addSubview:button];
        [button mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(25.5);
            make.right.mas_equalTo(-25.5);
            make.height.mas_equalTo(40);
            make.top.mas_equalTo(self.weeklyButton.mas_bottom).mas_offset(22);
        }];
        // 创建一个圆形选择指示器
        UIView *indicatorView = [[UIView alloc] initWithFrame:CGRectZero];
        indicatorView.layer.cornerRadius = 8;
        indicatorView.layer.borderWidth = 0.5;
        indicatorView.layer.borderColor = [UIColor qmui_colorWithHexString:@"#B3D7F4"].CGColor;
        indicatorView.tag = 200;
        [button addSubview:indicatorView];
        [indicatorView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.height.mas_equalTo(16);
            make.left.mas_equalTo(14);
            make.top.mas_equalTo(12);
        }];
        
        // 创建一个圆形内选择指示器
        UIView *indicatorViewInner = [[UIView alloc] initWithFrame:CGRectZero];
        indicatorViewInner.backgroundColor = [UIColor qmui_colorWithHexString:@"#28A8FF"];
        indicatorViewInner.layer.cornerRadius = 3.5;
        indicatorViewInner.tag = 201;
        [indicatorView addSubview:indicatorViewInner];
        [indicatorViewInner mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.height.mas_equalTo(7);
            make.left.mas_equalTo(4.5);
            make.top.mas_equalTo(4.5);
        }];
//        indicatorViewInner.hidden= YES;
        
        // 添加标题标签
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        titleLabel.text = @"Three Days Free Trial   then ＄19.99/month";
        titleLabel.font = [UIFont systemFontOfSize:15];
        titleLabel.textColor = [UIColor qmui_colorWithHexString:@"#457387"];
        [button addSubview:titleLabel];
        [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(38);
            make.top.bottom.mas_equalTo(0);
            make.right.mas_equalTo(10);
        }];
        self.monthlyButton = button;
        [self.monthlyButton addTarget:self action:@selector(monthlyButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    }
    
    // 默认选中周订阅
    [self selectButton:self.weeklyButton];
    self.isWeeklySelected = YES;
    
    // 试用按钮
    CGFloat safebottom = SafeAreaInsetsConstantForDeviceWithNotch.bottom;
    self.trialButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.trialButton.frame = CGRectMake(47, self.view.qmui_height - 72 - 40 - safebottom, self.view.bounds.size.width - 96, 40);
    self.trialButton.layer.cornerRadius = 20;
    [self.trialButton setTitle:@"Try it free" forState:UIControlStateNormal];
    [self.trialButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.trialButton.layer.masksToBounds = YES;
    self.trialButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    [self.trialButton addTarget:self action:@selector(trialButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.trialButton];
    {
        // 1. 创建目标视图
        UIView *gradientView = self.trialButton;
        // 2. 创建渐变图层
        CAGradientLayer *gradientLayer = [CAGradientLayer layer];
            
        // 3. 配置颜色数组（必须使用 CGColor）
        gradientLayer.colors = @[
            (__bridge id)[UIColor qmui_colorWithHexString:@"#3BE2F4"].CGColor,
            (__bridge id)[UIColor qmui_colorWithHexString:@"#28A8FF"].CGColor
        ];
            
        // 4. 设置 90 度方向（从左到右水平渐变）
        gradientLayer.startPoint = CGPointMake(0, 0.5); // 左边界中点
        gradientLayer.endPoint = CGPointMake(1, 0.5);   // 右边界中点
        
        // 5. 设置图层尺寸
        gradientLayer.frame = gradientView.bounds;
        
        // 6. 添加到视图图层
        [gradientView.layer insertSublayer:gradientLayer atIndex:0];
    }
    
    UIView *lineView = [[UIView alloc] initWithFrame:CGRectZero];
    lineView.backgroundColor = [UIColor qmui_colorWithHexString:@"#A1B8CB"];
    [self.view addSubview:lineView];
    [lineView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(self.view.mas_centerX);
        make.top.mas_equalTo(self.trialButton.mas_bottom).mas_offset(22.5);
        make.width.mas_equalTo(0.5);
        make.height.mas_equalTo(12);
    }];
    
    {
        
        QMUIButton *tearmButton = [QMUIButton buttonWithType:UIButtonTypeCustom];
        [self.view addSubview:tearmButton];
        [tearmButton setTitle:@"Terms Of Use" forState:UIControlStateNormal];
        [tearmButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.mas_equalTo(lineView.mas_left).mas_offset(-17.5);
            make.width.mas_greaterThanOrEqualTo(1);
            make.height.mas_equalTo(17);
            make.centerY.mas_equalTo(lineView.mas_centerY);
        }];
        tearmButton.titleLabel.font = [UIFont systemFontOfSize:12];
        [tearmButton setTitleColor:[UIColor qmui_colorWithHexString:@"#457387"] forState:UIControlStateNormal];
    }
    
    {
        
        QMUIButton *privacyButton = [QMUIButton buttonWithType:UIButtonTypeCustom];
        [self.view addSubview:privacyButton];
        [privacyButton setTitle:@"Privacy Policy" forState:UIControlStateNormal];
        [privacyButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(lineView.mas_left).mas_offset(17.5);
            make.width.mas_greaterThanOrEqualTo(1);
            make.height.mas_equalTo(17);
            make.centerY.mas_equalTo(lineView.mas_centerY);
        }];
        privacyButton.titleLabel.font = [UIFont systemFontOfSize:12];
        [privacyButton setTitleColor:[UIColor qmui_colorWithHexString:@"#457387"] forState:UIControlStateNormal];
    }
}

- (UIButton *)createSubscriptionButtonWithFrame:(CGRect)frame title:(NSString *)title {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = frame;
    button.backgroundColor = [UIColor colorWithRed:0.9 green:0.95 blue:1.0 alpha:0.8];
    button.layer.cornerRadius = 25;
    
    // 创建一个圆形选择指示器
    UIView *indicatorView = [[UIView alloc] initWithFrame:CGRectMake(15, 15, 20, 20)];
    indicatorView.layer.cornerRadius = 10;
    indicatorView.layer.borderWidth = 2;
    indicatorView.layer.borderColor = [UIColor colorWithRed:0 green:0.8 blue:1.0 alpha:1.0].CGColor;
    indicatorView.tag = 100;
    [button addSubview:indicatorView];
    
    // 添加标题标签
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(45, 0, frame.size.width - 60, frame.size.height)];
    titleLabel.text = title;
    titleLabel.font = [UIFont systemFontOfSize:16];
    titleLabel.textColor = [UIColor darkGrayColor];
    [button addSubview:titleLabel];
    
    return button;
}

- (void)selectButton:(UIButton *)button {
    // 重置所有按钮
    [self resetButtonSelection:self.weeklyButton];
    [self resetButtonSelection:self.monthlyButton];
    
    // 选中当前按钮
    UIView *indicatorView = [button viewWithTag:200];
    UIView *indicatorViewInner = [indicatorView viewWithTag:201];
    indicatorViewInner.hidden = NO;
    indicatorView.layer.borderColor = [UIColor qmui_colorWithHexString:@"#28A8FF"].CGColor;
}

- (void)resetButtonSelection:(UIButton *)button {
    UIView *indicatorView = [button viewWithTag:200];
    UIView *indicatorViewInner = [indicatorView viewWithTag:201];
    indicatorViewInner.hidden = YES;
    indicatorView.layer.borderColor = [UIColor qmui_colorWithHexString:@"#B3D7F4"].CGColor;
}

#pragma mark - Button Actions

- (void)closeButtonTapped {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)restoreButtonTapped {
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

- (void)weeklyButtonTapped {
    [self selectButton:self.weeklyButton];
    self.isWeeklySelected = YES;
    
    if (self.products.count > 0) {
        self.selectedProduct = self.products[0]; // 假设第一个产品是周订阅
    }
}

- (void)monthlyButtonTapped {
    [self selectButton:self.monthlyButton];
    self.isWeeklySelected = NO;
    
    if (self.products.count > 1) {
        self.selectedProduct = self.products[1]; // 假设第二个产品是月订阅
    }
}

- (void)trialButtonTapped {
    if (!self.selectedProduct) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"The product is unavailable."
                                                                       message:@"Unable to obtain product information. Please try again later."
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Confirm" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    
    // 检查是否可以付款
    if ([SKPaymentQueue canMakePayments]) {
        SKPayment *payment = [SKPayment paymentWithProduct:self.selectedProduct];
        [[SKPaymentQueue defaultQueue] addPayment:payment];
    } else {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Payment restricted"
                                                                       message:@"Your device is not permitted to make in-app purchases."
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Confirm" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

#pragma mark - IAP Setup

- (void)setupIAP {
    // 注册为交易观察者
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    
    // 产品ID
    NSSet *productIdentifiers = [NSSet setWithArray:@[
        @"com.yourcompany.qingli.weekly",
        @"com.yourcompany.qingli.monthly"
    ]];
    
    // 创建产品请求
    SKProductsRequest *productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:productIdentifiers];
    productsRequest.delegate = self;
    [productsRequest start];
}

#pragma mark - SKProductsRequestDelegate

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    self.products = response.products;
    
    if (self.products.count > 0) {
        // 默认选择第一个产品（周订阅）
        self.selectedProduct = self.products[0];
        
        // 更新UI显示产品信息
        [self updateProductInfo];
    } else {
        NSLog(@"No available products.");
    }
    
    for (NSString *invalidIdentifier in response.invalidProductIdentifiers) {
        NSLog(@"Invalid product ID: %@", invalidIdentifier);
    }
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
    NSLog(@"Product request failed: %@", error.localizedDescription);
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Fail To Load"
                                                                   message:@"The product information cannot be loaded. Please check your network connection and try again."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Confirm" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)updateProductInfo {
    // 更新周订阅按钮
    if (self.products.count > 0) {
        SKProduct *weeklyProduct = self.products[0];
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
        formatter.numberStyle = NSNumberFormatterCurrencyStyle;
        formatter.locale = weeklyProduct.priceLocale;
        NSString *weeklyPrice = [formatter stringFromNumber:weeklyProduct.price];
        
        UILabel *weeklyLabel = [self.weeklyButton.subviews objectAtIndex:1];
        weeklyLabel.text = [NSString stringWithFormat:@"Three Days Free Trial  then %@/week", weeklyPrice];
    }
    
    // 更新月订阅按钮
    if (self.products.count > 1) {
        SKProduct *monthlyProduct = self.products[1];
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
        formatter.numberStyle = NSNumberFormatterCurrencyStyle;
        formatter.locale = monthlyProduct.priceLocale;
        NSString *monthlyPrice = [formatter stringFromNumber:monthlyProduct.price];
        
        UILabel *monthlyLabel = [self.monthlyButton.subviews objectAtIndex:1];
        monthlyLabel.text = [NSString stringWithFormat:@"Three Days Free Trial  then %@/month", monthlyPrice];
    }
}

#pragma mark - SKPaymentTransactionObserver

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions {
    for (SKPaymentTransaction *transaction in transactions) {
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchasing:
                [self handlePurchasingState:transaction];
                break;
            case SKPaymentTransactionStatePurchased:
                [self handlePurchasedState:transaction];
                break;
            case SKPaymentTransactionStateFailed:
                [self handleFailedState:transaction];
                break;
            case SKPaymentTransactionStateRestored:
                [self handleRestoredState:transaction];
                break;
            case SKPaymentTransactionStateDeferred:
                [self handleDeferredState:transaction];
                break;
            default:
                break;
        }
    }
}

- (void)handlePurchasingState:(SKPaymentTransaction *)transaction {
    NSLog(@"正在购买...");
}

- (void)handlePurchasedState:(SKPaymentTransaction *)transaction {
    NSLog(@"购买成功: %@", transaction.payment.productIdentifier);
    
    // 解锁功能
    [self unlockFeatures:transaction.payment.productIdentifier];
    
    // 完成交易
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    
    // 显示成功消息
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"purchase succeeds"
                                                                   message:@"You have successfully subscribed to the premium features!"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Confirm" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)handleFailedState:(SKPaymentTransaction *)transaction {
    NSLog(@"购买失败: %@", transaction.error.localizedDescription);
    
    // 完成交易
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    
    // 显示错误消息
    if (transaction.error.code != SKErrorPaymentCancelled) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Purchase failed"
                                                                       message:transaction.error.localizedDescription
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Confirm" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)handleRestoredState:(SKPaymentTransaction *)transaction {
    NSLog(@"恢复购买: %@", transaction.originalTransaction.payment.productIdentifier);
    
    // 解锁功能
    [self unlockFeatures:transaction.originalTransaction.payment.productIdentifier];
    
    // 完成交易
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

- (void)handleDeferredState:(SKPaymentTransaction *)transaction {
    NSLog(@"购买延迟: %@", transaction.payment.productIdentifier);
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue {
    NSLog(@"恢复购买完成");
    
    if (queue.transactions.count == 0) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"restore purchase"
                                                                       message:@"No previous purchase records were found."
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Confirm" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    } else {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"restore purchase"
                                                                       message:@"Your purchase has been successfully restored!"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Confirm" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self dismissViewControllerAnimated:YES completion:nil];
        }]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error {
    NSLog(@"恢复购买失败: %@", error.localizedDescription);
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Failed to restore purchase."
                                                                   message:error.localizedDescription
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Confirm" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Helper Methods

- (void)unlockFeatures:(NSString *)productIdentifier {
    // 保存购买状态到UserDefaults
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:YES forKey:@"isPremiumUser"];
    [defaults setObject:productIdentifier forKey:@"purchasedProduct"];
    [defaults setObject:[NSDate date] forKey:@"purchaseDate"];
    [defaults synchronize];
    
    // 发送通知，通知应用其他部分用户已升级
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UserDidPurchasePremium" object:nil];
}

- (void)dealloc {
    // 移除交易观察者
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
}

@end
