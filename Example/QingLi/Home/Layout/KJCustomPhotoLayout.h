//
//  KJCustomPhotoLayout.h
//  QingLi
//
//  Created by QingLi on 2023/11/10.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface KJCustomPhotoLayout : UICollectionViewFlowLayout

// 大图尺寸
@property (nonatomic, assign) CGSize largePhotoSize;
// 小图尺寸
@property (nonatomic, assign) CGSize smallPhotoSize;
// 元素间距
@property (nonatomic, assign) CGFloat interItemSpacing;
// 行间距
@property (nonatomic, assign) CGFloat lineSpacing;

@end

NS_ASSUME_NONNULL_END 