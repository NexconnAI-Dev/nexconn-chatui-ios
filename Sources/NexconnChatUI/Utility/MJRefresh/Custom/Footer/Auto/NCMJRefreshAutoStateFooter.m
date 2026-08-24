//
//  NCMJRefreshAutoStateFooter.m
//  NCMJRefreshExample
//
//  Adapted from MJRefresh: https://github.com/CoderMJLee/MJRefresh
//  Original copyright (c) 2013-2015 MJRefresh.
//  Modified by Nexconn in 2026.
//

#import "NCMJRefreshAutoStateFooter.h"

@interface NCMJRefreshAutoStateFooter () {
    /** Label displaying the refresh state. */
    __unsafe_unretained UILabel *_stateLabel;
}
/** Titles keyed by refresh state. */
@property (strong, nonatomic) NSMutableDictionary *stateTitles;
@end

@implementation NCMJRefreshAutoStateFooter
#pragma mark - Lazy Loading
- (NSMutableDictionary *)stateTitles {
    if (!_stateTitles) {
        self.stateTitles = [NSMutableDictionary dictionary];
    }
    return _stateTitles;
}

- (UILabel *)stateLabel {
    if (!_stateLabel) {
        [self addSubview:_stateLabel = [UILabel ncmj_label]];
    }
    return _stateLabel;
}

#pragma mark - Public Methods
- (void)setTitle:(NSString *)title forState:(NCMJRefreshState)state {
    if (title == nil)
        return;
    self.stateTitles[@(state)] = title;
    self.stateLabel.text = self.stateTitles[@(self.state)];
}

#pragma mark - Private Methods
- (void)stateLabelClick {
    if (self.state == NCMJRefreshStateIdle) {
        [self beginRefreshing];
    }
}

#pragma mark - Overrides
- (void)prepare {
    [super prepare];

    // Initialize spacing.
    self.labelLeftInset = NCMJRefreshLabelLeftInset;

    // Observe label text changes.
    self.stateLabel.userInteractionEnabled = YES;
    [self.stateLabel addGestureRecognizer:[[UITapGestureRecognizer alloc]
                                              initWithTarget:self
                                                      action:@selector(stateLabelClick)]];
}

- (void)placeSubviews {
    [super placeSubviews];

    if (self.stateLabel.constraints.count)
        return;

    // Position the state label.
    self.stateLabel.frame = self.bounds;
}

- (void)setState:(NCMJRefreshState)state {
    NCMJRefreshCheckState

        if (self.isRefreshingTitleHidden && state == NCMJRefreshStateRefreshing) {
        self.stateLabel.text = nil;
    }
    else {
        self.stateLabel.text = self.stateTitles[@(state)];
    }
}
@end
