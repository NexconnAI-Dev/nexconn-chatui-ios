//
//  NCMediaManager.h
//  NexconnChatUI
//
//  Created by Yudong Yang on 2018/9/20.
//  Copyright © 2018 NCChatUI. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^NCDownsizeImageBlock)(UIImage *_Nullable image, BOOL doNothing);

NS_ASSUME_NONNULL_BEGIN

@interface NCMediaManager : NSObject
+ (NCMediaManager *)sharedManager;

@property (nonatomic, copy) NCDownsizeImageBlock progressBlock;

- (void)downsizeImage:(UIImage *)image
      completionBlock:(NCDownsizeImageBlock)imageBlock
        progressBlock:(NCDownsizeImageBlock)progressBlock;

/**
 Downsizes image resolution synchronously.

 - Parameter image: Original image.
 - Returns: Compressed image.
 */
- (UIImage *)downsizeImage:(UIImage *)image;

@end

NS_ASSUME_NONNULL_END
