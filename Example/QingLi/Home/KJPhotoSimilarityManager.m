#import "KJPhotoSimilarityManager.h"
#import "KJOptimizedDBSCAN.h"
#import "KJMediaCleanViewController.h"
#import <Vision/Vision.h>
#import <Vision/VNObservation.h>
#import <QuartzCore/QuartzCore.h>

// 特征向量缓存管理
@interface KJFeaturePrintCache : NSObject

+ (instancetype)sharedCache;
- (VNFeaturePrintObservation *)featureVectorForAsset:(PHAsset *)asset;
- (void)cacheFeatureVector:(VNFeaturePrintObservation *)featureVector forAsset:(PHAsset *)asset;
- (void)removeFeatureVectorForAsset:(PHAsset *)asset;
- (void)clearCache;
- (void)cleanupCacheForLibrary:(PHFetchResult *)currentLibraryAssets;
- (void)preheatCacheWithAssets:(NSArray<PHAsset *> *)assets;

@end

@implementation KJFeaturePrintCache {
    NSCache *_memoryCache;
    NSString *_diskCachePath;
    dispatch_queue_t _ioQueue;
}

+ (instancetype)sharedCache {
    static KJFeaturePrintCache *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _memoryCache = [[NSCache alloc] init];
        _memoryCache.name = @"com.qingli.featureprintcache";
        _memoryCache.totalCostLimit = 100 * 1024 * 1024; // 100MB缓存限制
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        _diskCachePath = [[paths firstObject] stringByAppendingPathComponent:@"FeatureVectorCache"];
        
        _ioQueue = dispatch_queue_create("com.qingli.featureprintcache.io", DISPATCH_QUEUE_SERIAL);
        
        // 创建磁盘缓存目录
        if (![[NSFileManager defaultManager] fileExistsAtPath:_diskCachePath]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:_diskCachePath
                                      withIntermediateDirectories:YES
                                                       attributes:nil
                                                            error:nil];
        }
    }
    return self;
}

- (NSString *)cachePathForKey:(NSString *)key {
    return [_diskCachePath stringByAppendingPathComponent:key];
}

- (VNFeaturePrintObservation *)featureVectorForAsset:(PHAsset *)asset {
    NSString *key = asset.localIdentifier;
    
    // 先查内存缓存
    VNFeaturePrintObservation *cachedVector = [_memoryCache objectForKey:key];
    if (cachedVector) {
        return cachedVector;
    }
    
    // 再查磁盘缓存
    NSString *cachePath = [self cachePathForKey:key];
    if ([[NSFileManager defaultManager] fileExistsAtPath:cachePath]) {
        NSData *vectorData = [NSData dataWithContentsOfFile:cachePath];
        if (vectorData) {
            NSError *error = nil;
            VNFeaturePrintObservation *featureVector = [NSKeyedUnarchiver unarchivedObjectOfClass:[VNFeaturePrintObservation class]
                                                                                         fromData:vectorData
                                                                                            error:&error];
            if (featureVector && !error) {
                [_memoryCache setObject:featureVector forKey:key];
                return featureVector;
            }
        }
    }
    
    return nil;
}

- (void)cacheFeatureVector:(VNFeaturePrintObservation *)featureVector forAsset:(PHAsset *)asset {
    if (!featureVector || !asset) return;
    
    NSString *key = asset.localIdentifier;
    
    // 保存到内存缓存
    [_memoryCache setObject:featureVector forKey:key];
    
    // 保存到磁盘缓存
    dispatch_async(_ioQueue, ^{
        NSString *cachePath = [self cachePathForKey:key];
        NSError *error = nil;
        NSData *vectorData = [NSKeyedArchiver archivedDataWithRootObject:featureVector
                                                   requiringSecureCoding:YES
                                                                   error:&error];
        if (vectorData && !error) {
            [vectorData writeToFile:cachePath atomically:YES];
        }
    });
}

- (void)removeFeatureVectorForAsset:(PHAsset *)asset {
    NSString *key = asset.localIdentifier;
    
    // 从内存缓存中移除
    [_memoryCache removeObjectForKey:key];
    
    // 从磁盘缓存中移除
    dispatch_async(_ioQueue, ^{
        NSString *cachePath = [self cachePathForKey:key];
        [[NSFileManager defaultManager] removeItemAtPath:cachePath error:nil];
    });
}

- (void)clearCache {
    [_memoryCache removeAllObjects];
    
    dispatch_async(_ioQueue, ^{
        [[NSFileManager defaultManager] removeItemAtPath:self->_diskCachePath error:nil];
        [[NSFileManager defaultManager] createDirectoryAtPath:self->_diskCachePath
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:nil];
    });
}

