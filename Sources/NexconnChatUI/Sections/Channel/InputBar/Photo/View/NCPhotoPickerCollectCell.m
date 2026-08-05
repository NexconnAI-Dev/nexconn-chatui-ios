//
//  NCPhotoPickerCollectCell.m
//  NCChatUIExtension
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCPhotoPickerCollectCell.h"
#import "NCAssetModel.h"
#import "NCChatUICommonDefine.h"
#import "NCAssetHelper.h"
#import <MobileCoreServices/UTCoreTypes.h>
#import "NCPhotoPickImageView.h"
#import "NCAlertView.h"
#import "NCBaseButton.h"
#define WIDTH (([UIScreen mainScreen].bounds.size.width - 20) / 4)
#define SIZE CGSizeMake(WIDTH, WIDTH)

@interface NCPhotoPickerCollectCell ()
@property (nonatomic, strong) NCAssetModel *assetModel;
/**
 *  Displays the image.
 */
@property (nonatomic, strong) NCPhotoPickImageView *photoImageView;
/**
 *  Selection thumbnail shown for the cell.
 */
@property (nonatomic, strong) NCBaseButton *selectbutton;

@property (nonatomic, weak) id<NCPhotoPickerCollectCellDelegate> delegate;

@property (nonatomic, strong) UIImage *thumbnailImage;

@end
@implementation NCPhotoPickerCollectCell

#pragma mark - Init
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setupSubviews];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.assetModel = nil;
    self.photoImageView.image = nil;
    self.selectbutton.selected = NO;
}

#pragma mark - Public Methods
- (void)configPickerCellWithItem:(NCAssetModel *)model delegate:(id<NCPhotoPickerCollectCellDelegate>)delegate{
    self.assetModel = model;
    self.delegate = delegate;
    [self.photoImageView setPhotoModel:model];
    _selectbutton.selected = model.isSelect;
    
    NSString *modelIdentifier = [[NCAssetHelper shareAssetHelper] getAssetIdentifier:model.asset];
    if([self.representedAssetIdentifier isEqualToString:modelIdentifier]) {
        if(self.thumbnailImage) {
            self.photoImageView.image = self.thumbnailImage;
            return ;
        }
    }else {
        self.photoImageView.image = nil;
    }
    self.representedAssetIdentifier = modelIdentifier;
    
    // Fetch the thumbnail.
    [[NCAssetHelper shareAssetHelper]
        getThumbnailWithAsset:model.asset
                         size:CGSizeMake((WIDTH * SCREEN_SCALE), (WIDTH * SCREEN_SCALE))
                       result:^(UIImage *thumbnailImage) {
        dispatch_main_async_safe(^{
            self.thumbnailImage = thumbnailImage;
            self.photoImageView.image = thumbnailImage;
        });
    }];
}

#pragma mark - Private Methods

- (void)onSelectButtonClick:(UIButton *)sender {
    if(!self.assetModel) {
        return;
    }
    if(self.assetModel.mediaType == PHAssetMediaTypeVideo && NSClassFromString(@"NCSightCapturer")) {
        [[NCAssetHelper shareAssetHelper] getOriginVideoWithAsset:self.assetModel.asset result:^(AVAsset *avAsset, NSDictionary *info, NSString *imageIdentifier) {
            if (![[[NCAssetHelper shareAssetHelper] getAssetIdentifier:self.assetModel.asset] isEqualToString:imageIdentifier]) {
                return;
            }
            dispatch_main_async_safe(^{
                if (!avAsset) {
                    if(self.delegate && [self.delegate respondsToSelector:@selector(downloadFailFromiCloud)]) {
                        [self.delegate downloadFailFromiCloud];
                    }
                    return;
                }
                [self changeMessageModelState:sender.selected
                                   assetModel:self.assetModel];
            });
        } progressHandler:^(double progress, NSError * _Nonnull error, BOOL * _Nonnull stop, NSDictionary * _Nonnull info) {
            
        }];
        return;
    }
    [[NCAssetHelper shareAssetHelper]
        getOriginImageDataWithAsset:self.assetModel
                             result:^(NSData *imageData, NSDictionary *info, NCAssetModel *assetModel) {
                                 if (![self.representedAssetIdentifier isEqualToString:[[NCAssetHelper shareAssetHelper]
                                 getAssetIdentifier:assetModel.asset]]) {
                                     return;
                                 }
        
                                 dispatch_main_async_safe(^{
                                     if(!imageData || [self.assetModel isVideoAssetInvalid]) {
                                         if(self.delegate && [self.delegate respondsToSelector:@selector(downloadFailFromiCloud)]) {
                                             [self.delegate downloadFailFromiCloud];
                                         }
                                         return;
                                     }
                                     self.assetModel.imageSize = imageData.length;
                                     [self changeMessageModelState:sender.selected assetModel:assetModel];
                                     
                                 });
                             }
                    progressHandler:^(double progress, NSError * _Nonnull error, BOOL * _Nonnull stop, NSDictionary * _Nonnull info) {
        
    }];
}

