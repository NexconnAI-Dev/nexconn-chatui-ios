//
//  NCGIFImageView.h
//
//
//  Adapted from FLAnimatedImage: https://github.com/Flipboard/FLAnimatedImage
//  Original copyright (c) 2014-2016 Flipboard.
//  Modified by Nexconn in 2026.
//

#import "NCBaseImageView.h"
#import "NCGIFImage.h"

@interface NCGIFImageView : NCBaseImageView

@property (nonatomic, strong) NCGIFImage *animatedImage;

@end
