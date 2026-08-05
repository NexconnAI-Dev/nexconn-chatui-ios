#import <Foundation/Foundation.h>
#import "NCChatUIEventProtocols.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^NCChatUINetworkStatusChangedHandler)(NCChatUINetworkStatus status);

@interface NCChatUINetworkStatusService : NSObject

@property (atomic, assign, readonly) NCChatUINetworkStatus currentNetworkStatus;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithStatusChangedHandler:(nullable NCChatUINetworkStatusChangedHandler)statusChangedHandler NS_DESIGNATED_INITIALIZER;

- (void)startMonitorIfNeeded;
- (void)stopMonitor;
- (void)refreshCurrentStatusAndNotify:(BOOL)shouldNotify;

@end

NS_ASSUME_NONNULL_END