- (void)changeMessageModelState:(BOOL)originState assetModel:(NCAssetModel *)assetModel {
    bool currentState = NO;
    if(self.delegate && [self.delegate respondsToSelector:@selector(canChangeSelectedState:)]) {
        currentState = [self.delegate canChangeSelectedState:assetModel];
    }
    if (originState != currentState) {
        assetModel.thumbnailImage = self.thumbnailImage;
        if(self.delegate && [self.delegate respondsToSelector:@selector(didChangeSelectedState:model:)]) {
            [self.delegate didChangeSelectedState:currentState model:assetModel];
        }
    }
    self.selectbutton.selected = currentState;
}

- (void)animationWithLayer:(CALayer *)layer {
    NSNumber *animationScale1 = @(0.7);
    NSNumber *animationScale2 = @(0.92);
    [UIView animateWithDuration:0.15
        delay:0
        options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseInOut
        animations:^{
            [layer setValue:animationScale1 forKeyPath:@"transform.scale"];
        }
        completion:^(BOOL finished) {
            [UIView animateWithDuration:0.15
                delay:0
                options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseInOut
                animations:^{
                    [layer setValue:animationScale2 forKeyPath:@"transform.scale"];
                }
                completion:^(BOOL finished) {
                    [UIView animateWithDuration:0.1
                                          delay:0
                                        options:UIViewAnimationOptionBeginFromCurrentState |
                                                UIViewAnimationOptionCurveEaseInOut
                                     animations:^{
                                         [layer setValue:@(1.0) forKeyPath:@"transform.scale"];
                                     }
                                     completion:nil];
                }];
        }];
}

- (void)setupSubviews{
    [self.contentView addSubview:self.photoImageView];
    [self.contentView addSubview:self.selectbutton];

    [_selectbutton setTranslatesAutoresizingMaskIntoConstraints:NO];

    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-2-[_selectbutton(44)]"
                                                                 options:kNilOptions
                                                                 metrics:nil
                                                                   views:NSDictionaryOfVariableBindings(_selectbutton)]];  
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[_selectbutton(44)]-2-|"
                                                                 options:kNilOptions
                                                                 metrics:nil
                                                                   views:NSDictionaryOfVariableBindings(_selectbutton)]];
}

- (void)didTapPhotoImageView {
    if(self.delegate && [self.delegate respondsToSelector:@selector(didTapPickerCollectCell:)]) {
        [self.delegate didTapPickerCollectCell:self.assetModel];
    }
    
}

#pragma mark - Getters and Setters


- (NCPhotoPickImageView *)photoImageView{
    if (!_photoImageView) {
        _photoImageView = [[NCPhotoPickImageView alloc] initWithFrame:self.bounds];
        _photoImageView.contentMode = UIViewContentModeScaleAspectFill;
        UITapGestureRecognizer *tap =
                    [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapPhotoImageView)];
        tap.numberOfTapsRequired = 1;
        tap.numberOfTouchesRequired = 1;
        [_photoImageView addGestureRecognizer:tap];
        _photoImageView.userInteractionEnabled = YES;
        _photoImageView.clipsToBounds = YES;
    }
    return _photoImageView;;
}

- (NCBaseButton *)selectbutton{
    if (!_selectbutton) {
        _selectbutton = [[NCBaseButton alloc] initWithFrame:CGRectZero];
        [_selectbutton addTarget:self
                          action:@selector(onSelectButtonClick:)
                forControlEvents:UIControlEventTouchUpInside];
        [_selectbutton setImage:NCDynamicImage(@"media_file_state_uncheck_img") forState:UIControlStateNormal];
        [_selectbutton setImage:NCDynamicImage(@"media_file_state_check_img")
                       forState:UIControlStateSelected];
        if ([NCChatUIUtility isRTL]) {
            _selectbutton.contentEdgeInsets = UIEdgeInsetsMake(0, 0 , 28, 28);
        } else {
            _selectbutton.contentEdgeInsets = UIEdgeInsetsMake(0, 28 , 28, 0);
        }
    }
    return _selectbutton;
}
@end
