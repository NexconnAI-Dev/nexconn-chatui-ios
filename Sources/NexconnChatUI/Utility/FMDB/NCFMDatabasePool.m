//
//  NCFMDatabasePool.m
//  fmdb
//
//  Adapted from FMDB: https://github.com/ccgus/fmdb
//  Original copyright (c) 2008-2014 Flying Meat Inc.
//  Modified by Nexconn in 2026.
//

#if NCFMDB_SQLITE_STANDALONE
#import <sqlite3/sqlite3.h>
#else
#import <sqlite3.h>
#endif

#import "NCFMDatabase.h"

@interface NCFMDatabasePool ()

- (void)pushDatabaseBackInPool:(NCFMDatabase *)db;
- (NCFMDatabase *)db;

@end

@implementation NCFMDatabasePool
@synthesize path = _path;
@synthesize delegate = _delegate;
@synthesize maximumNumberOfDatabasesToCreate = _maximumNumberOfDatabasesToCreate;
@synthesize openFlags = _openFlags;

+ (instancetype)databasePoolWithPath:(NSString *)aPath {
    return NCFMDBReturnAutoreleased([[self alloc] initWithPath:aPath]);
}

+ (instancetype)databasePoolWithPath:(NSString *)aPath flags:(int)openFlags {
    return NCFMDBReturnAutoreleased([[self alloc] initWithPath:aPath flags:openFlags]);
}

- (instancetype)initWithPath:(NSString *)aPath flags:(int)openFlags {

    self = [super init];

    if (self != nil) {
        _path = [aPath copy];
        _lockQueue =
            dispatch_queue_create([[NSString stringWithFormat:@"fmdb.%@", self] UTF8String], NULL);
        _databaseInPool = NCFMDBReturnRetained([NSMutableArray array]);
        _databaseOutPool = NCFMDBReturnRetained([NSMutableArray array]);
        _openFlags = openFlags;
    }

    return self;
}

- (instancetype)initWithPath:(NSString *)aPath {
    // default flags for sqlite3_open
    return [self initWithPath:aPath
                        flags:SQLITE_OPEN_FULLMUTEX | SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE];
}

- (instancetype)init {
    return [self initWithPath:nil];
}

- (void)dealloc {

    _delegate = 0x00;
    NCFMDBRelease(_path);
    NCFMDBRelease(_databaseInPool);
    NCFMDBRelease(_databaseOutPool);

    if (_lockQueue) {
        NCFMDBDispatchQueueRelease(_lockQueue);
        _lockQueue = 0x00;
    }
#if !__has_feature(objc_arc)
    [super dealloc];
#endif
}

- (void)executeLocked:(void (^)(void))aBlock {
    dispatch_sync(_lockQueue, aBlock);
}

- (void)pushDatabaseBackInPool:(NCFMDatabase *)db {

    if (!db) { // db can be null if we set an upper bound on the # of databases to create.
        return;
    }

    [self executeLocked:^() {
      if ([self->_databaseInPool containsObject:db]) {
          [[NSException exceptionWithName:@"Database already in pool"
                                   reason:@"The NCFMDatabase being put back into the pool is "
                                          @"already present in the pool"
                                 userInfo:nil] raise];
      }

      [self->_databaseInPool addObject:db];
      [self->_databaseOutPool removeObject:db];
    }];
}

