//
//  KJSummaryHeaderView.h
//  QingLi
//
//  Created by QingLi on 2023/11/11.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface KJSummaryHeaderView : UICollectionReusableView

@property (nonatomic, strong, readonly) UIImageView *iconImageView;
@property (nonatomic, strong, readonly) UILabel *countLabel;
@property (nonatomic, strong, readonly) UILabel *descriptionLabel;

+ (NSString *)identifier;
- (void)configureWithCount:(NSInteger)count;

@end

NS_ASSUME_NONNULL_END 