//
//  KJMediaCleanViewController.m
//  QingLi
//
//  Created by QingLi on 2023/11/11.
//

#import "KJMediaCleanViewController.h"
#import "KJPhotoCell.h"
#import "KJPhotoSectionHeader.h"
#import "KJSummaryHeaderView.h"
#import "Layout/KJCustomPhotoLayout.h"
#import <Photos/Photos.h>
#import "KJPhotoSimilarityManager.h"

@interface KJMediaCleanViewController () <UICollectionViewDataSource, UICollectionViewDelegate, KJPhotoSectionHeaderDelegate, UIScrollViewDelegate>

@property (nonatomic, assign, readwrite) KJMediaType mediaType;
@property (nonatomic, strong) NSArray<NSArray<PHAsset *> *> *groupedMedia;
@property (nonatomic, strong) NSMutableArray<PHAsset *> *selectedMedia;
@property (nonatomic, strong) UIView *gradientView;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) QMUIButton *deleteButton;
@property (nonatomic, strong) NSMutableSet<NSIndexPath *> *selectedIndexPaths;
@property (nonatomic, strong) UIActivityIndicatorView *loadingIndicator;
@property (nonatomic, strong) UIProgressView *progressView;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UILabel *descriptionLabel;
@property (nonatomic, strong) UILabel *navTitleLabel; // 自定义标题
@property (nonatomic, strong) KJSummaryHeaderView *summaryHeaderView; // 摘要视图

@end

@implementation KJMediaCleanViewController

#pragma mark - 初始化方法

- (instancetype)initWithMediaType:(KJMediaType)mediaType {
    self = [super init];
    if (self) {
        _mediaType = mediaType;
    }
    return self;
}

#pragma mark - 视图生命周期

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = UIColor.whiteColor;
    self.selectedIndexPaths = [NSMutableSet set];
    self.selectedMedia = [NSMutableArray array];
    
    [self setupNavigationBar];
    [self setupGradientView];
    [self setupDeleteButton];
    [self setupSummaryHeaderView];
    [self setupCollectionView];
    [self setupLoadingViews];
    [self requestPhotoLibraryAccess];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.navigationController) {
        [self.navigationController setNavigationBarHidden:NO animated:animated];
        
        if (@available(iOS 15.0, *)) {
            // iOS 15及以上版本已在setupNavigationBar中设置，无需额外操作
        } else {
            [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
            self.navigationController.navigationBar.shadowImage = [UIImage new];
        }
    }
}

#pragma mark - UI设置

- (void)setupNavigationBar {
    // 使用自定义标题视图
    self.navTitleLabel = [[UILabel alloc] init];
    self.navTitleLabel.font = [UIFont boldSystemFontOfSize:17];
    self.navTitleLabel.textColor = [UIColor blackColor];
    self.navigationItem.titleView = self.navTitleLabel;
    
    // 设置标题
    switch (self.mediaType) {
        case KJMediaTypeVideo:
            self.navTitleLabel.text = @"Videos";
            break;
        case KJMediaTypeLivePhoto:
            self.navTitleLabel.text = @"Live Photos";
            break;
        case KJMediaTypeScreenshot:
            self.navTitleLabel.text = @"Screenshots";
            break;
    }
    
    // 创建小一号的返回箭头图标
    UIImage *chevronImage = [UIImage systemImageNamed:@"chevron.left"];
    UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:18 weight:UIImageSymbolWeightRegular];
    UIImage *smallerChevronImage = [chevronImage imageByApplyingSymbolConfiguration:config];
    
    // 添加左侧返回按钮
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithImage:smallerChevronImage
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(backButtonTapped)];
    
    backButton.tintColor = [UIColor blackColor];
    self.navigationItem.leftBarButtonItem = backButton;
    
    // 设置导航栏为透明背景
    if (@available(iOS 15.0, *)) {
        UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
        [appearance configureWithTransparentBackground];
        appearance.backgroundColor = [UIColor clearColor];
        appearance.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor blackColor]};
        self.navigationController.navigationBar.standardAppearance = appearance;
        self.navigationController.navigationBar.scrollEdgeAppearance = appearance;
    } else {
        self.navigationController.navigationBar.barTintColor = [UIColor clearColor];
        self.navigationController.navigationBar.backgroundColor = [UIColor clearColor];
        [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
        self.navigationController.navigationBar.shadowImage = [UIImage new];
        self.navigationController.navigationBar.translucent = YES;
    }
}

