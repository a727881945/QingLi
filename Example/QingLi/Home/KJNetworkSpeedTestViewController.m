//
//  KJNetworkSpeedTestViewController.m
//  QingLi_Example
//
//  Created by wangkejie on 2025/4/2.
//  Copyright © 2025 wangkejie. All rights reserved.
//

#import "KJNetworkSpeedTestViewController.h"

@interface KJNetworkSpeedTestViewController ()

@property (nonatomic, strong) UIView *speedometerView;
@property (nonatomic, strong) CAShapeLayer *backgroundArcLayer;
@property (nonatomic, strong) CAShapeLayer *progressArcLayer;
@property (nonatomic, strong) UILabel *speedLabel;
@property (nonatomic, strong) UILabel *unitLabel;
@property (nonatomic, strong) UILabel *statusLabel;

@property (nonatomic, strong) UIView *downloadView;
@property (nonatomic, strong) UILabel *downloadLabel;
@property (nonatomic, strong) UILabel *downloadValueLabel;

@property (nonatomic, strong) UIView *uploadView;
@property (nonatomic, strong) UILabel *uploadLabel;
@property (nonatomic, strong) UILabel *uploadValueLabel;

@property (nonatomic, strong) UIView *pingView;
@property (nonatomic, strong) UILabel *pingLabel;
@property (nonatomic, strong) UILabel *pingValueLabel;

@property (nonatomic, strong) UIButton *actionButton;

@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSTimer *speedTestTimer;
@property (nonatomic, assign) BOOL isTestRunning;
@property (nonatomic, assign) double downloadSpeed;
@property (nonatomic, assign) double uploadSpeed;
@property (nonatomic, assign) double pingTime;
@property (nonatomic, assign) NSInteger downloadedBytes;
@property (nonatomic, assign) NSInteger uploadedBytes;
@property (nonatomic, strong) NSDate *startTime;

@end

@implementation KJNetworkSpeedTestViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Speed Test";
    self.view.backgroundColor = [UIColor qmui_colorWithHexString:@"#F8FBFF"];
    CGFloat width = self.view.bounds.size.width;
    {
        CGFloat height = width / 375.0 * 216;
        UIImageView *bg = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
        bg.image = [UIImage imageNamed:@"speed_bg"];
        [self.view addSubview:bg];
        
//        CGRect avatarFrame = CGRectMake((width - 122) / 2.0, 20 + NavigationContentTop, 122, 122);
//        UIImageView *avatar = [[UIImageView alloc] initWithFrame:avatarFrame];
//        
//        avatar.image = [UIImage imageNamed:@"contact_avatar"];
//        [self.view addSubview:avatar];
    }
    
    [self setupUI];
    [self setupSession];
}

- (void)setupSession {
    NSURLSessionConfiguration *configuration =  [NSURLSessionConfiguration defaultSessionConfiguration];
    self.session = [NSURLSession sessionWithConfiguration:configuration delegate:nil delegateQueue:nil];
}

