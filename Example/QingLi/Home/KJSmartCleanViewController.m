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
#import <Photos/Photos.h>
#import <Vision/Vision.h>

@interface KJSmartCleanViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, KJPhotoSectionHeaderDelegate>

@property (nonatomic, strong) NSArray<NSArray<PHAsset *> *> *groupedPhotos;
@property (nonatomic, strong) NSMutableArray<PHAsset *> *selectedPhotos;
@property (nonatomic, strong) UIView *gradientView;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) QMUIButton *deleteButton;
@property (nonatomic, strong) NSMutableSet<NSIndexPath *> *selectedIndexPaths;
@property (nonatomic, strong) UIActivityIndicatorView *loadingIndicator;
@property (nonatomic, strong) UIProgressView *progressView;
@property (nonatomic, strong) UILabel *statusLabel;

@end

@implementation KJSmartCleanViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = UIColor.whiteColor;
    self.selectedIndexPaths = [NSMutableSet set];
    self.selectedPhotos = [NSMutableArray array];
    
    [self setupGradientView];
    [self setupCollectionView];
    [self setupDeleteButton];
    [self setupLoadingViews];
    [self requestPhotoLibraryAccess];
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
        make.top.left.right.equalTo(self.view);
        make.height.mas_equalTo(fitScale(218.5));
    }];
    
    // 添加标题
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = @"Similar Photos";
    titleLabel.font = [UIFont systemFontOfSize:22 weight:UIFontWeightBold];
    titleLabel.textColor = [UIColor blackColor];
    [self.gradientView addSubview:titleLabel];
    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.gradientView);
        make.top.equalTo(self.gradientView).offset(fitScale(50));
    }];
    
    // 添加说明
    UILabel *descriptionLabel = [[UILabel alloc] init];
    descriptionLabel.text = @"Find and clean duplicate and similar photos";
    descriptionLabel.font = [UIFont systemFontOfSize:14];
    descriptionLabel.textColor = [UIColor darkGrayColor];
    descriptionLabel.textAlignment = NSTextAlignmentCenter;
    [self.gradientView addSubview:descriptionLabel];
    [descriptionLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.gradientView);
        make.top.equalTo(titleLabel.mas_bottom).offset(10);
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
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.minimumInteritemSpacing = fitScale(8);
    layout.minimumLineSpacing = fitScale(8);
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
        make.edges.equalTo(self.view);
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
    
    // 使用相似照片管理器查找相似照片
    [[KJPhotoSimilarityManager sharedManager] findSimilarPhotosWithProgress:^(float progress) {
        // 更新进度条
        self.progressView.progress = progress;
        
        // 更新状态文本
        if (progress < 0.3) {
            self.statusLabel.text = @"Analyzing photos...";
        } else if (progress < 0.7) {
            self.statusLabel.text = @"Finding similar photos...";
        } else {
            self.statusLabel.text = @"Almost done...";
        }
        
    } completion:^(NSArray<NSArray<PHAsset *> *> * _Nonnull similarGroups, NSError * _Nullable error) {
        // 隐藏加载视图
        self.loadingIndicator.hidden = YES;
        self.progressView.hidden = YES;
        self.statusLabel.hidden = YES;
        [self.loadingIndicator stopAnimating];
        
        // 显示集合视图
        self.collectionView.hidden = NO;
        
        // 更新数据源
        self.groupedPhotos = similarGroups;
        [self.collectionView reloadData];
        
        // 没有找到相似照片时提示用户
        if (similarGroups.count == 0) {
            [self showNoSimilarPhotosAlert];
        }
    }];
}

- (void)showNoSimilarPhotosAlert {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"No Similar Photos"
                                                                   message:@"No similar photos were found in your library."
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
        header.title = [NSString stringWithFormat:@"Similar%ld", (long)indexPath.section + 1];
        
        // Check if all items in this section are selected
        NSArray *sectionPhotos = self.groupedPhotos[indexPath.section];
        NSInteger selectedCount = 0;
        for (NSInteger item = 0; item < sectionPhotos.count; item++) {
            if ([self.selectedIndexPaths containsObject:[NSIndexPath indexPathForItem:item inSection:indexPath.section]]) {
                selectedCount++;
            }
        }
        header.isAllSelected = selectedCount == sectionPhotos.count;
        
        return header;
    }
    return nil;
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.item == 0) {
        return CGSizeMake(fitScale(133), fitScale(133));
    }
    return CGSizeMake(fitScale(62), fitScale(62));
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
                [self findSimilarPhotos]; // 重新分析照片
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

@end

