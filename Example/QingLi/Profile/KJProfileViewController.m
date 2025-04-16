//
//  KJProfileViewController.m
//  QingLi_Example
//
//  Created by wangkejie on 2024/12/24.
//  Copyright © 2024 wangkejie. All rights reserved.
//

#import "KJProfileViewController.h"

@interface KJProfileViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray *menuItems;
@property (nonatomic, strong) NSArray *menuIcons;

@end

@implementation KJProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 设置页面标题
    self.title = @"Center";
    
    // 设置菜单项数据
    self.menuItems = @[
        @[@"About Us", @"Privacy & Policy", @"Feedback"],
        @[@"App Version"]
    ];
    
    self.menuIcons = @[
        @[@"info.circle", @"lock.shield", @"envelope"],
        @[@"info.circle.fill"]
    ];
    
    // 设置页面背景色
    self.view.backgroundColor = [UIColor qmui_colorWithHexString:@"#E5F4FD"];
    
    // 创建并配置表格视图
    [self setupTableView];
}

- (void)setupTableView {
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleInsetGrouped];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 15, 0, 0);
    self.tableView.showsVerticalScrollIndicator = NO;
    self.tableView.tableFooterView = [UIView new];
    
    if (@available(iOS 13.0, *)) {
        self.tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentAutomatic;
    }
    
    [self.view addSubview:self.tableView];
    
    // 设置底部TabBar效果
//    [self setupTabBar];
}

- (void)setupTabBar {
    // 创建底部视图
    UIView *tabBarView = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - 49 - self.view.safeAreaInsets.bottom, self.view.frame.size.width, 49 + self.view.safeAreaInsets.bottom)];
    tabBarView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:tabBarView];
    
    // 调整tableView高度，避免与底部视图重叠
    CGRect tableFrame = self.tableView.frame;
    tableFrame.size.height = self.view.frame.size.height - 49 - self.view.safeAreaInsets.bottom;
    self.tableView.frame = tableFrame;
    
    // 添加三个选项卡按钮
    CGFloat buttonWidth = tabBarView.frame.size.width / 3;
    
    // 首页按钮
    UIButton *homeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    homeButton.frame = CGRectMake(0, 0, buttonWidth, 49);
    [homeButton setTitle:@"Home" forState:UIControlStateNormal];
    [homeButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    [homeButton setImage:[UIImage systemImageNamed:@"house"] forState:UIControlStateNormal];
    homeButton.titleEdgeInsets = UIEdgeInsetsMake(30, -25, 0, 0);
    homeButton.imageEdgeInsets = UIEdgeInsetsMake(-10, 0, 0, 0);
    homeButton.tintColor = [UIColor lightGrayColor];
    [tabBarView addSubview:homeButton];
    
    // 联系人按钮
    UIButton *contactsButton = [UIButton buttonWithType:UIButtonTypeCustom];
    contactsButton.frame = CGRectMake(buttonWidth, 0, buttonWidth, 49);
    [contactsButton setTitle:@"Contacts" forState:UIControlStateNormal];
    [contactsButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    [contactsButton setImage:[UIImage systemImageNamed:@"person.2"] forState:UIControlStateNormal];
    contactsButton.titleEdgeInsets = UIEdgeInsetsMake(30, -25, 0, 0);
    contactsButton.imageEdgeInsets = UIEdgeInsetsMake(-10, 0, 0, 0);
    contactsButton.tintColor = [UIColor lightGrayColor];
    [tabBarView addSubview:contactsButton];
    
    // 个人中心按钮（当前选中）
    UIButton *centerButton = [UIButton buttonWithType:UIButtonTypeCustom];
    centerButton.frame = CGRectMake(buttonWidth * 2, 0, buttonWidth, 49);
    [centerButton setTitle:@"Center" forState:UIControlStateNormal];
    [centerButton setTitleColor:[UIColor qmui_colorWithHexString:@"#007AFF"] forState:UIControlStateNormal];
    [centerButton setImage:[UIImage systemImageNamed:@"person.circle"] forState:UIControlStateNormal];
    centerButton.titleEdgeInsets = UIEdgeInsetsMake(30, -25, 0, 0);
    centerButton.imageEdgeInsets = UIEdgeInsetsMake(-10, 0, 0, 0);
    centerButton.tintColor = [UIColor qmui_colorWithHexString:@"#007AFF"];
    [tabBarView addSubview:centerButton];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.menuItems.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSArray *sectionItems = self.menuItems[section];
    return sectionItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.backgroundColor = [UIColor whiteColor];
        cell.textLabel.font = [UIFont systemFontOfSize:16];
        cell.textLabel.textColor = [UIColor blackColor];
    }
    
    // 清除自定义视图，防止视图重叠
    for (UIView *subview in cell.contentView.subviews) {
        if (![subview isKindOfClass:[UILabel class]]) {
            [subview removeFromSuperview];
        }
    }
    
    NSArray *sectionItems = self.menuItems[indexPath.section];
    NSString *itemTitle = sectionItems[indexPath.row];
    cell.textLabel.text = itemTitle;
    
    // 设置图标
    NSArray *sectionIcons = self.menuIcons[indexPath.section];
    NSString *iconName = sectionIcons[indexPath.row];
    
    if (@available(iOS 13.0, *)) {
        // 直接使用系统图标，无背景
        UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:22 weight:UIImageSymbolWeightRegular];
        UIImage *icon = [UIImage systemImageNamed:iconName withConfiguration:config];
        
        // 设置图标颜色为蓝色
        UIImage *coloredIcon = [icon imageWithTintColor:[UIColor qmui_colorWithHexString:@"#007AFF"] renderingMode:UIImageRenderingModeAlwaysOriginal];
        
        // 直接使用cell的imageView属性
        cell.imageView.image = coloredIcon;
        cell.imageView.contentMode = UIViewContentModeScaleAspectFit;
        
        // 设置辅助视图
        if ([itemTitle isEqualToString:@"App Version"]) {
            cell.detailTextLabel.text = @"V1.0";
            cell.detailTextLabel.textColor = [UIColor lightGrayColor];
            cell.accessoryType = UITableViewCellAccessoryNone;
        } else {
            cell.detailTextLabel.text = nil;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
    }
    
    return cell;
}

