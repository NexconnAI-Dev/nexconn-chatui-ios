//
//  NCAlbumTableCell.m
//  NCChatUIExtension
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCAlbumTableCell.h"
#import "NCChatUICommonDefine.h"
#import "NCChatUIConfig.h"

@implementation NCAlbumTableCell
- (void)layoutSubviews {
    [super layoutSubviews];
    self.backgroundColor = NCDynamicColor(@"common_background_color");
    self.imageView.frame = CGRectMake(0, 0, 65, 65);
    self.imageView.center = CGPointMake(self.imageView.frame.size.width / 2, self.imageView.frame.size.height / 2);
    CGRect labelFrame = self.textLabel.frame;
    if ([NCChatUIUtility isRTL]) {
        self.imageView.frame = CGRectMake(self.contentView.frame.size.width - 65, 0, 65, 65);
        labelFrame.origin.x = 0;
        labelFrame.size.width = self.contentView.frame.size.width - self.imageView.frame.size.width - 12;
        self.textLabel.semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;
    } else {
        self.textLabel.semanticContentAttribute = UISemanticContentAttributeForceLeftToRight;

        labelFrame.origin.x = self.imageView.frame.size.width + self.imageView.frame.origin.x + 12;
        labelFrame.size.width = self.contentView.frame.size.width - labelFrame.origin.x;
    }
    self.textLabel.frame = labelFrame;
}

#pragma mark - Public Methods

- (void)configCellWithItem:(NCAlbumModel *)model {
    self.imageView.clipsToBounds = YES;
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;
    UIColor *color = NCDynamicColor(@"text_primary_color");
    if (!color) {
        color = [NCChatUIUtility generateDynamicColor:HEXCOLOR(0x000000) darkColor:[HEXCOLOR(0xffffff) colorWithAlphaComponent:0.9]];
    }
    NSMutableAttributedString *nameString =
        [[NSMutableAttributedString alloc] initWithString:model.albumName
                                               attributes:@{
                                                   NSFontAttributeName : [[NCChatUIConfig defaultConfig].font fontOfSecondLevel],
                                                   NSForegroundColorAttributeName :color
                                               }];
    UIColor *foreColor = NCDynamicColor(@"disabled_color");
    if (!foreColor) {
        foreColor = [NCChatUIUtility generateDynamicColor:[UIColor lightGrayColor] darkColor:HEXCOLOR(0x585858)];
    }
    NSAttributedString *countString = [[NSAttributedString alloc]
        initWithString:[NSString stringWithFormat:@"  (%ld)", model.count]
            attributes:@{
                NSFontAttributeName : [[NCChatUIConfig defaultConfig].font fontOfSecondLevel],
                NSForegroundColorAttributeName :foreColor
            }];
    [nameString appendAttributedString:countString];
    self.textLabel.attributedText = nameString;
    if ([model.asset isKindOfClass:[PHFetchResult class]]) {
        [[NCAssetHelper shareAssetHelper] getThumbnailWithAsset:[model.asset lastObject]
                                                           size:CGSizeMake(65 * SCREEN_SCALE, 65 * SCREEN_SCALE)
                                                         result:^(UIImage *thumbnailImage) {
                                                             dispatch_async(dispatch_get_main_queue(), ^{
                                                                 self.imageView.image = thumbnailImage;
                                                                 self.textLabel.text = @""; // Resetting the text forces UIKit to refresh the image layout.
                                                                 self.textLabel.attributedText = nameString;
                                                             });
                                                         }];
    }
}

@end
