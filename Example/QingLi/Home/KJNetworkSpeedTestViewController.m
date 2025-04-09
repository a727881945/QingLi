//
//  KJNetworkSpeedTestViewController.m
//  QingLi_Example
//
//  Created by wangkejie on 2025/4/2.
//  Copyright © 2025 wangkejie. All rights reserved.
//

#import "KJNetworkSpeedTestViewController.h"
#import <objc/runtime.h>

@interface KJNetworkSpeedTestViewController () <NSURLSessionDataDelegate, NSURLSessionTaskDelegate>

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
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, strong) CAShapeLayer *maskLayer;
@property (nonatomic, assign) BOOL isTestRunning;
@property (nonatomic, assign) double downloadSpeed; // 单位: MB/s
@property (nonatomic, assign) double uploadSpeed; // 单位: MB/s
@property (nonatomic, assign) double pingTime;
@property (nonatomic, assign) NSInteger downloadedBytes;
@property (nonatomic, assign) NSInteger uploadedBytes;
@property (nonatomic, strong) NSDate *startTime;
@property (nonatomic, strong) NSDate *lastUpdateTime;
@property (nonatomic, assign) double currentInstantSpeed; // 单位: Mbps (显示用)
@property (nonatomic, assign) BOOL isDownloadTesting;
@property (nonatomic, assign) BOOL isUploadTesting;
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
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    self.session = [NSURLSession sessionWithConfiguration:configuration 
                                                 delegate:self 
                                            delegateQueue:nil];
}