// 添加清理不存在资产的缓存的方法
- (void)cleanupCacheForLibrary:(PHFetchResult *)currentLibraryAssets {
    // 创建当前库中资产ID的集合
    NSMutableSet<NSString *> *currentAssetIds = [NSMutableSet setWithCapacity:currentLibraryAssets.count];
    [currentLibraryAssets enumerateObjectsUsingBlock:^(PHAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [currentAssetIds addObject:obj.localIdentifier];
    }];
    
    // 由于NSCache不提供枚举方法，我们可以只清理磁盘缓存
    // 并且在下次访问时按需更新内存缓存
    
    // 清理磁盘缓存中不存在的资产
    dispatch_async(_ioQueue, ^{
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSError *error = nil;
        NSArray *cacheFiles = [fileManager contentsOfDirectoryAtPath:self->_diskCachePath error:&error];
        
        if (error) return;
        
        for (NSString *filename in cacheFiles) {
            // 如果文件对应的资产不在库中，删除该文件
            if (![currentAssetIds containsObject:filename]) {
                NSString *filePath = [self->_diskCachePath stringByAppendingPathComponent:filename];
                [fileManager removeItemAtPath:filePath error:nil];
                
                // 同时也从内存缓存中移除（如果存在）
                [self->_memoryCache removeObjectForKey:filename];
            }
        }
    });
}

// 预热缓存
- (void)preheatCacheWithAssets:(NSArray<PHAsset *> *)assets {
    if (assets.count == 0) return;
    
    NSLog(@"预热缓存...");
    
    // 计算要预热的资产数量 - 最多预热100张
    NSInteger preheatCount = MIN(100, assets.count);
    NSMutableArray<PHAsset *> *assetsToPreload = [NSMutableArray arrayWithCapacity:preheatCount];
    
    // 选择最近的照片进行预热
    NSArray<PHAsset *> *sortedAssets = [assets sortedArrayUsingComparator:^NSComparisonResult(PHAsset * _Nonnull obj1, PHAsset * _Nonnull obj2) {
        return [obj2.creationDate compare:obj1.creationDate]; // 按创建日期降序
    }];
    
    for (NSInteger i = 0; i < preheatCount; i++) {
        [assetsToPreload addObject:sortedAssets[i]];
    }
    
    dispatch_async(_ioQueue, ^{
        for (PHAsset *asset in assetsToPreload) {
            NSString *key = asset.localIdentifier;
            NSString *cachePath = [self cachePathForKey:key];
            
            // 检查磁盘上是否存在
            if ([[NSFileManager defaultManager] fileExistsAtPath:cachePath]) {
                NSData *vectorData = [NSData dataWithContentsOfFile:cachePath];
                if (vectorData) {
                    NSError *error = nil;
                    VNFeaturePrintObservation *featureVector = [NSKeyedUnarchiver unarchivedObjectOfClass:[VNFeaturePrintObservation class]
                                                                                               fromData:vectorData
                                                                                                  error:&error];
                    if (featureVector && !error) {
                        [self->_memoryCache setObject:featureVector forKey:key];
                    }
                }
            }
        }
        NSLog(@"缓存预热完成，已加载 %ld 项", (long)preheatCount);
    });
}

@end

// 图像缓存管理
@interface KJImageCache : NSObject

+ (instancetype)sharedCache;
- (UIImage *)imageForKey:(NSString *)key;
- (void)cacheImage:(UIImage *)image forKey:(NSString *)key;
- (void)removeImageForKey:(NSString *)key;
- (void)clearCache;

@end

@implementation KJImageCache {
    NSCache *_memoryCache;
    NSString *_diskCachePath;
    dispatch_queue_t _ioQueue;
}

+ (instancetype)sharedCache {
    static KJImageCache *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _memoryCache = [[NSCache alloc] init];
        _memoryCache.name = @"com.qingli.imagecache";
        _memoryCache.totalCostLimit = 50 * 1024 * 1024; // 50MB缓存限制
        
        // 创建磁盘缓存目录
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        _diskCachePath = [[paths firstObject] stringByAppendingPathComponent:@"ImageCache"];
        
        _ioQueue = dispatch_queue_create("com.qingli.imagecache.io", DISPATCH_QUEUE_SERIAL);
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:_diskCachePath]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:_diskCachePath
                                      withIntermediateDirectories:YES
                                                       attributes:nil
                                                            error:nil];
        }
    }
    return self;
}

- (NSString *)cachePathForKey:(NSString *)key {
    return [_diskCachePath stringByAppendingPathComponent:key];
}

