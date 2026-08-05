//
//  NCEmoticonTabSource.h
//  NCExtensionKit
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <UIKit/UIKit.h>

/// Data source protocol for custom emoticon tab views.
@protocol NCEmoticonTabSource <NSObject>

/// @return The unique identifier string for this emoticon tab.
- (NSString *)identify;

/// @return The icon image for this emoticon tab.
- (UIImage *)image;

/*!
 Number of pages in the emoticon tab
 @return Number of pages in the emoticon tab
 */
- (int)pageCount;
/*!
 Emoticon view for the page at the given index

 @return Emoticon view for the page at the given index
  The returned view size must equal contentViewSize (width = screen width, height = 186)
 */
- (UIView *)loadEmoticonView:(NSString *)identify index:(int)index;
@end
