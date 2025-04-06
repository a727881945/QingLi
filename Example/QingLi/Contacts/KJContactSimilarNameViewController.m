//
//  KJContactSimilarNameViewController.m
//  QingLi_Example
//
//  Created by wangkejie on 2025/4/2.
//  Copyright © 2025 wangkejie. All rights reserved.
//

#import "KJContactSimilarNameViewController.h"
#import <Contacts/Contacts.h>
#import <ContactsUI/ContactsUI.h>
#import "KJContactHeaderCell.h"
#import "KJContactCell.h"
#import "KJSectionHeaderView.h"

@interface KJContactSimilarNameViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) NSMutableArray *similarNameGroups; // 存储重复联系人组
@property (nonatomic, strong) NSMutableDictionary *selectedContacts; // 存储重复联系人组
@property (nonatomic, strong) UIBarButtonItem *backButton;
@property (nonatomic, strong) UIBarButtonItem *selectAllButton;
@property (nonatomic, strong) UITableView *tableView;

@end

@implementation KJContactSimilarNameViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Similar Names";
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self setupNavigationBar];
    [self setupUI];
    
    // 初始化数据
    self.similarNameGroups = [NSMutableArray array];
    self.selectedContacts = [NSMutableDictionary dictionary];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self loadSimilarNameContacts];
    });
}

- (void)setupNavigationBar {
    self.backButton = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"chevron.left"] 
                                                       style:UIBarButtonItemStylePlain 
                                                      target:self 
                                                      action:@selector(backButtonTapped)];
    self.navigationItem.leftBarButtonItem = self.backButton;
    
    self.selectAllButton = [[UIBarButtonItem alloc] initWithTitle:@"Select All" 
                                                            style:UIBarButtonItemStylePlain 
                                                           target:self 
                                                           action:@selector(selectAllButtonTapped)];
    self.navigationItem.rightBarButtonItem = self.selectAllButton;
}

- (void)setupUI {
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.tableView.backgroundColor = [UIColor systemGroupedBackgroundColor];
    self.tableView.sectionHeaderHeight = 40;
    [self.view addSubview:self.tableView];
    
    // 注册cell
    [self.tableView registerClass:[KJContactHeaderCell class] forCellReuseIdentifier:@"HeaderCell"];
    [self.tableView registerClass:[KJContactCell class] forCellReuseIdentifier:@"ContactCell"];
}

- (void)loadSimilarNameContacts {
    CNContactStore *contactStore = [[CNContactStore alloc] init];
    [contactStore requestAccessForEntityType:CNEntityTypeContacts completionHandler:^(BOOL granted, NSError * _Nullable error) {
        if (granted) {
            NSArray *keys = @[CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey, CNContactImageDataKey, CNContactThumbnailImageDataKey];
            CNContactFetchRequest *request = [[CNContactFetchRequest alloc] initWithKeysToFetch:keys];
            
            NSMutableDictionary *nameMap = [NSMutableDictionary dictionary];
            
            NSError *fetchError = nil;
            [contactStore enumerateContactsWithFetchRequest:request error:&fetchError usingBlock:^(CNContact * _Nonnull contact, BOOL * _Nonnull stop) {
                NSString *fullName = [NSString stringWithFormat:@"%@ %@", contact.givenName, contact.familyName];
                if (fullName.length > 0) {
                    if (!nameMap[fullName]) {
                        nameMap[fullName] = [NSMutableArray array];
                    }
                    [nameMap[fullName] addObject:contact];
                }
            }];
            
            if (fetchError) {
                NSLog(@"获取联系人失败: %@", fetchError);
                return;
            }
            
            // 找出相似名字的联系人
            [nameMap enumerateKeysAndObjectsUsingBlock:^(NSString *name, NSMutableArray *contacts, BOOL *stop) {
                if (contacts.count > 1) {
                    [self.similarNameGroups addObject:contacts];
                    
                    // 为每个组初始化选中状态
                    NSString *key = [NSString stringWithFormat:@"%lu", (unsigned long)self.similarNameGroups.count - 1];
                    self.selectedContacts[key] = [NSMutableSet set];
                }
            }];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self.similarNameGroups.count == 0) {
                    [self showNoContactsAlert];
                } else {
                    [self.tableView reloadData];
                }
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showPermissionDeniedAlert];
            });
        }
    }];
}

