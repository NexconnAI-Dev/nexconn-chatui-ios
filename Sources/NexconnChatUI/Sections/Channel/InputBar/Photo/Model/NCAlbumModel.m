//
//  NCAlbumModel.m
//  NCChatUIExtension
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCAlbumModel.h"

@implementation NCAlbumModel
+ (NCAlbumModel *)modelWithAsset:(id)asset name:(NSString *)string count:(long)count {
    NCAlbumModel *model = [[NCAlbumModel alloc] init];
    model.asset = asset;
    model.albumName = string ?: @"";
    model.count = count;
    return model;
}
@end
