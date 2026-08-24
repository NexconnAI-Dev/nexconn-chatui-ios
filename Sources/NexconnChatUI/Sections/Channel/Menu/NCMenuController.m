//
//  NCMenuViewController.m
//  PopMenu
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCMenuController.h"
#import "NCChatUICommonDefine.h"
#import "NCChatUIUtility.h"
#import "NCMenuItem.h"
#import "NCMenuView.h"

// Triangular pointer view
@interface NCArrowView : UIView
@property (nonatomic, assign)
    BOOL pointingUp; // YES points toward the top edge; NO points toward the bottom edge.
@end

@implementation NCArrowView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.opaque = NO;
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    UIColor *color = NCDynamicColor(@"pop_layer_background_color");
    // Match the menu background color.
    if (color) {
        [color setFill];
    }

    // Draw the pointer triangle.
    CGFloat width = rect.size.width;
    CGFloat height = rect.size.height;

    CGContextBeginPath(context);

    if (self.pointingUp) {
        // Triangle with its tip on the top edge
        CGContextMoveToPoint(context, width / 2, 0);     // Tip
        CGContextAddLineToPoint(context, 0, height);     // Bottom left
        CGContextAddLineToPoint(context, width, height); // Bottom right
    } else {
        // Triangle with its tip on the bottom edge
        CGContextMoveToPoint(context, 0, 0);                 // Top left
        CGContextAddLineToPoint(context, width, 0);          // Top right
        CGContextAddLineToPoint(context, width / 2, height); // Tip
    }

    CGContextClosePath(context);
    CGContextFillPath(context);
}

@end

// Container for the menu and pointer
@interface NCMenuHolderView : UIView
@property (nonatomic, strong) NCMenuView *menuView;
@property (nonatomic, strong) NCArrowView *arrowView;
@property (nonatomic, assign) BOOL arrowPointingUp;
@end

@implementation NCMenuHolderView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

@end

@interface NCMenuController ()

@property (nonatomic, assign, readwrite, getter=isMenuVisible) BOOL menuVisible;
@property (nonatomic, strong)
    UIView *overlayView; // Transparent overlay that intercepts background taps
@property (nonatomic, strong) NCMenuHolderView *containerView;
@property (nonatomic, copy) void (^actionHandler)(NCMenuItem *menuItem, NSInteger index);
@property (nonatomic, assign) CGRect keyboardFrame;
@property (nonatomic, assign, getter=isKeyboardVisible) BOOL keyboardVisible;

@end

@implementation NCMenuController

+ (instancetype)sharedMenuController {
    static NCMenuController *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _menuVisible = NO;
        _keyboardFrame = CGRectZero;
        _keyboardVisible = NO;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWillChangeFrame:)
                                                     name:UIKeyboardWillChangeFrameNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWillHide:)
                                                     name:UIKeyboardWillHideNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)showMenuFromView:(UIView *)targetView
               menuItems:(NSArray<NCMenuItem *> *)menuItems
           actionHandler:(void (^)(NCMenuItem *menuItem, NSInteger index))actionHandler {
    NSMutableArray *items = [NSMutableArray array];
    for (UIMenuItem *item in menuItems) {
        if ([item isKindOfClass:[NCMenuItem class]]) {
            [items addObject:item];
        } else if ([item isKindOfClass:[UIMenuItem class]]) {
            NCMenuItem *obj = [NCMenuItem menuItemWithItem:item];
            if (obj) {
                [items addObject:obj];
            }
        }
    }
    [self showMenuFromRect:targetView.bounds
                    inView:targetView
                 menuItems:items
             actionHandler:actionHandler];
}