- (UIImage *)imageForKey:(NSString *)key {
    // 先查内存缓存
    UIImage *cachedImage = [_memoryCache objectForKey:key];
    if (cachedImage) {
        return cachedImage;
    }
    
    // 再查磁盘缓存
    NSString *cachePath = [self cachePathForKey:key];
    if ([[NSFileManager defaultManager] fileExistsAtPath:cachePath]) {
        @try {
            NSData *imageData = [NSData dataWithContentsOfFile:cachePath];
            if (imageData) {
                UIImage *image = [UIImage imageWithData:imageData];
                if (image) {
                    [_memoryCache setObject:image forKey:key];
                    return image;
                }
            }
        } @catch (NSException *exception) {
            NSLog(@"从磁盘加载图像时出错: %@", exception);
        }
    }
    
    return nil;
}

- (void)cacheImage:(UIImage *)image forKey:(NSString *)key {
    if (!image || !key) return;
    
    // 保存到内存缓存
    [_memoryCache setObject:image forKey:key];
    
    // 保存到磁盘缓存
    dispatch_async(_ioQueue, ^{
        NSString *cachePath = [self cachePathForKey:key];
        NSData *imageData = UIImagePNGRepresentation(image);
        if (imageData) {
            [imageData writeToFile:cachePath atomically:YES];
        }
    });
}

- (void)removeImageForKey:(NSString *)key {
    [_memoryCache removeObjectForKey:key];
    
    dispatch_async(_ioQueue, ^{
        NSString *cachePath = [self cachePathForKey:key];
        [[NSFileManager defaultManager] removeItemAtPath:cachePath error:nil];
    });
}

- (void)clearCache {
    [_memoryCache removeAllObjects];
    
    dispatch_async(_ioQueue, ^{
        [[NSFileManager defaultManager] removeItemAtPath:self->_diskCachePath error:nil];
        [[NSFileManager defaultManager] createDirectoryAtPath:self->_diskCachePath
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:nil];
    });
}

@end

// 照片相似性管理类实现
@interface KJPhotoSimilarityManager ()

@property (nonatomic, strong) dispatch_queue_t processingQueue;
@property (nonatomic, strong) dispatch_semaphore_t concurrencySemaphore;
@property (nonatomic, assign) float similarityThreshold;
@property (nonatomic, assign) CGSize targetImageSize;
@property (nonatomic, assign) KJMediaType mediaType; // 添加媒体类型属性

@end

@implementation KJPhotoSimilarityManager

+ (instancetype)sharedManager {
    static KJPhotoSimilarityManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _processingQueue = dispatch_queue_create("com.qingli.photosimilarity", DISPATCH_QUEUE_CONCURRENT);
        _concurrencySemaphore = dispatch_semaphore_create(4); // 限制最大并发数为4
        _similarityThreshold = 0.5f; // 相似度阈值，值越小要求越严格
        _targetImageSize = CGSizeMake(150, 150); // 缩略图尺寸
        _mediaType = KJMediaTypeVideo; // 默认为视频类型
        
        // 延迟应用启动时初始化和维护缓存，等UI显示后再执行
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self initializeAndMaintainCache];
        });
    }
    return self;
}

// 设置媒体类型
- (void)setMediaType:(KJMediaType)mediaType {
    _mediaType = mediaType;
}

// 在应用启动时初始化和维护缓存
- (void)initializeAndMaintainCache {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        // 检查照片库权限
        PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
        if (status == PHAuthorizationStatusAuthorized || status == PHAuthorizationStatusLimited) {
            // 获取当前照片库中的所有照片
            PHFetchOptions *options = [[PHFetchOptions alloc] init];
            options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
            PHFetchResult *allPhotos = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:options];
            
            // 清理缓存中不存在的照片
            [[KJFeaturePrintCache sharedCache] cleanupCacheForLibrary:allPhotos];
            
            // 预热缓存
            NSMutableArray<PHAsset *> *recentPhotos = [NSMutableArray array];
            [allPhotos enumerateObjectsUsingBlock:^(PHAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [recentPhotos addObject:obj];
                if (idx >= 200) *stop = YES; // 最多取200张最近的照片
            }];
            
            // 预热缓存
            [[KJFeaturePrintCache sharedCache] preheatCacheWithAssets:recentPhotos];
        }
    });
}

#pragma mark - 公共方法

