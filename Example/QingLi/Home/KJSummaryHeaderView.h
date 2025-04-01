//
//  KJSummaryHeaderView.h
//  QingLi
//
//  Created by QingLi on 2023/11/11.
//

#import <UIKit/UIKit.h>
#import "KJMediaCleanViewController.h" // 导入媒体类型定义

NS_ASSUME_NONNULL_BEGIN

@interface KJSummaryHeaderView : UICollectionReusableView

@property (nonatomic, strong, readonly) UIImageView *iconImageView;
@property (nonatomic, strong, readonly) UILabel *countLabel;
@property (nonatomic, strong, readonly) UILabel *descriptionLabel;

+ (NSString *)identifier;
- (void)configureWithCount:(NSInteger)count;
- (void)configureWithCount:(NSInteger)count mediaType:(KJMediaType)mediaType;

@end

NS_ASSUME_NONNULL_END 