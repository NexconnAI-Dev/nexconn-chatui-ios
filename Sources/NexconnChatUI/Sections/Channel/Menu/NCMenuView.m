//
//  NCMenuView.m
//  PopMenu
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCMenuView.h"
#import "NCChatUICommonDefine.h"
#import "NCMenuItem.h"
#import "NCMenuItemView.h"

@interface NCMenuView ()

@property (nonatomic, strong, readwrite) NSArray<NCMenuItem *> *menuItems;
@property (nonatomic, strong) UIStackView *mainStackView;
@property (nonatomic, copy) void (^actionHandler)(NCMenuItem *menuItem, NSInteger index);
@property (nonatomic, strong) NSLayoutConstraint *widthConstraint;

@end

@implementation NCMenuView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupDefaultValues];
        [self setupUI];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self setupDefaultValues];
        [self setupUI];
    }
    return self;
}

- (void)setupDefaultValues {
    _maxItemsPerRow = 5;
    _itemSpacing = 0;
    _rowSpacing = 0;
}

- (void)setupUI {
    // Create the vertical stack that contains menu rows.
    _mainStackView = [[UIStackView alloc] init];
    _mainStackView.axis = UILayoutConstraintAxisVertical;
    _mainStackView.alignment = UIStackViewAlignmentFill;
    _mainStackView.distribution = UIStackViewDistributionFill;
    _mainStackView.spacing = self.rowSpacing;
    _mainStackView.translatesAutoresizingMaskIntoConstraints = NO;

    [self addSubview:_mainStackView];

    // Outer padding
    CGFloat padding = 10;

    // Pin the stack within the menu padding.
    [NSLayoutConstraint activateConstraints:@[
        [_mainStackView.topAnchor constraintEqualToAnchor:self.topAnchor constant:padding],
        [_mainStackView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-padding],
        [_mainStackView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:padding],
        [_mainStackView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor
                                                      constant:-padding]
    ]];

    // Configure the background and corner radius.
    self.backgroundColor = NCDynamicColor(@"pop_layer_background_color");
    self.layer.cornerRadius = 12;
    self.layer.masksToBounds = NO;

    // Add the menu shadow.
    self.layer.shadowColor = [UIColor blackColor].CGColor;
    self.layer.shadowOffset = CGSizeMake(0, 2);
    self.layer.shadowOpacity = 0.15;
    self.layer.shadowRadius = 8;
}

- (void)configureWithMenuItems:(NSArray<NCMenuItem *> *)menuItems
                 actionHandler:(void (^)(NCMenuItem *menuItem, NSInteger index))actionHandler {
    self.menuItems = menuItems;
    self.actionHandler = actionHandler;

    // Remove the previous menu rows.
    for (UIView *subview in self.mainStackView.arrangedSubviews) {
        [self.mainStackView removeArrangedSubview:subview];
        [subview removeFromSuperview];
    }

    if (menuItems.count == 0) {
        return;
    }

    // Use a fixed width for each menu item.
    CGFloat itemWidth = 60; // Fixed menu-item width

    // Group menu items into rows.
    NSInteger totalItems = menuItems.count;
    NSInteger numberOfRows = (totalItems + self.maxItemsPerRow - 1) / self.maxItemsPerRow;

    for (NSInteger row = 0; row < numberOfRows; row++) {
        NSInteger startIndex = row * self.maxItemsPerRow;
        NSInteger endIndex = MIN(startIndex + self.maxItemsPerRow, totalItems);
        NSInteger itemsInThisRow = endIndex - startIndex;

        // Create the horizontal stack for this row.
        UIStackView *rowStackView = [[UIStackView alloc] init];
        rowStackView.axis = UILayoutConstraintAxisHorizontal;
        rowStackView.alignment = UIStackViewAlignmentFill; // Let row content determine its height.
        rowStackView.distribution = UIStackViewDistributionFill; // Preserve explicit item widths.
        rowStackView.spacing = self.itemSpacing;
        rowStackView.translatesAutoresizingMaskIntoConstraints = NO;

        // Add menu-item views to the row.
        for (NSInteger i = startIndex; i < endIndex; i++) {
            NCMenuItem *menuItem = menuItems[i];
            NCMenuItemView *itemView = [[NCMenuItemView alloc] init];
            itemView.translatesAutoresizingMaskIntoConstraints = NO;
            [itemView configureWithMenuItem:menuItem];

            // Constrain the item to the fixed width.
            [itemView.widthAnchor constraintEqualToConstant:itemWidth].active = YES;

            // Forward item selection with its original index.
            NSInteger index = i;
            itemView.actionHandler = ^{
              if (actionHandler) {
                  actionHandler(menuItem, index);
              }
            };

            [rowStackView addArrangedSubview:itemView];
        }

        // Add a flexible trailing spacer to left-align an incomplete later row.
        if (itemsInThisRow < self.maxItemsPerRow && numberOfRows > 1 && row > 0) {
            UIView *spacerView = [[UIView alloc] init];
            spacerView.backgroundColor = [UIColor clearColor];
            spacerView.translatesAutoresizingMaskIntoConstraints = NO;

            // Give the spacer the lowest hugging and compression resistance so it fills the
            // remaining width.
            [spacerView setContentHuggingPriority:UILayoutPriorityDefaultLow
                                          forAxis:UILayoutConstraintAxisHorizontal];
            [spacerView setContentCompressionResistancePriority:UILayoutPriorityDefaultLow
                                                        forAxis:UILayoutConstraintAxisHorizontal];

            [rowStackView addArrangedSubview:spacerView];
        }

        [self.mainStackView addArrangedSubview:rowStackView];
    }

    // Apply the current row spacing.
    self.mainStackView.spacing = self.rowSpacing;

    // Size the menu from the number of items in its first, fullest row.
    CGFloat padding = 10;
    NSInteger itemsInFirstRow = MIN(self.maxItemsPerRow, totalItems);
    CGFloat totalWidth =
        itemsInFirstRow * itemWidth + (itemsInFirstRow - 1) * self.itemSpacing + padding * 2;

    // Deactivate the previous width constraint.
    if (self.widthConstraint) {
        self.widthConstraint.active = NO;
    }

    // Install the updated width constraint.
    self.widthConstraint = [self.widthAnchor constraintEqualToConstant:totalWidth];
    self.widthConstraint.active = YES;
}

- (void)setItemSpacing:(CGFloat)itemSpacing {
    _itemSpacing = itemSpacing;
    for (UIView *subview in self.mainStackView.arrangedSubviews) {
        if ([subview isKindOfClass:[UIStackView class]]) {
            ((UIStackView *)subview).spacing = itemSpacing;
        }
    }
}

- (void)setRowSpacing:(CGFloat)rowSpacing {
    _rowSpacing = rowSpacing;
    self.mainStackView.spacing = rowSpacing;
}

@end
