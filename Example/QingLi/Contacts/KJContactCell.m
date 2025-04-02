//
//  KJContactCell.m
//  QingLi_Example
//
//  Created by wangkejie on 2025/4/2.
//  Copyright © 2025 wangkejie. All rights reserved.
//

#import "KJContactCell.h"

@implementation KJContactCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        _avatarImageView = [[UIImageView alloc] init];
        _avatarImageView.layer.cornerRadius = 20;
        _avatarImageView.clipsToBounds = YES;
        _avatarImageView.contentMode = UIViewContentModeScaleAspectFill;
        [self.contentView addSubview:_avatarImageView];
        
        _nameLabel = [[UILabel alloc] init];
        _nameLabel.font = [UIFont systemFontOfSize:16];
        [self.contentView addSubview:_nameLabel];
        
        _phoneLabel = [[UILabel alloc] init];
        _phoneLabel.font = [UIFont systemFontOfSize:14];
        _phoneLabel.textColor = [UIColor grayColor];
        [self.contentView addSubview:_phoneLabel];
        
        _checkButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_checkButton setImage:[UIImage systemImageNamed:@"circle"] forState:UIControlStateNormal];
        [_checkButton setImage:[UIImage systemImageNamed:@"checkmark.circle.fill"] forState:UIControlStateSelected];
        [self.contentView addSubview:_checkButton];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat padding = 15;
    _avatarImageView.frame = CGRectMake(padding, 10, 40, 40);
    _nameLabel.frame = CGRectMake(padding + 50, 10, 150, 20);
    _phoneLabel.frame = CGRectMake(padding + 50, 30, 150, 20);
    _checkButton.frame = CGRectMake(self.contentView.frame.size.width - 50, 20, 30, 30);
}

- (void)setIsSelected:(BOOL)isSelected {
    _isSelected = isSelected;
    _checkButton.selected = isSelected;
}

@end