- (void)setupUI {
    CGFloat top = NavigationBarHeight;
    
    // 返回按钮
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"chevron.left"] 
                                                                   style:UIBarButtonItemStylePlain 
                                                                  target:self 
                                                                  action:@selector(backButtonTapped)];
    backButton.tintColor = [UIColor blackColor];
    self.navigationItem.leftBarButtonItem = backButton;
    
    // 标题颜色
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor blackColor]};
    
    // 速度计视图
    self.speedometerView = [[UIView alloc] initWithFrame:CGRectMake(0, top + 92, self.view.bounds.size.width, 250)];
    [self.view addSubview:self.speedometerView];
    
    // 使用CADisplayLink代替NSTimer来获得更流畅的动画
    [self setupDisplayLink];
    
    // 创建背景弧形 - 使用渐变效果，修改角度为从-210到30
    self.backgroundArcLayer = [CAShapeLayer layer];
    self.backgroundArcLayer.path = [self createArcPathWithRadius:110 startAngle:-210 endAngle:30].CGPath;
    self.backgroundArcLayer.position = CGPointMake(self.speedometerView.bounds.size.width / 2, 120);
    self.backgroundArcLayer.fillColor = [UIColor clearColor].CGColor;
    self.backgroundArcLayer.strokeColor = [UIColor colorWithRed:0.95 green:0.95 blue:0.95 alpha:1.0].CGColor;
    self.backgroundArcLayer.lineWidth = 18;
    self.backgroundArcLayer.lineCap = kCALineCapRound;
    [self.speedometerView.layer addSublayer:self.backgroundArcLayer];
    
    // 添加背景渐变
    CAGradientLayer *bgGradientLayer = [CAGradientLayer layer];
    bgGradientLayer.frame = self.speedometerView.bounds;
    bgGradientLayer.colors = @[
        (__bridge id)[UIColor colorWithRed:0.95 green:0.95 blue:0.95 alpha:1.0].CGColor,
        (__bridge id)[UIColor colorWithRed:0.98 green:0.98 blue:0.98 alpha:1.0].CGColor
    ];
    bgGradientLayer.startPoint = CGPointMake(0, 0);
    bgGradientLayer.endPoint = CGPointMake(1, 1);
    
    CAShapeLayer *bgMaskLayer = [CAShapeLayer layer];
    bgMaskLayer.path = [self createArcPathWithRadius:110 startAngle:-210 endAngle:30].CGPath;
    bgMaskLayer.position = CGPointMake(self.speedometerView.bounds.size.width / 2, 120);
    bgMaskLayer.fillColor = [UIColor clearColor].CGColor;
    bgMaskLayer.strokeColor = [UIColor whiteColor].CGColor;
    bgMaskLayer.lineWidth = 18;
    bgMaskLayer.lineCap = kCALineCapRound;
    
    bgGradientLayer.mask = bgMaskLayer;
    [self.speedometerView.layer addSublayer:bgGradientLayer];
    
    // 改用直接可见的进度弧
    CAShapeLayer *progressArcLayer = [CAShapeLayer layer];
    progressArcLayer.path = [self createArcPathWithRadius:110 startAngle:-210 endAngle:-210].CGPath;
    progressArcLayer.position = CGPointMake(self.speedometerView.bounds.size.width / 2, 120);
    progressArcLayer.fillColor = [UIColor clearColor].CGColor;
    progressArcLayer.strokeColor = [UIColor systemBlueColor].CGColor;
    progressArcLayer.lineWidth = 18;
    progressArcLayer.lineCap = kCALineCapRound;
    [self.speedometerView.layer addSublayer:progressArcLayer];
    
    // 保存强引用
    self.maskLayer = progressArcLayer;
    
    // 添加刻度标签
    [self addSpeedometerLabels];
    
    // 内部圆形背景
    UIView *innerCircle = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 170, 170)];
    innerCircle.center = CGPointMake(self.speedometerView.bounds.size.width / 2, 120);
    innerCircle.layer.cornerRadius = 85;
    innerCircle.backgroundColor = [UIColor whiteColor];
    innerCircle.layer.shadowColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.1].CGColor;
    innerCircle.layer.shadowOffset = CGSizeMake(0, 2);
    innerCircle.layer.shadowRadius = 10;
    innerCircle.layer.shadowOpacity = 0.5;
    [self.speedometerView addSubview:innerCircle];
    
    // 速度显示标签
    self.speedLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 160, 70)];
    self.speedLabel.center = CGPointMake(self.speedometerView.bounds.size.width / 2, 110);
    self.speedLabel.textAlignment = NSTextAlignmentCenter;
    self.speedLabel.font = [UIFont systemFontOfSize:40 weight:UIFontWeightBold];
    self.speedLabel.text = @"0.00";
    [self.speedometerView addSubview:self.speedLabel];
    
    // 单位标签 - 修改为Mbps
    self.unitLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 150, 30)];
    self.unitLabel.center = CGPointMake(self.speedometerView.bounds.size.width / 2, 145);
    self.unitLabel.textAlignment = NSTextAlignmentCenter;
    self.unitLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    self.unitLabel.textColor = [UIColor darkGrayColor];
    self.unitLabel.text = @"Mbps";
    [self.speedometerView addSubview:self.unitLabel];
    
    // 状态标签
    self.statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width - 60, 30)];
    self.statusLabel.center = CGPointMake(self.speedometerView.bounds.size.width / 2, 230);
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    self.statusLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
    self.statusLabel.textColor = [UIColor grayColor];
    self.statusLabel.text = @"Tap Start to begin speed test";
    [self.speedometerView addSubview:self.statusLabel];
    
    // 下载速度视图 - 增加高度
    self.downloadView = [self createInfoViewWithIcon:@"arrow.down.circle.fill" color:[UIColor systemBlueColor]];
    self.downloadView.frame = CGRectMake(20, top + 358, self.view.bounds.size.width - 40, 60);
    [self.view addSubview:self.downloadView];
    
    self.downloadLabel = [self createInfoLabelWithText:@"Download"];
    [self.downloadView addSubview:self.downloadLabel];
    
    self.downloadValueLabel = [self createValueLabelWithText:@"0.00 Mbps"];
    [self.downloadView addSubview:self.downloadValueLabel];
    
    // 上传速度视图 - 增加高度
    self.uploadView = [self createInfoViewWithIcon:@"arrow.up.circle.fill" color:[UIColor systemGreenColor]];
    self.uploadView.frame = CGRectMake(20, top + 428, self.view.bounds.size.width - 40, 60);
    [self.view addSubview:self.uploadView];
    
    self.uploadLabel = [self createInfoLabelWithText:@"Upload"];
    [self.uploadView addSubview:self.uploadLabel];
    
    self.uploadValueLabel = [self createValueLabelWithText:@"0.00 Mbps"];
    [self.uploadView addSubview:self.uploadValueLabel];
    
    // Ping视图 - 增加高度
    self.pingView = [self createInfoViewWithIcon:@"wifi.circle.fill" color:[UIColor systemOrangeColor]];
    self.pingView.frame = CGRectMake(20, top + 498, self.view.bounds.size.width - 40, 60);
    [self.view addSubview:self.pingView];
    
    self.pingLabel = [self createInfoLabelWithText:@"Ping"];
    [self.pingView addSubview:self.pingLabel];
    
    self.pingValueLabel = [self createValueLabelWithText:@"0.00 ms"];
    [self.pingView addSubview:self.pingValueLabel];
    
    // 开始/停止按钮
    self.actionButton = [UIButton buttonWithType:UIButtonTypeCustom];
    CGFloat buttonY = self.view.bounds.size.height - 72.5 - 55 - self.view.safeAreaInsets.bottom;
    self.actionButton.frame = CGRectMake(50, buttonY, self.view.bounds.size.width - 100, 55);
    
    // 添加渐变背景到按钮
    CAGradientLayer *buttonGradient = [CAGradientLayer layer];
    buttonGradient.frame = CGRectMake(0, 0, self.view.bounds.size.width - 100, 55);
    buttonGradient.colors = @[
        (__bridge id)[UIColor colorWithRed:0.0 green:0.8 blue:1.0 alpha:1.0].CGColor,
        (__bridge id)[UIColor colorWithRed:0.0 green:0.7 blue:0.9 alpha:1.0].CGColor
    ];
    buttonGradient.startPoint = CGPointMake(0, 0);
    buttonGradient.endPoint = CGPointMake(1, 1);
    buttonGradient.cornerRadius = 27.5;
    [self.actionButton.layer insertSublayer:buttonGradient atIndex:0];
    
    [self.actionButton setTitle:@"Start Test" forState:UIControlStateNormal];
    self.actionButton.titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold];
    self.actionButton.layer.cornerRadius = 27.5;
    self.actionButton.layer.shadowColor = [UIColor colorWithRed:0 green:0.7 blue:1.0 alpha:0.5].CGColor;
    self.actionButton.layer.shadowOffset = CGSizeMake(0, 4);
    self.actionButton.layer.shadowRadius = 8;
    self.actionButton.layer.shadowOpacity = 0.5;
    [self.actionButton addTarget:self action:@selector(actionButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.actionButton];
    
    // 初始化状态
    [self resetUI];
}