- (void)setupUI {
    CGFloat top = NavigationBarHeight;

    // 返回按钮
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"chevron.left"] 
                                                                   style:UIBarButtonItemStylePlain 
                                                                  target:self 
                                                                  action:@selector(backButtonTapped)];
    self.navigationItem.leftBarButtonItem = backButton;
    
    // 速度计视图
    self.speedometerView = [[UIView alloc] initWithFrame:CGRectMake(0, top + 100, self.view.bounds.size.width, 250)];
    [self.view addSubview:self.speedometerView];
    
    // 创建背景弧形
    self.backgroundArcLayer = [CAShapeLayer layer];
    self.backgroundArcLayer.path = [self createArcPathWithRadius:100 startAngle:-210 endAngle:30].CGPath;
    self.backgroundArcLayer.position = CGPointMake(self.speedometerView.bounds.size.width / 2, 120);
    self.backgroundArcLayer.fillColor = [UIColor clearColor].CGColor;
    self.backgroundArcLayer.strokeColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.0].CGColor;
    self.backgroundArcLayer.lineWidth = 15;
    [self.speedometerView.layer addSublayer:self.backgroundArcLayer];
    
    // 创建进度弧形
    self.progressArcLayer = [CAShapeLayer layer];
    self.progressArcLayer.path = [self createArcPathWithRadius:100 startAngle:-210 endAngle:-210].CGPath;
    self.progressArcLayer.position = CGPointMake(self.speedometerView.bounds.size.width / 2, 120);
    self.progressArcLayer.fillColor = [UIColor clearColor].CGColor;
    self.progressArcLayer.strokeColor = [UIColor colorWithRed:0.0 green:0.8 blue:1.0 alpha:1.0].CGColor;
    self.progressArcLayer.lineWidth = 15;
    self.progressArcLayer.lineCap = kCALineCapRound;
    [self.speedometerView.layer addSublayer:self.progressArcLayer];
    
    // 添加刻度标签
    [self addSpeedometerLabels];
    
    // 速度显示标签
    self.speedLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 150, 60)];
    self.speedLabel.center = CGPointMake(self.speedometerView.bounds.size.width / 2, 120);
    self.speedLabel.textAlignment = NSTextAlignmentCenter;
    self.speedLabel.font = [UIFont systemFontOfSize:40 weight:UIFontWeightBold];
    self.speedLabel.text = @"0.00";
    [self.speedometerView addSubview:self.speedLabel];
    
    // 单位标签
    self.unitLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 150, 30)];
    self.unitLabel.center = CGPointMake(self.speedometerView.bounds.size.width / 2, 150);
    self.unitLabel.textAlignment = NSTextAlignmentCenter;
    self.unitLabel.font = [UIFont systemFontOfSize:14];
    self.unitLabel.text = @"MB/S";
    [self.speedometerView addSubview:self.unitLabel];
    
    // 状态标签
    self.statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 30)];
    self.statusLabel.center = CGPointMake(self.speedometerView.bounds.size.width / 2, 200);
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    self.statusLabel.font = [UIFont systemFontOfSize:14];
    self.statusLabel.textColor = [UIColor grayColor];
    self.statusLabel.text = @"正在测速中...";
    [self.speedometerView addSubview:self.statusLabel];
    
    // 下载速度视图
    self.downloadView = [self createInfoViewWithIcon:@"arrow.down.circle.fill" color:[UIColor systemBlueColor]];
    self.downloadView.frame = CGRectMake(20, top + 350, self.view.bounds.size.width - 40, 40);
    [self.view addSubview:self.downloadView];
    
    self.downloadLabel = [self createInfoLabelWithText:@"Down Load"];
    [self.downloadView addSubview:self.downloadLabel];
    
    self.downloadValueLabel = [self createValueLabelWithText:@"0.00 Mbps"];
    [self.downloadView addSubview:self.downloadValueLabel];
    
    // 上传速度视图
    self.uploadView = [self createInfoViewWithIcon:@"arrow.up.circle.fill" color:[UIColor systemGreenColor]];
    self.uploadView.frame = CGRectMake(20, top + 400, self.view.bounds.size.width - 40, 40);
    [self.view addSubview:self.uploadView];
    
    self.uploadLabel = [self createInfoLabelWithText:@"Up Load"];
    [self.uploadView addSubview:self.uploadLabel];
    
    self.uploadValueLabel = [self createValueLabelWithText:@"0.00 Mbps"];
    [self.uploadView addSubview:self.uploadValueLabel];
    
    // Ping视图
    self.pingView = [self createInfoViewWithIcon:@"wifi.circle.fill" color:[UIColor systemOrangeColor]];
    self.pingView.frame = CGRectMake(20, top + 450, self.view.bounds.size.width - 40, 40);
    [self.view addSubview:self.pingView];
    
    self.pingLabel = [self createInfoLabelWithText:@"Ping"];
    [self.pingView addSubview:self.pingLabel];
    
    self.pingValueLabel = [self createValueLabelWithText:@"0.00 ms"];
    [self.pingView addSubview:self.pingValueLabel];
    
    // 开始/停止按钮
    self.actionButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.actionButton.frame = CGRectMake(50, top + 520, self.view.bounds.size.width - 100, 50);
    self.actionButton.backgroundColor = [UIColor colorWithRed:0.0 green:0.8 blue:1.0 alpha:1.0];
    [self.actionButton setTitle:@"Start" forState:UIControlStateNormal];
    self.actionButton.titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightMedium];
    self.actionButton.layer.cornerRadius = 25;
    [self.actionButton addTarget:self action:@selector(actionButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.actionButton];
    
    // 初始化状态
    [self resetUI];
}

- (void)addSpeedometerLabels {
    NSArray *values = @[@"0", @"25M", @"50M", @"75M", @"100M", @"1G"];
    NSArray *angles = @[@(-210), @(-168), @(-126), @(-84), @(-42), @(0)];
    
    for (int i = 0; i < values.count; i++) {
        CGFloat angle = [angles[i] floatValue] * M_PI / 180.0;
        CGFloat radius = 130;
        CGFloat x = self.speedometerView.bounds.size.width / 2 + radius * cos(angle);
        CGFloat y = 120 + radius * sin(angle);
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 40, 20)];
        label.center = CGPointMake(x, y);
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont systemFontOfSize:10];
        label.textColor = [UIColor grayColor];
        label.text = values[i];
        [self.speedometerView addSubview:label];
    }
}

