//
//  KJHomeViewController.m
//  QingLi_Example
//
//  Created by wangkejie on 2024/12/23.
//  Copyright © 2024 wangkejie. All rights reserved.
//

#import "KJHomeViewController.h"
#import "KJSmartCleanViewController.h"
#import "KJMediaCleanViewController.h"

typedef NS_ENUM(NSUInteger, KJHomeViewFeatureType) {
    KJHomeViewFeatureTypeSimilarPhotos = 300,
    KJHomeViewFeatureTypeVideos,
    KJHomeViewFeatureTypeLivePhotos,
    KJHomeViewFeatureTypeScreeshot
};

@interface KJHomeViewController ()

@property (nonatomic, strong) CAShapeLayer *progressLayer;
@property (nonatomic, strong) CAShapeLayer *maskLayer;

@property (nonatomic) UILabel *totolLabel;
@property (nonatomic) UILabel *descLabel;

@end

@implementation KJHomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor qmui_colorWithHexString:@"#F8FBFF"];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self getDiskSpace];
    });
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    [self.view addSubview:scrollView];
    
    CGFloat top = [QMUIHelper statusBarHeightConstant] + 22;
    QMUIButton *leftTopBt = [[QMUIButton alloc] qmui_initWithImage:[UIImage imageNamed:@"gengduo-6"] title:nil];
    leftTopBt.frame = CGRectMake(14, top, 16, 16);
    leftTopBt.qmui_outsideEdge = UIEdgeInsetsMake(-2, -2, -2, -2);
    [self.view addSubview:leftTopBt];
    
    QMUIButton *rightTopBT = [[QMUIButton alloc] qmui_initWithImage:nil title:@"Free Trial"];
    [rightTopBT setBackgroundImage:[UIImage imageNamed:@"home_right_top"] forState:UIControlStateNormal];
    rightTopBT.titleLabel.font = [UIFont systemFontOfSize:11];
    [rightTopBT setTitleColor:[UIColor qmui_colorWithHexString:@"#111111"] forState:UIControlStateNormal];
    rightTopBT.imagePosition = 0;
    rightTopBT.frame = CGRectMake(self.view.bounds.size.width - 70 - 14, top, 70, 26);
    rightTopBT.qmui_outsideEdge = UIEdgeInsetsMake(-2, -2, -2, -2);
    [self.view addSubview:rightTopBT];
    
    CGFloat width = self.view.bounds.size.width;
    CGFloat navHeight = [QMUIHelper navigationBarMaxYConstant];
    
    {
        UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, 484-64+navHeight)];
        [scrollView addSubview:headerView];
        CAGradientLayer *gLayer = [[CAGradientLayer alloc] init];
        gLayer.frame = headerView.bounds;
        gLayer.colors = @[
            (id)[UIColor qmui_colorWithHexString:@"#CDF0FF"].CGColor,
            (id)[UIColor qmui_colorWithHexString:@"#ECFFFF"].CGColor,
            (id)[UIColor qmui_colorWithHexString:@"#F8FBFF"].CGColor,
        ];
        gLayer.startPoint = CGPointMake(0.5, 0);
        gLayer.endPoint = CGPointMake(0.5, 1);
        [headerView.layer addSublayer:gLayer];
    }
    
    {
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        imageView.image = [UIImage imageNamed:@"home_big_top"];
        [scrollView addSubview:imageView];
        CGFloat imageTop = navHeight - 30;
        [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.mas_equalTo(scrollView);
            make.top.mas_equalTo(imageTop);
            make.height.width.mas_equalTo(288);
        }];
        
        CGFloat marginTop = navHeight + 33.5;
        CGFloat marginLeft = (width - 159) / 2.0;
        CGRect rect = CGRectMake(marginLeft, marginTop, 159, 159);
        UIView *circleView = [[UIView alloc] initWithFrame:rect];
        [scrollView addSubview:circleView];
        [self setupCircularProgressView:circleView];
        
        UIImageView *circleMaskImageView = [[UIImageView alloc] initWithFrame:rect];
        [scrollView addSubview:circleMaskImageView];
        circleMaskImageView.image = [UIImage imageNamed:@"circle_mask"];
        
        //进度文字
        UILabel *progressLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        [scrollView addSubview:progressLabel];
        [progressLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.mas_equalTo(imageView.mas_centerX);
            make.centerY.mas_equalTo(imageView.mas_centerY).mas_offset(-10);
            make.width.mas_greaterThanOrEqualTo(10);
            make.height.mas_greaterThanOrEqualTo(10);
        }];
        progressLabel.font = [UIFont boldSystemFontOfSize:24];
        progressLabel.textColor = [UIColor qmui_colorWithHexString:@"#111111"];
        progressLabel.textAlignment = NSTextAlignmentCenter;
