#import "KJPhotoCell.h"
#import "KJTools.h"

@interface KJPhotoCell()

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIImageView *checkmarkView;
@property (nonatomic, strong) UILabel *bestPhotoLabel;

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
    [self.contentView addSubview:self.imageView];
    [self.imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.contentView);
    }];
    
    // Checkmark View
    self.checkmarkView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkmark"]];
    self.checkmarkView.hidden = YES;
    [self.contentView addSubview:self.checkmarkView];
    [self.checkmarkView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.right.equalTo(self.contentView).insets(UIEdgeInsetsMake(5, 0, 0, 5));
        make.size.mas_equalTo(CGSizeMake(20, 20));
    }];
    
    // Best Photo Label
    self.bestPhotoLabel = [[UILabel alloc] init];
    self.bestPhotoLabel.text = @"Best Photo";
    self.bestPhotoLabel.textColor = [UIColor whiteColor];
    self.bestPhotoLabel.font = [UIFont systemFontOfSize:10];
    self.bestPhotoLabel.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
    self.bestPhotoLabel.textAlignment = NSTextAlignmentCenter;
    self.bestPhotoLabel.hidden = YES;
    [self.contentView addSubview:self.bestPhotoLabel];
    [self.bestPhotoLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self.contentView);
        make.height.mas_equalTo(20);
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
}

- (void)setIsSelected:(BOOL)isSelected {
    _isSelected = isSelected;
    [self updateSelectionState];
}

- (void)setIsBestPhoto:(BOOL)isBestPhoto {
    _isBestPhoto = isBestPhoto;
    self.bestPhotoLabel.hidden = !isBestPhoto;
}

- (void)updateSelectionState {
    self.checkmarkView.hidden = !self.isSelected;
    self.contentView.layer.borderWidth = self.isSelected ? 2 : 0;
    self.contentView.layer.borderColor = self.isSelected ? [UIColor qmui_colorWithHexString:@"#0092FF"].CGColor : [UIColor clearColor].CGColor;
}

@end 