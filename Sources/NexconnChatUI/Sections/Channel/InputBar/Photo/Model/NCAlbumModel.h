//
//  NCAlbumModel.h
//  NCChatUIExtension
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface NCAlbumModel : NSObject

@property (nonatomic, strong) NSString *albumName;

@property (nonatomic, assign) long count;

@property (nonatomic, strong) id asset;

+ (NCAlbumModel *)modelWithAsset:(id)asset name:(NSString *)string count:(long)count;

@end