- (void)showMenuFromRect:(CGRect)targetRect
                  inView:(UIView *)targetView
               menuItems:(NSArray<NCMenuItem *> *)menuItems
           actionHandler:(void (^)(NCMenuItem *menuItem, NSInteger index))actionHandler {
    if (menuItems.count == 0) {
        return;
    }

    // Dismiss any existing menu.
    [self hideMenuAnimated:NO];

    void (^menuActionHandler)(NCMenuItem *menuItem, NSInteger index) = [actionHandler copy];
    self.actionHandler = menuActionHandler;

    // Resolve the window containing the target view.
    UIWindow *currentWindow = targetView.window;
    if (!currentWindow) {
        currentWindow = [NCChatUIUtility getWindowForView:targetView];
    }
    if (!currentWindow) {
        currentWindow = [UIApplication sharedApplication].windows.firstObject;
    }
    if (!currentWindow) {
        return;
    }

    // Create the tap-intercepting overlay.
    [self createOverlayViewInWindow:currentWindow];

    // Create the menu view.
    NCMenuView *menuView = [[NCMenuView alloc] init];
    menuView.translatesAutoresizingMaskIntoConstraints = NO;
    menuView.maxItemsPerRow = 5;
    menuView.itemSpacing = 0;
    menuView.rowSpacing = 0;

    __weak typeof(self) weakSelf = self;
    [menuView configureWithMenuItems:menuItems
                       actionHandler:^(NCMenuItem *menuItem, NSInteger index) {
                         __strong typeof(weakSelf) strongSelf = weakSelf;
                         if (menuActionHandler) {
                             menuActionHandler(menuItem, index);
                         } else if (strongSelf.actionHandler) {
                             strongSelf.actionHandler(menuItem, index);
                         }
                         [strongSelf hideMenuAnimated:YES];
                       }];

    // Attach the menu to a temporary container so Auto Layout can measure it.
    UIView *tempContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1000, 1000)];
    [tempContainer addSubview:menuView];

    // Resolve the menu layout.
    [menuView setNeedsLayout];
    [menuView layoutIfNeeded];

    // Read the compressed layout size.
    CGSize menuSize = [menuView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];

    // Detach the measured menu from the temporary container.
    [menuView removeFromSuperview];

    // Convert the target rectangle into window coordinates.
    CGRect targetRectInWindow = [targetView convertRect:targetRect toView:currentWindow];

    // Calculate the menu position.
    CGFloat arrowHeight = 8;
    CGFloat arrowWidth = 16;
    CGFloat padding = 10;

    CGRect visibleBounds = [self visibleBoundsForWindow:currentWindow];
    CGFloat menuWidth = menuSize.width;
    CGFloat menuHeight = menuSize.height;

    CGFloat containerHeight = menuHeight + arrowHeight;
    CGPoint arrowAnchorPoint = [self arrowAnchorPointForTargetRect:targetRectInWindow
                                                     visibleBounds:visibleBounds];

    // Prefer the space above the target when the full container fits there; otherwise use the space
    // below.
    BOOL preferAbove = (CGRectGetMinY(targetRectInWindow) - containerHeight - padding) >
                       (CGRectGetMinY(visibleBounds) + padding);

    CGFloat menuX = arrowAnchorPoint.x - menuWidth / 2;
    CGFloat containerY;

    if (preferAbove) {
        containerY = CGRectGetMinY(targetRectInWindow) - containerHeight - padding;
    } else {
        containerY = CGRectGetMaxY(targetRectInWindow) + padding;
    }

    // Clamp the container to the window area that remains visible above the keyboard.
    CGFloat minX = CGRectGetMinX(visibleBounds) + padding;
    CGFloat maxX = CGRectGetMaxX(visibleBounds) - padding;
    if (menuWidth >= maxX - minX) {
        menuX = minX;
    } else if (menuX < minX) {
        menuX = minX;
    } else if (menuX + menuWidth > maxX) {
        menuX = maxX - menuWidth;
    }

    CGFloat minY = CGRectGetMinY(visibleBounds) + padding;
    CGFloat maxY = CGRectGetMaxY(visibleBounds) - padding;
    if (containerY < minY) {
        containerY = minY;
    } else if (containerY + containerHeight > maxY) {
        containerY = maxY - containerHeight;
    }

    // Create the final menu container.
    self.containerView = [[NCMenuHolderView alloc]
        initWithFrame:CGRectMake(menuX, containerY, menuWidth, containerHeight)];
    BOOL arrowPointingUp = [self arrowShouldPointUpForTargetRect:targetRectInWindow
                                                  containerFrame:self.containerView.frame
                                                   visibleBounds:visibleBounds];
    self.containerView.arrowPointingUp = arrowPointingUp;

    // Point toward the target based on the final clamped container position.
    NCArrowView *arrowView = [[NCArrowView alloc] init];
    arrowView.pointingUp = arrowPointingUp;

    CGFloat arrowX = arrowAnchorPoint.x - menuX - arrowWidth / 2;
    arrowX = MAX(
        10, MIN(arrowX, menuWidth - arrowWidth - 10)); // Keep the pointer inside the menu edges.

    // Position the pointer on the edge nearest the target. The measured menu now uses explicit
    // frames.
    menuView.translatesAutoresizingMaskIntoConstraints = YES;

    if (arrowPointingUp) {
        arrowView.frame = CGRectMake(arrowX, 0, arrowWidth, arrowHeight);
        menuView.frame = CGRectMake(0, arrowHeight, menuWidth, menuHeight);
    } else {
        arrowView.frame = CGRectMake(arrowX, menuHeight, arrowWidth, arrowHeight);
        menuView.frame = CGRectMake(0, 0, menuWidth, menuHeight);
    }

    self.containerView.menuView = menuView;
    self.containerView.arrowView = arrowView;

    [self.containerView addSubview:menuView];
    [self.containerView addSubview:arrowView];

    // Add the container to the overlay.
    [self.overlayView addSubview:self.containerView];
    self.menuVisible = YES;

    // Animate the menu into view.
    self.containerView.alpha = 0;
    self.containerView.transform = CGAffineTransformMakeScale(0.8, 0.8);

    UIViewAnimationOptions showAnimationOptions = UIViewAnimationOptionCurveEaseOut |
                                                  UIViewAnimationOptionAllowUserInteraction |
                                                  UIViewAnimationOptionBeginFromCurrentState;
    [UIView animateWithDuration:0.25
                          delay:0
         usingSpringWithDamping:0.8
          initialSpringVelocity:0
                        options:showAnimationOptions
                     animations:^{
                       self.containerView.alpha = 1;
                       self.containerView.transform = CGAffineTransformIdentity;
                     }
                     completion:nil];
}

