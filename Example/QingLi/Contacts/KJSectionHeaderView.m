//
//  KJSectionHeaderView.m
//  QingLi_Example
//
//  Created by wangkejie on 2025/4/2.
//  Copyright © 2025 wangkejie. All rights reserved.
//

#import "KJSectionHeaderView.h"

@implementation KJSectionHeaderView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont systemFontOfSize:14];
        _titleLabel.textColor = [UIColor grayColor];
        _titleLabel.text = @"Select contacts to merge";
        [self addSubview:_titleLabel];
        
        _selectAllButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [_selectAllButton setTitle:@"Select All" forState:UIControlStateNormal];
        _selectAllButton.titleLabel.font = [UIFont systemFontOfSize:14];
        [self addSubview:_selectAllButton];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat padding = 15;
    _titleLabel.frame = CGRectMake(padding, 5, 200, 30);
    _selectAllButton.frame = CGRectMake(self.frame.size.width - 100, 5, 80, 30);
}


@end
