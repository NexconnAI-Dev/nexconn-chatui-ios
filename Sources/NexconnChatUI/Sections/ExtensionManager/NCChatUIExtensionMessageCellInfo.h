//
//  NCChatUIExtensionMessageCellInfo.h
//  NCIMExtension
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <Foundation/Foundation.h>

/// MessageCell info for extension modules.
@interface NCChatUIExtensionMessageCellInfo : NSObject

@property (nonatomic, copy) NSString *messageType;
@property (nonatomic, strong) Class messageCellClass;

@end