- (void)findSimilarPhotosWithMediaType:(KJMediaType)mediaType
                         progressBlock:(void(^)(float progress))progressBlock
                            completion:(void(^)(NSArray<NSArray<PHAsset *> *> *similarGroups, NSError * _Nullable error))completion {
    // 设置当前媒体类型
    self.mediaType = mediaType;
    
    // 切换到后台队列执行
    dispatch_async(self.processingQueue, ^{
        // 请求照片库访问权限
        [self requestPhotoLibraryAccessWithCompletion:^(BOOL granted, NSError * _Nullable error) {
            if (!granted) {
                if (completion) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completion(nil, error);
                    });
                }
                return;
            }
            
            // 获取照片
            [self fetchAssetsWithCompletion:^(NSArray<PHAsset *> * _Nullable assets, NSError * _Nullable error) {
                if (error) {
                    if (completion) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            completion(nil, error);
                        });
                    }
                    return;
                }
                
                if (assets.count == 0) {
                    if (completion) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            completion(@[], nil);
                        });
                    }
                    return;
                }
                
                // 更新进度
                if (progressBlock) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        progressBlock(0.1);
                    });
                }
                
                // 先检查缓存状态
                [self checkCacheStatusForAssets:assets completion:^(float cacheRatio) {
                    NSLog(@"缓存命中率: %.2f%%", cacheRatio * 100);
                    
                    // 如果缓存率高，使用快速处理路径
                    if (cacheRatio > 0.7) {
                        NSLog(@"使用缓存优化路径...");
                        [self processCachedAssetsForSimilarity:assets progressBlock:progressBlock completion:completion];
                    } else {
                        NSLog(@"使用标准处理路径...");
                        // 预过滤分组
                        NSArray<NSArray<PHAsset *> *> *preFilteredGroups = [self preFilterAssets:assets];
                        
                        // 处理预过滤后的分组
                        [self processSimilarityGroups:preFilteredGroups progressBlock:progressBlock completion:completion];
                    }
                }];
            }];
        }];
    });
}

- (NSArray<NSDictionary<NSString *, id> *> *)groupPhotosByDate:(NSArray<PHAsset *> *)assets {
    // 日期格式化器
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd";
    
    // 按日期分组
    NSMutableDictionary<NSString *, NSMutableArray<PHAsset *> *> *groupedPhotos = [NSMutableDictionary dictionary];
    
    for (PHAsset *asset in assets) {
        if (asset.creationDate) {
            NSString *dateString = [dateFormatter stringFromDate:asset.creationDate];
            if (!groupedPhotos[dateString]) {
                groupedPhotos[dateString] = [NSMutableArray array];
            }
            [groupedPhotos[dateString] addObject:asset];
        }
    }
    
    // 将分组结果排序并转换为指定格式
    NSMutableArray<NSDictionary<NSString *, id> *> *result = [NSMutableArray array];
    
    NSArray<NSString *> *sortedDates = [[groupedPhotos allKeys] sortedArrayUsingSelector:@selector(compare:)];
    
    for (NSString *date in sortedDates) {
        [result addObject:@{
            @"date": date,
            @"assets": groupedPhotos[date]
        }];
    }
    
    return [result copy];
}

- (void)deleteAssets:(NSArray<PHAsset *> *)assets completion:(void(^)(BOOL success, NSError * _Nullable error))completion {
    if (assets.count == 0) {
        if (completion) {
            completion(NO, [NSError errorWithDomain:@"com.qingli.photosimilarity"
                                               code:KJPhotoLibraryErrorUnknown
                                           userInfo:@{NSLocalizedDescriptionKey: @"No assets to delete"}]);
        }
        return;
    }
    
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        [PHAssetChangeRequest deleteAssets:assets];
    } completionHandler:^(BOOL success, NSError * _Nullable error) {
        if (success) {
            // 从缓存中移除已删除的资产
            for (PHAsset *asset in assets) {
                NSString *cacheKey = asset.localIdentifier;
                [[KJFeaturePrintCache sharedCache] removeFeatureVectorForAsset:asset];
                [[KJImageCache sharedCache] removeImageForKey:cacheKey];
            }
        }
        
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(success, error);
            });
        }
    }];
}

#pragma mark - 私有辅助方法

// 请求照片库访问权限
- (void)requestPhotoLibraryAccessWithCompletion:(void(^)(BOOL granted, NSError * _Nullable error))completion {
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    
    switch (status) {
        case PHAuthorizationStatusNotDetermined:
        {
            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus newStatus) {
                BOOL granted = (newStatus == PHAuthorizationStatusAuthorized || newStatus == PHAuthorizationStatusLimited);
                NSError *error = nil;
                
                if (!granted) {
                    error = [NSError errorWithDomain:@"com.qingli.photosimilarity"
                                                code:KJPhotoLibraryErrorAccessDenied
                                            userInfo:@{NSLocalizedDescriptionKey: @"访问照片库被拒绝。"}];
                }
                
                if (completion) {
                    completion(granted, error);
                }
            }];
            break;
        }
            
        case PHAuthorizationStatusAuthorized:
        case PHAuthorizationStatusLimited:
        {
            if (completion) {
                completion(YES, nil);
            }
            break;
        }
            
        case PHAuthorizationStatusDenied:
        case PHAuthorizationStatusRestricted:
        default:
        {
            if (completion) {
                NSError *error = [NSError errorWithDomain:@"com.qingli.photosimilarity"
                                                     code:KJPhotoLibraryErrorAccessDenied
                                                 userInfo:@{NSLocalizedDescriptionKey: @"访问照片库被拒绝。"}];
                completion(NO, error);
            }
            break;
        }
    }
}

