//
//  NCPhotoPickImageView.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCPhotoPickImageView.h"
#import "NCChatUICommonDefine.h"
#import "NCChatUIConfig.h"
#import <MobileCoreServices/UTCoreTypes.h>
#import "NCBaseImageView.h"
#import "NCSemanticContext.h"
#import "NCBaseLabel.h"
//#import <QuartzCore/QuartzCore.h>
typedef NS_ENUM(NSUInteger, NCPotoPickStatus) {
    NCPotoPickStatusNormal = 0,
    NCPotoPickStatusSelect,
};
@interface NCPhotoPickImageView()

@property (nonatomic, strong) UIView *maskCoverView;
@property (nonatomic, strong) UIView *typeBackgroundView;

@property (nonatomic, strong) UILabel *gifLabel;

@property (nonatomic, strong) NCBaseLabel *durationLabel;
@property (nonatomic, strong) NCBaseImageView *videoIcon;
@end

@implementation NCPhotoPickImageView

- (void)setPhotoModel:(NCAssetModel *)model{
    if (model.mediaType == PHAssetMediaTypeVideo && NSClassFromString(@"NCSightCapturer")) {
        [self showSightTypeView];
        self.durationLabel.text = model.durationText;
    } else if([[model.asset valueForKey:@"uniformTypeIdentifier"]
               isEqualToString:(__bridge NSString *)kUTTypeGIF]){
        [self showGifTypeView];
    } else {
        [self hiddenTypeView];
    }
    [self setPickStatus:(model.isSelect ? NCPotoPickStatusSelect : NCPotoPickStatusNormal)];
}

#pragma mark - privite
- (void)setPickStatus:(NCPotoPickStatus)pickStatus{
    switch (pickStatus) {
        case NCPotoPickStatusNormal:
            _maskCoverView.backgroundColor = [UIColor clearColor];
            break;
        case NCPotoPickStatusSelect:
            _maskCoverView.backgroundColor = NCMASKCOLOR(0x000000, 0.4);
            break;
        default:
            break;
    }
}

- (void)hiddenTypeView{
    self.typeBackgroundView.hidden = YES;
    self.gifLabel.hidden = YES;
    self.videoIcon.hidden = YES;
    self.durationLabel.hidden = YES;
}

- (void)showSightTypeView{
    self.typeBackgroundView.hidden = NO;
    self.gifLabel.hidden = YES;
    self.videoIcon.hidden = NO;
    self.durationLabel.hidden = NO;
}

- (void)showGifTypeView{
    self.typeBackgroundView.hidden = NO;
    self.gifLabel.hidden = NO;
    self.videoIcon.hidden = YES;
    self.durationLabel.hidden = YES;
}

#pragma mark - getter
- (UIView *)maskCoverView{
    if (!_maskCoverView) {
        UIView *view = [[UIView alloc] initWithFrame:self.bounds];
        [self addSubview:view];
        _maskCoverView = view;
    }
    return _maskCoverView;
}

- (UIView *)typeBackgroundView{
    if (!_typeBackgroundView) {
        _typeBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, self.bounds.size.height-28, self.bounds.size.width, 28)];
        _typeBackgroundView.hidden = YES;
        // Create a gradient layer sized to the view.
        CAGradientLayer *gradientLayer = [CAGradientLayer layer];
        gradientLayer.frame = _typeBackgroundView.bounds;
        // Add the gradient layer to the view's backing layer.
        [_typeBackgroundView.layer addSublayer:gradientLayer];
        
        // Set the gradient start and end points in the 0-1 coordinate range.
        gradientLayer.startPoint = CGPointMake(0, 0);
        gradientLayer.endPoint = CGPointMake(0, 1);
        
        // Set the gradient colors.
        gradientLayer.colors = @[(__bridge id)NCMASKCOLOR(0xffffff,0).CGColor,
                                 (__bridge id)NCMASKCOLOR(0x696969,0.2).CGColor,
                                 (__bridge id)NCMASKCOLOR(0x696969,0.6).CGColor];
        
        // Set the gradient stops in the 0-1 range.
        gradientLayer.locations = @[@(0.35f), @(0.7f), @(1.0f)];
        [self addSubview:_typeBackgroundView];
    }
    return _typeBackgroundView;
}

- (NCBaseLabel *)durationLabel {
    if (!_durationLabel) {
        CGRect frame = CGRectMake(33, 9.5, self.typeBackgroundView.frame.size.width-33, 14);
        if ([NCChatUIUtility isRTL]) {
            frame = CGRectMake(0, 9.5, self.typeBackgroundView.frame.size.width-33, 14);
        }
        _durationLabel = [[NCBaseLabel alloc] initWithFrame:frame];
        _durationLabel.textColor = NCDynamicColor(@"control_title_white_color");
        _durationLabel.font = [[NCChatUIConfig defaultConfig].font fontOfAssistantLevel];
        [self.typeBackgroundView addSubview:_durationLabel];
    }
    return _durationLabel;
}

- (NCBaseImageView *)videoIcon {
    if (!_videoIcon) {
        CGRect frame = (CGRect){6, self.typeBackgroundView.frame.size.height-21, 19, 19};
        UIImage *image = NCDynamicImage(@"photo_picker_cell_video_img");
        if ([NCChatUIUtility isRTL]) {
            frame =(CGRect){self.typeBackgroundView.frame.size.width - 6-19, self.typeBackgroundView.frame.size.height-21, 19, 19};
        }
        _videoIcon = [[NCBaseImageView alloc] initWithFrame:frame];
        _videoIcon.image = [NCSemanticContext imageflippedForRTL:image];
        [self.typeBackgroundView addSubview:_videoIcon];
    }
    return _videoIcon;
}

- (NCBaseLabel *)gifLabel {
    if (!_gifLabel) {
        CGRect frame = CGRectMake(6, 9.5, self.typeBackgroundView.frame.size.width-6, 14);
        if ([NCChatUIUtility isRTL]) {
            frame =CGRectMake(0, 9.5, self.typeBackgroundView.frame.size.width-6, 14);
        }
        _gifLabel = [[NCBaseLabel alloc] initWithFrame:frame];
        _gifLabel.textColor = NCDynamicColor(@"pop_layer_background_color");
        _gifLabel.font = [[NCChatUIConfig defaultConfig].font fontOfAssistantLevel];
        _gifLabel.text = @"GIF";
        [self.typeBackgroundView addSubview:_gifLabel];
    }
    return _gifLabel;
}
@end
