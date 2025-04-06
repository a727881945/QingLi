#import "KJAllContactsViewController.h"
#import <Contacts/Contacts.h>
#import <ContactsUI/ContactsUI.h>

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
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, top, self.view.frame.size.width, self.view.frame.size.height - 56 - top) style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"contactCell"];
    [self.view addSubview:self.tableView];
    
    // Delete button
    self.deleteButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.deleteButton.frame = CGRectMake(0, self.view.frame.size.height - 60, self.view.frame.size.width, 60);
    [self.deleteButton setTitle:@"Delete selected contacts" forState:UIControlStateNormal];
    [self.deleteButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.deleteButton.backgroundColor = [UIColor systemRedColor];
    [self.deleteButton addTarget:self action:@selector(deleteSelectedContacts) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.deleteButton];
    
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

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.filteredContacts.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"contactCell" forIndexPath:indexPath];
    CNContact *contact = self.filteredContacts[indexPath.row];
    
    // 头像
    if (contact.thumbnailImageData) {
        cell.imageView.image = [UIImage imageWithData:contact.thumbnailImageData];
    } else {
        cell.imageView.image = [UIImage systemImageNamed:@"person.crop.circle"];
    }
    
    // 姓名和电话号码
    NSString *name = [NSString stringWithFormat:@"%@%@", contact.familyName, contact.givenName];
    NSString *phoneNumber = @"No phone number";
    if (contact.phoneNumbers.count > 0) {
        CNPhoneNumber *phone = contact.phoneNumbers.firstObject.value;
        phoneNumber = phone.stringValue;
    }
    
    // 使用多行显示
    cell.textLabel.numberOfLines = 0;
    cell.detailTextLabel.numberOfLines = 0;
    
    // 创建属性字符串来组合姓名和电话
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] init];
    
    // 添加姓名（粗体）
    NSAttributedString *nameAttr = [[NSAttributedString alloc] initWithString:name attributes:@{
        NSFontAttributeName: [UIFont boldSystemFontOfSize:17]
    }];
    [attributedText appendAttributedString:nameAttr];
    
    // 添加换行和电话号码
    if (phoneNumber.length > 0) {
        NSAttributedString *newline = [[NSAttributedString alloc] initWithString:@"\n"];
        NSAttributedString *phoneAttr = [[NSAttributedString alloc] initWithString:phoneNumber attributes:@{
            NSFontAttributeName: [UIFont systemFontOfSize:14],
            NSForegroundColorAttributeName: [UIColor grayColor]
        }];
        [attributedText appendAttributedString:newline];
        [attributedText appendAttributedString:phoneAttr];
    }
    
    cell.textLabel.attributedText = attributedText;
    
    // 自定义选择框
    UIButton *checkBox = [UIButton buttonWithType:UIButtonTypeCustom];
    checkBox.frame = CGRectMake(0, 0, 24, 24);
    checkBox.userInteractionEnabled = NO; // 让cell的点击事件优先处理
    
    if ([self.selectedContacts containsObject:contact.identifier]) {
        [checkBox setImage:[UIImage systemImageNamed:@"checkmark.square.fill"] forState:UIControlStateNormal];
        checkBox.tintColor = [UIColor systemBlueColor];
    } else {
        [checkBox setImage:[UIImage systemImageNamed:@"square"] forState:UIControlStateNormal];
        checkBox.tintColor = [UIColor lightGrayColor];
    }
    
    cell.accessoryView = checkBox;
    
    return cell;
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