// 获取照片资产
- (void)fetchAssetsWithCompletion:(void(^)(NSArray<PHAsset *> * _Nullable assets, NSError * _Nullable error))completion {
    PHFetchOptions *options = [[PHFetchOptions alloc] init];
    options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
    
    PHFetchResult *fetchResult;
    switch (self.mediaType) {
        case KJMediaTypeVideo:
            options.predicate = [NSPredicate predicateWithFormat:@"mediaType == %d", PHAssetMediaTypeVideo];
            fetchResult = [PHAsset fetchAssetsWithOptions:options];
            break;
            
        case KJMediaTypeLivePhoto:
            if (@available(iOS 9.1, *)) {
                options.predicate = [NSPredicate predicateWithFormat:@"(mediaSubtypes & %d) != 0", PHAssetMediaSubtypePhotoLive];
                fetchResult = [PHAsset fetchAssetsWithOptions:options];
            } else {
                // 创建一个空的PHFetchResult
                fetchResult = [PHAsset fetchAssetsWithOptions:[[PHFetchOptions alloc] init]];
                // 由于iOS 9.1以下没有Live Photo，所以返回空结果
            }
            break;
            
        case KJMediaTypeScreenshot:
            options.predicate = [NSPredicate predicateWithFormat:@"(mediaSubtypes & %d) != 0", PHAssetMediaSubtypePhotoScreenshot];
            fetchResult = [PHAsset fetchAssetsWithOptions:options];
            break;
            
        default: // 默认处理相似照片（普通照片）
            fetchResult = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:options];
            break;
    }
    
    NSMutableArray<PHAsset *> *assets = [NSMutableArray arrayWithCapacity:fetchResult.count];
    
    [fetchResult enumerateObjectsUsingBlock:^(PHAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [assets addObject:obj];
    }];
    
    if (completion) {
        completion([assets copy], nil);
    }
}

// 预过滤资产
- (NSArray<NSArray<PHAsset *> *> *)preFilterAssets:(NSArray<PHAsset *> *)assets {
    // 按照尺寸分组，相同尺寸的照片更可能相似
    NSMutableDictionary<NSString *, NSMutableArray<PHAsset *> *> *groupedAssets = [NSMutableDictionary dictionary];
    
    for (PHAsset *asset in assets) {
        NSString *key = [NSString stringWithFormat:@"%ldx%ld", (long)asset.pixelWidth, (long)asset.pixelHeight];
        
        if (!groupedAssets[key]) {
            groupedAssets[key] = [NSMutableArray array];
        }
        
        [groupedAssets[key] addObject:asset];
    }
    
    // 转换为数组
    NSMutableArray<NSArray<PHAsset *> *> *result = [NSMutableArray array];
    
    [groupedAssets enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSMutableArray<PHAsset *> * _Nonnull obj, BOOL * _Nonnull stop) {
        [result addObject:[obj copy]];
    }];
    
    return [result copy];
}

// 处理相似性分组
- (void)processSimilarityGroups:(NSArray<NSArray<PHAsset *> *> *)groups
                   progressBlock:(void(^)(float progress))progressBlock
                      completion:(void(^)(NSArray<NSArray<PHAsset *> *> *similarGroups, NSError * _Nullable error))completion {
    
    NSMutableArray<NSArray<PHAsset *> *> *finalSimilarGroups = [NSMutableArray array];
    __block NSInteger totalGroups = groups.count;
    __block NSInteger processedGroups = 0;
    
    dispatch_group_t group = dispatch_group_create();
    
    // 遍历每个预过滤的组
    for (NSArray<PHAsset *> *assetGroup in groups) {
        if (assetGroup.count < 2) {
            // 跳过只有一张照片的组
            processedGroups++;
            continue;
        }
        
        dispatch_group_enter(group);
        
        // 处理每个组
        [self processGroup:assetGroup completion:^(NSArray<NSArray<PHAsset *> *> *similarGroups) {
            // 只添加包含两个或更多照片的相似组
            for (NSArray<PHAsset *> *similarGroup in similarGroups) {
                if (similarGroup.count >= 2) {
                    @synchronized (finalSimilarGroups) {
                        [finalSimilarGroups addObject:similarGroup];
                    }
                }
            }
            
            processedGroups++;
            
            // 更新进度
            if (progressBlock) {
                float progress = 0.1f + ((float)processedGroups / (float)totalGroups) * 0.8f;
                dispatch_async(dispatch_get_main_queue(), ^{
                    progressBlock(progress);
                });
            }
            
            dispatch_group_leave(group);
        }];
    }
    
    // 等待所有组处理完成
    dispatch_group_notify(group, self.processingQueue, ^{
        // 完成处理，返回结果
        if (progressBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                progressBlock(1.0);
            });
        }
        
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(finalSimilarGroups, nil);
            });
        }
    });
}

