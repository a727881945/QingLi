#import "KJPhotoCell.h"
#import "KJTools.h"

@interface KJPhotoCell()

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIImageView *selectStateImageView;
@property (nonatomic, strong) UILabel *bestPhotoLabel;
@property (nonatomic, strong) UIImageView *playIconView;

@end

@implementation KJPhotoCell

+ (NSString *)identifier {
    return NSStringFromClass(self);
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupViews];
    }
    return self;
}

- (void)setupViews {
    // Image View
    self.imageView = [[UIImageView alloc] init];
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;
    self.imageView.clipsToBounds = YES;
    self.imageView.layer.cornerRadius = 8;
    self.imageView.layer.masksToBounds = YES;
    [self.contentView addSubview:self.imageView];
    [self.imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.contentView);
    }];
    
    // Select State Image View
    self.selectStateImageView = [[UIImageView alloc] init];
    self.selectStateImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.contentView addSubview:self.selectStateImageView];
    [self.selectStateImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.right.equalTo(self.contentView).insets(UIEdgeInsetsMake(3.5, 0, 0, 3.5));
        make.size.mas_equalTo(CGSizeMake(12, 12));
    }];
    
    // Best Photo Label
    self.bestPhotoLabel = [[UILabel alloc] init];
    self.bestPhotoLabel.text = @"Best Photo";
    self.bestPhotoLabel.textColor = [UIColor whiteColor];
    self.bestPhotoLabel.font = [UIFont systemFontOfSize:10];
    self.bestPhotoLabel.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
    self.bestPhotoLabel.textAlignment = NSTextAlignmentCenter;
    self.bestPhotoLabel.hidden = YES;
    [self.imageView addSubview:self.bestPhotoLabel];
    [self.bestPhotoLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self.contentView);
        make.height.mas_equalTo(20);
    }];
    
    // 播放图标 - 使用UIImageView替代按钮
    self.playIconView = [[UIImageView alloc] init];
    
    // 使用系统SF Symbols中的更美观的播放图标
    UIImage *playImage = [UIImage systemImageNamed:@"play.circle.fill"];
    UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:24 weight:UIImageSymbolWeightRegular];
    self.playIconView.image = [playImage imageByApplyingSymbolConfiguration:config];
    
    self.playIconView.tintColor = [[UIColor whiteColor] colorWithAlphaComponent:0.8]; // 半透明白色
    self.playIconView.contentMode = UIViewContentModeScaleAspectFit;
    self.playIconView.hidden = YES; // 默认隐藏
    
    // 添加到cell的右下角，更不容易影响选择
    self.playIconView.userInteractionEnabled = YES;
    [self.contentView addSubview:self.playIconView];
    [self.playIconView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.contentView);
        make.size.mas_equalTo(CGSizeMake(24, 24));
    }];
}

- (void)setAsset:(PHAsset *)asset {
    _asset = asset;
    
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.synchronous = NO;
    options.deliveryMode = PHImageRequestOptionsDeliveryModeOpportunistic;
    
    CGSize size = CGSizeMake(self.contentView.bounds.size.width * [UIScreen mainScreen].scale,
                            self.contentView.bounds.size.height * [UIScreen mainScreen].scale);
    
    [[PHImageManager defaultManager] requestImageForAsset:asset
                                             targetSize:size
                                            contentMode:PHImageContentModeAspectFill
                                                options:options
                                          resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        if (result) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.imageView.image = result;
            });
        }
    }];
    
    // 根据资产类型显示不同UI
    BOOL isVideo = (asset.mediaType == PHAssetMediaTypeVideo);
    self.playIconView.hidden = !isVideo;
    
    // 如果是视频，始终隐藏"Best Photo"标签
    if (isVideo) {
        self.bestPhotoLabel.hidden = YES;
    } else {
        // 如果是照片，根据isBestPhoto属性决定是否显示
        self.bestPhotoLabel.hidden = !_isBestPhoto;
    }
}

- (void)setIsSelected:(BOOL)isSelected {
    _isSelected = isSelected;
    [self updateSelectionState];
}

- (void)setIsBestPhoto:(BOOL)isBestPhoto {
    _isBestPhoto = isBestPhoto;
    
    // 只有在资产不是视频时才显示最佳照片标签
    if (self.asset && self.asset.mediaType != PHAssetMediaTypeVideo) {
        self.bestPhotoLabel.hidden = !isBestPhoto;
    } else {
        self.bestPhotoLabel.hidden = YES; 
    }
}

- (void)updateSelectionState {
    // 更新选中状态图标
    UIImage *stateImage = self.isSelected ? [UIImage imageNamed:@"select_icon"] : [UIImage imageNamed:@"unselect_icon"];
    self.selectStateImageView.image = stateImage;
    
    // 更新边框
    self.contentView.layer.borderWidth = self.isSelected ? 2 : 0;
    self.contentView.layer.borderColor = self.isSelected ? [UIColor qmui_colorWithHexString:@"#0092FF"].CGColor : [UIColor clearColor].CGColor;
}

@end 
