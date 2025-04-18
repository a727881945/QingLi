#import "KJAllContactsViewController.h"
#import <Contacts/Contacts.h>
#import <ContactsUI/ContactsUI.h>
#import "KJContactCell.h"

@interface KJAllContactsViewController () <UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) UIButton *deleteButton;
@property (nonatomic, strong) NSMutableArray<CNContact *> *contacts;
@property (nonatomic, strong) NSMutableArray<CNContact *> *filteredContacts;
@property (nonatomic, strong) NSMutableSet<NSString *> *selectedContacts;
@property (nonatomic, assign) BOOL isSearching;
@end

@implementation KJAllContactsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{    
        [self requestContactsAccess];
    });
}

- (void)setupUI {
    
    CGFloat top = NavigationContentTop;
    // Search box
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, top, self.view.frame.size.width, 56)];
    self.searchBar.delegate = self;
    self.searchBar.placeholder = @"Search name or phone";
    [self.view addSubview:self.searchBar];
    top += 56;
    // Table view
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView registerClass:[KJContactCell class] forCellReuseIdentifier:@"contactCell"];
    [self.view addSubview:self.tableView];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    // Delete button
    {
        QMUIButton *deleteButton = [QMUIButton buttonWithType:UIButtonTypeCustom];
        
        CAGradientLayer *gradient = [CAGradientLayer layer];
        gradient.colors = @[
            (id)[UIColor qmui_colorWithHexString:@"#3BE2F4"].CGColor,
            (id)[UIColor qmui_colorWithHexString:@"##28A8FF"].CGColor,
        ];
        gradient.frame = CGRectMake(0, 0, self.view.bounds.size.width - 94, 38);
        gradient.locations = @[@0, @1.0];
        gradient.startPoint = CGPointMake(0, 0.5);
        gradient.endPoint = CGPointMake(1, 0.5);
        [deleteButton.layer addSublayer:gradient];
        deleteButton.layer.cornerRadius = 19;
        deleteButton.layer.masksToBounds = YES;
        [self.view addSubview:deleteButton];
        [deleteButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(47);
            make.right.mas_equalTo(-47);
            make.height.mas_equalTo(38);
            make.bottom.mas_equalTo(0).mas_offset(-SafeAreaInsetsConstantForDeviceWithNotch.bottom);
        }];
        self.deleteButton = deleteButton;
        [self.deleteButton setTitle:@"Delete selected contacts" forState:UIControlStateNormal];
        [self.deleteButton setTitleColor:[UIColor qmui_colorWithHexString:@"#FFFFFF"] forState:UIControlStateNormal];
        [self.deleteButton addTarget:self action:@selector(deleteSelectedContacts) forControlEvents:UIControlEventTouchUpInside];

    }
    
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.searchBar.mas_bottom);
        make.bottom.mas_equalTo(self.deleteButton.mas_top).mas_offset(-23);
        make.left.right.mas_equalTo(0);
    }];
    
    // Initialize data
    self.contacts = [NSMutableArray array];
    self.filteredContacts = [NSMutableArray array];
    self.selectedContacts = [NSMutableSet set];
}

- (void)requestContactsAccess {
    CNAuthorizationStatus status = [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts];
    if (status == CNAuthorizationStatusNotDetermined) {
        CNContactStore *store = [[CNContactStore alloc] init];
        [store requestAccessForEntityType:CNEntityTypeContacts completionHandler:^(BOOL granted, NSError * _Nullable error) {
            if (granted) {
                [self fetchAllContacts];
            }
        }];
    } else if (status == CNAuthorizationStatusAuthorized) {
        [self fetchAllContacts];
    }
}

