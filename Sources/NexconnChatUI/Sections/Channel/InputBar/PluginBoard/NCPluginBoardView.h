//
//  NCPluginBoardView.h
//  NCExtensionKit
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NCBaseCollectionView.h"
@protocol NCPluginBoardViewDelegate;

/*!
 View for the input extension plugin board
 */
@interface NCPluginBoardView : UIView

/*!
 All current extension items
 */
@property (nonatomic, strong) NSMutableArray *allItems;

/*!
 Display all function buttons
 */
@property (nonatomic, strong) NCBaseCollectionView *contentView;

/*!
 Extension view that overlays other views in the plus area; hidden by default
 */
@property (nonatomic, strong) UIView *extensionView;

/*!
 Tap callback for the plugin board
 */
@property (nonatomic, weak) id<NCPluginBoardViewDelegate> pluginBoardDelegate;

/*!
 Insert an extension item into the plugin board

 @param normalImage Display image of the extension item
 @param highlightedImage Highlighted image of the extension item
 @param title Display title of the extension item
 @param index Index at which to insert
 @param tag   Unique identifier of the extension item

  You can add custom extension items after NCChannelViewController's viewDidLoad.
 The SDK reserves identifiers in the 1XXX range; avoid using 1XXX for custom items to prevent conflicts.
 */
- (void)insertItem:(UIImage *)normalImage highlightedImage:(UIImage *)highlightedImage title:(NSString *)title atIndex:(NSInteger)index tag:(NSInteger)tag;

/*!
 Append an extension item to the end of the plugin board

 @param normalImage Display image of the extension item
 @param highlightedImage Highlighted image of the extension item
 @param title Display title of the extension item
 @param tag   Unique identifier of the extension item

  You can add custom extension items after NCChannelViewController's viewDidLoad.
 The SDK reserves identifiers in the 1XXX range; avoid using 1XXX for custom items to prevent conflicts.
 */
- (void)insertItem:(UIImage *)normalImage highlightedImage:(UIImage *)highlightedImage title:(NSString *)title tag:(NSInteger)tag;

/*!
 Update the specified extension item

 @param index Index of the extension item
 @param normalImage Display image of the extension item
 @param highlightedImage Highlighted image of the extension item
 @param title Display title of the extension item
 */
- (void)updateItemAtIndex:(NSInteger)index normalImage:(UIImage *)normalImage highlightedImage:(UIImage *)highlightedImage title:(NSString *)title;

/*!
 Update the specified extension item

 @param tag   Unique identifier of the extension item
 @param normalImage Display image of the extension item
 @param highlightedImage Highlighted image of the extension item
 @param title Display title of the extension item
 */
- (void)updateItemWithTag:(NSInteger)tag normalImage:(UIImage *)normalImage highlightedImage:(UIImage *)highlightedImage title:(NSString *)title;

/*!
 Remove the specified extension item from the plugin board

 @param index Index of the extension item to remove
 */
- (void)removeItemAtIndex:(NSInteger)index;

/*!
 Remove the specified extension item from the plugin board

 @param tag Unique identifier of the extension item to remove
 */
- (void)removeItemWithTag:(NSInteger)tag;

/*!
 Remove all extension items from the plugin board
 */
- (void)removeAllItems;
@end

/*!
 Tap callback for the plugin board
 */
@protocol NCPluginBoardViewDelegate <NSObject>

/*!
 Callback for tapping an extension item on the plugin board

 @param pluginBoardView Current plugin board
 @param tag             Unique identifier of the tapped extension item
 */
- (void)pluginBoardView:(NCPluginBoardView *)pluginBoardView clickedItemWithTag:(NSInteger)tag;

@end