// 处理单个组
- (void)processGroup:(NSArray<PHAsset *> *)assets
          completion:(void(^)(NSArray<NSArray<PHAsset *> *> *similarGroups))completion {
    
    // 提取特征向量
    [self extractFeatureVectorsFromAssets:assets completion:^(NSArray<NSDictionary<NSString *, id> *> *results) {
        if (results.count < 2) {
            if (completion) {
                completion(@[]);
            }
            return;
        }
        
        // 准备DBSCAN聚类的输入
        NSMutableArray<VNFeaturePrintObservation *> *featureVectors = [NSMutableArray arrayWithCapacity:results.count];
        NSMutableArray<PHAsset *> *processedAssets = [NSMutableArray arrayWithCapacity:results.count];
        
        for (NSDictionary<NSString *, id> *result in results) {
            [featureVectors addObject:result[@"featureVector"]];
            [processedAssets addObject:result[@"asset"]];
        }
        
        // 应用DBSCAN聚类
        KJOptimizedDBSCAN *dbscan = [[KJOptimizedDBSCAN alloc] initWithMinPoints:2 epsilon:self.similarityThreshold];
        NSArray<NSArray<NSNumber *> *> *clusters = [dbscan fit:featureVectors];
        
        // 将聚类结果转换为资产组
        NSMutableArray<NSArray<PHAsset *> *> *assetClusters = [NSMutableArray array];
        
        for (NSArray<NSNumber *> *cluster in clusters) {
            NSMutableArray<PHAsset *> *assetCluster = [NSMutableArray array];
            
            for (NSNumber *index in cluster) {
                NSInteger idx = [index integerValue];
                if (idx < processedAssets.count) {
                    [assetCluster addObject:processedAssets[idx]];
                }
            }
            
            if (assetCluster.count >= 2) {
                [assetClusters addObject:[assetCluster copy]];
            }
        }
        
        if (completion) {
            completion([assetClusters copy]);
        }
    }];
}

// 提取资产的特征向量
- (void)extractFeatureVectorsFromAssets:(NSArray<PHAsset *> *)assets
                             completion:(void(^)(NSArray<NSDictionary<NSString *, id> *> *results))completion {
    
    NSMutableArray<NSDictionary<NSString *, id> *> *results = [NSMutableArray array];
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t queue = dispatch_queue_create("com.qingli.featureextraction", DISPATCH_QUEUE_CONCURRENT);
    
    for (PHAsset *asset in assets) {
        dispatch_group_enter(group);
        
        // 尝试从缓存获取特征向量
        VNFeaturePrintObservation *cachedVector = [[KJFeaturePrintCache sharedCache] featureVectorForAsset:asset];
        
        if (cachedVector) {
            // 使用缓存的特征向量
            @synchronized (results) {
                [results addObject:@{
                    @"asset": asset,
                    @"featureVector": cachedVector
                }];
            }
            dispatch_group_leave(group);
        } else {
            // 需要提取特征向量
            dispatch_semaphore_wait(self.concurrencySemaphore, DISPATCH_TIME_FOREVER);
            
            dispatch_async(queue, ^{
                // 获取图像
                [self requestImageForAsset:asset targetSize:self.targetImageSize contentMode:PHImageContentModeAspectFill completion:^(UIImage * _Nullable image) {
                    if (image) {
                        // 提取特征向量
                        [self extractFeatureVectorFromImage:image completion:^(VNFeaturePrintObservation * _Nullable featureVector) {
                            if (featureVector) {
                                // 缓存特征向量
                                [[KJFeaturePrintCache sharedCache] cacheFeatureVector:featureVector forAsset:asset];
                                
                                // 添加到结果
                                @synchronized (results) {
                                    [results addObject:@{
                                        @"asset": asset,
                                        @"featureVector": featureVector
                                    }];
                                }
                            }
                            
                            dispatch_semaphore_signal(self.concurrencySemaphore);
                            dispatch_group_leave(group);
                        }];
                    } else {
                        dispatch_semaphore_signal(self.concurrencySemaphore);
                        dispatch_group_leave(group);
                    }
                }];
            });
        }
    }
    
    dispatch_group_notify(group, self.processingQueue, ^{
        if (completion) {
            completion([results copy]);
        }
    });
}