- (void)setupGradientView {
    self.gradientView = [[UIView alloc] init];
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.colors = @[
        (id)[UIColor qmui_colorWithHexString:@"#E5F3FF"].CGColor,
        (id)[UIColor whiteColor].CGColor
    ];
    gradient.locations = @[@0, @1.0];
    gradient.startPoint = CGPointMake(0.5, 0);
    gradient.endPoint = CGPointMake(0.5, 1);
    [self.view addSubview:self.gradientView];
    [self.gradientView.layer addSublayer:gradient];
    
    [self.gradientView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view);
        make.left.right.equalTo(self.view);
        make.height.mas_equalTo(fitScale(418.5));
    }];
    
    // 添加说明文字
    self.descriptionLabel = [[UILabel alloc] init];
    self.descriptionLabel.font = [UIFont systemFontOfSize:14];
    self.descriptionLabel.textColor = [UIColor darkGrayColor];
    self.descriptionLabel.textAlignment = NSTextAlignmentCenter;
    [self.gradientView addSubview:self.descriptionLabel];
    
    // 根据媒体类型设置不同的描述文本
    switch (self.mediaType) {
        case KJMediaTypeVideo:
            self.descriptionLabel.text = @"Find and clean large videos to free up space";
            break;
        case KJMediaTypeLivePhoto:
            self.descriptionLabel.text = @"Find and clean live photos to free up space";
            break;
        case KJMediaTypeScreenshot:
            self.descriptionLabel.text = @"Find and clean unused screenshots";
            break;
    }
    
    [self.descriptionLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.gradientView);
        make.top.equalTo(self.mas_topLayoutGuideBottom).offset(fitScale(12));
    }];
    
    // Update gradient frame when view layout changes
    [self.gradientView setNeedsLayout];
    [self.gradientView layoutIfNeeded];
    gradient.frame = self.gradientView.bounds;
}

- (void)setupLoadingViews {
    // 加载指示器
    self.loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    self.loadingIndicator.color = [UIColor qmui_colorWithHexString:@"#0092FF"];
    [self.view addSubview:self.loadingIndicator];
    [self.loadingIndicator mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.view);
    }];
    
    // 进度条
    self.progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    self.progressView.progressTintColor = [UIColor qmui_colorWithHexString:@"#0092FF"];
    self.progressView.trackTintColor = [UIColor lightGrayColor];
    [self.view addSubview:self.progressView];
    [self.progressView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.width.equalTo(self.view).multipliedBy(0.8);
        make.top.equalTo(self.loadingIndicator.mas_bottom).offset(20);
    }];
    
    // 状态标签
    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.font = [UIFont systemFontOfSize:14];
    self.statusLabel.textColor = [UIColor darkGrayColor];
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.statusLabel];
    
    // 根据媒体类型设置不同的状态文本
    switch (self.mediaType) {
        case KJMediaTypeVideo:
            self.statusLabel.text = @"Analyzing videos...";
            break;
        case KJMediaTypeLivePhoto:
            self.statusLabel.text = @"Analyzing live photos...";
            break;
        case KJMediaTypeScreenshot:
            self.statusLabel.text = @"Analyzing screenshots...";
            break;
    }
    
    [self.statusLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.top.equalTo(self.progressView.mas_bottom).offset(10);
    }];
    
    // 隐藏加载视图
    self.loadingIndicator.hidden = YES;
    self.progressView.hidden = YES;
    self.statusLabel.hidden = YES;
}

