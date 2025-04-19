//
//  KJContactDuplViewController.m
//  QingLi_Example
//
//  Created by wangkejie on 2025/4/2.
//  Copyright © 2025 wangkejie. All rights reserved.
//

#import "KJContactDuplViewController.h"
#import <Contacts/Contacts.h>
#import <ContactsUI/ContactsUI.h>
#import "KJContactHeaderCell.h"
#import "KJContactCell.h"
#import "KJSectionHeaderView.h"

@interface KJContactDuplViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *duplicateGroups; // 存储重复联系人组
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableSet *> *selectedContacts; // 存储选中的联系人
@property (nonatomic, strong) UIBarButtonItem *backButton;
@property (nonatomic, strong) UIBarButtonItem *selectAllButton;

@end

@implementation KJContactDuplViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Duplicate Numbers";
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self setupNavigationBar];
    [self setupUI];
    
    // 初始化数据
    self.duplicateGroups = [NSMutableArray array];
    self.selectedContacts = [NSMutableDictionary dictionary];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self loadDuplicateContacts];
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
    self.tableView.backgroundColor = [UIColor systemGroupedBackgroundColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;

    self.tableView.sectionHeaderHeight = 40;
    [self.view addSubview:self.tableView];
    
    // 注册cell
    [self.tableView registerClass:[KJContactHeaderCell class] forCellReuseIdentifier:@"HeaderCell"];
    [self.tableView registerClass:[KJContactCell class] forCellReuseIdentifier:@"ContactCell"];
}