- (void)setupDisplayLink {
    // 确保在主线程创建和配置DisplayLink
    if (!NSThread.isMainThread) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setupDisplayLink];
        });
        return;
    }
    
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateAnimation:)];
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    self.displayLink.paused = YES;
}

- (void)updateAnimation:(CADisplayLink *)displayLink {
    // CADisplayLink已经在主线程运行，但添加安全检查
    if (!NSThread.isMainThread) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateAnimation:displayLink];
        });
        return;
    }
    
    if (!self.isTestRunning) return;
    
    static double lastSpeed = 0;
    // 根据当前测试阶段选择合适的速度值
    double currentSpeedMBps = 0; // MB/s
    
    if (self.isDownloadTesting) {
        currentSpeedMBps = self.downloadSpeed; // MB/s
        // 测试进行中也更新相应的值标签 (显示为Mbps)
        if (currentSpeedMBps > 0) {
            double displaySpeedMbps = currentSpeedMBps * 8.0; // 转换为Mbps
            self.downloadValueLabel.text = [NSString stringWithFormat:@"%.2f Mbps", displaySpeedMbps];
        }
    } else if (self.isUploadTesting) {
        currentSpeedMBps = self.uploadSpeed; // MB/s
        // 测试进行中也更新相应的值标签 (显示为Mbps)
        if (currentSpeedMBps > 0) {
            double displaySpeedMbps = currentSpeedMBps * 8.0; // 转换为Mbps
            self.uploadValueLabel.text = [NSString stringWithFormat:@"%.2f Mbps", displaySpeedMbps];
        }
    } else {
        // 当测试完成后，显示下载速度
        if (self.downloadSpeed > 0) {
            currentSpeedMBps = self.downloadSpeed; // MB/s
        }
    }
    
    // 平滑过渡速度变化 - 使动画更流畅 (仍使用MB/s)
    double animatedSpeedMBps = lastSpeed + (currentSpeedMBps - lastSpeed) * 0.1;
    lastSpeed = animatedSpeedMBps;
    
    // 转换为Mbps用于显示
    double displaySpeedMbps = animatedSpeedMBps * 8.0; // 转换为Mbps
    
    // 更新显示值 (Mbps)
    self.currentInstantSpeed = displaySpeedMbps;
    self.speedLabel.text = [NSString stringWithFormat:@"%.2f", displaySpeedMbps];
    
    // 更新进度弧 - 调整为最大225Mbps
    double progress = displaySpeedMbps / 225.0; // 使用Mbps的值来计算进度
    progress = MIN(1.0, MAX(0.0, progress));
    
    CGFloat endAngle = -210 + progress * 240; // 240度为完整弧度范围(-210到30)
    
    if (self.maskLayer) {
        // 使用原生UIView动画
        [UIView animateWithDuration:0.1 animations:^{
            UIBezierPath *newPath = [self createArcPathWithRadius:110 startAngle:-210 endAngle:endAngle];
            self.maskLayer.path = newPath.CGPath;
            
            // 根据速度改变颜色 - 调整阈值
            if (displaySpeedMbps < 50.0) {
                self.maskLayer.strokeColor = [UIColor systemRedColor].CGColor;
            } else if (displaySpeedMbps < 125.0) {
                self.maskLayer.strokeColor = [UIColor systemOrangeColor].CGColor;
            } else {
                self.maskLayer.strokeColor = [UIColor systemBlueColor].CGColor;
            }
        }];
    } else {
        // 移除错误日志，改为静默失败
    }
    
    // 确保下载测试结束后显示的是最终下载速度
    if (!self.isDownloadTesting && !self.isUploadTesting && self.downloadSpeed > 0) {
        // 测试完成，确保显示最终下载速度 (MB/s -> Mbps)
        double finalDownloadSpeedMbps = self.downloadSpeed * 8.0; // 转换为Mbps
        
        if ([self.speedLabel.text doubleValue] != finalDownloadSpeedMbps) {
            // 如果当前显示的值不是最终下载速度，则更新
            self.speedLabel.text = [NSString stringWithFormat:@"%.2f", finalDownloadSpeedMbps];
            [self updateSpeedometerTo:finalDownloadSpeedMbps];
        }
    }
}

