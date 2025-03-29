#import "KJPhotoSectionHeader.h"
#import "KJTools.h"

@interface KJPhotoSectionHeader()

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) QMUIButton *selectAllButton;

@end

@implementation KJPhotoSectionHeader

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
    // Title Label
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    self.titleLabel.textColor = [UIColor blackColor];
    [self addSubview:self.titleLabel];
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).offset(fitScale(16));
        make.centerY.equalTo(self);
    }];
    
    // Select All Button
    self.selectAllButton = [[QMUIButton alloc] init];
    [self.selectAllButton setTitleColor:[UIColor qmui_colorWithHexString:@"#0092FF"] forState:UIControlStateNormal];
    self.selectAllButton.titleLabel.font = [UIFont systemFontOfSize:14];
    [self.selectAllButton addTarget:self action:@selector(selectAllButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.selectAllButton];
    [self.selectAllButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self).offset(-fitScale(16));
        make.centerY.equalTo(self);
    }];
}

- (void)setTitle:(NSString *)title {
    _title = title;
    self.titleLabel.text = title;
}

- (void)setIsAllSelected:(BOOL)isAllSelected {
    _isAllSelected = isAllSelected;
    [self.selectAllButton setTitle:isAllSelected ? @"Deselect All" : @"Select All" forState:UIControlStateNormal];
}

- (void)selectAllButtonTapped {
    if ([self.delegate respondsToSelector:@selector(sectionHeader:didTapSelectAllAtSection:)]) {
        [self.delegate sectionHeader:self didTapSelectAllAtSection:self.section];
    }
}

@end 