// 添加方法以确保图标和文字水平对齐
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    // 强制布局子视图
    [cell layoutIfNeeded];
    
    // 调整imageView的中心点垂直位置，使其与textLabel垂直对齐
    cell.imageView.center = CGPointMake(cell.imageView.center.x, cell.contentView.center.y);
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSArray *sectionItems = self.menuItems[indexPath.section];
    NSString *itemTitle = sectionItems[indexPath.row];
    
    if ([itemTitle isEqualToString:@"About Us"]) {
        // 跳转到关于我们页面
        [self showAboutUsPage];
    } else if ([itemTitle isEqualToString:@"Privacy & Policy"]) {
        // 跳转到隐私政策页面
        [self showPrivacyPolicyPage];
    } else if ([itemTitle isEqualToString:@"Feedback"]) {
        // 跳转到反馈页面
        [self showFeedbackPage];
    } else if ([itemTitle isEqualToString:@"App Version"]) {
        // 版本信息，不需要处理点击事件
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60.0;
}

#pragma mark - Action Methods

- (void)showAboutUsPage {
    UIViewController *aboutUsVC = [[UIViewController alloc] init];
    aboutUsVC.title = @"About Us";
    aboutUsVC.view.backgroundColor = [UIColor whiteColor];
    [self.navigationController pushViewController:aboutUsVC animated:YES];
}

- (void)showPrivacyPolicyPage {
    UIViewController *privacyVC = [[UIViewController alloc] init];
    privacyVC.title = @"Privacy & Policy";
    privacyVC.view.backgroundColor = [UIColor whiteColor];
    [self.navigationController pushViewController:privacyVC animated:YES];
}

- (void)showFeedbackPage {
    UIViewController *feedbackVC = [[UIViewController alloc] init];
    feedbackVC.title = @"Feedback";
    feedbackVC.view.backgroundColor = [UIColor whiteColor];
    [self.navigationController pushViewController:feedbackVC animated:YES];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
