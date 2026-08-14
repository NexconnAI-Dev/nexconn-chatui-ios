//
//  NCInputStateManager.m
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#import "NCInputStateManager.h"
#import "NCMentionedStringRangeInfo.h"
#import "NCChatUIUtility.h"
#import "NCChatUICommonDefine.h"
#import "NCGroupMentionViewModel.h"
#import <NexconnChatSDK/NexconnChatSDK.h>

@interface NCInputStateManager ()

/// Managed text input view.
@property (nonatomic, weak) UITextView *textView;

/// Mention range metadata.
@property (nonatomic, strong) NSMutableArray<NCMentionedStringRangeInfo *> *mentionedRangeInfoList;

@end

@implementation NCInputStateManager

#pragma mark - Initialization

- (instancetype)initWithTextView:(UITextView *)textView
                        delegate:(id<NCInputStateManagerDelegate>)delegate {
    self = [super init];
    if (self) {
        _textView = textView;
        _delegate = delegate;
        _isMentionedEnabled = YES;
        _mentionedRangeInfoList = [[NSMutableArray alloc] init];
    }
    return self;
}

#pragma mark -

- (BOOL)handleTextChange:(NSString *)text inRange:(NSRange)range {
    if (!self.isMentionedEnabled || !self.textView) {
        return YES;
    }
    
    BOOL shouldUseDefaultChangeText = YES;
    
    // Track the edited range.
    NSInteger changedLocation = 0;
    NSInteger changedLength = 0;
    
    // A zero replacement length indicates deletion.
    if (text.length == 0) {
        for (NCMentionedStringRangeInfo *mentionedInfo in [self.mentionedRangeInfoList copy]) {
            NSRange mentionedRange = mentionedInfo.range;
            
            // Deleting at the end of a mention removes the entire mention token.
            if (range.length == 1 && (mentionedRange.location + mentionedRange.length == range.location + 1)) {
                // Remove the full mention only when its range is valid.
                if ([self isSafeToDeleteRange:mentionedRange fromTextStorage:self.textView.textStorage]) {
                    shouldUseDefaultChangeText = NO;
                    
                    [self.textView.textStorage deleteCharactersInRange:mentionedRange];
                    
                    // Mutating textStorage does not trigger textViewDidChange:, so notify manually.
                    [self notifyTextViewDidChange];
                    
                    range.location = range.location - mentionedRange.length + 1;
                    range.length = 0;
                    self.textView.selectedRange = NSMakeRange(mentionedRange.location, 0);
                    
                    changedLocation = mentionedInfo.range.location;
                    changedLength = -(NSInteger)mentionedInfo.range.length;
                    
                    [self.mentionedRangeInfoList removeObject:mentionedInfo];
                    break;
                }
            } else if (mentionedRange.location <= range.location &&
                       range.location < mentionedRange.location + mentionedRange.length) {
                [self.mentionedRangeInfoList removeObject:mentionedInfo];
                // Continue because one deletion can overlap multiple mention ranges.
            }
        }
        
        if (changedLength == 0) {
            // Track ordinary deletions that do not intersect a mention.
            changedLocation = range.location + 1;
            changedLength = -(NSInteger)range.length;
        }
    } else {
        if ([text isEqualToString:@"@"]) {
            if ([self shouldTriggerMentionedChoose:range]) {
                __weak typeof(self) weakSelf = self;
                [self.delegate inputStateManager:self
                                showUserSelector:^(NCChatUIUserInfo *selectedUser) {
                                    [weakSelf insertMentionedUser:selectedUser symbolRequest:NO];
                                }
                                          cancel:^{
                                              // Ignore selection-only changes.
                                          }];
            }
        }
        
        // Remove a mention when editing starts inside it; otherwise shift its range to match the edit.
        for (NCMentionedStringRangeInfo *mentionedInfo in [self.mentionedRangeInfoList copy]) {
            NSRange strRange = mentionedInfo.range;
            if ((range.location > strRange.location) && (range.location < (strRange.location + strRange.length))) {
                [self.mentionedRangeInfoList removeObject:mentionedInfo];
                break;
            }
        }
        changedLocation = range.location;
        changedLength = text.length - range.length;
    }
    
    [self updateAllMentionedRangeInfo:changedLocation length:changedLength];
    [self notifyMentionsDidUpdate];
    
    return shouldUseDefaultChangeText;
}

