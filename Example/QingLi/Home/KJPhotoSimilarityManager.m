#import "KJPhotoSimilarityManager.h"
#import "KJOptimizedDBSCAN.h"
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
    }
    return self;
}

- (UIImage *)imageForKey:(NSString *)key {
    return [_memoryCache objectForKey:key];
}

- (void)cacheImage:(UIImage *)image forKey:(NSString *)key {
    if (!image || !key) return;
    [_memoryCache setObject:image forKey:key];
}

- (void)removeImageForKey:(NSString *)key {
    [_memoryCache removeObjectForKey:key];
}

- (void)clearCache {
    [_memoryCache removeAllObjects];
}

@end

// 照片相似性管理类实现
@interface KJPhotoSimilarityManager ()

@property (nonatomic, strong) dispatch_queue_t processingQueue;
@property (nonatomic, strong) dispatch_semaphore_t concurrencySemaphore;
@property (nonatomic, assign) float similarityThreshold;
@property (nonatomic, assign) CGSize targetImageSize;

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
        _targetImageSize = CGSizeMake(100, 100); // 缩略图尺寸
    }
    return self;
}

#pragma mark - 公共方法

- (void)findSimilarPhotosWithProgress:(void(^)(float progress))progressBlock
                           completion:(void(^)(NSArray<NSArray<PHAsset *> *> *similarGroups, NSError * _Nullable error))completion {
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
                
                // 预过滤分组
                NSArray<NSArray<PHAsset *> *> *preFilteredGroups = [self preFilterAssets:assets];
                
                // 处理预过滤后的分组
                [self processSimilarityGroups:preFilteredGroups progressBlock:progressBlock completion:completion];
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
    
    PHFetchResult *fetchResult = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:options];
    
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
    
    __block NSMutableArray<NSArray<PHAsset *> *> *finalSimilarGroups = [NSMutableArray array];
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
            @synchronized (finalSimilarGroups) {
                [finalSimilarGroups addObjectsFromArray:similarGroups];
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

@end 