//        progressLabel.text = @"76.4%";
        self.totolLabel = progressLabel;
        
        UILabel *progressSubLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        [scrollView addSubview:progressSubLabel];
        [progressSubLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.mas_equalTo(imageView.mas_centerX);
            make.top.mas_equalTo(progressLabel.mas_bottom).mas_offset(4);
            make.width.mas_greaterThanOrEqualTo(10);
            make.height.mas_equalTo(16);
        }];
        progressSubLabel.font = [UIFont systemFontOfSize:12];
        progressSubLabel.textColor = [UIColor qmui_colorWithHexString:@"#999999"];
        progressSubLabel.textAlignment = NSTextAlignmentCenter;
//        progressSubLabel.text = @"96.8G/128G";
        self.descLabel = progressSubLabel;
    }
    
    {
        //Smart Cleaning
        QMUIButton *scBt = [QMUIButton buttonWithType:UIButtonTypeCustom];
        CGFloat left = (width - 160) / 2.0;
        scBt.frame = CGRectMake(left, 244+navHeight, 160, 38);
        [scBt setTitle:@"Smart Cleaning" forState:UIControlStateNormal];
        [scBt setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        scBt.titleLabel.font = [UIFont systemFontOfSize:16];
        CAGradientLayer *gradientLayer = [CAGradientLayer layer];
        gradientLayer.frame = scBt.bounds;
        gradientLayer.colors = @[
            (id)[UIColor qmui_colorWithHexString:@"#3BE2F4"].CGColor,
            (id)[UIColor qmui_colorWithHexString:@"#28A8FF"].CGColor
        ];
        gradientLayer.startPoint = CGPointMake(0.0, 0.5);
        gradientLayer.endPoint = CGPointMake(1, 0.5);
        scBt.layer.cornerRadius = 19;
        scBt.layer.masksToBounds = YES;
        [scBt.layer insertSublayer:gradientLayer atIndex:0];
        [scrollView addSubview:scBt];
    }
    
    {
        //Memory
        QMUIButton *memoryBT = [QMUIButton buttonWithType:UIButtonTypeCustom];
        [scrollView addSubview:memoryBT];
        memoryBT.imagePosition = QMUIButtonImagePositionLeft;
        memoryBT.spacingBetweenImageAndTitle = 3;
        [memoryBT setImage:[UIImage imageNamed:@"home_memory"] forState:UIControlStateNormal];
        [memoryBT setTitle:@"Memory 50%" forState:UIControlStateNormal];
        [memoryBT setTitleColor:[UIColor qmui_colorWithHexString:@"#666666"] forState:UIControlStateNormal];
        memoryBT.titleLabel.font = [UIFont systemFontOfSize:12];
        [memoryBT mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(50);
            make.top.mas_equalTo(306+navHeight);
            make.height.mas_equalTo(14);
            make.width.mas_greaterThanOrEqualTo(10);
        }];
        
        //Cpu
        QMUIButton *cpuBT = [QMUIButton buttonWithType:UIButtonTypeCustom];
        [scrollView addSubview:cpuBT];
        cpuBT.imagePosition = QMUIButtonImagePositionLeft;
        cpuBT.spacingBetweenImageAndTitle = 3;
        [cpuBT setImage:[UIImage imageNamed:@"home_cpu"] forState:UIControlStateNormal];
        [cpuBT setTitle:@"Cpu 50%" forState:UIControlStateNormal];
        [cpuBT setTitleColor:[UIColor qmui_colorWithHexString:@"#666666"] forState:UIControlStateNormal];
        cpuBT.titleLabel.font = [UIFont systemFontOfSize:12];
        [cpuBT mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.mas_equalTo(width - 50);
            make.top.mas_equalTo(306+navHeight);
            make.height.mas_equalTo(14);
            make.width.mas_greaterThanOrEqualTo(10);
        }];
    }
    
    //四个功能区
    {
        NSArray *features = @[@(KJHomeViewFeatureTypeSimilarPhotos), @(KJHomeViewFeatureTypeVideos), @(KJHomeViewFeatureTypeLivePhotos), @(KJHomeViewFeatureTypeScreeshot)];
        {
            QMUIButton *featureBT = [QMUIButton buttonWithType:UIButtonTypeCustom];
            featureBT.tag = KJHomeViewFeatureTypeSimilarPhotos;
            featureBT.frame = CGRectMake(fitScale(14), navHeight+353, fitScale(168.5), 60);
            featureBT.backgroundColor = [UIColor qmui_colorWithHexString:@"#FFFFFF"];
            featureBT.layer.cornerRadius = 4;
            featureBT.layer.cornerRadius = YES;
            [scrollView addSubview:featureBT];
            UIImageView *btImageView = [[UIImageView alloc] initWithFrame:CGRectMake(fitScale(14), (60 - fitScale(25)) / 2.0, fitScale(26), fitScale(26))];
            btImageView.image = [UIImage imageNamed:@"home_similar_photos3x"];
            [featureBT addSubview:btImageView];
            UILabel *btLabel = [[UILabel alloc] initWithFrame:CGRectMake(fitScale(14) + fitScale(26) + fitScale(7), (60 - fitScale(25)) / 2.0, fitScale(110), fitScale(26))];
            btLabel.text = @"Similar Photos";
            btLabel.font = [UIFont systemFontOfSize:14];
            btLabel.textColor = [UIColor qmui_colorWithHexString:@"#111111"];
            [featureBT addSubview:btLabel];
            [featureBT addTarget:self action:@selector(didClickFeaturButton:) forControlEvents:UIControlEventTouchUpInside];
        }
        {
            QMUIButton *featureBT = [QMUIButton buttonWithType:UIButtonTypeCustom];
            featureBT.tag = KJHomeViewFeatureTypeVideos;
            featureBT.frame = CGRectMake(fitScale(192.5), navHeight+353, fitScale(168.5), 60);
            featureBT.backgroundColor = [UIColor qmui_colorWithHexString:@"#FFFFFF"];
            featureBT.layer.cornerRadius = 4;
            featureBT.layer.cornerRadius = YES;
            [scrollView addSubview:featureBT];
            UIImageView *btImageView = [[UIImageView alloc] initWithFrame:CGRectMake(fitScale(14), (60 - fitScale(25)) / 2.0, fitScale(26), fitScale(26))];
            btImageView.image = [UIImage imageNamed:@"home_videos"];
            [featureBT addSubview:btImageView];
            UILabel *btLabel = [[UILabel alloc] initWithFrame:CGRectMake(fitScale(14) + fitScale(26) + fitScale(7), (60 - fitScale(25)) / 2.0, fitScale(110), fitScale(26))];
            btLabel.text = @"Videos";
            btLabel.font = [UIFont systemFontOfSize:14];
            btLabel.textColor = [UIColor qmui_colorWithHexString:@"#111111"];
            [featureBT addSubview:btLabel];
            [featureBT addTarget:self action:@selector(didClickFeaturButton:) forControlEvents:UIControlEventTouchUpInside];
        }
        {
            QMUIButton *featureBT = [QMUIButton buttonWithType:UIButtonTypeCustom];
            featureBT.tag = KJHomeViewFeatureTypeLivePhotos;
            featureBT.frame = CGRectMake(fitScale(14), navHeight+423, fitScale(168.5), 60);
            featureBT.backgroundColor = [UIColor qmui_colorWithHexString:@"#FFFFFF"];
            featureBT.layer.cornerRadius = 4;
            featureBT.layer.cornerRadius = YES;
            [scrollView addSubview:featureBT];
            UIImageView *btImageView = [[UIImageView alloc] initWithFrame:CGRectMake(fitScale(14), (60 - fitScale(25)) / 2.0, fitScale(26), fitScale(26))];
            btImageView.image = [UIImage imageNamed:@"home_livephoto"];
            [featureBT addSubview:btImageView];
            UILabel *btLabel = [[UILabel alloc] initWithFrame:CGRectMake(fitScale(14) + fitScale(26) + fitScale(7), (60 - fitScale(25)) / 2.0, fitScale(110), fitScale(26))];
            btLabel.text = @"Live Photos";
            btLabel.font = [UIFont systemFontOfSize:14];
            btLabel.textColor = [UIColor qmui_colorWithHexString:@"#111111"];
            [featureBT addSubview:btLabel];
            [featureBT addTarget:self action:@selector(didClickFeaturButton:) forControlEvents:UIControlEventTouchUpInside];
        }
        {
            QMUIButton *featureBT = [QMUIButton buttonWithType:UIButtonTypeCustom];
            featureBT.tag = KJHomeViewFeatureTypeScreeshot;
            featureBT.frame = CGRectMake(fitScale(192.5), navHeight+423, fitScale(168.5), 60);
            featureBT.backgroundColor = [UIColor qmui_colorWithHexString:@"#FFFFFF"];
            featureBT.layer.cornerRadius = 4;
            featureBT.layer.cornerRadius = YES;
            [scrollView addSubview:featureBT];
            UIImageView *btImageView = [[UIImageView alloc] initWithFrame:CGRectMake(fitScale(14), (60 - fitScale(25)) / 2.0, fitScale(26), fitScale(26))];
            btImageView.image = [UIImage imageNamed:@"home_screenshot"];
            [featureBT addSubview:btImageView];
            UILabel *btLabel = [[UILabel alloc] initWithFrame:CGRectMake(fitScale(14) + fitScale(26) + fitScale(7), (60 - fitScale(25)) / 2.0, fitScale(110), fitScale(26))];
            btLabel.text = @"ScreenShot";
            btLabel.font = [UIFont systemFontOfSize:14];
            btLabel.textColor = [UIColor qmui_colorWithHexString:@"#111111"];
            [featureBT addSubview:btLabel];
            [featureBT addTarget:self action:@selector(didClickFeaturButton:) forControlEvents:UIControlEventTouchUpInside];
        }
    }
    
    //其他功能
    {
        {
            UILabel *btLabel = [[UILabel alloc] initWithFrame:CGRectMake(fitScale(14), navHeight + 507, 200, 22.5)];
            btLabel.text = @"其他功能";
            btLabel.font = [UIFont boldSystemFontOfSize:16];
            btLabel.textColor = [UIColor qmui_colorWithHexString:@"#111111"];
            [scrollView addSubview:btLabel];
        }
        {
            QMUIButton *featureBT = [QMUIButton buttonWithType:UIButtonTypeCustom];
            featureBT.frame = CGRectMake(fitScale(14), navHeight+537.5, width-2*fitScale(14), 60);
            featureBT.backgroundColor = [UIColor qmui_colorWithHexString:@"#FFFFFF"];
            featureBT.layer.cornerRadius = 4;
            featureBT.layer.cornerRadius = YES;
            [scrollView addSubview:featureBT];
            
            UIImageView *btImageView = [[UIImageView alloc] initWithFrame:CGRectMake(14, 13.5, 33, 33)];
            btImageView.image = [UIImage imageNamed:@"home_speed"];
            [featureBT addSubview:btImageView];
            UILabel *btLabel = [[UILabel alloc] initWithFrame:CGRectMake(53, 13.5, 200, 33)];
            btLabel.text = @"Velocity Measurement";
            btLabel.font = [UIFont systemFontOfSize:14];
            btLabel.textColor = [UIColor qmui_colorWithHexString:@"#111111"];
            [featureBT addSubview:btLabel];
            UIImageView *btImageViewRight = [[UIImageView alloc] initWithFrame:CGRectMake(featureBT.bounds.size.width - 14 - 10, 25, 10, 10)];
            btImageViewRight.image = [UIImage imageNamed:@"home_right_row"];
            [featureBT addSubview:btImageViewRight];
            [featureBT addTarget:self action:@selector(didClickSpeedTest) forControlEvents:UIControlEventTouchUpInside];
        }
    }
}

