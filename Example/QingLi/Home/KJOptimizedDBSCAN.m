#import "KJOptimizedDBSCAN.h"

@implementation KJOptimizedDBSCAN

- (instancetype)initWithMinPoints:(NSInteger)minPoints epsilon:(double)epsilon {
    self = [super init];
    if (self) {
        _minPoints = minPoints;
        _epsilon = epsilon;
    }
    return self;
}

- (NSArray<NSArray<NSNumber *> *> *)fit:(NSArray<VNFeaturePrintObservation *> *)observations {
    return [self fit:observations progressCallback:nil];
}

- (NSArray<NSArray<NSNumber *> *> *)fit:(NSArray<VNFeaturePrintObservation *> *)observations
                        progressCallback:(nullable void(^)(float progress))progressCallback {
    if (observations.count == 0) {
        return @[];
    }
    
    // 创建邻近列表，预计算所有点对的距离关系
    NSArray<NSArray<NSNumber *> *> *neighborLists = [self createNeighborLists:observations progressCallback:progressCallback];
    
    NSMutableArray<NSMutableArray<NSNumber *> *> *clusters = [NSMutableArray array];
    NSMutableSet<NSNumber *> *visited = [NSMutableSet set];
    NSMutableSet<NSNumber *> *noise = [NSMutableSet set];
    
    // 进度跟踪
    NSInteger totalPoints = observations.count;
    __block NSInteger processedPoints = 0;
    
    for (NSInteger i = 0; i < observations.count; i++) {
        if ([visited containsObject:@(i)]) {
            continue;
        }
        
        [visited addObject:@(i)];
        processedPoints++;
        
        NSArray<NSNumber *> *neighbors = neighborLists[i];
        
        if (neighbors.count < self.minPoints) {
            [noise addObject:@(i)];
        } else {
            NSMutableArray<NSNumber *> *cluster = [NSMutableArray array];
            [self expandCluster:i neighbors:neighbors neighborLists:neighborLists
                        cluster:cluster visited:visited processedCount:&processedPoints];
            
            if (cluster.count >= self.minPoints) {
                [clusters addObject:cluster];
            }
        }
        
        // 更新进度
        if (progressCallback && processedPoints % 20 == 0) {
            float progress = (float)processedPoints / (float)totalPoints;
            progressCallback(0.5 + progress * 0.4); // 假设总进度的50%-90%用于DBSCAN处理
        }
    }
    
    return [clusters copy];
}

// 创建邻近列表，预计算所有点对的距离关系
- (NSArray<NSArray<NSNumber *> *> *)createNeighborLists:(NSArray<VNFeaturePrintObservation *> *)observations
                                        progressCallback:(nullable void(^)(float progress))progressCallback {
    NSInteger totalCount = observations.count;
    NSMutableArray<NSArray<NSNumber *> *> *neighborLists = [NSMutableArray arrayWithCapacity:totalCount];
    
    for (NSInteger i = 0; i < totalCount; i++) {
        [neighborLists addObject:@[]];
    }
    
    // 使用并行处理来提高速度
    dispatch_apply(totalCount, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^(size_t i) {
        VNFeaturePrintObservation *point = observations[i];
        NSMutableArray<NSNumber *> *neighbors = [NSMutableArray array];
        
        for (NSInteger j = 0; j < totalCount; j++) {
            if (i != j) { // 避免自身比较
                float distance = 0.0f;
                NSError *error = nil;
                BOOL success = [point computeDistance:&distance toFeaturePrintObservation:observations[j] error:&error];
                
                if (success && !error && distance <= self.epsilon) {
                    [neighbors addObject:@(j)];
                }
            }
        }
        
        @synchronized (neighborLists) {
            neighborLists[i] = [neighbors copy];
        }
        
        // 更新进度
        if (progressCallback && i % 10 == 0) {
            float preCalcProgress = (float)i / (float)totalCount;
            progressCallback(preCalcProgress * 0.4); // 前半部分进度用于预计算
        }
    });
    
    return [neighborLists copy];
}

- (void)expandCluster:(NSInteger)pointIndex
            neighbors:(NSArray<NSNumber *> *)neighbors
         neighborLists:(NSArray<NSArray<NSNumber *> *> *)neighborLists
               cluster:(NSMutableArray<NSNumber *> *)cluster
               visited:(NSMutableSet<NSNumber *> *)visited
         processedCount:(NSInteger *)processedCount {
    
    [cluster addObject:@(pointIndex)];
    
    NSMutableArray<NSNumber *> *searchQueue = [neighbors mutableCopy];
    NSInteger queueIndex = 0;
    
    while (queueIndex < searchQueue.count) {
        NSNumber *currentPoint = searchQueue[queueIndex];
        NSInteger currentIdx = [currentPoint integerValue];
        
        if (![visited containsObject:currentPoint]) {
            [visited addObject:currentPoint];
            (*processedCount)++;
            
            NSArray<NSNumber *> *currentNeighbors = neighborLists[currentIdx];
            
            if (currentNeighbors.count >= self.minPoints) {
                for (NSNumber *neighbor in currentNeighbors) {
                    if (![visited containsObject:neighbor] && ![searchQueue containsObject:neighbor]) {
                        [searchQueue addObject:neighbor];
                    }
                }
            }
        }
        
        if (![cluster containsObject:currentPoint]) {
            [cluster addObject:currentPoint];
        }
        
        queueIndex++;
    }
}

@end 