- (void)addSpeedometerLabels {
    // 修改为9个均匀分布的点：0, 25, 50, 75, 100, 125, 150, 175, 225
    NSArray *values = @[@"0", @"25", @"50", @"75", @"100", @"125", @"150", @"175", @"225"];
    // 均匀分布角度从-210到30，保持对称
    NSArray *angles = @[@(-210), @(-180), @(-150), @(-120), @(-90), @(-60), @(-30), @(0), @(30)];
    
    for (int i = 0; i < values.count; i++) {
        CGFloat angle = [angles[i] floatValue] * M_PI / 180.0;
        CGFloat radius = 145;
        CGFloat x = self.speedometerView.bounds.size.width / 2 + radius * cos(angle);
        CGFloat y = 120 + radius * sin(angle);
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 40, 20)];
        label.center = CGPointMake(x, y);
        label.textAlignment = NSTextAlignmentCenter;
        // 使刻度标签字体更清晰，更现代化
        label.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
        label.textColor = [UIColor darkGrayColor];
        label.text = values[i];
        [self.speedometerView addSubview:label];
        
        // 添加小刻度线
        CAShapeLayer *tickLayer = [CAShapeLayer layer];
        CGFloat tickStartRadius = 125;
        CGFloat tickEndRadius = 132;
        
        UIBezierPath *tickPath = [UIBezierPath bezierPath];
        [tickPath moveToPoint:CGPointMake(self.speedometerView.bounds.size.width / 2 + tickStartRadius * cos(angle), 
                                          120 + tickStartRadius * sin(angle))];
        [tickPath addLineToPoint:CGPointMake(self.speedometerView.bounds.size.width / 2 + tickEndRadius * cos(angle), 
                                             120 + tickEndRadius * sin(angle))];
        
        tickLayer.path = tickPath.CGPath;
        tickLayer.strokeColor = [UIColor lightGrayColor].CGColor;
        tickLayer.lineWidth = 2;
        [self.speedometerView.layer addSublayer:tickLayer];
    }
    
    // 添加更多中间小刻度，确保均匀分布在-210到30度之间
    CGFloat totalAngleRange = 240.0; // 从-210到30度，总共240度
    int numberOfTicks = 24; // 设置小刻度总数
    CGFloat angleStep = totalAngleRange / numberOfTicks; // 每个小刻度之间的角度间隔
    
    for (int i = 0; i <= numberOfTicks; i++) {
        CGFloat tickAngle = -210 + i * angleStep;
        
        // 检查是否是主刻度位置
        BOOL isMainTick = NO;
        for (NSNumber *angle in angles) {
            if (fabs(tickAngle - [angle floatValue]) < 0.5) { // 允许小误差
                isMainTick = YES;
                break;
            }
        }
        
        if (!isMainTick) {
            CGFloat angle = tickAngle * M_PI / 180.0; // 转换为弧度
            CGFloat tickStartRadius = 128;
            CGFloat tickEndRadius = 132;
            
            CAShapeLayer *tickLayer = [CAShapeLayer layer];
            
            UIBezierPath *tickPath = [UIBezierPath bezierPath];
            [tickPath moveToPoint:CGPointMake(self.speedometerView.bounds.size.width / 2 + tickStartRadius * cos(angle), 
                                              120 + tickStartRadius * sin(angle))];
            [tickPath addLineToPoint:CGPointMake(self.speedometerView.bounds.size.width / 2 + tickEndRadius * cos(angle), 
                                                 120 + tickEndRadius * sin(angle))];
            
            tickLayer.path = tickPath.CGPath;
            tickLayer.strokeColor = [UIColor lightGrayColor].CGColor;
            tickLayer.lineWidth = 1;
            [self.speedometerView.layer addSublayer:tickLayer];
        }
    }
}

