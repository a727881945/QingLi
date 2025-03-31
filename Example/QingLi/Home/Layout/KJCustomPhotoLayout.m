//
//  KJCustomPhotoLayout.m
//  QingLi
//
//  Created by QingLi on 2023/11/10.
//

#import "KJCustomPhotoLayout.h"

@interface KJCustomPhotoLayout ()
@property (nonatomic, strong) NSMutableArray<UICollectionViewLayoutAttributes *> *layoutAttributes;
@property (nonatomic, assign) CGSize contentSize;
@end

@implementation KJCustomPhotoLayout

- (instancetype)init {
    self = [super init];
    if (self) {
        self.largePhotoSize = CGSizeMake(180, 180);
        self.smallPhotoSize = CGSizeMake(85, 85);
        self.interItemSpacing = 10;
        self.lineSpacing = 10;
        self.contentSize = CGSizeZero;
    }
    return self;
}

- (void)prepareLayout {
    [super prepareLayout];
    
    // 如果collectionView为nil则不处理
    if (!self.collectionView) {
        return;
    }
    
    // 初始化布局属性数组
    self.layoutAttributes = [NSMutableArray array];
    
    // 获取section数量
    NSInteger numberOfSections = [self.collectionView numberOfSections];
    if (numberOfSections == 0) {
        return;
    }
    
    CGFloat contentWidth = self.collectionView.bounds.size.width - self.sectionInset.left - self.sectionInset.right;
    CGFloat sectionVerticalOffset = 0;
    
    for (NSInteger section = 0; section < numberOfSections; section++) {
        // 获取当前section的item数量
        NSInteger numberOfItems = [self.collectionView numberOfItemsInSection:section];
        if (numberOfItems == 0) {
            continue;
        }
        
        // 添加section header
        CGFloat headerHeight = self.headerReferenceSize.height;
        if (headerHeight > 0) {
            NSIndexPath *headerIndexPath = [NSIndexPath indexPathForItem:0 inSection:section];
            UICollectionViewLayoutAttributes *headerAttributes = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader withIndexPath:headerIndexPath];
            headerAttributes.frame = CGRectMake(0, sectionVerticalOffset, self.collectionView.bounds.size.width, headerHeight);
            [self.layoutAttributes addObject:headerAttributes];
            sectionVerticalOffset += headerHeight;
        }
        
        // 计算在大图右侧空间内可以摆放的小图数量
        CGFloat rightSpaceWidth = contentWidth - self.largePhotoSize.width - self.interItemSpacing;
        NSInteger smallImagesPerRow = floor(rightSpaceWidth / (self.smallPhotoSize.width + self.interItemSpacing)) + 1;
        
        // 计算大图右侧能放置的小图行数
        NSInteger rowsInLargePhotoHeight = floor((self.largePhotoSize.height + self.lineSpacing) / (self.smallPhotoSize.height + self.lineSpacing));
        
        // 计算右侧区域最多可放置的小图数量
        NSInteger maxSmallImagesInRightArea = smallImagesPerRow * rowsInLargePhotoHeight;
        
        // 每个section的内容区域起始位置
        CGFloat contentTop = sectionVerticalOffset + self.sectionInset.top;
        
        for (NSInteger i = 0; i < numberOfItems; i++) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:section];
            UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
            
            if (i == 0) {
                // 第一个item是大图
                attributes.frame = CGRectMake(self.sectionInset.left, 
                                             contentTop, 
                                             self.largePhotoSize.width, 
                                             self.largePhotoSize.height);
            } else if (i <= maxSmallImagesInRightArea) {
                // 大图右侧区域的小图
                NSInteger positionInRightArea = i - 1; // 在右侧区域中的位置
                NSInteger rowInRightArea = positionInRightArea / smallImagesPerRow; // 在右侧区域中的行
                NSInteger colInRightArea = positionInRightArea % smallImagesPerRow; // 在右侧区域中的列
                
                CGFloat x = self.sectionInset.left + self.largePhotoSize.width + self.interItemSpacing + colInRightArea * (self.smallPhotoSize.width + self.interItemSpacing);
                CGFloat y = contentTop + rowInRightArea * (self.smallPhotoSize.height + self.lineSpacing);
                
                attributes.frame = CGRectMake(x, y, self.smallPhotoSize.width, self.smallPhotoSize.height);
            } else {
                // 大图以下区域的小图
                NSInteger positionInBottomArea = i - 1 - maxSmallImagesInRightArea; // 在底部区域中的位置
                NSInteger smallImagesPerRowInBottomArea = floor(contentWidth / (self.smallPhotoSize.width + self.interItemSpacing)) + 1; // 底部每行可放置的小图数量
                NSInteger rowInBottomArea = positionInBottomArea / smallImagesPerRowInBottomArea; // 在底部区域中的行
                NSInteger colInBottomArea = positionInBottomArea % smallImagesPerRowInBottomArea; // 在底部区域中的列
                
                CGFloat x = self.sectionInset.left + colInBottomArea * (self.smallPhotoSize.width + self.interItemSpacing);
                CGFloat y = contentTop + self.largePhotoSize.height + self.lineSpacing + rowInBottomArea * (self.smallPhotoSize.height + self.lineSpacing);
                
                attributes.frame = CGRectMake(x, y, self.smallPhotoSize.width, self.smallPhotoSize.height);
            }
            
            [self.layoutAttributes addObject:attributes];
        }
        
        // 计算这个section的底部位置
        CGFloat sectionHeight = 0;
        
        if (numberOfItems <= 1) {
            // 只有大图或空section
            sectionHeight = self.largePhotoSize.height + self.sectionInset.top + self.sectionInset.bottom;
        } else if (numberOfItems <= maxSmallImagesInRightArea + 1) {
            // 只有大图和右侧区域小图
            NSInteger smallImagesCount = numberOfItems - 1;
            NSInteger rowsNeeded = ceil((CGFloat)smallImagesCount / smallImagesPerRow);
            CGFloat smallPhotosHeight = rowsNeeded * self.smallPhotoSize.height + (rowsNeeded - 1) * self.lineSpacing;
            sectionHeight = MAX(self.largePhotoSize.height, smallPhotosHeight) + self.sectionInset.top + self.sectionInset.bottom;
        } else {
            // 有底部区域小图
            NSInteger bottomAreaImages = numberOfItems - 1 - maxSmallImagesInRightArea;
            NSInteger smallImagesPerRowInBottomArea = floor(contentWidth / (self.smallPhotoSize.width + self.interItemSpacing)) + 1;
            NSInteger rowsInBottomArea = ceil((CGFloat)bottomAreaImages / smallImagesPerRowInBottomArea);
            
            sectionHeight = self.largePhotoSize.height + self.lineSpacing +
                           rowsInBottomArea * (self.smallPhotoSize.height + self.lineSpacing) - self.lineSpacing +
                           self.sectionInset.top + self.sectionInset.bottom;
        }
        
        // 更新下一个section的垂直起始位置
        sectionVerticalOffset += sectionHeight;
    }
    
    // 设置内容尺寸
    self.contentSize = CGSizeMake(self.collectionView.bounds.size.width, sectionVerticalOffset);
}

