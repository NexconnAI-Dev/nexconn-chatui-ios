//
//  NCFMDatabasePool.h
//  fmdb
//
//  Adapted from FMDB: https://github.com/ccgus/fmdb
//  Original copyright (c) 2008-2014 Flying Meat Inc.
//  Modified by Nexconn in 2026.
//

#import <Foundation/Foundation.h>

@class NCFMDatabase;

/** Pool of `<NCFMDatabase>` objects.

 ### See also

 - `<NCFMDatabaseQueue>`
 - `<NCFMDatabase>`

 @warning Before using `NCFMDatabasePool`, please consider using `<NCFMDatabaseQueue>` instead.

 If you really really really know what you're doing and `NCFMDatabasePool` is what
 you really really need (ie, you're using a read only database), OK you can use
 it.  But just be careful not to deadlock!

 For an example on deadlocking, search for:
 `ONLY_USE_THE_POOL_IF_YOU_ARE_DOING_READS_OTHERWISE_YOULL_DEADLOCK_USE_FMDATABASEQUEUE_INSTEAD`
 in the main.m file.
 */

@interface NCFMDatabasePool : NSObject {
    NSString *_path;

    dispatch_queue_t _lockQueue;

    NSMutableArray *_databaseInPool;
    NSMutableArray *_databaseOutPool;

    __weak id _delegate;

    NSUInteger _maximumNumberOfDatabasesToCreate;
    int _openFlags;
}

/** Database path */

@property (atomic, retain) NSString *path;

/** Delegate object */

@property (atomic, weak) id delegate;

/** Maximum number of databases to create */

@property (atomic, assign) NSUInteger maximumNumberOfDatabasesToCreate;

/** Open flags */

@property (atomic, readonly) int openFlags;

///---------------------
/// @name Initialization
///---------------------

/** Create pool using path.

 @param aPath The file path of the database.

 - Returns: The `NCFMDatabasePool` object. `nil` on error.
 */

+ (instancetype)databasePoolWithPath:(NSString *)aPath;

/** Create pool using path and specified flags

 @param aPath The file path of the database.
 @param openFlags Flags passed to the openWithFlags method of the database

 - Returns: The `NCFMDatabasePool` object. `nil` on error.
 */

+ (instancetype)databasePoolWithPath:(NSString *)aPath flags:(int)openFlags;

/** Create pool using path.

 @param aPath The file path of the database.

 - Returns: The `NCFMDatabasePool` object. `nil` on error.
 */

- (instancetype)initWithPath:(NSString *)aPath;

/** Create pool using path and specified flags.

 @param aPath The file path of the database.
 @param openFlags Flags passed to the openWithFlags method of the database

 - Returns: The `NCFMDatabasePool` object. `nil` on error.
 */

- (instancetype)initWithPath:(NSString *)aPath flags:(int)openFlags;

///------------------------------------------------
/// @name Keeping track of checked in/out databases
///------------------------------------------------

/** Number of checked-in databases in pool

 - Returns: s Number of databases
 */

- (NSUInteger)countOfCheckedInDatabases;

/** Number of checked-out databases in pool

 - Returns: s Number of databases
 */

- (NSUInteger)countOfCheckedOutDatabases;

/** Total number of databases in pool

 - Returns: s Number of databases
 */

- (NSUInteger)countOfOpenDatabases;

/** Release all databases in pool */

- (void)releaseAllDatabases;

///------------------------------------------
/// @name Perform database operations in pool
///------------------------------------------

/** Synchronously perform database operations in pool.

 @param block The code to be run on the `NCFMDatabasePool` pool.
 */

- (void)inDatabase:(void (^)(NCFMDatabase *db))block;

/** Synchronously perform database operations in pool using transaction.

 @param block The code to be run on the `NCFMDatabasePool` pool.
 */

- (void)inTransaction:(void (^)(NCFMDatabase *db, BOOL *rollback))block;

/** Synchronously perform database operations in pool using deferred transaction.

 @param block The code to be run on the `NCFMDatabasePool` pool.
 */

- (void)inDeferredTransaction:(void (^)(NCFMDatabase *db, BOOL *rollback))block;

/** Synchronously perform database operations in pool using save point.

 @param block The code to be run on the `NCFMDatabasePool` pool.

 - Returns: `NSError` object if error; `nil` if successful.

 @warning You can not nest these, since calling it will pull another database out of the pool and
 you'll get a deadlock. If you need to nest, use `<[NCFMDatabase startSavePointWithName:error:]>`
 instead.
*/

- (NSError *)inSavePoint:(void (^)(NCFMDatabase *db, BOOL *rollback))block;

@end

/** NCFMDatabasePool delegate category

 This is a category that defines the protocol for the NCFMDatabasePool delegate
 */

@interface NSObject (NCFMDatabasePoolDelegate)

/** Asks the delegate whether database should be added to the pool.

 @param pool     The `NCFMDatabasePool` object.
 @param database The `NCFMDatabase` object.

 - Returns: `YES` if it should add database to pool; `NO` if not.

 */

- (BOOL)databasePool:(NCFMDatabasePool *)pool shouldAddDatabaseToPool:(NCFMDatabase *)database;

/** Tells the delegate that database was added to the pool.

 @param pool     The `NCFMDatabasePool` object.
 @param database The `NCFMDatabase` object.

 */

- (void)databasePool:(NCFMDatabasePool *)pool didAddDatabase:(NCFMDatabase *)database;

@end
