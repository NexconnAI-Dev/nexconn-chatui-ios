//
//  NCMJRefreshConfig.h
//
//  Adapted from MJRefresh: https://github.com/CoderMJLee/MJRefresh
//  Original copyright (c) 2013-2015 MJRefresh.
//  Modified by Nexconn in 2026.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NCMJRefreshConfig : NSObject

/** Optional language code stored by this configuration object. Defaults to nil and is not updated automatically. */
@property (copy, nonatomic, nullable) NSString *languageCode;

/** - Returns: Singleton Config instance */
+ (instancetype)defaultConfig;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype) new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
