//
//  NCSearchBar.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCSearchBar.h"
#import "NCChatUIUtility.h"
#import "NCChatUICommonDefine.h"

@interface NCSearchBar ()<UITextFieldDelegate>
@property (nonatomic, strong) UITextField *textField;
@end

@implementation NCSearchBar

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Support right-to-left layout.
        [self updateRTLUI];
        
        // Access the search text field.
        if (@available(iOS 13.0, *)) {
            self.textField = self.searchTextField;
        } else {
            self.textField = [self valueForKey:@"searchField"];
        }
        
        // Set a text-field background color that supports Dark Mode.
        self.textField.backgroundColor = [UIColor clearColor];
        self.showsCancelButton = NO;
        
        // Set the search icon color.
        if (@available(iOS 13.0, *)) {
            UIImageView *iconView = (UIImageView *)self.searchTextField.leftView;
            if (iconView && [iconView isKindOfClass:[UIImageView class]]) {
                iconView.tintColor = NCDynamicColor(@"primary_color");
            }
        }
        UIColor *color = NCDynamicColor(@"text_secondary_color");;
        if (!color) {
            color = [UIColor lightGrayColor];
        }
        NSString *placeholderText =  NCUILocalizedString(@"to_search");
        NSDictionary *attributes = @{
            NSFontAttributeName: [UIFont systemFontOfSize:17],
            NSForegroundColorAttributeName:color  // Set the placeholder color.
        };
        // Apply the attributed placeholder.
        self.textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:placeholderText attributes:attributes];
           
        self.textField.delegate = self;
        
        // Make all backgrounds transparent.
        self.backgroundColor = [UIColor clearColor];
        self.barTintColor = [UIColor clearColor];
        self.backgroundImage = [UIImage new];
        
        // Remove the border.
        self.layer.borderWidth = 0;
        
    }
    return self;
}

- (void)updateRTLUI {
    if ([NCChatUIUtility isRTL]) {
        self.semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;
    } else {
        self.semanticContentAttribute = UISemanticContentAttributeForceLeftToRight;
    }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    BOOL retValue = YES;
    if ([self.delegate respondsToSelector:@selector(searchBarShouldBeginEditing:)]) {
        retValue = [self.delegate searchBarShouldBeginEditing:self];
    }
    return retValue;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    BOOL retValue = YES;
    if ([self.delegate respondsToSelector:@selector(searchBarShouldEndEditing:)]) {
        retValue = [self.delegate searchBarShouldEndEditing:self];
    }
    return retValue;
}


@end