- (UIView *)createInfoViewWithIcon:(NSString *)iconName color:(UIColor *)color {
    UIView *view = [[UIView alloc] init];
    view.backgroundColor = [UIColor whiteColor];
    view.layer.cornerRadius = 16;
    view.layer.shadowColor = [UIColor blackColor].CGColor;
    view.layer.shadowOffset = CGSizeMake(0, 2);
    view.layer.shadowOpacity = 0.1;
    view.layer.shadowRadius = 4;
    
    // 增大图标尺寸
    UIImageView *iconView = [[UIImageView alloc] initWithFrame:CGRectMake(16, 15, 30, 30)];
    UIImage *icon = [UIImage systemImageNamed:iconName];
    UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:24 weight:UIImageSymbolWeightMedium];
    iconView.image = [icon imageByApplyingSymbolConfiguration:config];
    iconView.tintColor = color;
    iconView.contentMode = UIViewContentModeScaleAspectFit;
    [view addSubview:iconView];
    
    return view;
}

- (UILabel *)createInfoLabelWithText:(NSString *)text {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(60, 0, 120, 60)];
    label.text = text;
    label.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    label.textColor = [UIColor darkGrayColor];
    return label;
}

- (UILabel *)createValueLabelWithText:(NSString *)text {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 130, 60)];
    label.textAlignment = NSTextAlignmentRight;
    label.text = text;
    label.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
    label.textColor = [UIColor blackColor];
    label.frame = CGRectMake(self.view.bounds.size.width - 180, 0, 130, 60);
    return label;
}

