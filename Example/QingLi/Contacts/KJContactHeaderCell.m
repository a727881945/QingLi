//
//  KJContactHeaderCell.m
//  QingLi_Example
//
//  Created by wangkejie on 2025/4/2.
//  Copyright © 2025 wangkejie. All rights reserved.
//

#import "KJContactHeaderCell.h"

@implementation KJContactHeaderCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor colorWithRed:0.9 green:0.95 blue:1.0 alpha:1.0];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        _avatarImageView = [[UIImageView alloc] init];
        _avatarImageView.layer.cornerRadius = 25;
        _avatarImageView.clipsToBounds = YES;
        _avatarImageView.contentMode = UIViewContentModeScaleAspectFill;
        [self.contentView addSubview:_avatarImageView];
        
        _nameLabel = [[UILabel alloc] init];
        _nameLabel.font = [UIFont boldSystemFontOfSize:16];
        [self.contentView addSubview:_nameLabel];
        
        _phoneLabel = [[UILabel alloc] init];
        _phoneLabel.font = [UIFont systemFontOfSize:14];
        _phoneLabel.textColor = [UIColor grayColor];
        [self.contentView addSubview:_phoneLabel];
        
        _mergeButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [_mergeButton setTitle:@"Merge to" forState:UIControlStateNormal];
        _mergeButton.titleLabel.font = [UIFont systemFontOfSize:14];
        [_mergeButton setTitleColor:[UIColor systemBlueColor] forState:UIControlStateNormal];
        [self.contentView addSubview:_mergeButton];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat padding = 15;
    _avatarImageView.frame = CGRectMake(padding, 10, 50, 50);
    _nameLabel.frame = CGRectMake(padding + 60, 15, 150, 20);
    _phoneLabel.frame = CGRectMake(padding + 60, 35, 150, 20);
    _mergeButton.frame = CGRectMake(self.contentView.frame.size.width - 100, 25, 80, 30);
}

@end
