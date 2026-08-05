//
//  NCChannelCollectionViewHeader.m
//  NCChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCChannelCollectionViewHeader.h"

@interface NCChannelCollectionViewHeader ()
@property (nonatomic, strong) UIActivityIndicatorView *indicatorView;
@end

@implementation NCChannelCollectionViewHeader
#pragma mark - Life Cycle
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self addSubview:self.indicatorView];
    }
    return self;
}

#pragma mark - Super Methods
- (void)layoutSubviews {
    self.indicatorView.center = CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2);
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    [_indicatorView setCenter:CGPointMake(frame.size.width / 2, frame.size.height / 2)];
}

#pragma mark - Public Methods
- (void)startAnimating {
    [self.indicatorView startAnimating];
}
- (void)stopAnimating {
    if (self.indicatorView.isAnimating == YES) {
        [self.indicatorView stopAnimating];
    }
}

#pragma mark - Getters and Setters
- (UIActivityIndicatorView *)indicatorView {
    if (!_indicatorView) {
        if (@available(iOS 13.0, *)) {
            _indicatorView =
                [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
        } else {
            _indicatorView =
                [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        }
    }
    return _indicatorView;
}
@end
