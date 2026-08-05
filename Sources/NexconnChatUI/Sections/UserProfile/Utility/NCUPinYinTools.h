//
//  NCUPinYinTools.h
//  NexconnUserProfile
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NCUPinYinTools : NSObject
+ (NSMutableDictionary *)sortedWithPinYinArray:(NSArray *)array
                                    usingBlock:(NSString * (^)(id obj, NSUInteger idx))block;

/**
 *  Converts Chinese characters to uppercase Pinyin initials.
 *
 *  @param hanZi Input text.
 *
 *  @return Text with each Chinese character replaced by its uppercase Pinyin initial.
 */
+ (NSString *)hanZiToPinYinWithString:(NSString *)hanZi;
@end

NS_ASSUME_NONNULL_END