- (BOOL)shouldTriggerMentionedChoose:(NSRange)range {
    if (range.location == 0) {
        return YES;
    } else if (!isalnum([self.textView.text characterAtIndex:range.location - 1])) {
        // Do not open the mention picker when @ follows an alphanumeric character.
        return YES;
    }
    return NO;
}

- (void)insertMentionedUser:(NCChatUIUserInfo *)userInfo {
    // Insert the @ symbol unless the caller reports that it is already present.
    [self insertMentionedUser:userInfo symbolRequest:YES];
}

- (void)insertMentionedUser:(NCChatUIUserInfo *)userInfo symbolRequest:(BOOL)symbolRequest {
    if (!self.isMentionedEnabled || !userInfo.userId || !self.textView) {
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // Read the current insertion point.
        NSUInteger cursorPosition = self.textView.selectedRange.location;
        if (cursorPosition > self.textView.textStorage.length) {
            cursorPosition = self.textView.textStorage.length;
        }
        
        // Build the mention token at the insertion point.
        NSUInteger mentionedPosition;
        NSString *insertContent = nil;
        NSInteger changeRangeLength;
        
        if (symbolRequest) {
            // Insert both the @ symbol and user name.
            if (userInfo.name.length > 0) {
                insertContent = [NSString stringWithFormat:@"@%@ ", userInfo.name];
            } else {
                insertContent = [NSString stringWithFormat:@"@%@ ", userInfo.userId];
            }
            mentionedPosition = cursorPosition;
            changeRangeLength = [insertContent length];
        } else {
            // The @ symbol already exists, so insert only the user name.
            if (userInfo.name.length > 0) {
                insertContent = [NSString stringWithFormat:@"%@ ", userInfo.name];
            } else {
                insertContent = [NSString stringWithFormat:@"%@ ", userInfo.userId];
            }
            mentionedPosition = (cursorPosition >= 1) ? (cursorPosition - 1) : 0;
            changeRangeLength = [insertContent length] + 1; // Include the existing @ symbol.
        }
        
        // Create the attributed mention token.
        NSMutableAttributedString *attStr = [[NSMutableAttributedString alloc] initWithString:insertContent];
        [attStr addAttribute:NSFontAttributeName
                       value:self.textView.font
                       range:NSMakeRange(0, insertContent.length)];
        UIColor *foreColor = NCDynamicColor(@"text_primary_color");
        if (foreColor) {
            [attStr addAttribute:NSForegroundColorAttributeName
                           value:foreColor
                           range:NSMakeRange(0, insertContent.length)];
        }

        // Insert the mention into the text storage.
        [self.textView.textStorage insertAttributedString:attStr atIndex:cursorPosition];
        
        // Mutating textStorage does not trigger textViewDidChange:, so notify manually.
        [self notifyTextViewDidChange];
        
        self.textView.selectedRange = NSMakeRange(cursorPosition + insertContent.length, 0);
        [self updateAllMentionedRangeInfo:cursorPosition length:insertContent.length];
        
        // Store the mention range metadata.
        NCMentionedStringRangeInfo *mentionedStrInfo = [[NCMentionedStringRangeInfo alloc] init];
        if (symbolRequest) {
            mentionedStrInfo.content = insertContent; // insertContent already includes the @ symbol.
        } else {
            mentionedStrInfo.content = [@"@" stringByAppendingString:insertContent]; // Prefix the user name with @.
        }
        mentionedStrInfo.userId = userInfo.userId;
        mentionedStrInfo.range = NSMakeRange(mentionedPosition, changeRangeLength);
        [self.mentionedRangeInfoList addObject:mentionedStrInfo];
        
        [self notifyMentionsDidUpdate];
    });
}