// 为了确保系统正确处理maskLayer的更新，修改createArcPathWithRadius方法
- (UIBezierPath *)createArcPathWithRadius:(CGFloat)radius startAngle:(CGFloat)startAngle endAngle:(CGFloat)endAngle {
    // 注意：UIBezierPath默认是顺时针方向，而CAShapeLayer是逆时针
    // 确保一致的绘制方向
    UIBezierPath *path = [UIBezierPath bezierPath];
    CGPoint center = CGPointZero; // CAShapeLayer使用其自身坐标系
    
    [path moveToPoint:CGPointMake(center.x + radius * cos(startAngle * M_PI / 180.0),
                                 center.y + radius * sin(startAngle * M_PI / 180.0))];
    
    [path addArcWithCenter:center
                    radius:radius
                startAngle:startAngle * M_PI / 180.0
                  endAngle:endAngle * M_PI / 180.0
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
    [self.actionButton setTitle:@"Stop Test" forState:UIControlStateNormal];
    
    // 重置UI
    [self resetUI];
    self.statusLabel.text = @"Speed test is in progress...";
    
    // 开始测试
    [self performPingTest];
    
    // 启动CADisplayLink进行动画更新
    self.displayLink.paused = NO;
}

- (void)stopSpeedTest {
    self.isTestRunning = NO;
    [self.actionButton setTitle:@"Start Test" forState:UIControlStateNormal];
    
    // 停止CADisplayLink
    self.displayLink.paused = YES;
    
    self.isDownloadTesting = NO;
    self.isUploadTesting = NO;
    
    // 取消所有任务
    [self.session invalidateAndCancel];
    [self setupSession];
    
    self.statusLabel.text = @"The speed measurement has been stopped.";
}

- (void)resetUI {
    self.downloadSpeed = 0;
    self.uploadSpeed = 0;
    self.pingTime = 0;
    
    self.speedLabel.text = @"0.00";
    self.downloadValueLabel.text = @"-- Mbps";
    self.uploadValueLabel.text = @"-- Mbps";
    self.pingValueLabel.text = @"-- ms";
    self.statusLabel.text = @"Press start to test speed";
    [self updateSpeedometerTo:0];
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
    // 使用大文件进行下载测试，设置测试时间为15秒
    NSURL *url = [NSURL URLWithString:@"https://speed.cloudflare.com/__down?bytes=50000000"];
    
    self.downloadedBytes = 0;
    self.startTime = [NSDate date];
    self.lastUpdateTime = [NSDate date];
    self.isDownloadTesting = YES;
    self.isUploadTesting = NO;
    self.statusLabel.text = @"Testing download speed...";
    
    // 设置15秒后自动结束下载测试
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.isDownloadTesting) {
            // 计算平均下载速度
            NSTimeInterval duration = [[NSDate date] timeIntervalSinceDate:self.startTime];
            if (duration > 0) {
                // 计算最终平均下载速度 (MB/s)
                double averageSpeedMBps = (self.downloadedBytes / 1024.0 / 1024.0) / duration;
                
                // 存储最终的平均下载速度 (MB/s)
                self.downloadSpeed = averageSpeedMBps;
                
                // 转换为Mbps用于显示
                double displaySpeedMbps = averageSpeedMBps * 8.0;
                
                // 同时更新中心标签和下载值标签 (Mbps)
                self.downloadValueLabel.text = [NSString stringWithFormat:@"%.2f Mbps", displaySpeedMbps];
                self.speedLabel.text = [NSString stringWithFormat:@"%.2f", displaySpeedMbps];
                
                // 更新仪表盘UI (Mbps)
                [self updateSpeedometerTo:displaySpeedMbps];
            }
            
            // 结束下载测试，开始上传测试
            self.isDownloadTesting = NO;
            [self performUploadTest];
        }
    });
    
    NSURLSessionDataTask *downloadTask = [self.session dataTaskWithURL:url];
    [downloadTask resume];
}

- (void)performUploadTest {
    // 创建一个较大的数据包进行上传测试（约15秒）
    NSMutableData *uploadData = [NSMutableData dataWithCapacity:8 * 1024 * 1024]; // 8MB
    for (int i = 0; i < 8 * 1024 * 1024; i++) {
        uint8_t byte = (uint8_t)(i % 256);
        [uploadData appendBytes:&byte length:1];
    }
    
    NSURL *url = [NSURL URLWithString:@"https://speed.cloudflare.com/__up"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/octet-stream" forHTTPHeaderField:@"Content-Type"];
    
    self.uploadedBytes = 0;
    self.startTime = [NSDate date];
    self.lastUpdateTime = [NSDate date];
    self.isDownloadTesting = NO;
    self.isUploadTesting = YES;
    self.statusLabel.text = @"Testing upload speed...";
    
    // 设置15秒后自动结束上传测试
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.isUploadTesting) {
            // 计算平均上传速度
            NSTimeInterval duration = [[NSDate date] timeIntervalSinceDate:self.startTime];
            if (duration > 0) {
                // 计算平均上传速度 (MB/s)
                double averageSpeedMBps = (self.uploadedBytes / 1024.0 / 1024.0) / duration;
                
                // 存储平均上传速度 (MB/s)
                self.uploadSpeed = averageSpeedMBps;
                
                // 转换为Mbps用于显示
                double displaySpeedMbps = averageSpeedMBps * 8.0;
                
                // 更新上传速度显示 (Mbps)
                self.uploadValueLabel.text = [NSString stringWithFormat:@"%.2f Mbps", displaySpeedMbps];
            }
            
            // 测试完成后，将中心标签恢复为显示下载速度 (MB/s -> Mbps)
            double displayDownloadSpeedMbps = self.downloadSpeed * 8.0;
            self.speedLabel.text = [NSString stringWithFormat:@"%.2f", displayDownloadSpeedMbps];
            [self updateSpeedometerTo:displayDownloadSpeedMbps];
            
            // 结束上传测试
            self.isUploadTesting = NO;
            self.statusLabel.text = @"Speed measurement completed";
        }
    });
    
    NSURLSessionUploadTask *uploadTask = [self.session uploadTaskWithRequest:request fromData:uploadData];
    [uploadTask resume];
}