- (CGSize)collectionViewContentSize {
    // 如果已经计算过了，直接返回
    if (!CGSizeEqualToSize(self.contentSize, CGSizeZero)) {
        return self.contentSize;
    }
    
    // 如果collectionView为nil则返回零尺寸
    if (!self.collectionView) {
        return CGSizeZero;
    }
    
    // 还没有计算过内容大小，重新计算
    NSInteger numberOfSections = [self.collectionView numberOfSections];
    if (numberOfSections == 0) {
        return CGSizeZero;
    }
    
    CGFloat contentHeight = 0;
    CGFloat contentWidth = self.collectionView.bounds.size.width;
    
    // 累加每个section的高度
    for (NSInteger section = 0; section < numberOfSections; section++) {
        NSInteger numberOfItems = [self.collectionView numberOfItemsInSection:section];
        if (numberOfItems == 0) {
            continue;
        }
        
        // 添加header高度
        if (self.headerReferenceSize.height > 0) {
            contentHeight += self.headerReferenceSize.height;
        }
        
        CGFloat sectionContentWidth = contentWidth - self.sectionInset.left - self.sectionInset.right;
        CGFloat rightSpaceWidth = sectionContentWidth - self.largePhotoSize.width - self.interItemSpacing;
        NSInteger smallImagesPerRow = floor(rightSpaceWidth / (self.smallPhotoSize.width + self.interItemSpacing)) + 1;
        NSInteger rowsInLargePhotoHeight = floor((self.largePhotoSize.height + self.lineSpacing) / (self.smallPhotoSize.height + self.lineSpacing));
        NSInteger maxSmallImagesInRightArea = smallImagesPerRow * rowsInLargePhotoHeight;
        
        // 计算section高度
        CGFloat sectionHeight = 0;
        
        if (numberOfItems <= 1) {
            // 只有大图或空section
            sectionHeight = self.largePhotoSize.height + self.sectionInset.top + self.sectionInset.bottom;
        } else if (numberOfItems <= maxSmallImagesInRightArea + 1) {
            // 只有大图和右侧区域小图
            NSInteger smallImagesCount = numberOfItems - 1;
            NSInteger rowsNeeded = ceil((CGFloat)smallImagesCount / smallImagesPerRow);
            CGFloat smallPhotosHeight = rowsNeeded * self.smallPhotoSize.height + (rowsNeeded - 1) * self.lineSpacing;
            sectionHeight = MAX(self.largePhotoSize.height, smallPhotosHeight) + self.sectionInset.top + self.sectionInset.bottom;
        } else {
            // 有底部区域小图
            NSInteger bottomAreaImages = numberOfItems - 1 - maxSmallImagesInRightArea;
            NSInteger smallImagesPerRowInBottomArea = floor(sectionContentWidth / (self.smallPhotoSize.width + self.interItemSpacing)) + 1;
            NSInteger rowsInBottomArea = ceil((CGFloat)bottomAreaImages / smallImagesPerRowInBottomArea);
            
            sectionHeight = self.largePhotoSize.height + self.lineSpacing +
                           rowsInBottomArea * (self.smallPhotoSize.height + self.lineSpacing) - self.lineSpacing +
                           self.sectionInset.top + self.sectionInset.bottom;
        }
        
        contentHeight += sectionHeight;
    }
    
    self.contentSize = CGSizeMake(contentWidth, contentHeight);
    return self.contentSize;
}

