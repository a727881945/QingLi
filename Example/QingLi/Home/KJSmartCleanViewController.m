//
//  KJSmartCleanViewController.m
//  QingLi_Example
//
//  Created by wangkejie on 2024/12/26.
//  Copyright © 2024 wangkejie. All rights reserved.
//

#import "KJSmartCleanViewController.h"

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>
#import <CoreImage/CoreImage.h>
#import <Vision/Vision.h>

@interface KJSmartCleanViewController() <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) NSArray<NSArray<PHAsset *> *> *groupedPhotos;
@property (nonatomic, strong) NSMutableArray<PHAsset *> *selectPhotos;
@property (nonatomic, strong) UIView *bottomView;
@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong) UICollectionView *collectionView;

@end

@implementation KJSmartCleanViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = UIColor.whiteColor;
    
    // Initialize properties
    self.groupedPhotos = @[];
    self.selectPhotos = [NSMutableArray array];
    
    // Setup CollectionView
    [self setupCollectionView];
    [self.view addSubview:self.collectionView];
    [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
}

- (void)setupCollectionView {
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.sectionInset = UIEdgeInsetsMake(0, fitScale(16), 0, fitScale(16));
    layout.itemSize = CGSizeMake(fitScale(70), fitScale(70));
    layout.headerReferenceSize = CGSizeMake(self.view.frame.size.width, fitScale(40));
    
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
//    [self.collectionView registerClass:[PhotoCell class] forCellWithReuseIdentifier:PhotoCell.identifier];
//    [self.collectionView registerClass:[SectionHeader class]
//            forSupplementaryViewOfKind:UICollectionElementKindSectionHeader
//                   withReuseIdentifier:SectionHeader.identifier];
    self.collectionView.backgroundColor = UIColor.whiteColor;
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
}

// ... Rest of the implementation follows similar pattern

- (void)deleteSelectPhotos {
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();

}


@end

