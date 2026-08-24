#import "NCChatUINetworkStatusService.h"
#import <SystemConfiguration/SystemConfiguration.h>
#import <TargetConditionals.h>
#import <netinet/in.h>

@interface NCChatUINetworkStatusService ()

@property (atomic, assign, readwrite) NCChatUINetworkStatus currentNetworkStatus;
@property (nonatomic, assign) SCNetworkReachabilityRef networkReachability;
@property (nonatomic, copy, nullable) NCChatUINetworkStatusChangedHandler statusChangedHandler;

- (void)p_handleReachabilityFlagsChanged:(SCNetworkReachabilityFlags)flags;
- (void)p_notifyStatusChanged:(NCChatUINetworkStatus)status;

@end

static NCChatUINetworkStatus
NCChatUINetworkStatusFromReachabilityFlags(SCNetworkReachabilityFlags flags) {
    BOOL isReachable = (flags & kSCNetworkReachabilityFlagsReachable) != 0;
    BOOL needsConnection = (flags & kSCNetworkReachabilityFlagsConnectionRequired) != 0;
    BOOL canConnectWithoutUserInteraction =
        ((flags & kSCNetworkReachabilityFlagsConnectionOnDemand) != 0 ||
         (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0);
    BOOL canConnectAutomatically = canConnectWithoutUserInteraction &&
                                   ((flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0);
    if (!isReachable || (needsConnection && !canConnectAutomatically)) {
        return NCChatUINetworkStatusNotReachable;
    }
#if TARGET_OS_IPHONE
    if ((flags & kSCNetworkReachabilityFlagsIsWWAN) != 0) {
        return NCChatUINetworkStatusReachableViaWWAN;
    }
#endif
    return NCChatUINetworkStatusReachableViaWiFi;
}

static void NCChatUIReachabilityCallback(SCNetworkReachabilityRef target,
                                         SCNetworkReachabilityFlags flags, void *info) {
    (void)target;
    NCChatUINetworkStatusService *service = (__bridge NCChatUINetworkStatusService *)info;
    if (!service) {
        return;
    }
    [service p_handleReachabilityFlagsChanged:flags];
}

@implementation NCChatUINetworkStatusService

- (instancetype)initWithStatusChangedHandler:
    (NCChatUINetworkStatusChangedHandler)statusChangedHandler {
    self = [super init];
    if (self) {
        _statusChangedHandler = [statusChangedHandler copy];
        _currentNetworkStatus = NCChatUINetworkStatusNotReachable;
    }
    return self;
}

- (void)dealloc {
    [self stopMonitor];
}

- (void)startMonitorIfNeeded {
    if (self.networkReachability) {
        return;
    }
    struct sockaddr_in address;
    memset(&address, 0, sizeof(address));
    address.sin_len = sizeof(address);
    address.sin_family = AF_INET;

    SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithAddress(
        kCFAllocatorDefault, (const struct sockaddr *)&address);
    if (!reachability) {
        self.currentNetworkStatus = NCChatUINetworkStatusNotReachable;
        return;
    }
    SCNetworkReachabilityContext context = {0, (__bridge void *)self, NULL, NULL, NULL};
    BOOL setCallback =
        SCNetworkReachabilitySetCallback(reachability, NCChatUIReachabilityCallback, &context);
    BOOL scheduled = SCNetworkReachabilityScheduleWithRunLoop(reachability, CFRunLoopGetMain(),
                                                              kCFRunLoopCommonModes);
    if (!setCallback || !scheduled) {
        if (scheduled) {
            SCNetworkReachabilityUnscheduleFromRunLoop(reachability, CFRunLoopGetMain(),
                                                       kCFRunLoopCommonModes);
        }
        CFRelease(reachability);
        self.currentNetworkStatus = NCChatUINetworkStatusNotReachable;
        return;
    }
    self.networkReachability = reachability;
    [self refreshCurrentStatusAndNotify:NO];
}

- (void)stopMonitor {
    if (!self.networkReachability) {
        return;
    }
    SCNetworkReachabilityUnscheduleFromRunLoop(self.networkReachability, CFRunLoopGetMain(),
                                               kCFRunLoopCommonModes);
    CFRelease(self.networkReachability);
    self.networkReachability = NULL;
}

- (void)refreshCurrentStatusAndNotify:(BOOL)shouldNotify {
    if (!self.networkReachability) {
        [self startMonitorIfNeeded];
    }
    if (!self.networkReachability) {
        if (self.currentNetworkStatus != NCChatUINetworkStatusNotReachable) {
            self.currentNetworkStatus = NCChatUINetworkStatusNotReachable;
            if (shouldNotify) {
                [self p_notifyStatusChanged:NCChatUINetworkStatusNotReachable];
            }
        }
        return;
    }
    SCNetworkReachabilityFlags flags = 0;
    if (!SCNetworkReachabilityGetFlags(self.networkReachability, &flags)) {
        if (self.currentNetworkStatus != NCChatUINetworkStatusNotReachable) {
            self.currentNetworkStatus = NCChatUINetworkStatusNotReachable;
            if (shouldNotify) {
                [self p_notifyStatusChanged:NCChatUINetworkStatusNotReachable];
            }
        }
        return;
    }
    NCChatUINetworkStatus status = NCChatUINetworkStatusFromReachabilityFlags(flags);
    if (status == self.currentNetworkStatus) {
        return;
    }
    self.currentNetworkStatus = status;
    if (shouldNotify) {
        [self p_notifyStatusChanged:status];
    }
}

- (void)p_handleReachabilityFlagsChanged:(SCNetworkReachabilityFlags)flags {
    NCChatUINetworkStatus status = NCChatUINetworkStatusFromReachabilityFlags(flags);
    NCChatUINetworkStatus oldStatus = self.currentNetworkStatus;
    if (status == oldStatus) {
        return;
    }
    self.currentNetworkStatus = status;
    [self p_notifyStatusChanged:status];
}

- (void)p_notifyStatusChanged:(NCChatUINetworkStatus)status {
    if (self.statusChangedHandler) {
        self.statusChangedHandler(status);
    }
}

@end