// 请求图像
- (void)requestImageForAsset:(PHAsset *)asset
                  targetSize:(CGSize)targetSize
                 contentMode:(PHImageContentMode)contentMode
                  completion:(void(^)(UIImage * _Nullable image))completion {
    
    NSString *cacheKey = asset.localIdentifier;
    
    // 检查缓存
    UIImage *cachedImage = [[KJImageCache sharedCache] imageForKey:cacheKey];
    if (cachedImage) {
        if (completion) {
            completion(cachedImage);
        }
        return;
    }
    
    // 请求选项
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.deliveryMode = PHImageRequestOptionsDeliveryModeFastFormat;
    options.resizeMode = PHImageRequestOptionsResizeModeFast;
    options.synchronous = NO;
    options.networkAccessAllowed = NO;
    
    // 请求图像
    [[PHImageManager defaultManager] requestImageForAsset:asset
                                               targetSize:targetSize
                                              contentMode:contentMode
                                                  options:options
                                            resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        if (result) {
            // 缓存图像
            [[KJImageCache sharedCache] cacheImage:result forKey:cacheKey];
        }
        
        if (completion) {
            completion(result);
        }
    }];
}

// 提取特征向量
- (void)extractFeatureVectorFromImage:(UIImage *)image
                           completion:(void(^)(VNFeaturePrintObservation * _Nullable featureVector))completion {
    
    // 创建CIImage
    CIImage *ciImage = [CIImage imageWithCGImage:image.CGImage];
    if (!ciImage) {
        if (completion) {
            completion(nil);
        }
        return;
    }
    
    // 创建请求
    VNGenerateImageFeaturePrintRequest *request = [[VNGenerateImageFeaturePrintRequest alloc] init];
    
    // 创建处理器
    VNImageRequestHandler *handler = [[VNImageRequestHandler alloc] initWithCIImage:ciImage options:@{}];
    
    // 执行请求
    NSError *error = nil;
    [handler performRequests:@[request] error:&error];
    
    if (error) {
        NSLog(@"特征提取错误: %@", error);
        if (completion) {
            completion(nil);
        }
        return;
    }
    
    // 获取结果
    VNFeaturePrintObservation *observation = (VNFeaturePrintObservation *)request.results.firstObject;
    
    if (completion) {
        completion(observation);
    }
}

// 检查缓存状态
- (void)checkCacheStatusForAssets:(NSArray<PHAsset *> *)assets completion:(void(^)(float cacheRatio))completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // 抽样检查缓存状态
        NSInteger sampleSize = MIN(50, assets.count);
        NSInteger cachedCount = 0;
        
        NSMutableArray<PHAsset *> *sampleAssets = [NSMutableArray arrayWithCapacity:sampleSize];
        for (NSInteger i = 0; i < sampleSize; i++) {
            NSInteger randomIndex = arc4random_uniform((uint32_t)assets.count);
            [sampleAssets addObject:assets[randomIndex]];
        }
        
        for (PHAsset *asset in sampleAssets) {
            VNFeaturePrintObservation *cachedVector = [[KJFeaturePrintCache sharedCache] featureVectorForAsset:asset];
            if (cachedVector) {
                cachedCount++;
            }
        }
        
        float cacheRatio = (float)cachedCount / (float)sampleSize;
        
        if (completion) {
            completion(cacheRatio);
        }
    });
}

