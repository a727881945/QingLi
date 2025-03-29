#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol KJPhotoSectionHeaderDelegate <NSObject>

- (void)sectionHeader:(id)header didTapSelectAllAtSection:(NSInteger)section;

@end

@interface KJPhotoSectionHeader : UICollectionReusableView

@property (nonatomic, weak) id<KJPhotoSectionHeaderDelegate> delegate;
@property (nonatomic, assign) NSInteger section;
@property (nonatomic, assign) BOOL isAllSelected;
@property (nonatomic, copy) NSString *title;

+ (NSString *)identifier;

@end

NS_ASSUME_NONNULL_END 