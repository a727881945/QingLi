//
//  KJSmartCleanViewController.m
//  QingLi_Example
//
//  Created by wangkejie on 2024/12/26.
//  Copyright © 2024 wangkejie. All rights reserved.
//

#import "KJSmartCleanViewController.h"
#import "KJPhotoCell.h"
#import "KJPhotoSectionHeader.h"
#import "KJPhotoSimilarityManager.h"
#import "Layout/KJCustomPhotoLayout.h"
#import "KJSummaryHeaderView.h"
#import <Photos/Photos.h>
#import <Vision/Vision.h>

@interface KJSmartCleanViewController () <UICollectionViewDataSource, UICollectionViewDelegate, KJPhotoSectionHeaderDelegate, UIScrollViewDelegate>

@property (nonatomic, strong) NSArray<NSArray<PHAsset *> *> *groupedPhotos;
@property (nonatomic, strong) NSMutableArray<PHAsset *> *selectedPhotos;
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
@property (nonatomic, assign, readwrite) KJMediaType mediaType; // 添加媒体类型属性，设置为readwrite

@end

@implementation KJSmartCleanViewController

#pragma mark - 初始化方法

- (instancetype)init {
    // 默认使用照片类型
    return [self initWithMediaType:KJMediaTypePhoto];
}

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
    self.selectedPhotos = [NSMutableArray array];
    
    [self setupNavigationBar];
    [self setupGradientView];
    [self setupDeleteButton];  // 先初始化底部按钮
    [self setupSummaryHeaderView]; // 初始化摘要视图
    [self setupCollectionView]; // 再初始化collection
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
    } else {
        NSLog(@"警告：SmartCleanViewController 不在导航控制器中，导航栏设置将不生效");
    }
}

- (void)setupNavigationBar {
    // 使用自定义标题视图而不是navigationItem.title
    self.navTitleLabel = [[UILabel alloc] init];
    
    // 根据媒体类型设置不同的标题
    if (self.mediaType == KJMediaTypeVideo) {
        self.navTitleLabel.text = @"Similar Videos";
    } else {
        self.navTitleLabel.text = @"Similar Photos";
    }
    
    self.navTitleLabel.font = [UIFont boldSystemFontOfSize:17];
    self.navTitleLabel.textColor = [UIColor blackColor];
    self.navigationItem.titleView = self.navTitleLabel;
    
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

- (void)backButtonTapped {
    if (self.navigationController) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
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
    
    // 根据媒体类型显示不同的描述文本
    if (self.mediaType == KJMediaTypeVideo) {
        self.descriptionLabel.text = @"Find and clean duplicate and similar videos";
    } else {
        self.descriptionLabel.text = @"Find and clean duplicate and similar photos";
    }
    
    self.descriptionLabel.font = [UIFont systemFontOfSize:14];
    self.descriptionLabel.textColor = [UIColor darkGrayColor];
    self.descriptionLabel.textAlignment = NSTextAlignmentCenter;
    [self.gradientView addSubview:self.descriptionLabel];
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
    self.statusLabel.text = @"Analyzing photos...";
    self.statusLabel.font = [UIFont systemFontOfSize:14];
    self.statusLabel.textColor = [UIColor darkGrayColor];
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.statusLabel];
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
    
    // 需要确保deleteButton已经被添加到视图中并有正确的约束
    [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        // 将CollectionView顶部与summaryHeaderView底部对齐
        make.top.equalTo(self.summaryHeaderView.mas_bottom).offset(fitScale(8));
        make.left.equalTo(self.view);
        make.right.equalTo(self.view);
        // 确保这里使用强引用，避免约束问题
        if (self.deleteButton) {
            make.bottom.equalTo(self.deleteButton.mas_top).offset(-fitScale(12));
        } else {
            make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom);
        }
    }];
}

- (void)setupDeleteButton {
    self.deleteButton = [[QMUIButton alloc] init];
    [self.deleteButton setTitle:@"Delete Photos" forState:UIControlStateNormal];
    [self.deleteButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.deleteButton.backgroundColor = [UIColor qmui_colorWithHexString:@"#0092FF"];
    self.deleteButton.layer.cornerRadius = fitScale(22);
    [self.deleteButton addTarget:self action:@selector(deleteSelectedPhotos) forControlEvents:UIControlEventTouchUpInside];
    
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

#pragma mark - Photo Library Access

- (void)requestPhotoLibraryAccess {
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (status == PHAuthorizationStatusAuthorized) {
                [self findSimilarPhotos];
            } else {
                [self showPermissionDeniedAlert];
            }
        });
    }];
}

