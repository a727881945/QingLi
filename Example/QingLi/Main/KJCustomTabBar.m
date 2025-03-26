//
//  KJCustomTabBar.m
//  QingLi_Example
//
//  Created by wangkejie on 2024/12/18.
//  Copyright © 2024 wangkejie. All rights reserved.
//

#import "KJCustomTabBar.h"
@interface KJCustomTabBar()

@property (nonatomic, strong) UIStackView *stackView;
@property (nonatomic, strong) QMUIButton *homeButton;
@property (nonatomic, strong) QMUIButton *contactsButton;
@property (nonatomic, strong) QMUIButton *profileButton;
@property (nonatomic) NSUInteger selectedIndex;

@end
@implementation KJCustomTabBar

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupSubviews];
    }
    return self;
}

- (void)setupSubviews {
    [self addSubview:self.stackView];
    [self.stackView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(50);
        make.right.mas_equalTo(-50);
        make.height.mas_equalTo(52);
        make.top.mas_equalTo(6);
    }];
    self.homeButton = [[QMUIButton alloc] qmui_initWithImage:[UIImage imageNamed:@"qingliclear"] title:@"Home"];
    self.homeButton.imagePosition = QMUIButtonImagePositionTop;

    self.contactsButton = [[QMUIButton alloc] qmui_initWithImage:[UIImage imageNamed:@"contagts"] title:@"Contacts"];
    self.contactsButton.imagePosition = QMUIButtonImagePositionTop;
    
    self.profileButton = [[QMUIButton alloc] qmui_initWithImage:[UIImage imageNamed:@"center"] title:@"Center"];
    self.profileButton.imagePosition = QMUIButtonImagePositionTop;
    
    [self addsubButtons:self.homeButton tag:0];
    [self addsubButtons:self.contactsButton tag:1];
    [self addsubButtons:self.profileButton tag:2];
    self.selectedIndex = 0;
    [self updateButtonColors];
}

- (void)buttonTapped:(QMUIButton *)sender {
    self.selectedIndex = sender.tag;
    sender.selected = YES;
    [self updateButtonColors];
    if (self.delegate) {
        [self.delegate tabBarDidSelectButtonAtIndex:sender.tag];
    }
}

- (void)addsubButtons:(QMUIButton *)button tag:(NSInteger)tag {
    [button qmui_setImageTintColor:[UIColor qmui_colorWithHexString:@"#9BA4AC"] forState:UIControlStateNormal];
    [button setTitleColor:[UIColor qmui_colorWithHexString:@"#9BA4AC"] forState:UIControlStateNormal];
    [button qmui_setImageTintColor:[UIColor qmui_colorWithHexString:@"#0092FF"] forState:UIControlStateSelected];
    [button setTitleColor:[UIColor qmui_colorWithHexString:@"#0092FF"] forState:UIControlStateSelected];

    button.tag = tag;
    button.titleLabel.font = [UIFont systemFontOfSize:12];
    [button addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.stackView addArrangedSubview:button];
    [button mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(60);
        make.bottom.top.mas_equalTo(0);
    }];
}

- (void)updateButtonColors {
    for (UIButton *button in self.stackView.arrangedSubviews) {
        button.selected = (button.tag == self.selectedIndex);
    }
}


- (UIStackView *)stackView {
    if (!_stackView) {
        _stackView = [[UIStackView alloc] initWithFrame:CGRectZero];
        _stackView.axis = UILayoutConstraintAxisHorizontal;
        _stackView.alignment = UIStackViewAlignmentCenter;
        _stackView.distribution = UIStackViewDistributionEqualSpacing;
    }
    return _stackView;
}

@end
