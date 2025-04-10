//
//  KJContactsViewController.m
//  QingLi_Example
//
//  Created by wangkejie on 2024/12/24.
//  Copyright © 2024 wangkejie. All rights reserved.
//

#import "KJContactsViewController.h"
#import "KJAllContactsViewController.h"
#import "KJContactDuplViewController.h"
#import "KJContactSimilarNameViewController.h"

@interface KJContactsViewController ()

@end

@implementation KJContactsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor qmui_colorWithHexString:@"#F8FBFF"];
    CGFloat width = self.view.bounds.size.width;
    CGFloat top = 0;
    {
        CGFloat height = width / 375.0 * 190;
        UIImageView *bg = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
        bg.image = [UIImage imageNamed:@"contact_bg"];
        [self.view addSubview:bg];
        
        CGRect avatarFrame = CGRectMake((width - 122) / 2.0, 20 + NavigationContentTop, 122, 122);
        UIImageView *avatar = [[UIImageView alloc] initWithFrame:avatarFrame];
        
        avatar.image = [UIImage imageNamed:@"contact_avatar"];
        [self.view addSubview:avatar];
        
        top = CGRectGetMaxY(avatarFrame);
    }
    
    {
        //all contacts
        CGFloat buttonWidth = (width - 32 * 2);
        QMUIButton *button = [QMUIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake(32, top + 50, buttonWidth, 64);
        button.backgroundColor = [UIColor qmui_colorWithHexString:@"#FFFFFF"];
        [self.view addSubview:button];
        
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(14, 14, 36, 36)];
        imageView.image = [UIImage imageNamed:@"contact_people"];
        [button addSubview:imageView];
        
        UILabel *titleLable = [[UILabel alloc] initWithFrame:CGRectMake(58, 0, 200, 64)];
        titleLable.text = @"All contacts";
        titleLable.font = [UIFont systemFontOfSize:14];
        titleLable.textColor = [UIColor qmui_colorWithHexString:@"#111111"];
        [button addSubview:titleLable];
        
        UIImageView *imageViewRight = [[UIImageView alloc] initWithFrame:CGRectMake(buttonWidth - 14 - 10, 27, 10, 10)];
        imageViewRight.image = [UIImage imageNamed:@"contact_right"];
        [button addSubview:imageViewRight];
        [self.view addSubview:button];
        top = CGRectGetMaxY(button.frame);
        [button addTarget:self action:@selector(p_jumpToAllContactsVC) forControlEvents:UIControlEventTouchUpInside];
    }
    
    {
        //Duplicate numbers
        CGFloat buttonWidth = (width - 32 * 2);
        QMUIButton *button = [QMUIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake(32, top + 30, buttonWidth, 64);
        button.backgroundColor = [UIColor qmui_colorWithHexString:@"#FFFFFF"];
        [self.view addSubview:button];
        
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(14, 14, 36, 36)];
        imageView.image = [UIImage imageNamed:@"contact_dul"];
        [button addSubview:imageView];
        
        UILabel *titleLable = [[UILabel alloc] initWithFrame:CGRectMake(58, 0, 200, 64)];
        titleLable.text = @"Duplicate numbers";
        titleLable.font = [UIFont systemFontOfSize:14];
        titleLable.textColor = [UIColor qmui_colorWithHexString:@"#111111"];
        [button addSubview:titleLable];
        
        UIImageView *imageViewRight = [[UIImageView alloc] initWithFrame:CGRectMake(buttonWidth - 14 - 10, 27, 10, 10)];
        imageViewRight.image = [UIImage imageNamed:@"contact_right"];
        [button addSubview:imageViewRight];
        [self.view addSubview:button];
        top = CGRectGetMaxY(button.frame);
        [button addTarget:self action:@selector(p_jumpToContactsDuplVC) forControlEvents:UIControlEventTouchUpInside];
    }
    
    {
        //Similar name
        CGFloat buttonWidth = (width - 32 * 2);
        QMUIButton *button = [QMUIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake(32, top + 30, buttonWidth, 64);
        button.backgroundColor = [UIColor qmui_colorWithHexString:@"#FFFFFF"];
        [self.view addSubview:button];
        
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(14, 14, 36, 36)];
        imageView.image = [UIImage imageNamed:@"similar_name"];
        [button addSubview:imageView];
        
        UILabel *titleLable = [[UILabel alloc] initWithFrame:CGRectMake(58, 0, 200, 64)];
        titleLable.text = @"Similar name";
        titleLable.font = [UIFont systemFontOfSize:14];
        titleLable.textColor = [UIColor qmui_colorWithHexString:@"#111111"];
        [button addSubview:titleLable];
        
        UIImageView *imageViewRight = [[UIImageView alloc] initWithFrame:CGRectMake(buttonWidth - 14 - 10, 27, 10, 10)];
        imageViewRight.image = [UIImage imageNamed:@"contact_right"];
        [button addSubview:imageViewRight];
        [self.view addSubview:button];
        [button addTarget:self action:@selector(p_jumpToContactsSimilarVC) forControlEvents:UIControlEventTouchUpInside];
    }
}

- (void)p_jumpToAllContactsVC {
    KJAllContactsViewController *vc = [KJAllContactsViewController new];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)p_jumpToContactsDuplVC {
    KJContactDuplViewController *vc = [KJContactDuplViewController new];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)p_jumpToContactsSimilarVC {
    KJContactSimilarNameViewController *vc = [KJContactSimilarNameViewController new];
    [self.navigationController pushViewController:vc animated:YES];
}



@end
