//
//  NCPluginBoardItem.m
//  NCChatUIExtension
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCPluginBoardItem.h"
#import "NCBaseButton.h"
#import "NCChatUICommonDefine.h"
#import "NCChatUIConfig.h"
#import "UIImage+NCDynamicImage.h"
@implementation NCPluginBoardItem

- (instancetype)initWithTitle:(NSString *)title
                  normalImage:(UIImage *)normalImage
             highlightedImage:(UIImage *)highlightedImage
                          tag:(NSInteger)tag {
    self = [super init];
    if (self) {
        self.title = title;
        self.normalImage = normalImage;
        self.highlightedImage = highlightedImage;
        super.tag = tag;
    }
    return self;
}

- (void)loadView {
    UIView *myView = [UIView new];
    NCBaseButton *imageButton = [NCBaseButton buttonWithType:UIButtonTypeCustom];
    [imageButton setImage:self.normalImage forState:UIControlStateNormal];
    if (self.highlightedImage) {
        [imageButton setImage:self.highlightedImage forState:UIControlStateHighlighted];
    }
    [myView addSubview:imageButton];
    [imageButton addTarget:self
                    action:@selector(imageButtonTouchUpInside)
          forControlEvents:UIControlEventTouchUpInside];

    UILabel *label = [UILabel new];
    [label setText:_title];
    [label setTextColor:NCDynamicColor(@"text_secondary_color")];
    [label setFont:[[NCChatUIConfig defaultConfig].font fontOfAssistantLevel]];
    [label setTextAlignment:NSTextAlignmentCenter];
    [myView addSubview:label];
    [self.contentView addSubview:myView];

    // add contraints
    [myView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [imageButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    [label setTranslatesAutoresizingMaskIntoConstraints:NO];

    [self.contentView
        addConstraints:[NSLayoutConstraint
                           constraintsWithVisualFormat:@"H:|[myView(75)]|"
                                               options:kNilOptions
                                               metrics:nil
                                                 views:NSDictionaryOfVariableBindings(myView)]];
    [self.contentView
        addConstraints:[NSLayoutConstraint
                           constraintsWithVisualFormat:@"V:|[myView]|"
                                               options:kNilOptions
                                               metrics:nil
                                                 views:NSDictionaryOfVariableBindings(myView)]];

    [self.contentView addConstraints:[NSLayoutConstraint
                                         constraintsWithVisualFormat:@"H:|-7.5-[imageButton(60)]"
                                                             options:kNilOptions
                                                             metrics:nil
                                                               views:NSDictionaryOfVariableBindings(
                                                                         imageButton)]];

    [self.contentView addConstraints:[NSLayoutConstraint
                                         constraintsWithVisualFormat:@"H:|[label]|"
                                                             options:kNilOptions
                                                             metrics:nil
                                                               views:NSDictionaryOfVariableBindings(
                                                                         label, myView)]];
    [self.contentView
        addConstraints:[NSLayoutConstraint
                           constraintsWithVisualFormat:@"V:|[imageButton(60)]-5.5-[label(14)]"
                                               options:kNilOptions
                                               metrics:nil
                                                 views:NSDictionaryOfVariableBindings(
                                                           label, imageButton)]];
}

- (void)imageButtonTouchUpInside {
    self.Itemclick();
}

@end