- (void)didClickFeaturButton:(UIButton *)button {
    KJHomeViewFeatureType type = button.tag;
    switch (type) {
        case KJHomeViewFeatureTypeSimilarPhotos: {
            KJSmartCleanViewController *scvc = [[KJSmartCleanViewController alloc] init];
            [self.navigationController pushViewController:scvc animated:YES];
            break;
        }
        case KJHomeViewFeatureTypeVideos: {
            KJMediaCleanViewController *vc = [[KJMediaCleanViewController alloc] initWithMediaType:KJMediaTypeVideo];
            [self.navigationController pushViewController:vc animated:YES];
            break;
        }
        case KJHomeViewFeatureTypeLivePhotos: {
            KJMediaCleanViewController *vc = [[KJMediaCleanViewController alloc] initWithMediaType:KJMediaTypeLivePhoto];
            [self.navigationController pushViewController:vc animated:YES];
            break;
        }
        case KJHomeViewFeatureTypeScreeshot: {
            KJMediaCleanViewController *vc = [[KJMediaCleanViewController alloc] initWithMediaType:KJMediaTypeScreenshot];
            [self.navigationController pushViewController:vc animated:YES];
            break;
        }
        default:
            break;
    }
}

- (void)didClickSpeedTest {
    
}

- (void)setupCircularProgressView:(UIView *)circleView {
    CGRect rect = circleView.bounds;
    CGPoint center = CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
    CGFloat radius = CGRectGetWidth(rect) / 2.0 - 12;
    CGFloat lineWidth = 12.0;
    CGFloat startAngle = M_PI;
    CGFloat endAngle = 2 * M_PI + startAngle;

    // 创建路径
    UIBezierPath *circularPath = [UIBezierPath bezierPathWithArcCenter:center radius:radius startAngle:startAngle endAngle:endAngle clockwise:YES];
    
    // 创建轨道层
    CAShapeLayer *trackLayer = [CAShapeLayer layer];
    trackLayer.frame = circleView.bounds;
    trackLayer.path = circularPath.CGPath;
    trackLayer.strokeColor = [UIColor qmui_colorWithHexString:@"#F8FBFF"].CGColor;
    trackLayer.lineWidth = lineWidth;
    trackLayer.fillColor = [UIColor qmui_colorWithHexString:@"#F8FBFF"].CGColor;
    trackLayer.lineCap = kCALineCapRound;
    [circleView.layer addSublayer:trackLayer];
    
    {
        UIBezierPath *circularInnerPath = [UIBezierPath bezierPathWithArcCenter:center radius:radius-6 startAngle:startAngle endAngle:endAngle clockwise:YES];
        CAShapeLayer *fillLayer = CAShapeLayer.layer;
        fillLayer.path = circularInnerPath.CGPath;
        fillLayer.fillColor = UIColor.whiteColor.CGColor;
        [circleView.layer addSublayer:fillLayer];
    }
    

    // 创建进度层
    CAShapeLayer *progressLayer = [CAShapeLayer layer];
    progressLayer.frame = circleView.bounds;
    progressLayer.path = circularPath.CGPath;
    progressLayer.strokeColor = [UIColor whiteColor].CGColor;
    progressLayer.lineWidth = lineWidth;
    progressLayer.fillColor = [UIColor clearColor].CGColor;
    progressLayer.lineCap = kCALineCapRound;
    progressLayer.strokeEnd = 0.0; // 初始进度为0
    [circleView.layer addSublayer:progressLayer];
    self.progressLayer = progressLayer;
    
    // 创建渐变层
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.frame = circleView.bounds;
    gradientLayer.colors = @[
        (id)[UIColor qmui_colorWithHexString:@"#76DEBA"].CGColor,
        (id)[UIColor qmui_colorWithHexString:@"#5ECBF3"].CGColor
    ];
    gradientLayer.startPoint = CGPointMake(0.0, 0.0);
    gradientLayer.endPoint = CGPointMake(1, 1);

    // 创建遮罩层
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    maskLayer.path = circularPath.CGPath;
    maskLayer.strokeColor = [UIColor blackColor].CGColor;
    maskLayer.lineWidth = lineWidth;
    maskLayer.fillColor = [UIColor clearColor].CGColor;
    maskLayer.lineCap = kCALineCapRound;
    maskLayer.strokeEnd = 0.0; // 初始进度为0
    self.maskLayer = maskLayer;
    
    gradientLayer.mask = maskLayer;
    [circleView.layer addSublayer:gradientLayer];

    // 更新进度
    [self updateProgress:0];
}