- (void)setupCollectionView {
    // 创建自定义布局
    KJCustomPhotoLayout *layout = [[KJCustomPhotoLayout alloc] init];
    layout.largePhotoSize = CGSizeMake(fitScale(133), fitScale(133));
    layout.smallPhotoSize = CGSizeMake(fitScale(62), fitScale(62));
    layout.interItemSpacing = fitScale(8);
    layout.lineSpacing = fitScale(8);
    layout.sectionInset = UIEdgeInsetsMake(fitScale(16), fitScale(16), fitScale(16), fitScale(16));
    layout.headerReferenceSize = CGSizeMake(self.view.frame.size.width, fitScale(40));
    
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    [self.collectionView registerClass:[KJPhotoCell class] forCellWithReuseIdentifier:KJPhotoCell.identifier];
    [self.collectionView registerClass:[KJPhotoSectionHeader class]
            forSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                   withReuseIdentifier:KJPhotoSectionHeader.identifier];
    
    self.collectionView.backgroundColor = [UIColor clearColor];
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    
    [self.view addSubview:self.collectionView];
    
    [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.summaryHeaderView.mas_bottom).offset(fitScale(8));
        make.left.equalTo(self.view);
        make.right.equalTo(self.view);
        if (self.deleteButton) {
            make.bottom.equalTo(self.deleteButton.mas_top).offset(-fitScale(12));
        } else {
            make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom);
        }
    }];
}

- (void)setupDeleteButton {
    self.deleteButton = [[QMUIButton alloc] init];
    [self.deleteButton setTitle:@"Delete Media" forState:UIControlStateNormal];
    [self.deleteButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.deleteButton.backgroundColor = [UIColor qmui_colorWithHexString:@"#0092FF"];
    self.deleteButton.layer.cornerRadius = fitScale(22);
    [self.deleteButton addTarget:self action:@selector(deleteSelectedMedia) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:self.deleteButton];
    [self.deleteButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(fitScale(16));
        make.right.equalTo(self.view).offset(-fitScale(16));
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-fitScale(16));
        make.height.mas_equalTo(fitScale(44));
    }];
    
    self.deleteButton.enabled = NO;
    self.deleteButton.alpha = 0.5;
}

- (void)setupSummaryHeaderView {
    // 创建摘要视图
    self.summaryHeaderView = [[KJSummaryHeaderView alloc] init];
    
    // 添加到视图层级
    [self.view addSubview:self.summaryHeaderView];
    
    // 设置约束
    [self.summaryHeaderView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(fitScale(12));
        make.left.equalTo(self.view).offset(fitScale(16));
        make.right.lessThanOrEqualTo(self.view).offset(-fitScale(16));
        make.height.mas_equalTo(fitScale(40));
    }];
    
    // 默认隐藏，等待数据加载完成后显示
    self.summaryHeaderView.hidden = YES;
}

#pragma mark - 权限和媒体获取

- (void)requestPhotoLibraryAccess {
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (status == PHAuthorizationStatusAuthorized) {
                [self findMedia];
            } else {
                [self showPermissionDeniedAlert];
            }
        });
    }];
}

