//
//  NCUserProfileDefine.h
//  NexconnUserProfile
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#ifndef NCUserProfileDefine_h
#define NCUserProfileDefine_h

/// Selection state
typedef NS_ENUM(NSUInteger, NCSelectState) {
    /// Unselected
    NCSelectStateUnselect = 0,
    /// Selected
    NCSelectStateSelect = 1,
    /// Disabled (not selectable)
    NCSelectStateDisable = 2,
};

#endif /* NCUserProfileDefine_h */
