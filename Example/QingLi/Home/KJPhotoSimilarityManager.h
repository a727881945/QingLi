#import <Foundation/Foundation.h>
#import <Photos/Photos.h>
#import <Vision/Vision.h>
#import "KJMediaCleanViewController.h" // 导入媒体类型枚举

NS_ASSUME_NONNULL_BEGIN

// 照片库错误类型
typedef NS_ENUM(NSInteger, KJPhotoLibraryError) {
    KJPhotoLibraryErrorAccessDenied,
    KJPhotoLibraryErrorInvalidImage,
    KJPhotoLibraryErrorImageRequestFailed,
    KJPhotoLibraryErrorFeatureExtractionFailed,
    KJPhotoLibraryErrorUnknown
};

// 前向声明
@class KJOptimizedDBSCAN;

@interface KJPhotoSimilarityManager : NSObject

+ (instancetype)sharedManager;

// 设置要查找的媒体类型
- (void)setMediaType:(KJMediaType)mediaType;

// 获取相似照片组，带进度回调，新增媒体类型参数
- (void)findSimilarPhotosWithMediaType:(KJMediaType)mediaType
                         progressBlock:(void(^)(float progress))progressBlock
                            completion:(void(^)(NSArray<NSArray<PHAsset *> *> *similarGroups, NSError * _Nullable error))completion;

// 按日期对照片分组
- (NSArray<NSDictionary<NSString *, id> *> *)groupPhotosByDate:(NSArray<PHAsset *> *)assets;

// 删除照片资产
- (void)deleteAssets:(NSArray<PHAsset *> *)assets completion:(void(^)(BOOL success, NSError * _Nullable error))completion;

// 添加个私有方法到公共接口
- (void)extractFeaturesFromAssets:(NSArray<PHAsset *> *)assets
                  progressCallback:(void(^)(float progress))progressCallback
                       completion:(void(^)(NSArray<VNFeaturePrintObservation *> *features, NSArray<PHAsset *> *processedAssets))completion;

@end

NS_ASSUME_NONNULL_END 