- (void)fetchAllContacts {
    CNContactStore *store = [[CNContactStore alloc] init];
    NSArray *keys = @[CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey, CNContactThumbnailImageDataKey];
    NSPredicate *predicate = nil;
    NSError *error;
    NSArray<CNContact*> *contacts = [store unifiedContactsMatchingPredicate:predicate keysToFetch:keys error:&error];
    
    [self.contacts removeAllObjects];
    [self.contacts addObjectsFromArray:contacts];
    [self.filteredContacts removeAllObjects];
    [self.filteredContacts addObjectsFromArray:self.contacts];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

#pragma mark - UITableViewDataSource

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 66;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.filteredContacts.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    KJContactCell *cell = [tableView dequeueReusableCellWithIdentifier:@"contactCell" forIndexPath:indexPath];
    CNContact *contact = self.filteredContacts[indexPath.row];
        
    // 设置头像
    if (contact.thumbnailImageData) {
        cell.avatarImageView.image = [UIImage imageWithData:contact.thumbnailImageData];
    } else {
        cell.avatarImageView.image = [UIImage systemImageNamed:@"person.circle.fill"];
        cell.avatarImageView.tintColor = [UIColor systemBlueColor];
    }
    
    // 设置名称
    NSString *name = [NSString stringWithFormat:@"%@%@", contact.givenName ? [NSString stringWithFormat:@"%@ ", contact.givenName] : @"", contact.familyName];
    if (name.length == 0) {
        name = @"Unknown contact";
    }
    cell.nameLabel.text = name;
    
    // 设置电话
    if (contact.phoneNumbers.count > 0) {
        CNLabeledValue<CNPhoneNumber *> *phoneNumber = contact.phoneNumbers.firstObject;
        cell.phoneLabel.text = [phoneNumber.value stringValue];
    } else {
        cell.phoneLabel.text = @"No phone number";
    }
    
    if ([self.selectedContacts containsObject:contact.identifier]) {
        [cell setIsSelected:YES];
    } else {
        [cell setIsSelected:NO];
    }
    
    // 设置选择按钮点击事件
    [cell.checkButton addTarget:self action:@selector(checkButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    cell.checkButton.tag = indexPath.row + 200; // 使用tag存储位置信息
    
    return cell;
}

- (void)checkButtonTapped:(UIButton *)checkButton {
    NSInteger row = checkButton.tag - 200;
    [self tableView:self.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0]];
}


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    CNContact *contact = self.filteredContacts[indexPath.row];
    if ([self.selectedContacts containsObject:contact.identifier]) {
        [self.selectedContacts removeObject:contact.identifier];
    } else {
        [self.selectedContacts addObject:contact.identifier];
    }
    
    [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark - UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if (searchText.length == 0) {
        self.isSearching = NO;
        [self.filteredContacts removeAllObjects];
        [self.filteredContacts addObjectsFromArray:self.contacts];
    } else {
        self.isSearching = YES;
        [self.filteredContacts removeAllObjects];
        
        NSString *lowercaseSearchText = [searchText lowercaseString];
        for (CNContact *contact in self.contacts) {
            // 按姓名搜索
            NSString *name = [[NSString stringWithFormat:@"%@%@", contact.familyName, contact.givenName] lowercaseString];
            if ([name containsString:lowercaseSearchText]) {
                [self.filteredContacts addObject:contact];
                continue;
            }
            
            // 按电话号码搜索
            for (CNLabeledValue *phone in contact.phoneNumbers) {
                CNPhoneNumber *phoneNumber = phone.value;
                NSString *digits = [[phoneNumber.stringValue componentsSeparatedByCharactersInSet:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]] componentsJoinedByString:@""];
                if ([digits containsString:searchText]) {
                    [self.filteredContacts addObject:contact];
                    break;
                }
            }
        }
    }
    
    [self.tableView reloadData];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
}

#pragma mark - Actions

- (void)deleteSelectedContacts {
    if (self.selectedContacts.count == 0) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Warning" message:@"Please select the contact(s) you want to delete first." preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Confirm" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    
    // 添加确认弹窗
    UIAlertController *confirmAlert = [UIAlertController alertControllerWithTitle:@"Confirm Delete"
                                                                         message:[NSString stringWithFormat:@"Are you sure you want to delete this %lu contact?", (unsigned long)self.selectedContacts.count]
                                                                  preferredStyle:UIAlertControllerStyleAlert];
    
    // 取消按钮
    [confirmAlert addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                                     style:UIAlertActionStyleCancel
                                                   handler:nil]];
    
    // 确认删除按钮
    [confirmAlert addAction:[UIAlertAction actionWithTitle:@"Confirm"
                                                     style:UIAlertActionStyleDestructive
                                                   handler:^(UIAlertAction * _Nonnull action) {
        [self performDeleteContacts];
    }]];
    
    [self presentViewController:confirmAlert animated:YES completion:nil];
}

// 新增方法：执行实际的删除操作
- (void)performDeleteContacts {
    CNContactStore *store = [[CNContactStore alloc] init];
    CNSaveRequest *saveRequest = [[CNSaveRequest alloc] init];
    
    for (CNContact *contact in self.contacts) {
        if ([self.selectedContacts containsObject:contact.identifier]) {
            CNMutableContact *mutableContact = [contact mutableCopy];
            [saveRequest deleteContact:mutableContact];
        }
    }
    
    NSError *error;
    if ([store executeSaveRequest:saveRequest error:&error]) {
        [self.selectedContacts removeAllObjects];
        [self fetchAllContacts];
    } else {
        NSLog(@"删除失败: %@", error);
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error" message:@"Failed to delete the contact." preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Confirm" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

@end