- (void)loadDuplicateContacts {
    CNContactStore *contactStore = [[CNContactStore alloc] init];
    [contactStore requestAccessForEntityType:CNEntityTypeContacts completionHandler:^(BOOL granted, NSError * _Nullable error) {
        if (granted) {
            NSArray *keys = @[CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey, CNContactImageDataKey, CNContactThumbnailImageDataKey, CNContactEmailAddressesKey, CNContactPostalAddressesKey, CNContactUrlAddressesKey, CNContactRelationsKey, CNContactSocialProfilesKey, CNContactInstantMessageAddressesKey];
            CNContactFetchRequest *request = [[CNContactFetchRequest alloc] initWithKeysToFetch:keys];
            
            NSMutableDictionary *phoneNumberMap = [NSMutableDictionary dictionary];
            
            NSError *fetchError = nil;
            [contactStore enumerateContactsWithFetchRequest:request error:&fetchError usingBlock:^(CNContact * _Nonnull contact, BOOL * _Nonnull stop) {
                for (CNLabeledValue<CNPhoneNumber *> *phoneNumber in contact.phoneNumbers) {
                    NSString *number = [phoneNumber.value stringValue];
                    // 标准化电话号码，去除非数字字符
                    NSString *normalizedNumber = [[number componentsSeparatedByCharactersInSet:
                                                  [[NSCharacterSet decimalDigitCharacterSet] invertedSet]] 
                                                  componentsJoinedByString:@""];
                    
                    if (!phoneNumberMap[normalizedNumber]) {
                        phoneNumberMap[normalizedNumber] = [NSMutableArray array];
                    }
                    [phoneNumberMap[normalizedNumber] addObject:contact];
                }
            }];
            
            if (fetchError) {
                NSLog(@"获取联系人失败: %@", fetchError);
                return;
            }
            
            // 找出重复的联系人
            [phoneNumberMap enumerateKeysAndObjectsUsingBlock:^(NSString *number, NSMutableArray *contacts, BOOL *stop) {
                if (contacts.count > 1) {
                    [self.duplicateGroups addObject:contacts];
                    
                    // 为每个组初始化选中状态
                    NSString *key = [NSString stringWithFormat:@"%lu", (unsigned long)self.duplicateGroups.count - 1];
                    self.selectedContacts[key] = [NSMutableSet set];
                }
            }];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self.duplicateGroups.count == 0) {
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
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"warning"
                                                                   message:@"No duplicate contacts found."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Confirm" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showPermissionDeniedAlert {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"permission denied"
                                                                   message:@"Please enable access to the contact list in the settings."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"confirm" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.duplicateGroups.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSArray *group = self.duplicateGroups[section];
    return group.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *group = self.duplicateGroups[indexPath.section];
    CNContact *contact = group[indexPath.row];
    
    if (indexPath.row == 0) {
        KJContactHeaderCell *cell = [tableView dequeueReusableCellWithIdentifier:@"HeaderCell"];
        
        // 设置头像
        if (contact.thumbnailImageData) {
            cell.avatarImageView.image = [UIImage imageWithData:contact.thumbnailImageData];
        } else {
            cell.avatarImageView.image = [UIImage systemImageNamed:@"person.circle.fill"];
            cell.avatarImageView.tintColor = [UIColor systemGrayColor];
        }
        
        // 设置名称
        NSString *givenName = contact.givenName;
        NSString *name = [NSString stringWithFormat:@"%@%@%@", givenName ?: @"", givenName.length > 0 ? @" " : @"", contact.familyName];
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
        cell.mergeButton.tag = indexPath.section + 200;
        
        [cell.selectAllButton addTarget:self action:@selector(selectAllInSectionTapped:) forControlEvents:UIControlEventTouchUpInside];
        cell.selectAllButton.tag = indexPath.section + 200;
        
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
            name = @"Unknown contact";
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.row == 0 ? 136 : 66;
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
    NSArray *group = self.duplicateGroups[indexPath.section];
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
    for (NSInteger section = 0; section < self.duplicateGroups.count; section++) {
        NSArray *group = self.duplicateGroups[section];
        NSString *key = [NSString stringWithFormat:@"%ld", (long)section];
        NSMutableSet *selectedInSection = self.selectedContacts[key];
        
        if (!selectedInSection || selectedInSection.count < group.count - 1) {
            allSelected = NO;
            break;
        }
    }
    
    // 根据当前状态全选或全不选
    for (NSInteger section = 0; section < self.duplicateGroups.count; section++) {
        NSArray *group = self.duplicateGroups[section];
        NSString *key = [NSString stringWithFormat:@"%ld", (long)section];
        NSMutableSet *selectedInSection = self.selectedContacts[key];
        
        if (!selectedInSection) {
            selectedInSection = [NSMutableSet set];
            self.selectedContacts[key] = selectedInSection;
        }
        
        [selectedInSection removeAllObjects];
        
        if (!allSelected) {
            // Select all (except the first contact)
            for (NSInteger i = 1; i < group.count; i++) {
                [selectedInSection addObject:group[i]];
            }
        }
    }
    
    [self.tableView reloadData];
}

- (void)selectAllInSectionTapped:(UIButton *)button {
    NSInteger section = button.tag - 200;
    NSArray *group = self.duplicateGroups[section];
    NSString *key = [NSString stringWithFormat:@"%ld", (long)section];
    NSMutableSet *selectedInSection = self.selectedContacts[key];
    
    if (!selectedInSection) {
        selectedInSection = [NSMutableSet set];
        self.selectedContacts[key] = selectedInSection;
    }
    
    BOOL allSelected = selectedInSection.count == group.count - 1;
    
    [selectedInSection removeAllObjects];
    
    if (!allSelected) {
        // Select all (except the first contact)
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
    NSInteger section = button.tag - 200;
    NSString *key = [NSString stringWithFormat:@"%ld", (long)section];
    NSMutableSet *selectedInSection = self.selectedContacts[key];
    
    if (!selectedInSection || selectedInSection.count == 0) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Notice" 
                                                                       message:@"Please select contacts to merge" 
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    
    [self mergeSelectedContactsInSection:section];
}

- (void)mergeSelectedContactsInSection:(NSInteger)section {
    NSArray *group = self.duplicateGroups[section];
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
        
    // 合并所有信息
    NSMutableArray<CNLabeledValue<CNPhoneNumber*>*>*phoneNumbers = [mutableTargetContact.phoneNumbers mutableCopy] ?: [NSMutableArray array];
    NSMutableArray<CNLabeledValue<NSString*>*> *emailAddresses = [mutableTargetContact.emailAddresses mutableCopy] ?: [NSMutableArray array];
    NSMutableArray<CNLabeledValue<CNPostalAddress*>*> *postalAddresses = [mutableTargetContact.postalAddresses mutableCopy] ?: [NSMutableArray array];
    NSMutableArray<CNLabeledValue<NSString*>*> *urlAddresses = [mutableTargetContact.urlAddresses mutableCopy] ?: [NSMutableArray array];
    NSMutableArray<CNLabeledValue<CNContactRelation*>*> *contactRelations = [mutableTargetContact.contactRelations mutableCopy] ?: [NSMutableArray array];
    NSMutableArray<CNLabeledValue<CNSocialProfile*>*> *socialProfiles = [mutableTargetContact.socialProfiles mutableCopy] ?: [NSMutableArray array];
    NSMutableArray<CNLabeledValue<CNInstantMessageAddress*>*> *instantMessageAddresses = [mutableTargetContact.instantMessageAddresses mutableCopy] ?: [NSMutableArray array];
    
    for (CNContact *contact in selectedInSection) {
        // 合并电话号码
        for (CNLabeledValue<CNPhoneNumber *> *phoneNumber in contact.phoneNumbers) {
            if (![self contact:targetContact containsPhoneNumber:phoneNumber.value]) {
                [phoneNumbers addObject:phoneNumber];
            }
        }
        
        // 合并邮箱
        for (CNLabeledValue<NSString *> *email in contact.emailAddresses) {
            if (![self contact:mutableTargetContact containsEmail:email.value]) {
                [emailAddresses addObject:email];
            }
        }
        
        // 合并地址
        for (CNLabeledValue<CNPostalAddress *> *address in contact.postalAddresses) {
            if (![self contact:mutableTargetContact containsPostalAddress:address.value]) {
                [postalAddresses addObject:address];
            }
        }
        
        // 合并其他信息...
        [urlAddresses addObjectsFromArray:contact.urlAddresses];
        [contactRelations addObjectsFromArray:contact.contactRelations];
        [socialProfiles addObjectsFromArray:contact.socialProfiles];
        [instantMessageAddresses addObjectsFromArray:contact.instantMessageAddresses];
        [contactsToDelete addObject:contact];
    }
    
    // 设置合并后的信息
    mutableTargetContact.phoneNumbers = phoneNumbers;
    mutableTargetContact.emailAddresses = emailAddresses;
    mutableTargetContact.postalAddresses = postalAddresses;
    mutableTargetContact.urlAddresses = urlAddresses;
    mutableTargetContact.contactRelations = contactRelations;
    mutableTargetContact.socialProfiles = socialProfiles;
    mutableTargetContact.instantMessageAddresses = instantMessageAddresses;
    
    // 保存更改
    CNSaveRequest *saveRequest = [[CNSaveRequest alloc] init];
    [saveRequest updateContact:mutableTargetContact];
    
    // 修复这里的错误 - 需要先获取完整的联系人信息才能删除
    if (contactsToDelete && contactsToDelete.count > 0) {
        for (CNContact *contact in contactsToDelete) {
            if (!contact.identifier) continue;
            
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
    }
    
    NSError *saveError;
    if ([contactStore executeSaveRequest:saveRequest error:&saveError]) {
        // 合并成功，更新UI
        [self.duplicateGroups removeObjectAtIndex:section];
        [self.selectedContacts removeObjectForKey:key];
        
        // 重新加载表格
        [self.tableView reloadData];
        
        // 显示成功提示
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Success" 
                                                                       message:@"Contacts merged successfully" 
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    } else {
        NSLog(@"合并联系人失败: %@", saveError);
        
        // 显示错误提示
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error" 
                                                                       message:@"Failed to merge contacts" 
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

// 在合并电话号码时需要更严格的比较
- (BOOL)contact:(CNContact *)contact containsPhoneNumber:(CNPhoneNumber *)phoneNumber {
    NSString *targetNumber = [[phoneNumber.stringValue componentsSeparatedByCharactersInSet:
                             [[NSCharacterSet decimalDigitCharacterSet] invertedSet]] 
                             componentsJoinedByString:@""];
    
    for (CNLabeledValue<CNPhoneNumber *> *existingPhoneNumber in contact.phoneNumbers) {
        NSString *existingNumber = [[existingPhoneNumber.value.stringValue componentsSeparatedByCharactersInSet:
                                   [[NSCharacterSet decimalDigitCharacterSet] invertedSet]] 
                                   componentsJoinedByString:@""];
        if ([existingNumber isEqualToString:targetNumber]) {
            return YES;
        }
    }
    return NO;
}

// 新增辅助方法 - 检查邮箱是否已存在
- (BOOL)contact:(CNContact *)contact containsEmail:(NSString *)email {
    for (CNLabeledValue<NSString *> *existingEmail in contact.emailAddresses) {
        if ([existingEmail.value isEqualToString:email]) {
            return YES;
        }
    }
    return NO;
}

// 新增辅助方法 - 检查地址是否已存在
- (BOOL)contact:(CNContact *)contact containsPostalAddress:(CNPostalAddress *)address {
    NSString *targetAddress = [CNPostalAddressFormatter stringFromPostalAddress:address style:CNPostalAddressFormatterStyleMailingAddress];
    
    for (CNLabeledValue<CNPostalAddress *> *existingAddress in contact.postalAddresses) {
        NSString *existingAddressStr = [CNPostalAddressFormatter stringFromPostalAddress:existingAddress.value style:CNPostalAddressFormatterStyleMailingAddress];
        if ([existingAddressStr isEqualToString:targetAddress]) {
            return YES;
        }
    }
    return NO;
}

@end