- (NSArray<UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect {
    // 确保布局属性已经计算过
    if (self.layoutAttributes.count == 0 && self.collectionView) {
        [self prepareLayout];
    }
    
    NSMutableArray<UICollectionViewLayoutAttributes *> *visibleLayoutAttributes = [NSMutableArray array];
    
    // 找出在可见区域内的所有cell
    for (UICollectionViewLayoutAttributes *attributes in self.layoutAttributes) {
        if (CGRectIntersectsRect(attributes.frame, rect)) {
            [visibleLayoutAttributes addObject:attributes];
        }
    }
    
    return visibleLayoutAttributes;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    // 确保布局属性已经计算过
    if (self.layoutAttributes.count == 0 && self.collectionView) {
        [self prepareLayout];
    }
    
    // 查找对应的布局属性
    for (UICollectionViewLayoutAttributes *attributes in self.layoutAttributes) {
        if (attributes.representedElementCategory == UICollectionElementCategoryCell && 
            [attributes.indexPath isEqual:indexPath]) {
            return attributes;
        }
    }
    return nil;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath {
    // 确保布局属性已经计算过
    if (self.layoutAttributes.count == 0 && self.collectionView) {
        [self prepareLayout];
    }
    
    // 查找对应的supplementary view布局属性
    for (UICollectionViewLayoutAttributes *attributes in self.layoutAttributes) {
        if (attributes.representedElementCategory == UICollectionElementCategorySupplementaryView && 
            [attributes.indexPath isEqual:indexPath] && 
            [attributes.representedElementKind isEqualToString:elementKind]) {
            return attributes;
        }
    }
    return nil;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    // 当bounds改变时，重新计算布局
    if (!CGSizeEqualToSize(newBounds.size, self.collectionView.bounds.size)) {
        return YES;
    }
    return NO;
}

@end 