#import "FaceDB.h"
#import <sqlite3.h>

@implementation FaceRecord
@end

@interface FaceDB ()
@property (nonatomic, assign) sqlite3 *db;
@property (nonatomic, copy) NSString *dbPath;
@end

@implementation FaceDB

+ (instancetype)sharedInstance {
    static FaceDB *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[FaceDB alloc] init];
    });
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *docsDir = [paths objectAtIndex:0];
        _dbPath = [docsDir stringByAppendingPathComponent:@"arcsoft_face.db"];
        [self openDB];
        [self createTable];
    }
    return self;
}

- (void)openDB {
    if (sqlite3_open([_dbPath UTF8String], &_db) != SQLITE_OK) {
        NSLog(@"[FaceDB] Failed to open database");
    }
}

- (void)createTable {
    char *errMsg;
    const char *sql = "CREATE TABLE IF NOT EXISTS faces (user_id TEXT PRIMARY KEY, feature BLOB)";
    if (sqlite3_exec(_db, sql, NULL, NULL, &errMsg) != SQLITE_OK) {
        NSLog(@"[FaceDB] Failed to create table: %s", errMsg);
    }
}

- (BOOL)addFace:(NSString *)userId feature:(NSData *)feature {
    const char *sql = "INSERT OR REPLACE INTO faces (user_id, feature) VALUES (?, ?)";
    sqlite3_stmt *stmt;
    if (sqlite3_prepare_v2(_db, sql, -1, &stmt, NULL) == SQLITE_OK) {
        sqlite3_bind_text(stmt, 1, [userId UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_blob(stmt, 2, [feature bytes], (int)[feature length], SQLITE_TRANSIENT);

        if (sqlite3_step(stmt) != SQLITE_DONE) {
            NSLog(@"[FaceDB] Failed to insert face");
            sqlite3_finalize(stmt);
            return NO;
        }
        sqlite3_finalize(stmt);
        return YES;
    }
    return NO;
}

- (BOOL)removeFace:(NSString *)userId {
    const char *sql = "DELETE FROM faces WHERE user_id = ?";
    sqlite3_stmt *stmt;
    if (sqlite3_prepare_v2(_db, sql, -1, &stmt, NULL) == SQLITE_OK) {
        sqlite3_bind_text(stmt, 1, [userId UTF8String], -1, SQLITE_TRANSIENT);

        if (sqlite3_step(stmt) != SQLITE_DONE) {
            NSLog(@"[FaceDB] Failed to delete face");
            sqlite3_finalize(stmt);
            return NO;
        }
        sqlite3_finalize(stmt);
        return YES;
    }
    return NO;
}

- (BOOL)clearAll {
    char *errMsg;
    const char *sql = "DELETE FROM faces";
    if (sqlite3_exec(_db, sql, NULL, NULL, &errMsg) != SQLITE_OK) {
        NSLog(@"[FaceDB] Failed to clear table: %s", errMsg);
        return NO;
    }
    return YES;
}

- (NSArray<FaceRecord *> *)getAllFaces {
    NSMutableArray *faces = [NSMutableArray array];
    const char *sql = "SELECT user_id, feature FROM faces";
    sqlite3_stmt *stmt;
    if (sqlite3_prepare_v2(_db, sql, -1, &stmt, NULL) == SQLITE_OK) {
        while (sqlite3_step(stmt) == SQLITE_ROW) {
            FaceRecord *record = [[FaceRecord alloc] init];
            char *userIdChars = (char *)sqlite3_column_text(stmt, 0);
            if (userIdChars) {
                record.userId = [NSString stringWithUTF8String:userIdChars];
            }

            const void *featureBytes = sqlite3_column_blob(stmt, 1);
            int featureLen = sqlite3_column_bytes(stmt, 1);
            if (featureBytes && featureLen > 0) {
                record.featureData = [NSData dataWithBytes:featureBytes length:featureLen];
            }

            [faces addObject:record];
        }
        sqlite3_finalize(stmt);
    }
    return faces;
}

- (NSInteger)count {
    const char *sql = "SELECT COUNT(*) FROM faces";
    sqlite3_stmt *stmt;
    NSInteger count = 0;
    if (sqlite3_prepare_v2(_db, sql, -1, &stmt, NULL) == SQLITE_OK) {
        if (sqlite3_step(stmt) == SQLITE_ROW) {
            count = sqlite3_column_int(stmt, 0);
        }
        sqlite3_finalize(stmt);
    }
    return count;
}

@end