- (UIView *)createInfoViewWithIcon:(NSString *)iconName color:(UIColor *)color {
    UIView *view = [[UIView alloc] init];
    view.backgroundColor = [UIColor whiteColor];
    view.layer.cornerRadius = 8;
    view.layer.shadowColor = [UIColor blackColor].CGColor;
    view.layer.shadowOffset = CGSizeMake(0, 1);
    view.layer.shadowOpacity = 0.1;
    view.layer.shadowRadius = 2;
    
    UIImageView *iconView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 10, 20, 20)];
    iconView.image = [UIImage systemImageNamed:iconName];
    iconView.tintColor = color;
    [view addSubview:iconView];
    
    return view;
}

- (UILabel *)createInfoLabelWithText:(NSString *)text {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(40, 0, 100, 40)];
    label.text = text;
    label.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    return label;
}

- (UILabel *)createValueLabelWithText:(NSString *)text {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 40)];
    label.textAlignment = NSTextAlignmentRight;
    label.text = text;
    label.font = [UIFont systemFontOfSize:14];
    label.frame = CGRectMake(self.view.bounds.size.width - 150, 0, 100, 40);
    return label;
}

- (UIBezierPath *)createArcPathWithRadius:(CGFloat)radius startAngle:(CGFloat)startAngle endAngle:(CGFloat)endAngle {
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path addArcWithCenter:CGPointZero 
                    radius:radius 
                startAngle:startAngle * M_PI / 180 
                  endAngle:endAngle * M_PI / 180 
                 clockwise:YES];
    return path;
}

- (void)backButtonTapped {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)actionButtonTapped {
    if (self.isTestRunning) {
        [self stopSpeedTest];
    } else {
        [self startSpeedTest];
    }
}

- (void)startSpeedTest {
    self.isTestRunning = YES;
    [self.actionButton setTitle:@"Stop" forState:UIControlStateNormal];
    
    // 重置UI
    [self resetUI];
    self.statusLabel.text = @"正在测速中...";
    
    // 开始测试
    [self performPingTest];
    
    // 启动定时器更新UI
    self.speedTestTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 
                                                          target:self 
                                                        selector:@selector(updateSpeedTestUI) 
                                                        userInfo:nil 
                                                         repeats:YES];
}

- (void)stopSpeedTest {
    self.isTestRunning = NO;
    [self.actionButton setTitle:@"Start" forState:UIControlStateNormal];
    
    // 停止定时器
    [self.speedTestTimer invalidate];
    self.speedTestTimer = nil;
    
    // 取消所有任务
    [self.session invalidateAndCancel];
    [self setupSession];
    
    self.statusLabel.text = @"测速已停止";
}

- (void)resetUI {
    self.downloadSpeed = 0;
    self.uploadSpeed = 0;
    self.pingTime = 0;
    
    self.speedLabel.text = @"0.00";
    self.downloadValueLabel.text = @"0.00 Mbps";
    self.uploadValueLabel.text = @"0.00 Mbps";
    self.pingValueLabel.text = @"0.00 ms";
    
    // 重置进度弧
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"path"];
    animation.duration = 0.5;
    animation.fromValue = (__bridge id)self.progressArcLayer.path;
    animation.toValue = (__bridge id)[self createArcPathWithRadius:100 startAngle:-210 endAngle:-210].CGPath;
    animation.fillMode = kCAFillModeForwards;
    animation.removedOnCompletion = NO;
    [self.progressArcLayer addAnimation:animation forKey:@"path"];
}