- (void)showPermissionDeniedAlert {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Permission Denied"
                                                                   message:@"This app needs access to your photo library to find similar photos."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)findSimilarPhotos {
    // 显示加载视图
    self.loadingIndicator.hidden = NO;
    self.progressView.hidden = NO;
    self.statusLabel.hidden = NO;
    [self.loadingIndicator startAnimating];
    self.progressView.progress = 0.0;
    
    // 隐藏集合视图
    self.collectionView.hidden = YES;
    
    // 根据媒体类型设置适当的状态文本
    NSString *mediaTypeText = (self.mediaType == KJMediaTypeVideo) ? @"videos" : @"photos";
    self.statusLabel.text = [NSString stringWithFormat:@"Analyzing %@...", mediaTypeText];
    
    // 使用相似媒体管理器查找相似项，使用当前设置的媒体类型
    [[KJPhotoSimilarityManager sharedManager] findSimilarPhotosWithMediaType:self.mediaType progressBlock:^(float progress) {
        // 更新进度条
        self.progressView.progress = progress;
        
        // 更新状态文本，根据媒体类型使用不同的文本
        if (progress < 0.3) {
            self.statusLabel.text = [NSString stringWithFormat:@"Analyzing %@...", mediaTypeText];
        } else if (progress < 0.7) {
            self.statusLabel.text = [NSString stringWithFormat:@"Finding similar %@...", mediaTypeText];
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
        
        // 过滤，只保留至少有2张照片/视频的组
        NSMutableArray<NSArray<PHAsset *> *> *filteredGroups = [NSMutableArray array];
        for (NSArray<PHAsset *> *group in similarGroups) {
            if (group.count >= 2) {
                [filteredGroups addObject:group];
            }
        }
        
        // 更新数据源
        self.groupedPhotos = filteredGroups;
        
        // 先更新总照片/视频数量标签
        [self updateTotalPhotosCount];
        
        // 再显示集合视图
        self.collectionView.hidden = NO;
        [self.collectionView reloadData];
        
        // 没有找到相似项时提示用户
        if (filteredGroups.count == 0) {
            [self showNoSimilarItemsAlert];
        }
    }];
}

- (void)showNoSimilarItemsAlert {
    // 根据媒体类型显示不同的提示
    NSString *title = (self.mediaType == KJMediaTypeVideo) ? @"No Similar Videos" : @"No Similar Photos";
    NSString *message = (self.mediaType == KJMediaTypeVideo) 
        ? @"No similar videos were found in your library." 
        : @"No similar photos were found in your library.";
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return self.groupedPhotos.count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.groupedPhotos[section].count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    KJPhotoCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:KJPhotoCell.identifier forIndexPath:indexPath];
    
    PHAsset *asset = self.groupedPhotos[indexPath.section][indexPath.item];
    cell.asset = asset;
    // 只有在照片类型时才考虑 isBestPhoto 属性
    cell.isBestPhoto = (self.mediaType == KJMediaTypePhoto) && (indexPath.item == 0);
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
        
        // 根据媒体类型设置不同的标题
        header.title = (self.mediaType == KJMediaTypeVideo) ? @"Similar Videos" : @"Similar";
        
        // 设置该分区的照片/视频数量
        NSArray *sectionItems = self.groupedPhotos[indexPath.section];
        header.photoCount = sectionItems.count;
        
        // Check if all items in this section are selected
        NSInteger selectedCount = 0;
        for (NSInteger item = 0; item < sectionItems.count; item++) {
            if ([self.selectedIndexPaths containsObject:[NSIndexPath indexPathForItem:item inSection:indexPath.section]]) {
                selectedCount++;
            }
        }
        header.isAllSelected = selectedCount == sectionItems.count;
        
        return header;
    }
    return nil;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.selectedIndexPaths containsObject:indexPath]) {
        [self.selectedIndexPaths removeObject:indexPath];
        [self.selectedPhotos removeObject:self.groupedPhotos[indexPath.section][indexPath.item]];
    } else {
        [self.selectedIndexPaths addObject:indexPath];
        [self.selectedPhotos addObject:self.groupedPhotos[indexPath.section][indexPath.item]];
    }
    
    [collectionView reloadItemsAtIndexPaths:@[indexPath]];
    [self updateDeleteButtonState];
    
    // Update section header by reloading the section
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:indexPath.section];
    [collectionView reloadSections:indexSet];
}

