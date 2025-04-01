//
//  KJMediaManagerViewController.m
//  QingLi
//
//  Created by QingLi on 2023/11/11.
//

#import "KJMediaManagerViewController.h"
#import "KJSmartCleanViewController.h"
#import "KJMediaCleanViewController.h"

@interface KJMediaManagerViewController ()

@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *similarPhotoButton;
@property (nonatomic, strong) UIButton *videosButton;
@property (nonatomic, strong) UIButton *livePhotosButton;
@property (nonatomic, strong) UIButton *screenshotButton;

@end

@implementation KJMediaManagerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupUI];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // 隐藏导航栏
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}

#pragma mark - UI Setup

- (void)setupUI {
    self.view.backgroundColor = [UIColor whiteColor];
    
    // 设置标题
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.text = @"Media Manager";
    self.titleLabel.font = [UIFont boldSystemFontOfSize:24];
    self.titleLabel.textColor = [UIColor blackColor];
    [self.view addSubview:self.titleLabel];
    
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(30);
        make.centerX.equalTo(self.view);
    }];
    
    // 创建容器视图
    self.containerView = [[UIView alloc] init];
    [self.view addSubview:self.containerView];
    
    [self.containerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(30);
        make.left.right.equalTo(self.view);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom);
    }];
    
    // 创建功能按钮
    [self setupFunctionButtons];
}

- (void)setupFunctionButtons {
    // 相似照片按钮
    self.similarPhotoButton = [self createFunctionButtonWithTitle:@"Similar Photos" 
                                                           icon:@"photos_icon_01" 
                                                    iconColor:@"#FF9500" 
                                                 backgroundColor:@"#FFF5E6"];
    [self.similarPhotoButton addTarget:self action:@selector(openSimilarPhotos) forControlEvents:UIControlEventTouchUpInside];
    
    // 视频按钮
    self.videosButton = [self createFunctionButtonWithTitle:@"Videos" 
                                                     icon:@"video_icon" 
                                              iconColor:@"#007AFF" 
                                          backgroundColor:@"#E5F3FF"];
    [self.videosButton addTarget:self action:@selector(openVideos) forControlEvents:UIControlEventTouchUpInside];
    
    // 实况照片按钮
    self.livePhotosButton = [self createFunctionButtonWithTitle:@"Live Photos" 
                                                         icon:@"livephoto_icon" 
                                                  iconColor:@"#4CD964" 
                                              backgroundColor:@"#E6FFF0"];
    [self.livePhotosButton addTarget:self action:@selector(openLivePhotos) forControlEvents:UIControlEventTouchUpInside];
    
    // 截图按钮
    self.screenshotButton = [self createFunctionButtonWithTitle:@"Screenshot" 
                                                         icon:@"screenshot_icon" 
                                                  iconColor:@"#AF52DE" 
                                              backgroundColor:@"#F5E6FF"];
    [self.screenshotButton addTarget:self action:@selector(openScreenshots) forControlEvents:UIControlEventTouchUpInside];
    
    // 创建网格布局
    UIStackView *topStackView = [[UIStackView alloc] initWithArrangedSubviews:@[self.similarPhotoButton, self.videosButton]];
    topStackView.axis = UILayoutConstraintAxisHorizontal;
    topStackView.distribution = UIStackViewDistributionFillEqually;
    topStackView.spacing = 15;
    
    UIStackView *bottomStackView = [[UIStackView alloc] initWithArrangedSubviews:@[self.livePhotosButton, self.screenshotButton]];
    bottomStackView.axis = UILayoutConstraintAxisHorizontal;
    bottomStackView.distribution = UIStackViewDistributionFillEqually;
    bottomStackView.spacing = 15;
    
    UIStackView *mainStackView = [[UIStackView alloc] initWithArrangedSubviews:@[topStackView, bottomStackView]];
    mainStackView.axis = UILayoutConstraintAxisVertical;
    mainStackView.distribution = UIStackViewDistributionFillEqually;
    mainStackView.spacing = 15;
    
    [self.containerView addSubview:mainStackView];
    
    [mainStackView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.containerView).offset(30);
        make.left.equalTo(self.containerView).offset(20);
        make.right.equalTo(self.containerView).offset(-20);
        make.height.equalTo(mainStackView.mas_width).multipliedBy(0.5);
    }];
}

- (UIButton *)createFunctionButtonWithTitle:(NSString *)title icon:(NSString *)iconName iconColor:(NSString *)colorHex backgroundColor:(NSString *)bgColorHex {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.layer.cornerRadius = 12;
    button.backgroundColor = [UIColor qmui_colorWithHexString:bgColorHex];
    
    // 创建垂直布局
    UIStackView *stackView = [[UIStackView alloc] init];
    stackView.axis = UILayoutConstraintAxisVertical;
    stackView.alignment = UIStackViewAlignmentCenter;
    stackView.spacing = 8;
    stackView.translatesAutoresizingMaskIntoConstraints = NO;
    
    // 图标
    UIImageView *iconView = [[UIImageView alloc] init];
    iconView.image = [UIImage imageNamed:iconName];
    iconView.contentMode = UIViewContentModeScaleAspectFit;
    iconView.tintColor = [UIColor qmui_colorWithHexString:colorHex];
    [iconView setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    [stackView addArrangedSubview:iconView];
    
    // 标题
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = title;
    titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    titleLabel.textColor = [UIColor blackColor];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [stackView addArrangedSubview:titleLabel];
    
    [button addSubview:stackView];
    
    [iconView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(30, 30));
    }];
    
    [stackView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(button);
        make.width.equalTo(button).multipliedBy(0.8);
    }];
    
    // 添加触摸反馈
    button.adjustsImageWhenHighlighted = YES;
    
    return button;
}

#pragma mark - Navigation

- (void)openSimilarPhotos {
    KJSmartCleanViewController *vc = [[KJSmartCleanViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)openVideos {
    KJMediaCleanViewController *vc = [[KJMediaCleanViewController alloc] initWithMediaType:KJMediaTypeVideo];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)openLivePhotos {
    KJMediaCleanViewController *vc = [[KJMediaCleanViewController alloc] initWithMediaType:KJMediaTypeLivePhoto];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)openScreenshots {
    KJMediaCleanViewController *vc = [[KJMediaCleanViewController alloc] initWithMediaType:KJMediaTypeScreenshot];
    [self.navigationController pushViewController:vc animated:YES];
}

@end 