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
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        UIView *containerView = [[UIView alloc] initWithFrame:CGRectZero];
        [self.contentView addSubview:containerView];
        [containerView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(14);
            make.top.mas_equalTo(16);
            make.right.mas_equalTo(-14);
            make.height.mas_equalTo(74);
        }];
        containerView.backgroundColor = [UIColor qmui_colorWithHexString:@"#E8F5FF"];
        
        _avatarImageView = [[UIImageView alloc] init];
        _avatarImageView.layer.cornerRadius = 26;
        _avatarImageView.layer.masksToBounds = YES;
//        _avatarImageView.backgroundColor = [UIColor qmui_colorWithHexString:@"#0092FF"];
        _avatarImageView.contentMode = UIViewContentModeScaleAspectFill;
        [containerView addSubview:_avatarImageView];
        [_avatarImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(14);
            make.top.mas_equalTo(11);
            make.height.width.mas_equalTo(52);
        }];
        
        UIImageView *arowDownImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        arowDownImageView.image = [UIImage imageNamed:@"contact_arrow_down"];
        [containerView addSubview:arowDownImageView];
        [arowDownImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.mas_equalTo(-13);
            make.width.height.mas_equalTo(9);
            make.centerY.mas_equalTo(_avatarImageView.mas_centerY);
        }];
        
        _mergeButton = [QMUIButton buttonWithType:UIButtonTypeCustom];
        [_mergeButton setTitle:@"Merge to" forState:UIControlStateNormal];
        _mergeButton.titleLabel.font = [UIFont qmui_mediumSystemFontOfSize:12];
        _mergeButton.titleLabel.textAlignment = NSTextAlignmentRight;
        [_mergeButton setTitleColor:[UIColor qmui_colorWithHexString:@"#28A7FF"] forState:UIControlStateNormal];
        [containerView addSubview:_mergeButton];
        [_mergeButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.mas_equalTo(arowDownImageView.mas_left).mas_offset(-3.5);
            make.centerY.mas_equalTo(arowDownImageView.mas_centerY);
            make.width.mas_equalTo(58);
            make.height.mas_greaterThanOrEqualTo(1);
        }];
        
        _nameLabel = [[UILabel alloc] init];
        _nameLabel.font = [UIFont boldSystemFontOfSize:16];
        _nameLabel.textColor = [UIColor qmui_colorWithHexString:@"#111111"];
        [containerView addSubview:_nameLabel];
        [_nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(_avatarImageView.mas_right).mas_offset(8);
            make.top.mas_equalTo(17);
            make.height.mas_equalTo(23);
            make.right.mas_equalTo(_mergeButton.mas_left).mas_offset(-2);
        }];
        
        _phoneLabel = [[UILabel alloc] init];
        _phoneLabel.font = [UIFont systemFontOfSize:12];
        _phoneLabel.textColor = [UIColor qmui_colorWithHexString:@"#666666"];
        [containerView addSubview:_phoneLabel];
        [_phoneLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(_nameLabel.mas_bottom);
            make.left.mas_equalTo(_nameLabel.mas_left);
            make.height.mas_equalTo(17);
        }];
        

        
        UILabel *descLabel = [[UILabel alloc] init];
        descLabel.font = [UIFont systemFontOfSize:14];
        descLabel.textColor = [UIColor qmui_colorWithHexString:@"#999999"];
        descLabel.text = @"Select contacts to merge";
        [self.contentView addSubview:descLabel];
        [descLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(14);
            make.top.mas_equalTo(containerView.mas_bottom).mas_offset(14);
            make.width.mas_greaterThanOrEqualTo(1);
            make.height.mas_equalTo(20);
        }];
        
        _selectAllButton = [QMUIButton buttonWithType:UIButtonTypeCustom];
        [_selectAllButton setTitle:@"Select All" forState:UIControlStateNormal];
        _selectAllButton.titleLabel.font = [UIFont systemFontOfSize:12];
        [_selectAllButton setTitleColor:[UIColor qmui_colorWithHexString:@"#28A7FF"] forState:UIControlStateNormal];
        [self.contentView addSubview:_selectAllButton];
        [_selectAllButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.mas_equalTo(-14);
            make.centerY.mas_equalTo(descLabel.mas_centerY);
            make.height.mas_equalTo(17);
            make.width.mas_greaterThanOrEqualTo(1);
        }];
    }
    return self;
}

@end
