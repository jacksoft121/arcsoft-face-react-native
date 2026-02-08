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
    // Updated schema to match Android: id (INTEGER PRIMARY KEY AUTOINCREMENT), user_id (TEXT), feature_data (BLOB), register_time (INTEGER)
    // Note: Android uses "face" table name, we can keep "faces" or change it. Keeping "faces" for now but updating columns.
    // To support migration, we should check if columns exist, but for simplicity in this demo, we assume fresh install or compatible schema.
    // If you need migration, you'd need to check schema version.

    // Dropping table for schema update (DEV ONLY - REMOVE FOR PRODUCTION MIGRATION)
    // sqlite3_exec(_db, "DROP TABLE IF EXISTS faces", NULL, NULL, NULL);

    const char *sql = "CREATE TABLE IF NOT EXISTS faces ("
                      "id INTEGER PRIMARY KEY AUTOINCREMENT, "
                      "user_id TEXT, "
                      "feature_data BLOB, "
                      "register_time INTEGER)";

    if (sqlite3_exec(_db, sql, NULL, NULL, &errMsg) != SQLITE_OK) {
        NSLog(@"[FaceDB] Failed to create table: %s", errMsg);
    }

    // Create index on user_id for faster lookups (optional but good practice)
    const char *idxSql = "CREATE INDEX IF NOT EXISTS idx_user_id ON faces (user_id)";
    sqlite3_exec(_db, idxSql, NULL, NULL, NULL);
}

- (BOOL)addFace:(NSString *)userId feature:(NSData *)feature {
    // Check if user exists to update or insert
    // Android Room @Insert(onConflict = OnConflictStrategy.REPLACE) might replace based on PrimaryKey (id).
    // But here we want to update based on userId.
    // Let's first delete existing user to simulate "replace" behavior for userId, then insert new.

    [self removeFace:userId];

    const char *sql = "INSERT INTO faces (user_id, feature_data, register_time) VALUES (?, ?, ?)";
    sqlite3_stmt *stmt;
    if (sqlite3_prepare_v2(_db, sql, -1, &stmt, NULL) == SQLITE_OK) {
        sqlite3_bind_text(stmt, 1, [userId UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_blob(stmt, 2, [feature bytes], (int)[feature length], SQLITE_TRANSIENT);

        long long time = (long long)([[NSDate date] timeIntervalSince1970] * 1000);
        sqlite3_bind_int64(stmt, 3, time);

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
    const char *sql = "SELECT id, user_id, feature_data, register_time FROM faces";
    sqlite3_stmt *stmt;
    if (sqlite3_prepare_v2(_db, sql, -1, &stmt, NULL) == SQLITE_OK) {
        while (sqlite3_step(stmt) == SQLITE_ROW) {
            FaceRecord *record = [[FaceRecord alloc] init];

            record.id = sqlite3_column_int(stmt, 0);

            char *userIdChars = (char *)sqlite3_column_text(stmt, 1);
            if (userIdChars) {
                record.userId = [NSString stringWithUTF8String:userIdChars];
            }

            const void *featureBytes = sqlite3_column_blob(stmt, 2);
            int featureLen = sqlite3_column_bytes(stmt, 2);
            if (featureBytes && featureLen > 0) {
                record.featureData = [NSData dataWithBytes:featureBytes length:featureLen];
            }

            record.registerTime = sqlite3_column_int64(stmt, 3);

            [faces addObject:record];
        }
        sqlite3_finalize(stmt);
    }
    return faces;
}

- (NSArray<FaceRecord *> *)getFacesByUserId:(NSString *)userId {
    NSMutableArray *faces = [NSMutableArray array];
    const char *sql = "SELECT id, user_id, feature_data, register_time FROM faces WHERE user_id = ?";
    sqlite3_stmt *stmt;
    if (sqlite3_prepare_v2(_db, sql, -1, &stmt, NULL) == SQLITE_OK) {
        sqlite3_bind_text(stmt, 1, [userId UTF8String], -1, SQLITE_TRANSIENT);

        while (sqlite3_step(stmt) == SQLITE_ROW) {
            FaceRecord *record = [[FaceRecord alloc] init];

            record.id = sqlite3_column_int(stmt, 0);

            char *userIdChars = (char *)sqlite3_column_text(stmt, 1);
            if (userIdChars) {
                record.userId = [NSString stringWithUTF8String:userIdChars];
            }

            const void *featureBytes = sqlite3_column_blob(stmt, 2);
            int featureLen = sqlite3_column_bytes(stmt, 2);
            if (featureBytes && featureLen > 0) {
                record.featureData = [NSData dataWithBytes:featureBytes length:featureLen];
            }

            record.registerTime = sqlite3_column_int64(stmt, 3);

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