// Update stored mention ranges after a text edit.
- (void)updateAllMentionedRangeInfo:(NSInteger)changedLocation length:(NSInteger)changedLength {
    // Iterate over a copy because invalid mention entries may be removed.
    for (NCMentionedStringRangeInfo *mentionedInfo in [self.mentionedRangeInfoList copy]) {
        if (mentionedInfo.range.location >= changedLocation) {
            NSInteger newLocation = mentionedInfo.range.location + changedLength;
            if (newLocation >= 0) {
                // Shift the mention to its new valid location.
                mentionedInfo.range = NSMakeRange(newLocation, mentionedInfo.range.length);
            } else {
                // A negative location means the deletion invalidated the mention.
                [self.mentionedRangeInfoList removeObject:mentionedInfo];
            }
        }
    }
}

- (void)clearAllMentions {
    [self.mentionedRangeInfoList removeAllObjects];
    [self notifyMentionsDidUpdate];
}

- (void)setupMentionedRangeInfo:(NSArray<NCMentionedStringRangeInfo *> *)mentionedRangeInfo {
    [self.mentionedRangeInfoList removeAllObjects];
    [self.mentionedRangeInfoList addObjectsFromArray:mentionedRangeInfo];
    
    // Resolve the latest display information for mentioned users.
    [self updateMentionedInfoWithLatestUserInfo];
    [self notifyMentionsDidUpdate];
}

- (BOOL)hasContent {
    // Reconcile mention ranges with the current text.
    BOOL hasText = (self.textView.text.length > 0);
    return hasText;
}

// Replace mentioned user names in the input with their latest display names.
- (void)updateMentionedInfoWithLatestUserInfo {
    // 从后往前处理，避免前面替换影响后续 range
    NSArray<NCMentionedStringRangeInfo *> *sortedList = [self.mentionedRangeInfoList sortedArrayUsingComparator:^NSComparisonResult(NCMentionedStringRangeInfo *obj1, NCMentionedStringRangeInfo *obj2) {
        if (obj1.range.location > obj2.range.location) {
            return NSOrderedAscending; // 降序，从后往前
        } else if (obj1.range.location < obj2.range.location) {
            return NSOrderedDescending;
        }
        return NSOrderedSame;
    }];

    NSMutableString *currentText = [self.textView.text mutableCopy];

    for (NCMentionedStringRangeInfo *mentionedInfo in sortedList) {
        NSString *userId = mentionedInfo.userId;
        if (!userId) {
            continue;
        }

        // 校验 range 合法性
        if (mentionedInfo.range.location >= currentText.length ||
            mentionedInfo.range.location + mentionedInfo.range.length > currentText.length) {
            continue;
        }

        NCChatUIUserInfo *userInfo = nil;
        NSString *latestMentionedContent = nil;
        if ([self.delegate respondsToSelector:@selector(inputStateManager:getUserInfoForUserId:)]) {
            userInfo = [self.delegate inputStateManager:self getUserInfoForUserId:userId];
        }
        if (userInfo && userInfo.name.length > 0) {
            latestMentionedContent = [NSString stringWithFormat:@"@%@ ", userInfo.name];
        }

        if (latestMentionedContent && ![latestMentionedContent isEqualToString:mentionedInfo.content]) {
            // 按 range 精准替换当前位置内容
            [currentText replaceCharactersInRange:mentionedInfo.range withString:latestMentionedContent];

            // 计算长度差，重算前面所有 @ range（因为从后往前，已处理的在当前位置之后，不受影响）
            NSInteger lengthDiff = latestMentionedContent.length - mentionedInfo.range.length;
            if (lengthDiff != 0) {
                for (NCMentionedStringRangeInfo *info in self.mentionedRangeInfoList) {
                    if (info.range.location < mentionedInfo.range.location) {
                        // 当前位置之前的不受影响
                    } else if (info.range.location > mentionedInfo.range.location) {
                        // 当前位置之后的需要偏移
                        info.range = NSMakeRange(info.range.location + lengthDiff, info.range.length);
                    } else if (info == mentionedInfo) {
                        // 当前项更新 range
                        info.range = NSMakeRange(info.range.location, latestMentionedContent.length);
                    }
                }
            }

            mentionedInfo.content = latestMentionedContent;
        }
    }

    // 最后统一赋值回 textView
    self.textView.text = currentText;
}

