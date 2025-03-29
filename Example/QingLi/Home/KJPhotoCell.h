#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

@interface KJPhotoCell : UICollectionViewCell

@property (nonatomic, strong) PHAsset *asset;
@property (nonatomic, assign) BOOL isSelected;
@property (nonatomic, assign) BOOL isBestPhoto;

+ (NSString *)identifier;
- (void)updateSelectionState;

@end

NS_ASSUME_NONNULL_END 