- (void)showPermissionDeniedAlert {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Permission Denied"
                                                                   message:@"This app needs access to your photo library to clean media files."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)findMedia {
    // 显示加载视图
    self.loadingIndicator.hidden = NO;
    self.progressView.hidden = NO;
    self.statusLabel.hidden = NO;
    [self.loadingIndicator startAnimating];
    self.progressView.progress = 0.0;
    
    // 隐藏集合视图
    self.collectionView.hidden = YES;
    
    // 使用相似照片管理器查找媒体，直接传入媒体类型
    [[KJPhotoSimilarityManager sharedManager] findSimilarPhotosWithMediaType:self.mediaType progressBlock:^(float progress) {
        // 更新进度条
        self.progressView.progress = progress;
        
        // 更新状态文本
        if (progress < 0.3) {
            switch (self.mediaType) {
                case KJMediaTypeVideo:
                    self.statusLabel.text = @"Analyzing videos...";
                    break;
                case KJMediaTypeLivePhoto:
                    self.statusLabel.text = @"Analyzing live photos...";
                    break;
                case KJMediaTypeScreenshot:
                    self.statusLabel.text = @"Analyzing screenshots...";
                    break;
                default:
                    self.statusLabel.text = @"Analyzing photos...";
                    break;
            }
        } else if (progress < 0.7) {
            self.statusLabel.text = @"Processing files...";
        } else {
            self.statusLabel.text = @"Almost done...";
        }
        
    } completion:^(NSArray<NSArray<PHAsset *> *> * _Nonnull similarGroups, NSError * _Nullable error) {
        // 隐藏加载视图
        self.loadingIndicator.hidden = YES;
        self.progressView.hidden = YES;
        self.statusLabel.hidden = YES;
        [self.loadingIndicator stopAnimating];
        
        // 隐藏描述标签
        self.descriptionLabel.hidden = YES;
        
        // 过滤，只保留至少有2个媒体项的组
        NSMutableArray<NSArray<PHAsset *> *> *filteredGroups = [NSMutableArray array];
        for (NSArray<PHAsset *> *group in similarGroups) {
            if (group.count >= 2) {
                [filteredGroups addObject:group];
            }
        }
        
        // 更新数据源
        self.groupedMedia = [filteredGroups copy];
        
        // 先更新总媒体数量
        [self updateTotalMediaCount];
        
        // 再显示集合视图
        self.collectionView.hidden = NO;
        [self.collectionView reloadData];
        
        // 没有找到媒体时提示用户
        if (filteredGroups.count == 0) {
            [self showNoMediaAlert];
        }
    }];
}

- (void)showNoMediaAlert {
    NSString *mediaTypeString;
    switch (self.mediaType) {
        case KJMediaTypeVideo:
            mediaTypeString = @"videos";
            break;
        case KJMediaTypeLivePhoto:
            mediaTypeString = @"live photos";
            break;
        case KJMediaTypeScreenshot:
            mediaTypeString = @"screenshots";
            break;
    }
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"No %@", mediaTypeString]
                                                                   message:[NSString stringWithFormat:@"No %@ were found in your library.", mediaTypeString]
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return self.groupedMedia.count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.groupedMedia[section].count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    KJPhotoCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:KJPhotoCell.identifier forIndexPath:indexPath];
    
    PHAsset *asset = self.groupedMedia[indexPath.section][indexPath.item];
    cell.asset = asset;
    cell.isBestPhoto = indexPath.item == 0;
    cell.isSelected = [self.selectedIndexPaths containsObject:indexPath];
    
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        KJPhotoSectionHeader *header = [collectionView dequeueReusableSupplementaryViewOfKind:kind
                                                                        withReuseIdentifier:KJPhotoSectionHeader.identifier
                                                                               forIndexPath:indexPath];
        header.delegate = self;
        header.section = indexPath.section;
        
        // 根据媒体类型设置标题
        switch (self.mediaType) {
            case KJMediaTypeVideo:
                header.title = @"Video";
                break;
            case KJMediaTypeLivePhoto:
                header.title = @"Live";
                break;
            case KJMediaTypeScreenshot:
                header.title = @"Screenshot";
                break;
        }
        
        // 设置该分区的媒体数量
        NSArray *sectionMedia = self.groupedMedia[indexPath.section];
        header.photoCount = sectionMedia.count;
        
        // 检查此分区中是否所有项目都被选中
        NSInteger selectedCount = 0;
        for (NSInteger item = 0; item < sectionMedia.count; item++) {
            if ([self.selectedIndexPaths containsObject:[NSIndexPath indexPathForItem:item inSection:indexPath.section]]) {
                selectedCount++;
            }
        }
        header.isAllSelected = selectedCount == sectionMedia.count;
        
        return header;
    }
    return nil;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.selectedIndexPaths containsObject:indexPath]) {
        [self.selectedIndexPaths removeObject:indexPath];
        [self.selectedMedia removeObject:self.groupedMedia[indexPath.section][indexPath.item]];
    } else {
        [self.selectedIndexPaths addObject:indexPath];
        [self.selectedMedia addObject:self.groupedMedia[indexPath.section][indexPath.item]];
    }
    
    [collectionView reloadItemsAtIndexPaths:@[indexPath]];
    [self updateDeleteButtonState];
    
    // 更新分区头部
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:indexPath.section];
    [collectionView reloadSections:indexSet];
}