// 添加一个辅助方法直接更新进度条
- (void)updateSpeedometerTo:(double)speedMbps {
    // 注意：此方法接收的是Mbps值，而非MB/s
    // 立即在主线程更新进度条
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateSpeedometerTo:speedMbps];
        });
        return;
    }
    
    // 计算进度
    double progress = speedMbps / 225.0;
    progress = MIN(1.0, MAX(0.0, progress));
    CGFloat endAngle = -210 + progress * 240;
    
    // 强制更新进度条和颜色
    if (self.maskLayer) {
        // 先取消现有动画
        [self.maskLayer removeAllAnimations];
        
        // 使用UIView动画确保UI更新
        [UIView animateWithDuration:0.3 animations:^{
            UIBezierPath *newPath = [self createArcPathWithRadius:110 startAngle:-210 endAngle:endAngle];
            self.maskLayer.path = newPath.CGPath;
            
            // 设置颜色 - 调整阈值
            if (speedMbps < 50.0) {
                self.maskLayer.strokeColor = [UIColor systemRedColor].CGColor;
            } else if (speedMbps < 125.0) {
                self.maskLayer.strokeColor = [UIColor systemOrangeColor].CGColor;
            } else {
                self.maskLayer.strokeColor = [UIColor systemBlueColor].CGColor;
            }
        }];
    } else {
        // 移除错误日志，改为静默失败
    }
}