// 使用缓存优化的相似性处理路径
- (void)processCachedAssetsForSimilarity:(NSArray<PHAsset *> *)assets
                          progressBlock:(void(^)(float progress))progressBlock
                             completion:(void(^)(NSArray<NSArray<PHAsset *> *> *similarGroups, NSError * _Nullable error))completion {
    
    dispatch_async(self.processingQueue, ^{
        // 加载所有缓存的特征向量
        NSMutableArray<VNFeaturePrintObservation *> *featureVectors = [NSMutableArray array];
        NSMutableArray<PHAsset *> *processedAssets = [NSMutableArray array];
        NSMutableArray<PHAsset *> *uncachedAssets = [NSMutableArray array];
        
        // 首先快速加载所有缓存的向量
        for (PHAsset *asset in assets) {
            VNFeaturePrintObservation *cachedVector = [[KJFeaturePrintCache sharedCache] featureVectorForAsset:asset];
            if (cachedVector) {
                [featureVectors addObject:cachedVector];
                [processedAssets addObject:asset];
            } else {
                [uncachedAssets addObject:asset];
            }
        }
        
        // 更新进度
        if (progressBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                progressBlock(0.3);
            });
        }
        
        // 处理未缓存的资产
        if (uncachedAssets.count > 0) {
            dispatch_group_t group = dispatch_group_create();
            dispatch_queue_t queue = dispatch_queue_create("com.qingli.featureextraction", DISPATCH_QUEUE_CONCURRENT);
            
            __block NSInteger processedCount = 0;
            NSInteger totalCount = uncachedAssets.count;
            
            for (PHAsset *asset in uncachedAssets) {
                dispatch_group_enter(group);
                
                dispatch_semaphore_wait(self.concurrencySemaphore, DISPATCH_TIME_FOREVER);
                
                dispatch_async(queue, ^{
                    // 获取图像
                    [self requestImageForAsset:asset targetSize:self.targetImageSize contentMode:PHImageContentModeAspectFill completion:^(UIImage * _Nullable image) {
                        if (image) {
                            // 提取特征向量
                            [self extractFeatureVectorFromImage:image completion:^(VNFeaturePrintObservation * _Nullable featureVector) {
                                if (featureVector) {
                                    // 缓存特征向量
                                    [[KJFeaturePrintCache sharedCache] cacheFeatureVector:featureVector forAsset:asset];
                                    
                                    // 添加到处理集合
                                    @synchronized (featureVectors) {
                                        [featureVectors addObject:featureVector];
                                        [processedAssets addObject:asset];
                                    }
                                }
                                
                                processedCount++;
                                
                                // 更新进度
                                if (progressBlock) {
                                    float progress = 0.3f + ((float)processedCount / (float)totalCount) * 0.4f;
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        progressBlock(progress);
                                    });
                                }
                                
                                dispatch_semaphore_signal(self.concurrencySemaphore);
                                dispatch_group_leave(group);
                            }];
                        } else {
                            processedCount++;
                            dispatch_semaphore_signal(self.concurrencySemaphore);
                            dispatch_group_leave(group);
                        }
                    }];
                });
            }
            
            dispatch_group_notify(group, self.processingQueue, ^{
                // 所有特征都已处理，进行聚类
                [self finishProcessingWithFeatureVectors:featureVectors assets:processedAssets progressBlock:progressBlock completion:completion];
            });
        } else {
            // 如果所有资产都已缓存，直接进行聚类
            [self finishProcessingWithFeatureVectors:featureVectors assets:processedAssets progressBlock:progressBlock completion:completion];
        }
    });
}

// 完成处理
- (void)finishProcessingWithFeatureVectors:(NSArray<VNFeaturePrintObservation *> *)featureVectors
                                   assets:(NSArray<PHAsset *> *)processedAssets
                            progressBlock:(void(^)(float progress))progressBlock
                               completion:(void(^)(NSArray<NSArray<PHAsset *> *> *similarGroups, NSError * _Nullable error))completion {
    
    // 更新进度
    if (progressBlock) {
        dispatch_async(dispatch_get_main_queue(), ^{
            progressBlock(0.8);
        });
    }
    
    if (featureVectors.count < 2) {
        // 没有足够的特征向量进行聚类
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(@[], nil);
            });
        }
        return;
    }
    
    // 应用DBSCAN聚类
    KJOptimizedDBSCAN *dbscan = [[KJOptimizedDBSCAN alloc] initWithMinPoints:2 epsilon:self.similarityThreshold];
    NSArray<NSArray<NSNumber *> *> *clusters = [dbscan fit:featureVectors];
    
    // 将聚类结果转换为资产组
    NSMutableArray<NSArray<PHAsset *> *> *assetClusters = [NSMutableArray array];
    
    for (NSArray<NSNumber *> *cluster in clusters) {
        NSMutableArray<PHAsset *> *assetCluster = [NSMutableArray array];
        
        for (NSNumber *index in cluster) {
            NSInteger idx = [index integerValue];
            if (idx < processedAssets.count) {
                [assetCluster addObject:processedAssets[idx]];
            }
        }
        
        if (assetCluster.count >= 2) {
            [assetClusters addObject:[assetCluster copy]];
        }
    }
    
    // 更新进度
    if (progressBlock) {
        dispatch_async(dispatch_get_main_queue(), ^{
            progressBlock(1.0);
        });
    }
    
    // 返回结果
    if (completion) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion([assetClusters copy], nil);
        });
    }
}

// 保留原方法作为兼容方法，默认使用普通照片类型
- (void)findSimilarPhotosWithProgress:(void(^)(float progress))progressBlock
                           completion:(void(^)(NSArray<NSArray<PHAsset *> *> *similarGroups, NSError * _Nullable error))completion {
    [self findSimilarPhotosWithMediaType:KJMediaTypePhoto progressBlock:progressBlock completion:completion];
}

@end 
