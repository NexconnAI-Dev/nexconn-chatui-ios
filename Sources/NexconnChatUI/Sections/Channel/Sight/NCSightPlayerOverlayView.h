//
//  NCSightPlayerOverlayView.h
//  NCChatUIExtension
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCSightPlayerOverlay.h"
#import "NCSightPlayerTransport.h"
#import <UIKit/UIKit.h>

@interface NCSightPlayerOverlayView : UIView <NCSightPlayerTransport, NCSightPlayerOverlay>

@property (weak, nonatomic) id<NCSightTransportDelegate, NCSightPlayerOverlay> delegate;

@end