#pragma mark - KJPhotoSectionHeaderDelegate

- (void)sectionHeader:(id)header didTapSelectAllAtSection:(NSInteger)section {
    NSArray *sectionPhotos = self.groupedPhotos[section];
    BOOL shouldSelect = NO;
    
    // Check if all items are already selected
    NSInteger selectedCount = 0;
    for (NSInteger item = 0; item < sectionPhotos.count; item++) {
        if ([self.selectedIndexPaths containsObject:[NSIndexPath indexPathForItem:item inSection:section]]) {
            selectedCount++;
        }
    }
    
    shouldSelect = selectedCount != sectionPhotos.count;
    
    // Update selection state for all items in the section
    NSMutableArray *indexPathsToReload = [NSMutableArray array];
    for (NSInteger item = 0; item < sectionPhotos.count; item++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:section];
        [indexPathsToReload addObject:indexPath];
        
        if (shouldSelect) {
            [self.selectedIndexPaths addObject:indexPath];
            if (![self.selectedPhotos containsObject:sectionPhotos[item]]) {
                [self.selectedPhotos addObject:sectionPhotos[item]];
            }
        } else {
            [self.selectedIndexPaths removeObject:indexPath];
            [self.selectedPhotos removeObject:sectionPhotos[item]];
        }
    }
    
    [self.collectionView reloadItemsAtIndexPaths:indexPathsToReload];
    [self updateDeleteButtonState];
    
    // Update section header by reloading the section
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:section];
    [self.collectionView reloadSections:indexSet];
}

#pragma mark - Actions

- (void)updateDeleteButtonState {
    self.deleteButton.enabled = self.selectedPhotos.count > 0;
    self.deleteButton.alpha = self.deleteButton.enabled ? 1.0 : 0.5;
}

- (void)deleteSelectedPhotos {
    if (self.selectedPhotos.count == 0) return;
    
    NSArray *assetsToDelete = [self.selectedPhotos copy];
    
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        [PHAssetChangeRequest deleteAssets:assetsToDelete];
    } completionHandler:^(BOOL success, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) {
                [self.selectedIndexPaths removeAllObjects];
                [self.selectedPhotos removeAllObjects];
                
                // 重新分析照片并更新UI
                [self findSimilarPhotos];
                [self updateDeleteButtonState];
            } else {
                // Handle error
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error"
                                                                             message:@"Failed to delete photos"
                                                                      preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
                [self presentViewController:alert animated:YES completion:nil];
            }
        });
    }];
}

- (void)updateTotalPhotosCount {
    // 计算并更新总媒体数量
    NSInteger totalItems = 0;
    for (NSArray<PHAsset *> *group in self.groupedPhotos) {
        totalItems += group.count;
    }
    
    if (totalItems > 0) {
        // 配置摘要视图并显示，传入媒体类型
        [self.summaryHeaderView configureWithCount:totalItems mediaType:self.mediaType];
        self.summaryHeaderView.hidden = NO;
    } else {
        // 如果没有照片或视频，隐藏摘要视图
        self.summaryHeaderView.hidden = YES;
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
//    if (scrollView == self.collectionView) {
//        // 根据滚动位置设置标题透明度
//        CGFloat scrollOffset = scrollView.contentOffset.y;
//        CGFloat threshold = 50.0; // 可以调整此值以改变标题消失的速度
//        
//        if (scrollOffset <= 0) {
//            // 顶部时完全显示
//            self.navTitleLabel.alpha = 1.0;
//        } else if (scrollOffset > threshold) {
//            // 超过阈值时完全隐藏
//            self.navTitleLabel.alpha = 0.0;
//        } else {
//            // 逐渐隐藏
//            self.navTitleLabel.alpha = 1.0 - (scrollOffset / threshold);
//        }
//    }
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

@end