- (void)updateProgress:(CGFloat)progress {
    self.progressLayer.strokeEnd = progress;
    self.maskLayer.strokeEnd = progress;
}

- (void)getDiskSpace {
    NSError *error = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // 获取磁盘总空间
    NSDictionary *attributes = [fileManager attributesOfFileSystemForPath:NSHomeDirectory() error:&error];
    if (error) {
        NSLog(@"Error: %@", error.localizedDescription);
        return;
    }
    
    uint64_t totalSpace = [attributes[NSFileSystemSize] unsignedLongLongValue];
    uint64_t freeSpace = [attributes[NSFileSystemFreeSize] unsignedLongLongValue];
    
    NSLog(@"Total Disk Space: %llu bytes", totalSpace);
    NSLog(@"Free Disk Space: %llu bytes", freeSpace);
    
    CGFloat ratio = 1.0*(totalSpace - freeSpace) / (totalSpace * 1.0);
    CGFloat usedGB = 1.0*(totalSpace - freeSpace) / pow(1024, 3);
    CGFloat totaldGB = 1.0*totalSpace / pow(1024, 3);

    dispatch_async(dispatch_get_main_queue(), ^{
        self.totolLabel.text = [NSString stringWithFormat:@"%.1f%%", ratio * 100];
        self.descLabel.text = [NSString stringWithFormat:@"%.1fG/%.1fG", usedGB, totaldGB];
        [self updateProgress:ratio];
    });
}

@end