#pragma mark - NSURLSessionDataDelegate & NSURLSessionTaskDelegate

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    if (self.isDownloadTesting) {
        self.downloadedBytes += data.length;
        
        NSDate *now = [NSDate date];
        NSTimeInterval timeSinceLastUpdate = [now timeIntervalSinceDate:self.lastUpdateTime];
        NSTimeInterval totalTestTime = [now timeIntervalSinceDate:self.startTime];
        
        if (timeSinceLastUpdate >= 0.05) { // 更频繁更新为每0.05秒一次
            // 计算两种速度:
            // 1. 瞬时速度 - 基于最近数据包
            double instantSpeedMBps = (data.length / 1024.0 / 1024.0) / timeSinceLastUpdate; // MB/s
            
            // 2. 当前累计平均速度 - 基于测试开始以来的所有数据
            double averageSpeedMBps = (self.downloadedBytes / 1024.0 / 1024.0) / totalTestTime; // MB/s
            
            // 使用加权平均，随着测试进行，越来越偏向平均速度
            double weight = MIN(0.8, totalTestTime / 10.0);
            double combinedSpeedMBps = instantSpeedMBps * (1 - weight) + averageSpeedMBps * weight;
            
            // 更新当前速度 (MB/s)
            self.downloadSpeed = combinedSpeedMBps;
            
            // 转换为Mbps用于显示
            double displaySpeedMbps = combinedSpeedMBps * 8.0;
            
            // 更新显示用的瞬时速度 (Mbps)
            self.currentInstantSpeed = displaySpeedMbps;
            
            // 将UI更新移到主线程
            dispatch_async(dispatch_get_main_queue(), ^{
                self.downloadValueLabel.text = [NSString stringWithFormat:@"%.2f Mbps", displaySpeedMbps];
                self.speedLabel.text = [NSString stringWithFormat:@"%.2f", displaySpeedMbps];
                [self updateSpeedometerTo:displaySpeedMbps];
                
                // 在测试接近结束时，显示更明确的状态
                if (totalTestTime > 5.0 && self.downloadedBytes > 20 * 1024 * 1024) {
                    self.statusLabel.text = @"Evaluating download speed...";
                }
            });
            
            self.lastUpdateTime = now;
        }
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend {
    if (self.isUploadTesting) {
        NSDate *now = [NSDate date];
        NSTimeInterval timeSinceLastUpdate = [now timeIntervalSinceDate:self.lastUpdateTime];
        
        if (timeSinceLastUpdate >= 0.05) { // 更频繁更新为每0.05秒一次
            double instantSpeed = (bytesSent / 1024.0 / 1024.0) / timeSinceLastUpdate; // MB/s
            
            // 平滑处理，避免速度显示跳动太大，但保持更新敏感度
            self.uploadSpeed = self.uploadSpeed * 0.8 + instantSpeed * 0.2;
            
            // 转换为Mbps用于显示
            double displaySpeedMbps = self.uploadSpeed * 8.0;
            
            // 将UI更新移到主线程
            dispatch_async(dispatch_get_main_queue(), ^{
                self.currentInstantSpeed = displaySpeedMbps;
                self.uploadValueLabel.text = [NSString stringWithFormat:@"%.2f Mbps", displaySpeedMbps];
                self.speedLabel.text = [NSString stringWithFormat:@"%.2f", displaySpeedMbps];
                [self updateSpeedometerTo:displaySpeedMbps];
            });
            
            self.lastUpdateTime = now;
        }
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.isDownloadTesting) {
            self.isDownloadTesting = NO;
            
            if (!error) {
                NSTimeInterval duration = [[NSDate date] timeIntervalSinceDate:self.startTime];
                if (duration > 0) {
                    // 计算平均下载速度 (MB/s)
                    double averageSpeedMBps = (self.downloadedBytes / 1024.0 / 1024.0) / duration;
                    
                    // 更新内部变量 (MB/s)
                    self.downloadSpeed = averageSpeedMBps;
                    
                    // 显示值使用Mbps
                    double displaySpeedMbps = averageSpeedMBps * 8.0;
                    
                    self.downloadValueLabel.text = [NSString stringWithFormat:@"%.2f Mbps", displaySpeedMbps];
                    
                    // 确保仪表盘显示的也是Mbps值
                    self.currentInstantSpeed = displaySpeedMbps;
                    self.speedLabel.text = [NSString stringWithFormat:@"%.2f", displaySpeedMbps];
                    
                    // 强制更新进度条 - 使用Mbps的值来计算
                    [self updateSpeedometerTo:displaySpeedMbps];
                }
                
                // 下载测试完成后开始上传测试
                [self performUploadTest];
            } else {
                self.downloadValueLabel.text = @"Error";
                // 尝试上传测试
                [self performUploadTest];
            }
        } else if (self.isUploadTesting) {
            self.isUploadTesting = NO;
            
            if (!error) {
                NSTimeInterval duration = [[NSDate date] timeIntervalSinceDate:self.startTime];
                if (duration > 0) {
                    // 计算平均上传速度 (MB/s)
                    double averageSpeedMBps = (task.countOfBytesSent / 1024.0 / 1024.0) / duration;
                    
                    // 更新内部变量 (MB/s)
                    self.uploadSpeed = averageSpeedMBps;
                    
                    // 显示值使用Mbps
                    double displaySpeedMbps = averageSpeedMBps * 8.0;
                    self.uploadValueLabel.text = [NSString stringWithFormat:@"%.2f Mbps", displaySpeedMbps];
                    
                    // 保持下载速度的显示 (MB/s -> Mbps)
                    if (self.downloadSpeed > 0) {
                        double downloadDisplayMbps = self.downloadSpeed * 8.0;
                        self.currentInstantSpeed = downloadDisplayMbps;
                        self.speedLabel.text = [NSString stringWithFormat:@"%.2f", downloadDisplayMbps];
                        [self updateSpeedometerTo:downloadDisplayMbps];
                    }
                }
                
                // 测试完成
                if (self.isTestRunning) {
                    self.statusLabel.text = @"Speed measurement completed";
                }
            } else {
                self.uploadValueLabel.text = @"Error";
                if (self.isTestRunning) {
                    self.statusLabel.text = @"Speed measurement completed (partial errors)";
                }
            }
        }
    });
}
@end