- (void)showNoContactsAlert {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Notice" 
                                                                   message:@"No similar name contacts found" 
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showPermissionDeniedAlert {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Permission Denied" 
                                                                   message:@"Please allow access to contacts in Settings" 
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.similarNameGroups.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSArray *group = self.similarNameGroups[section];
    return group.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *group = self.similarNameGroups[indexPath.section];
    CNContact *contact = group[indexPath.row];
    
    if (indexPath.row == 0) {
        KJContactHeaderCell *cell = [tableView dequeueReusableCellWithIdentifier:@"HeaderCell"];
        
        // 设置头像
        if (contact.thumbnailImageData) {
            cell.avatarImageView.image = [UIImage imageWithData:contact.thumbnailImageData];
        } else {
            cell.avatarImageView.image = [UIImage systemImageNamed:@"person.circle.fill"];
            cell.avatarImageView.tintColor = [UIColor systemBlueColor];
        }
        
        // 设置名称
        NSString *name = [NSString stringWithFormat:@"%@ %@", contact.givenName, contact.familyName];
        if (name.length == 0) {
            name = @"Unknown Contact";
        }
        cell.nameLabel.text = name;
        
        // 设置电话
        if (contact.phoneNumbers.count > 0) {
            CNLabeledValue<CNPhoneNumber *> *phoneNumber = contact.phoneNumbers.firstObject;
            cell.phoneLabel.text = [phoneNumber.value stringValue];
        }
        
        // 设置合并按钮
        [cell.mergeButton addTarget:self action:@selector(mergeButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        cell.mergeButton.tag = indexPath.section;
        
        return cell;
    } else {
        KJContactCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ContactCell"];
        
        // 设置头像
        if (contact.thumbnailImageData) {
            cell.avatarImageView.image = [UIImage imageWithData:contact.thumbnailImageData];
        } else {
            cell.avatarImageView.image = [UIImage systemImageNamed:@"person.circle.fill"];
            cell.avatarImageView.tintColor = [UIColor systemGrayColor];
        }
        
        // 设置名称
        NSString *name = [NSString stringWithFormat:@"%@ %@", contact.givenName, contact.familyName];
        if (name.length == 0) {
            name = @"Unknown Contact";
        }
        cell.nameLabel.text = name;
        
        // 设置电话
        if (contact.phoneNumbers.count > 0) {
            CNLabeledValue<CNPhoneNumber *> *phoneNumber = contact.phoneNumbers.firstObject;
            cell.phoneLabel.text = [phoneNumber.value stringValue];
        }
        
        // 设置选中状态
        cell.isSelected = [self isContactSelected:contact inSection:indexPath.section];
        
        // 设置选择按钮点击事件
        [cell.checkButton addTarget:self action:@selector(checkButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        cell.checkButton.tag = indexPath.row * 1000 + indexPath.section; // 使用tag存储位置信息
        
        return cell;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    KJSectionHeaderView *headerView = [[KJSectionHeaderView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 40)];
    [headerView.selectAllButton addTarget:self action:@selector(selectAllInSectionTapped:) forControlEvents:UIControlEventTouchUpInside];
    headerView.selectAllButton.tag = section;
    return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.row == 0 ? 70 : 60;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 40;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row > 0) {
        [self toggleContactSelectionAtIndexPath:indexPath];
    }
}

#pragma mark - Helper Methods

- (BOOL)isContactSelected:(CNContact *)contact inSection:(NSInteger)section {
    NSString *key = [NSString stringWithFormat:@"%ld", (long)section];
    NSMutableSet *selectedInSection = self.selectedContacts[key];
    
    for (CNContact *selectedContact in selectedInSection) {
        if ([selectedContact.identifier isEqualToString:contact.identifier]) {
            return YES;
        }
    }
    
    return NO;
}

- (void)toggleContactSelectionAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *group = self.similarNameGroups[indexPath.section];
    CNContact *contact = group[indexPath.row];
    
    NSString *key = [NSString stringWithFormat:@"%ld", (long)indexPath.section];
    NSMutableSet *selectedInSection = self.selectedContacts[key];
    
    if (!selectedInSection) {
        selectedInSection = [NSMutableSet set];
        self.selectedContacts[key] = selectedInSection;
    }
    
    BOOL isSelected = NO;
    CNContact *contactToRemove = nil;
    
    for (CNContact *selectedContact in selectedInSection) {
        if ([selectedContact.identifier isEqualToString:contact.identifier]) {
            isSelected = YES;
            contactToRemove = selectedContact;
            break;
        }
    }
    
    if (isSelected) {
        [selectedInSection removeObject:contactToRemove];
    } else {
        [selectedInSection addObject:contact];
    }
    
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark - Actions

- (void)backButtonTapped {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)selectAllButtonTapped {
    BOOL allSelected = YES;
    
    // 检查是否所有联系人都已选中
    for (NSInteger section = 0; section < self.similarNameGroups.count; section++) {
        NSArray *group = self.similarNameGroups[section];
        NSString *key = [NSString stringWithFormat:@"%ld", (long)section];
        NSMutableSet *selectedInSection = self.selectedContacts[key];
        
        if (!selectedInSection || selectedInSection.count < group.count - 1) {
            allSelected = NO;
            break;
        }
    }
    
    // 根据当前状态全选或全不选
    for (NSInteger section = 0; section < self.similarNameGroups.count; section++) {
        NSArray *group = self.similarNameGroups[section];
        NSString *key = [NSString stringWithFormat:@"%ld", (long)section];
        NSMutableSet *selectedInSection = self.selectedContacts[key];
        
        if (!selectedInSection) {
            selectedInSection = [NSMutableSet set];
            self.selectedContacts[key] = selectedInSection;
        }
        
        [selectedInSection removeAllObjects];
        
        if (!allSelected) {
            // 全选（除了第一个联系人）
            for (NSInteger i = 1; i < group.count; i++) {
                [selectedInSection addObject:group[i]];
            }
        }
    }
    
    [self.tableView reloadData];
}

- (void)selectAllInSectionTapped:(UIButton *)button {
    NSInteger section = button.tag;
    NSArray *group = self.similarNameGroups[section];
    NSString *key = [NSString stringWithFormat:@"%ld", (long)section];
    NSMutableSet *selectedInSection = self.selectedContacts[key];
    
    if (!selectedInSection) {
        selectedInSection = [NSMutableSet set];
        self.selectedContacts[key] = selectedInSection;
    }
    
    BOOL allSelected = selectedInSection.count == group.count - 1;
    
    [selectedInSection removeAllObjects];
    
    if (!allSelected) {
        // 全选（除了第一个联系人）
        for (NSInteger i = 1; i < group.count; i++) {
            [selectedInSection addObject:group[i]];
        }
    }
    
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:section] withRowAnimation:UITableViewRowAnimationNone];
}

- (void)checkButtonTapped:(UIButton *)button {
    NSInteger section = button.tag % 1000;
    NSInteger row = button.tag / 1000;
    [self toggleContactSelectionAtIndexPath:[NSIndexPath indexPathForRow:row inSection:section]];
}

- (void)mergeButtonTapped:(UIButton *)button {
    NSInteger section = button.tag;
    NSString *key = [NSString stringWithFormat:@"%ld", (long)section];
    NSMutableSet *selectedInSection = self.selectedContacts[key];
    
    if (!selectedInSection || selectedInSection.count == 0) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Warning"
                                                                       message:@"Please select the contacts to be merged."
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Confirm" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    
    [self mergeSelectedContactsInSection:section];
}

- (void)mergeSelectedContactsInSection:(NSInteger)section {
    NSArray *group = self.similarNameGroups[section];
    CNContact *targetContact = group[0]; // 第一个联系人作为合并目标
    
    NSString *key = [NSString stringWithFormat:@"%ld", (long)section];
    NSMutableSet *selectedInSection = self.selectedContacts[key];
    
    if (selectedInSection.count == 0) {
        return;
    }
    
    CNContactStore *contactStore = [[CNContactStore alloc] init];
    
    // 创建可变联系人
    CNMutableContact *mutableTargetContact = [targetContact mutableCopy];
    
    // 收集所有要删除的联系人
    NSMutableArray *contactsToDelete = [NSMutableArray array];
    
    NSMutableArray<CNLabeledValue<CNPhoneNumber*>*>*phoneNumbers = [NSMutableArray array];

    for (CNContact *contact in selectedInSection) {
        // 合并电话号码
        for (CNLabeledValue<CNPhoneNumber *> *phoneNumber in contact.phoneNumbers) {
            if (![self contact:targetContact containsPhoneNumber:phoneNumber.value]) {
//                [mutableTargetContact.phoneNumbers addObject:phoneNumber];
                [phoneNumbers addObject:phoneNumber];
            }
        }
        
        // 合并其他信息（如邮箱、地址等）
        // ...
        
        [contactsToDelete addObject:contact];
    }
    mutableTargetContact.phoneNumbers = phoneNumbers.copy;
    
    // 保存更改
    CNSaveRequest *saveRequest = [[CNSaveRequest alloc] init];
    [saveRequest updateContact:mutableTargetContact];
    
    // 删除被合并的联系人
    for (CNContact *contact in contactsToDelete) {
        // 获取完整的联系人信息
        NSError *fetchError = nil;
        CNContact *fullContact = [contactStore unifiedContactWithIdentifier:contact.identifier keysToFetch:@[[CNContactViewController descriptorForRequiredKeys]] error:&fetchError];
        
        if (!fetchError && fullContact) {
            CNMutableContact *mutableContact = [fullContact mutableCopy];
            [saveRequest deleteContact:mutableContact];
        } else {
            NSLog(@"获取完整联系人信息失败: %@", fetchError);
        }
    }
    
    NSError *saveError;
    if ([contactStore executeSaveRequest:saveRequest error:&saveError]) {
        // 合并成功，更新UI
        [self.similarNameGroups removeObjectAtIndex:section];
        [self.selectedContacts removeObjectForKey:key];
        
        // 重新加载表格
        [self.tableView reloadData];
        
        // 显示成功提示
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Success"
                                                                       message:@"The contact person has been successfully merged."
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Confirm" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    } else {
        NSLog(@"合并联系人失败: %@", saveError);
        
        // 显示错误提示
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"ERROR"
                                                                       message:@"Failed to merge contacts."
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Confirm" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (BOOL)contact:(CNContact *)contact containsPhoneNumber:(CNPhoneNumber *)phoneNumber {
    NSString *targetNumber = [phoneNumber stringValue];
    
    for (CNLabeledValue<CNPhoneNumber *> *existingPhoneNumber in contact.phoneNumbers) {
        if ([[existingPhoneNumber.value stringValue] isEqualToString:targetNumber]) {
            return YES;
        }
    }
    
    return NO;
}

@end
