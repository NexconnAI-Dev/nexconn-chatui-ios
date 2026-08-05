//
//  NCPluginBoardItem.h
//  NCChatUIExtension
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCBaseCollectionViewCell.h"

@interface NCPluginBoardItem : NCBaseCollectionViewCell

@property (nonatomic, copy) NSString *title;

@property (nonatomic, strong) UIImage *normalImage;

@property (nonatomic, strong) UIImage *highlightedImage;

@property (nonatomic, copy) void (^Itemclick)(void);

- (instancetype)initWithTitle:(NSString *)title
                  normalImage:(UIImage *)normalImage
             highlightedImage:(UIImage *)highlightedImage
                          tag:(NSInteger)tag;

- (void)loadView;
@end
