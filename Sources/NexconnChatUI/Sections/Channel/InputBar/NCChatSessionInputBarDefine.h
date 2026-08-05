//
//  NCChatSessionInputBarDefine.h
//  NexconnChatUI
//
//  Created by nexconn-ios on 10/4/26.
//  Copyright (c) 2026 Nexconn. All rights reserved.
//

#ifndef NCChatSessionInputBarDefine_h
#define NCChatSessionInputBarDefine_h

/*!
 Layout style of the input toolbar
 */
typedef NS_ENUM(NSInteger, NCChatSessionInputBarControlStyle) {
    /*!
     Switch - Input - Extension
     */
    NC_CHAT_INPUT_BAR_STYLE_SWITCH_CONTAINER_EXTENTION = 0,
    /*!
     Extension - Input - Switch
     */
    NC_CHAT_INPUT_BAR_STYLE_EXTENTION_CONTAINER_SWITCH = 1,
    /*!
     Input - Switch - Extension
     */
    NC_CHAT_INPUT_BAR_STYLE_CONTAINER_SWITCH_EXTENTION = 2,
    /*!
     Input - Extension - Switch
     */
    NC_CHAT_INPUT_BAR_STYLE_CONTAINER_EXTENTION_SWITCH = 3,
    /*!
     Switch - Input
     */
    NC_CHAT_INPUT_BAR_STYLE_SWITCH_CONTAINER = 4,
    /*!
     Input - Switch
     */
    NC_CHAT_INPUT_BAR_STYLE_CONTAINER_SWITCH = 5,
    /*!
     Extension - Input
     */
    NC_CHAT_INPUT_BAR_STYLE_EXTENTION_CONTAINER = 6,
    /*!
     Input - Extension
     */
    NC_CHAT_INPUT_BAR_STYLE_CONTAINER_EXTENTION = 7,
    /*!
     Input only
     */
    NC_CHAT_INPUT_BAR_STYLE_CONTAINER = 8,
};

/*!
 Menu type of the input toolbar
 */
typedef NS_ENUM(NSInteger, NCChatSessionInputBarControlType) {
    /*!
     Default type
     */
    NCChatSessionInputBarControlDefaultType = 0,

    /*!
     Input disabled
     */
    NCChatSessionInputBarControlNoAvailableType = 3
};

/*!
 Input mode of the input toolbar
 */
typedef NS_ENUM(NSInteger, NCChatSessionInputBarInputType) {
    /*!
     Text input mode
     */
    NCChatSessionInputBarInputText = 0,
    /*!
     Voice input mode
     */
    NCChatSessionInputBarInputVoice = 1,
    /*!
     Extension input mode
     */
    NCChatSessionInputBarInputExtention = 2
};

/*!
 Input mode of the input toolbar
 */
typedef NS_ENUM(NSInteger, KBottomBarStatus) {
    /*!
     Initial state
     */
    KBottomBarDefaultStatus = 0,
    /*!
     Text input state
     */
    KBottomBarKeyboardStatus,
    /*!
     Plugin board input state
     */
    KBottomBarPluginStatus,
    /*!
     Emoji input state
     */
    KBottomBarEmojiStatus,
    /*!
     Voice message input state
     */
    KBottomBarRecordStatus
};

#endif /* NCChatSessionInputBarDefine_h */
