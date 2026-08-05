//
//  NCFMDatabaseQueue.h
//  fmdb
//
//  Adapted from FMDB: https://github.com/ccgus/fmdb
//  Original copyright (c) 2008-2014 Flying Meat Inc.
//  Modified by Nexconn in 2026.
//

#import <Foundation/Foundation.h>

@class NCFMDatabase;

/** To perform queries and updates on multiple threads, you'll want to use `NCFMDatabaseQueue`.

 Using a single instance of `<NCFMDatabase>` from multiple threads at once is a bad idea.  It has always been OK to
 make a `<NCFMDatabase>` object *per thread*.  Just don't share a single instance across threads, and definitely not
 across multiple threads at the same time.

 Instead, use `NCFMDatabaseQueue`. Here's how to use it:

 First, make your queue.

    NCFMDatabaseQueue *queue = [NCFMDatabaseQueue databaseQueueWithPath:aPath];

 Then use it like so:

    [queue inDatabase:^(NCFMDatabase *db) {
        [db executeUpdate:@"INSERT INTO myTable VALUES (?)", [NSNumber numberWithInt:1]];
        [db executeUpdate:@"INSERT INTO myTable VALUES (?)", [NSNumber numberWithInt:2]];
        [db executeUpdate:@"INSERT INTO myTable VALUES (?)", [NSNumber numberWithInt:3]];

        NCFMResultSet *rs = [db executeQuery:@"select * from foo"];
        while ([rs next]) {
            //…
        }
    }];

 An easy way to wrap things up in a transaction can be done like this:

    [queue inTransaction:^(NCFMDatabase *db, BOOL *rollback) {
        [db executeUpdate:@"INSERT INTO myTable VALUES (?)", [NSNumber numberWithInt:1]];
        [db executeUpdate:@"INSERT INTO myTable VALUES (?)", [NSNumber numberWithInt:2]];
        [db executeUpdate:@"INSERT INTO myTable VALUES (?)", [NSNumber numberWithInt:3]];

        if (whoopsSomethingWrongHappened) {
            *rollback = YES;
            return;
        }
        // etc…
        [db executeUpdate:@"INSERT INTO myTable VALUES (?)", [NSNumber numberWithInt:4]];
    }];

 `NCFMDatabaseQueue` will run the blocks on a serialized queue (hence the name of the class).  So if you call
 `NCFMDatabaseQueue`'s methods from multiple threads at the same time, they will be executed in the order they are
 received.  This way queries and updates won't step on each other's toes, and every one is happy.

 ### See also

 - `<NCFMDatabase>`

 @warning Do not instantiate a single `<NCFMDatabase>` object and use it across multiple threads. Use
 `NCFMDatabaseQueue` instead.

 @warning The calls to `NCFMDatabaseQueue`'s methods are blocking.  So even though you are passing along blocks,
 they will **not** be run on another thread.

 */

@interface NCFMDatabaseQueue : NSObject {
    NSString *_path;
    dispatch_queue_t _queue;
    NCFMDatabase *_db;
    int _openFlags;
}

/** Path of database */

@property (atomic, retain) NSString *path;

/** Open flags */

@property (atomic, readonly) int openFlags;

///----------------------------------------------------
/// @name Initialization, opening, and closing of queue
///----------------------------------------------------

/** Create queue using path.

 @param aPath The file path of the database.

 - Returns: The `NCFMDatabaseQueue` object. `nil` on error.
 */

+ (instancetype)databaseQueueWithPath:(NSString *)aPath;

/** Create queue using path and specified flags.

 @param aPath The file path of the database.
 @param openFlags Flags passed to the openWithFlags method of the database

 - Returns: The `NCFMDatabaseQueue` object. `nil` on error.
 */
+ (instancetype)databaseQueueWithPath:(NSString *)aPath flags:(int)openFlags;

/** Create queue using path.

 @param aPath The file path of the database.

 - Returns: The `NCFMDatabaseQueue` object. `nil` on error.
 */

- (instancetype)initWithPath:(NSString *)aPath;

/** Create queue using path and specified flags.

 @param aPath The file path of the database.
 @param openFlags Flags passed to the openWithFlags method of the database

 - Returns: The `NCFMDatabaseQueue` object. `nil` on error.
 */

- (instancetype)initWithPath:(NSString *)aPath flags:(int)openFlags;

/** Create queue using path and specified flags.

 @param aPath The file path of the database.
 @param openFlags Flags passed to the openWithFlags method of the database
 @param vfsName The name of a custom virtual file system

 - Returns: The `NCFMDatabaseQueue` object. `nil` on error.
 */

- (instancetype)initWithPath:(NSString *)aPath flags:(int)openFlags vfs:(NSString *)vfsName;

/** Returns the Class of 'NCFMDatabase' subclass, that will be used to instantiate database object.

 Subclasses can override this method to return specified Class of 'NCFMDatabase' subclass.

 - Returns: The Class of 'NCFMDatabase' subclass, that will be used to instantiate database object.
 */

+ (Class)databaseClass;

/** Close database used by queue. */

- (void)close;

///-----------------------------------------------
/// @name Dispatching database operations to queue
///-----------------------------------------------

/** Synchronously perform database operations on queue.

 @param block The code to be run on the queue of `NCFMDatabaseQueue`
 */

- (void)inDatabase:(void (^)(NCFMDatabase *db))block;

/** Synchronously perform database operations on queue, using transactions.

 @param block The code to be run on the queue of `NCFMDatabaseQueue`
 */

- (void)inTransaction:(void (^)(NCFMDatabase *db, BOOL *rollback))block;

/** Synchronously perform database operations on queue, using deferred transactions.

 @param block The code to be run on the queue of `NCFMDatabaseQueue`
 */

- (void)inDeferredTransaction:(void (^)(NCFMDatabase *db, BOOL *rollback))block;

///-----------------------------------------------
/// @name Dispatching database operations to queue
///-----------------------------------------------

/** Synchronously perform database operations using save point.

 @param block The code to be run on the queue of `NCFMDatabaseQueue`
 */

// NOTE: you can not nest these, since calling it will pull another database out of the pool and you'll get a deadlock.
// If you need to nest, use FMDatabase's startSavePointWithName:error: instead.
- (NSError *)inSavePoint:(void (^)(NCFMDatabase *db, BOOL *rollback))block;

@end
