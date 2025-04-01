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
    self.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];  // 调小字体
    self.titleLabel.textColor = [UIColor qmui_colorWithHexString:@"#1F2024"];
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
    [self updateTitleLabel];
}

- (void)setPhotoCount:(NSInteger)photoCount {
    _photoCount = photoCount;
    [self updateTitleLabel];
}

- (void)updateTitleLabel {
    // 创建富文本字符串
    NSString *fullText = [NSString stringWithFormat:@"Similar: %ld", (long)self.photoCount];
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:fullText];
    
    // 设置"Similar"部分的样式
    [attributedText addAttribute:NSFontAttributeName
                         value:[UIFont systemFontOfSize:13]
                         range:NSMakeRange(0, 7)];  // "Similar"的长度
    [attributedText addAttribute:NSForegroundColorAttributeName
                         value:[UIColor qmui_colorWithHexString:@"#1F2024"]
                         range:NSMakeRange(0, 7)];
    
    // 设置数字部分的样式
    if (self.photoCount > 0) {
        NSString *countString = [NSString stringWithFormat:@"%ld", (long)self.photoCount];
        NSRange countRange = [fullText rangeOfString:countString];
        if (countRange.location != NSNotFound) {
            [attributedText addAttribute:NSFontAttributeName
                                 value:[UIFont systemFontOfSize:13 weight:UIFontWeightMedium]
                                 range:countRange];
            [attributedText addAttribute:NSForegroundColorAttributeName
                                 value:[UIColor qmui_colorWithHexString:@"#4B5E8D"]
                                 range:countRange];
        }
    }
    
    self.titleLabel.attributedText = attributedText;
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
