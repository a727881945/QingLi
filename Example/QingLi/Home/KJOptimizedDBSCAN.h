#import <Foundation/Foundation.h>
#import <Vision/Vision.h>

NS_ASSUME_NONNULL_BEGIN

@interface KJOptimizedDBSCAN : NSObject

@property (nonatomic, assign) NSInteger minPoints;
@property (nonatomic, assign) double epsilon;

/**
 * 初始化DBSCAN聚类算法
 * @param minPoints 最小点数，一个簇至少需要包含的点数
 * @param epsilon 邻域半径，两个点之间的最大距离，小于该值被视为邻居
 */
- (instancetype)initWithMinPoints:(NSInteger)minPoints epsilon:(double)epsilon;

/**
 * 对特征向量进行聚类
 * @param observations 特征向量数组
 * @return 聚类后的索引数组，每个子数组代表一个簇
 */
- (NSArray<NSArray<NSNumber *> *> *)fit:(NSArray<VNFeaturePrintObservation *> *)observations;

/**
 * 对特征向量进行聚类，带进度回调
 * @param observations 特征向量数组
 * @param progressCallback 进度回调
 * @return 聚类后的索引数组，每个子数组代表一个簇
 */
- (NSArray<NSArray<NSNumber *> *> *)fit:(NSArray<VNFeaturePrintObservation *> *)observations 
                        progressCallback:(nullable void(^)(float progress))progressCallback;

@end

NS_ASSUME_NONNULL_END 