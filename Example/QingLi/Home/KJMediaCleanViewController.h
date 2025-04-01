//
//  KJMediaCleanViewController.h
//  QingLi
//
//  Created by QingLi on 2023/11/11.
//

#import "KJBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

// 媒体类型枚举
typedef NS_ENUM(NSInteger, KJMediaType) {
    KJMediaTypePhoto = 0,   // 普通照片
    KJMediaTypeVideo,       // 视频
    KJMediaTypeLivePhoto,   // 实况照片
    KJMediaTypeScreenshot   // 截图
};

@interface KJMediaCleanViewController : KJBaseViewController

// 指定初始化方法，需要传入媒体类型
- (instancetype)initWithMediaType:(KJMediaType)mediaType;

// 媒体类型属性
@property (nonatomic, assign, readonly) KJMediaType mediaType;

@end

NS_ASSUME_NONNULL_END 