- (void)clearAllStates {
    // Clear the input text.
    self.textView.text = @"";
    
    // Clear mention metadata.
    [self clearAllMentions];
}

#pragma mark - Private Methods

- (NSString *)currentText {
    return self.textView.text ?: @"";
}

- (void)notifyTextViewDidChange {
    // Manually forward the text change callback.
    if ([self.textView.delegate respondsToSelector:@selector(textViewDidChange:)]) {
        [self.textView.delegate textViewDidChange:self.textView];
    }
}

- (void)notifyMentionsDidUpdate {
    if ([self.delegate respondsToSelector:@selector(inputStateManagerDidUpdateMentions:)]) {
        [self.delegate inputStateManagerDidUpdateMentions:self];
    }
}

/// Validates a range before deleting it from text storage.
/// @param range The range to delete.
/// @param textStorage The target text storage.
/// @return YES when the full range is valid; otherwise NO.
- (BOOL)isSafeToDeleteRange:(NSRange)range fromTextStorage:(NSTextStorage *)textStorage {
    // A target text storage is required.
    if (!textStorage) {
        return NO;
    }
    
    // Reject missing and empty ranges.
    if (range.location == NSNotFound || range.length == 0) {
        return NO;
    }
    
    // The start must be inside the text storage.
    if (range.location >= textStorage.length) {
        return NO;
    }
    
    // The end must not exceed the text storage length.
    NSUInteger endLocation = range.location + range.length;
    if (endLocation > textStorage.length) {
        return NO;
    }
    
    return YES;
}

/// Checks whether text starts with a prefix at a specific index.
/// @param text The source text.
/// @param prefix The prefix to match.
/// @param index The starting index.
/// @return YES when the prefix matches; otherwise NO.
- (BOOL)text:(NSString *)text hasPrefix:(NSString *)prefix atIndex:(NSInteger)index {
    if (!text || !prefix || index < 0 || index >= text.length) {
        return NO;
    }
    
    NSInteger remainingLength = text.length - index;
    if (remainingLength < prefix.length) {
        return NO; // The remaining text is shorter than the prefix.
    }
    
    NSRange checkRange = NSMakeRange(index, prefix.length);
    NSString *substring = [text substringWithRange:checkRange];
    return [substring isEqualToString:prefix];
}

/// Checks whether a range is already present in the match list.
/// @param range The range to find.
/// @param matches The existing matches.
/// @return YES when the range is already present; otherwise NO.
- (BOOL)isRangeAlreadyInMatches:(NSRange)range matches:(NSArray *)matches {
    for (NSDictionary *match in matches) {
        NSRange existingRange = [match[@"range"] rangeValue];
        if (NSEqualRanges(range, existingRange)) {
            return YES;
        }
    }
    return NO;
}

#pragma mark - getter

- (NCMentionedInfo *)mentionedInfo {
    if (self.mentionedRangeInfoList.count > 0) {
        BOOL containsMentionAll = NO;
        NSMutableSet *mentionedUserIdList = [[NSMutableSet alloc] init];
        for (NCMentionedStringRangeInfo *mentionedInfo in self.mentionedRangeInfoList) {
            if (mentionedInfo.userId) {
                if ([self isMentionAllUserId:mentionedInfo.userId]) {
                    containsMentionAll = YES;
                    continue;
                }
                [mentionedUserIdList addObject:mentionedInfo.userId];
            }
        }
        if (containsMentionAll) {
            return [[NCMentionedInfo alloc] initWithType:NCMentionedTypeAll userIdList:nil mentionedContent:nil];
        }
        if (mentionedUserIdList.count == 0) {
            return nil;
        }
        NCMentionedInfo *mentionedInfo = [[NCMentionedInfo alloc] initWithType:NCMentionedTypeUsers
                                                                    userIdList:[mentionedUserIdList allObjects]
                                                              mentionedContent:nil];
        return mentionedInfo;
    }
    return nil;
}

- (BOOL)isMentionAllUserId:(NSString *)userId {
    return [userId isEqualToString:NCMentionAllUsersID];
}

- (NSArray<NCMentionedStringRangeInfo *> *)mentionedRangeInfo {
    return [self.mentionedRangeInfoList copy];
}

@end 
