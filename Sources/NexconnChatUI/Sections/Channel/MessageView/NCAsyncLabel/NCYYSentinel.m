//
//  YYSentinel.m
//  YYKit <https://github.com/ibireme/YYKit>
//
//  Original copyright (c) 2015 ibireme <ibireme@gmail.com>.
//  Modified by Nexconn in 2026.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "NCYYSentinel.h"
#import <libkern/OSAtomic.h>

@implementation NCYYSentinel {
    int32_t _value;
}

- (int32_t)value {
    return _value;
}

- (int32_t)increase {
    return OSAtomicIncrement32(&_value);
}

@end