- (void)updateSpeedTestUI {
    // 更新速度显示
    double currentSpeed = MAX(self.downloadSpeed, self.uploadSpeed);
    self.speedLabel.text = [NSString stringWithFormat:@"%.2f", currentSpeed];
    
    // 更新进度弧
    double progress = currentSpeed / 100.0; // 假设最大速度为100MB/s
    progress = MIN(1.0, progress);
    
    CGFloat endAngle = -210 + progress * 240;
    
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"path"];
    animation.duration = 0.5;
    animation.fromValue = (__bridge id)self.progressArcLayer.path;
    animation.toValue = (__bridge id)[self createArcPathWithRadius:100 startAngle:-210 endAngle:endAngle].CGPath;
    animation.fillMode = kCAFillModeForwards;
    animation.removedOnCompletion = NO;
    [self.progressArcLayer addAnimation:animation forKey:@"path"];
    
    // 更新颜色
    UIColor *progressColor;
    if (currentSpeed < 1.0) {
        progressColor = [UIColor systemRedColor];
    } else if (currentSpeed < 5.0) {
        progressColor = [UIColor systemOrangeColor];
    } else {
        progressColor = [UIColor colorWithRed:0.0 green:0.8 blue:1.0 alpha:1.0];
    }
    
    CABasicAnimation *colorAnimation = [CABasicAnimation animationWithKeyPath:@"strokeColor"];
    colorAnimation.duration = 0.5;
    colorAnimation.fromValue = (__bridge id)self.progressArcLayer.strokeColor;
    colorAnimation.toValue = (__bridge id)progressColor.CGColor;
    colorAnimation.fillMode = kCAFillModeForwards;
    colorAnimation.removedOnCompletion = NO;
    [self.progressArcLayer addAnimation:colorAnimation forKey:@"strokeColor"];
    
    // 更新下载/上传/Ping值
    self.downloadValueLabel.text = [NSString stringWithFormat:@"%.2f Mbps", self.downloadSpeed * 8];
    self.uploadValueLabel.text = [NSString stringWithFormat:@"%.2f Mbps", self.uploadSpeed * 8];
    self.pingValueLabel.text = [NSString stringWithFormat:@"%.2f ms", self.pingTime];
}

#pragma mark - Speed Test Methods

- (void)performPingTest {
    NSString *host = @"www.baidu.com";
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    config.timeoutIntervalForRequest = 10.0;
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
    
    NSDate *startTime = [NSDate date];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@", host]];
    NSURLSessionDataTask *task = [session dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSTimeInterval pingTime = [[NSDate date] timeIntervalSinceDate:startTime] * 1000; // 转换为毫秒
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!error) {
                self.pingTime = pingTime;
                self.pingValueLabel.text = [NSString stringWithFormat:@"%.2f ms", pingTime];
                
                // Ping测试完成后开始下载测试
                [self performDownloadTest];
            } else {
                self.pingValueLabel.text = @"Error";
                // 尝试下载测试
                [self performDownloadTest];
            }
        });
    }];
    
    [task resume];
}

- (void)performDownloadTest {
    // 使用大文件进行下载测试
    NSURL *url = [NSURL URLWithString:@"https://speed.cloudflare.com/__down?bytes=25000000"];
    
    self.downloadedBytes = 0;
    self.startTime = [NSDate date];
    
    NSURLSessionDataTask *downloadTask = [self.session dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!error && data) {
                NSTimeInterval duration = [[NSDate date] timeIntervalSinceDate:self.startTime];
                if (duration > 0) {
                    self.downloadSpeed = (data.length / 1024.0 / 1024.0) / duration; // MB/s
                }
                
                // 下载测试完成后开始上传测试
                [self performUploadTest];
            } else {
                self.downloadValueLabel.text = @"Error";
                // 尝试上传测试
                [self performUploadTest];
            }
        });
    }];
    
    [downloadTask resume];
}

- (void)performUploadTest {
    // 创建一个大的数据包进行上传测试
    NSMutableData *uploadData = [NSMutableData dataWithCapacity:5 * 1024 * 1024]; // 5MB
    for (int i = 0; i < 5 * 1024 * 1024; i++) {
        uint8_t byte = (uint8_t)(i % 256);
        [uploadData appendBytes:&byte length:1];
    }
    
    NSURL *url = [NSURL URLWithString:@"https://speed.cloudflare.com/__up"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/octet-stream" forHTTPHeaderField:@"Content-Type"];
    
    self.uploadedBytes = 0;
    self.startTime = [NSDate date];
    
    NSURLSessionUploadTask *uploadTask = [self.session uploadTaskWithRequest:request fromData:uploadData completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!error) {
                NSTimeInterval duration = [[NSDate date] timeIntervalSinceDate:self.startTime];
                if (duration > 0) {
                    self.uploadSpeed = (uploadData.length / 1024.0 / 1024.0) / duration; // MB/s
                }
                
                // 测试完成
                if (self.isTestRunning) {
                    self.statusLabel.text = @"测速完成";
                }
            } else {
                self.uploadValueLabel.text = @"Error";
                if (self.isTestRunning) {
                    self.statusLabel.text = @"测速完成(部分错误)";
                }
            }
        });
    }];
    
    [uploadTask resume];
}

@end