- (void)hideMenuAnimated:(BOOL)animated {
    if (!self.menuVisible) {
        return;
    }

    if (animated) {
        [UIView animateWithDuration:0.2
            animations:^{
              self.containerView.alpha = 0;
              self.containerView.transform = CGAffineTransformMakeScale(0.8, 0.8);
            }
            completion:^(BOOL finished) {
              [self cleanupMenu];
            }];
    } else {
        [self cleanupMenu];
    }
}

- (void)cleanupMenu {
    [self.containerView removeFromSuperview];
    self.containerView = nil;

    [self.overlayView removeFromSuperview];
    self.overlayView = nil;

    self.menuVisible = NO;
    self.actionHandler = nil;
}

- (void)createOverlayViewInWindow:(UIWindow *)window {
    // Create a transparent overlay that intercepts background taps.
    self.overlayView = [[UIView alloc] initWithFrame:window.bounds];
    self.overlayView.backgroundColor = [UIColor clearColor];
    self.overlayView.autoresizingMask =
        UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    // Add the background-tap recognizer.
    UITapGestureRecognizer *tapGesture =
        [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backgroundTapped:)];
    [self.overlayView addGestureRecognizer:tapGesture];

    // Place the overlay above the window's current content.
    [window addSubview:self.overlayView];
}

- (void)backgroundTapped:(UITapGestureRecognizer *)gesture {
    CGPoint location = [gesture locationInView:self.overlayView];

    // Dismiss the menu when the tap falls outside its container.
    if (!CGRectContainsPoint(self.containerView.frame, location)) {
        [self hideMenuAnimated:YES];
    }
}