- (NCFMDatabase *)db {

    __block NCFMDatabase *db;

    [self executeLocked:^() {
      db = [self->_databaseInPool lastObject];

      BOOL shouldNotifyDelegate = NO;

      if (db) {
          [self->_databaseOutPool addObject:db];
          [self->_databaseInPool removeLastObject];
      } else {

          if (self->_maximumNumberOfDatabasesToCreate) {
              NSUInteger currentCount =
                  [self->_databaseOutPool count] + [self->_databaseInPool count];

              if (currentCount >= self->_maximumNumberOfDatabasesToCreate) {
                  NCLogD(@"Maximum number of databases (%ld) has already been reached!",
                         (long)currentCount);
                  return;
              }
          }

          db = [NCFMDatabase databaseWithPath:self->_path];
          shouldNotifyDelegate = YES;
      }

// This ensures that the db is opened before returning
#if SQLITE_VERSION_NUMBER >= 3005000
      BOOL success = [db openWithFlags:self->_openFlags];
#else
        BOOL success = [db open];
#endif
      if (success) {
          if ([self->_delegate
                  respondsToSelector:@selector(databasePool:shouldAddDatabaseToPool:)] &&
              ![self->_delegate databasePool:self shouldAddDatabaseToPool:db]) {
              [db close];
              db = 0x00;
          } else {
              // It should not get added in the pool twice if lastObject was found
              if (![self->_databaseOutPool containsObject:db]) {
                  [self->_databaseOutPool addObject:db];

                  if (shouldNotifyDelegate &&
                      [self->_delegate
                          respondsToSelector:@selector(databasePool:didAddDatabase:)]) {
                      [self->_delegate databasePool:self didAddDatabase:db];
                  }
              }
          }
      } else {
          NCLogD(@"Could not open up the database at path %@", self->_path);
          db = 0x00;
      }
    }];

    return db;
}

- (NSUInteger)countOfCheckedInDatabases {

    __block NSUInteger count;

    [self executeLocked:^() {
      count = [self->_databaseInPool count];
    }];

    return count;
}

- (NSUInteger)countOfCheckedOutDatabases {

    __block NSUInteger count;

    [self executeLocked:^() {
      count = [self->_databaseOutPool count];
    }];

    return count;
}

- (NSUInteger)countOfOpenDatabases {
    __block NSUInteger count;

    [self executeLocked:^() {
      count = [self->_databaseOutPool count] + [self->_databaseInPool count];
    }];

    return count;
}

- (void)releaseAllDatabases {
    [self executeLocked:^() {
      [self->_databaseOutPool removeAllObjects];
      [self->_databaseInPool removeAllObjects];
    }];
}

- (void)inDatabase:(void (^)(NCFMDatabase *db))block {

    NCFMDatabase *db = [self db];

    block(db);

    [self pushDatabaseBackInPool:db];
}

- (void)beginTransaction:(BOOL)useDeferred
               withBlock:(void (^)(NCFMDatabase *db, BOOL *rollback))block {

    BOOL shouldRollback = NO;

    NCFMDatabase *db = [self db];

    if (useDeferred) {
        [db beginDeferredTransaction];
    } else {
        [db beginTransaction];
    }

    block(db, &shouldRollback);

    if (shouldRollback) {
        [db rollback];
    } else {
        [db commit];
    }

    [self pushDatabaseBackInPool:db];
}

- (void)inDeferredTransaction:(void (^)(NCFMDatabase *db, BOOL *rollback))block {
    [self beginTransaction:YES withBlock:block];
}

- (void)inTransaction:(void (^)(NCFMDatabase *db, BOOL *rollback))block {
    [self beginTransaction:NO withBlock:block];
}

- (NSError *)inSavePoint:(void (^)(NCFMDatabase *db, BOOL *rollback))block {
#if SQLITE_VERSION_NUMBER >= 3007000
    static unsigned long savePointIdx = 0;

    NSString *name = [NSString stringWithFormat:@"savePoint%ld", savePointIdx++];

    BOOL shouldRollback = NO;

    NCFMDatabase *db = [self db];

    NSError *err = 0x00;

    if (![db startSavePointWithName:name error:&err]) {
        [self pushDatabaseBackInPool:db];
        return err;
    }

    block(db, &shouldRollback);

    if (shouldRollback) {
        // We need to rollback and release this savepoint to remove it
        [db rollbackToSavePointWithName:name error:&err];
    }
    [db releaseSavePointWithName:name error:&err];

    [self pushDatabaseBackInPool:db];

    return err;
#else
    NSString *errorMessage = NSLocalizedString(@"Save point functions require SQLite 3.7", nil);
    if (self.logsErrors)
        NCLogD(@"%@", errorMessage);
    return [NSError errorWithDomain:@"NCFMDatabase"
                               code:0
                           userInfo:@{NSLocalizedDescriptionKey : errorMessage}];
#endif
}

@end