#pragma mark - KJPhotoSectionHeaderDelegate

- (void)sectionHeader:(id)header didTapSelectAllAtSection:(NSInteger)section {
    NSArray *sectionMedia = self.groupedMedia[section];
    BOOL shouldSelect = NO;
    
    // 检查是否所有项目都已被选中
    NSInteger selectedCount = 0;
    for (NSInteger item = 0; item < sectionMedia.count; item++) {
        if ([self.selectedIndexPaths containsObject:[NSIndexPath indexPathForItem:item inSection:section]]) {
            selectedCount++;
        }
    }
    
    shouldSelect = selectedCount != sectionMedia.count;
    
    // 更新所有项目的选择状态
    NSMutableArray *indexPathsToReload = [NSMutableArray array];
    for (NSInteger item = 0; item < sectionMedia.count; item++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:section];
        [indexPathsToReload addObject:indexPath];
        
        if (shouldSelect) {
            [self.selectedIndexPaths addObject:indexPath];
            if (![self.selectedMedia containsObject:sectionMedia[item]]) {
                [self.selectedMedia addObject:sectionMedia[item]];
            }
        } else {
            [self.selectedIndexPaths removeObject:indexPath];
            [self.selectedMedia removeObject:sectionMedia[item]];
        }
    }
    
    [self.collectionView reloadItemsAtIndexPaths:indexPathsToReload];
    [self updateDeleteButtonState];
    
    // 更新分区头部
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:section];
    [self.collectionView reloadSections:indexSet];
}

#pragma mark - 操作方法

- (void)backButtonTapped {
    if (self.navigationController) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)updateDeleteButtonState {
    self.deleteButton.enabled = self.selectedMedia.count > 0;
    self.deleteButton.alpha = self.deleteButton.enabled ? 1.0 : 0.5;
}

- (void)deleteSelectedMedia {
    if (self.selectedMedia.count == 0) return;
    
    NSString *actionTitle;
    switch (self.mediaType) {
        case KJMediaTypeVideo:
            actionTitle = @"Delete Videos";
            break;
        case KJMediaTypeLivePhoto:
            actionTitle = @"Delete Live Photos";
            break;
        case KJMediaTypeScreenshot:
            actionTitle = @"Delete Screenshots";
            break;
    }
    
    // 确认删除
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Confirm Deletion"
                                                                   message:[NSString stringWithFormat:@"Are you sure you want to delete %ld selected items?", (long)self.selectedMedia.count]
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:actionTitle style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [self performDeletion];
    }]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)performDeletion {
    NSArray *assetsToDelete = [self.selectedMedia copy];
    
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        [PHAssetChangeRequest deleteAssets:assetsToDelete];
    } completionHandler:^(BOOL success, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) {
                [self.selectedIndexPaths removeAllObjects];
                [self.selectedMedia removeAllObjects];
                
                // 重新加载媒体并更新UI
                [self findMedia];
                [self updateDeleteButtonState];
            } else {
                // 处理错误
                UIAlertController *errorAlert = [UIAlertController alertControllerWithTitle:@"Error"
                                                                                   message:@"Failed to delete media"
                                                                            preferredStyle:UIAlertControllerStyleAlert];
                [errorAlert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
                [self presentViewController:errorAlert animated:YES completion:nil];
            }
        });
    }];
}

- (void)updateTotalMediaCount {
    // 计算并更新总媒体数量
    NSInteger totalMedia = 0;
    for (NSArray<PHAsset *> *group in self.groupedMedia) {
        totalMedia += group.count;
    }
    
    if (totalMedia > 0) {
        // 配置摘要视图并显示
        [self.summaryHeaderView configureWithCount:totalMedia];
        self.summaryHeaderView.hidden = NO;
    } else {
        // 如果没有媒体，隐藏摘要视图
        self.summaryHeaderView.hidden = YES;
    }
}

@end 