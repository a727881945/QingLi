//
//  KJSummaryHeaderView.m
//  QingLi
//
//  Created by QingLi on 2023/11/11.
//

#import "KJSummaryHeaderView.h"

@interface KJSummaryHeaderView()

@property (nonatomic, strong, readwrite) UIImageView *iconImageView;
@property (nonatomic, strong, readwrite) UILabel *countLabel;
@property (nonatomic, strong, readwrite) UILabel *descriptionLabel;

@end

@implementation KJSummaryHeaderView

+ (NSString *)identifier {
    return NSStringFromClass(self);
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.layer.cornerRadius = 12;
        self.backgroundColor = [[UIColor qmui_colorWithHexString:@"#E3EBF8"] colorWithAlphaComponent:1];
        [self setupViews];
    }
    return self;
}

- (void)setupViews {
    // 图标视图
    self.iconImageView = [[UIImageView alloc] init];
    self.iconImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.iconImageView.image = [UIImage imageNamed:@"Photos_icon"];
//    self.iconImageView.tintColor = [UIColor qmui_colorWithHexString:@"#1F2024"];
    [self addSubview:self.iconImageView];
    
    // 数量标签
    self.countLabel = [[UILabel alloc] init];
    self.countLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    self.countLabel.textColor = [UIColor qmui_colorWithHexString:@"#4B5E8D"];
    [self addSubview:self.countLabel];
    
    // 描述标签
    self.descriptionLabel = [[UILabel alloc] init];
    self.descriptionLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightRegular];
    self.descriptionLabel.textColor = [UIColor qmui_colorWithHexString:@"#1F2024"];
    self.descriptionLabel.text = @"Duplicate & Similar";
    [self addSubview:self.descriptionLabel];
    
    // 设置约束
    [self.iconImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self).offset(16);
        make.centerY.equalTo(self);
        make.size.mas_equalTo(CGSizeMake(fitScale(18), fitScale(18)));
    }];
    
    [self.countLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.iconImageView.mas_trailing).offset(8);
        make.centerY.equalTo(self);
    }];
    
    [self.descriptionLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.countLabel.mas_trailing).offset(6);
        make.centerY.equalTo(self);
    }];
}

- (void)configureWithCount:(NSInteger)count {
    self.countLabel.text = [NSString stringWithFormat:@"%ld", (long)count];
}

@end 
