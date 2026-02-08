#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FaceRecord : NSObject
@property (nonatomic, assign) NSInteger id; // Auto-increment ID
@property (nonatomic, copy) NSString *userId;
@property (nonatomic, strong) NSData *featureData;
@property (nonatomic, assign) long long registerTime; // Timestamp in milliseconds
@end

@interface FaceDB : NSObject

+ (instancetype)sharedInstance;

- (BOOL)addFace:(NSString *)userId feature:(NSData *)feature;
- (BOOL)removeFace:(NSString *)userId;
- (BOOL)clearAll;
- (NSArray<FaceRecord *> *)getAllFaces;
- (NSInteger)count;

@end

NS_ASSUME_NONNULL_END