- (CGSize)calculateMenuSizeForItemCount:(NSInteger)itemCount {
    // Fixed menu-item dimensions
    CGFloat itemWidth = 60;
    CGFloat itemHeight = 70;

    // Calculate the number of rows.
    NSInteger maxItemsPerRow = 5;
    NSInteger numberOfRows = (itemCount + maxItemsPerRow - 1) / maxItemsPerRow;
    NSInteger itemsInLastRow = itemCount % maxItemsPerRow;
    if (itemsInLastRow == 0) {
        itemsInLastRow = maxItemsPerRow;
    }

    // Size the menu to the fullest row, capped at five items.
    CGFloat width = itemWidth * MIN(itemCount, maxItemsPerRow);

    // Calculate the row height total.
    CGFloat height = itemHeight * numberOfRows;

    // Add outer padding.
    CGFloat padding = 16;
    width += padding * 2;
    height += padding * 2;

    return CGSizeMake(width, height);
}

- (void)keyboardWillChangeFrame:(NSNotification *)notification {
    CGRect keyboardFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    BOOL visible =
        !CGRectIsEmpty(keyboardFrame) && CGRectGetMinY(keyboardFrame) < CGRectGetMaxY(screenBounds);
    [self updateKeyboardFrame:keyboardFrame visible:visible];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    [self updateKeyboardFrame:CGRectZero visible:NO];
}

- (void)updateKeyboardFrame:(CGRect)keyboardFrame visible:(BOOL)visible {
    self.keyboardFrame = keyboardFrame;
    self.keyboardVisible = visible;
}

- (CGRect)visibleBoundsForWindow:(UIWindow *)window {
    CGRect keyboardFrameInWindow = CGRectZero;
    if (self.isKeyboardVisible && !CGRectIsEmpty(self.keyboardFrame)) {
        keyboardFrameInWindow = [window convertRect:self.keyboardFrame fromWindow:nil];
    }
    return [self visibleBoundsForWindowBounds:window.bounds
                                keyboardFrame:keyboardFrameInWindow
                              keyboardVisible:self.isKeyboardVisible];
}

- (CGRect)visibleBoundsForWindowBounds:(CGRect)windowBounds
                         keyboardFrame:(CGRect)keyboardFrame
                       keyboardVisible:(BOOL)keyboardVisible {
    if (!keyboardVisible || CGRectIsEmpty(keyboardFrame)) {
        return windowBounds;
    }

    CGRect keyboardIntersection = CGRectIntersection(windowBounds, keyboardFrame);
    if (CGRectIsNull(keyboardIntersection) || CGRectIsEmpty(keyboardIntersection)) {
        return windowBounds;
    }

    CGRect visibleBounds = windowBounds;
    CGFloat visibleMaxY = CGRectGetMinY(keyboardIntersection);
    if (visibleMaxY > CGRectGetMinY(windowBounds)) {
        visibleBounds.size.height = visibleMaxY - CGRectGetMinY(windowBounds);
    }
    return visibleBounds;
}

- (CGPoint)arrowAnchorPointForTargetRect:(CGRect)targetRect visibleBounds:(CGRect)visibleBounds {
    CGRect visibleTargetRect = CGRectIntersection(targetRect, visibleBounds);
    if (CGRectIsNull(visibleTargetRect) || CGRectIsEmpty(visibleTargetRect)) {
        visibleTargetRect = targetRect;
    }
    return CGPointMake(CGRectGetMidX(visibleTargetRect), CGRectGetMidY(visibleTargetRect));
}

- (BOOL)arrowShouldPointUpForTargetRect:(CGRect)targetRect
                         containerFrame:(CGRect)containerFrame
                          visibleBounds:(CGRect)visibleBounds {
    CGPoint anchorPoint = [self arrowAnchorPointForTargetRect:targetRect
                                                visibleBounds:visibleBounds];
    return CGRectGetMidY(containerFrame) > anchorPoint.y;
}

@end
