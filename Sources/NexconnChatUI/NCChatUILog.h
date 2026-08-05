//
//  NCChatUILog.h
//  NexconnChatUI
//
//  Created on 2026/04/08.
//

#import <Foundation/Foundation.h>
#import <os/log.h>
#import <stdarg.h>
#import <string.h>

#ifndef NCCHATUI_LOG_ENABLE
#if DEBUG
#define NCCHATUI_LOG_ENABLE 1
#else
#define NCCHATUI_LOG_ENABLE 0
#endif
#endif

NS_INLINE NSString *NCChatUILogFileName(const char *path) {
    if (path == NULL) {
        return @"";
    }
    const char *fileName = strrchr(path, '/');
    const char *finalName = fileName ? (fileName + 1) : path;
    NSString *shortName = [NSString stringWithUTF8String:(finalName ? finalName : "")];
    return shortName ?: @"";
}

NS_INLINE void NCChatUILogOutput(NSString *level,
                                 const char *file,
                                 int line,
                                 const char *functionName,
                                 NSString *format,
                                 ...) NS_FORMAT_FUNCTION(5, 6);

NS_INLINE void NCChatUILogWrite(NSString *level,
                                const char *file,
                                int line,
                                const char *functionName,
                                NSString *format,
                                va_list args) {
    if (format.length == 0) {
        return;
    }

    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    NSString *logLevel = level ?: @"D";
    NSString *shortFileName = NCChatUILogFileName(file);
    NSString *funcName = functionName ? [NSString stringWithUTF8String:functionName] : @"";
    os_log_type_t logType = OS_LOG_TYPE_DEFAULT;
    if ([logLevel isEqualToString:@"D"]) {
        logType = OS_LOG_TYPE_DEBUG;
    } else if ([logLevel isEqualToString:@"I"]) {
        logType = OS_LOG_TYPE_INFO;
    } else if ([logLevel isEqualToString:@"E"] || [logLevel isEqualToString:@"F"]) {
        logType = OS_LOG_TYPE_ERROR;
    }

    static os_log_t chatUILog;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        chatUILog = os_log_create("com.nexconn.chatui", "sdk");
    });
    os_log_with_type(chatUILog,
                     logType,
                     "[NCChatUI][%{public}@][%{public}@:%{public}d][%{public}@] %{public}@",
                     logLevel,
                     shortFileName,
                     line,
                     funcName,
                     message);
}

NS_INLINE void NCChatUILogOutput(NSString *level,
                                 const char *file,
                                 int line,
                                 const char *functionName,
                                 NSString *format,
                                 ...) {
#if NCCHATUI_LOG_ENABLE
    va_list args;
    va_start(args, format);
    NCChatUILogWrite(level, file, line, functionName, format, args);
    va_end(args);
#else
    (void)level;
    (void)file;
    (void)line;
    (void)functionName;
    (void)format;
#endif
}

NS_INLINE void NCChatUILogOutputAlways(NSString *level,
                                       const char *file,
                                       int line,
                                       const char *functionName,
                                       NSString *format,
                                       ...) NS_FORMAT_FUNCTION(5, 6);

NS_INLINE void NCChatUILogOutputAlways(NSString *level,
                                       const char *file,
                                       int line,
                                       const char *functionName,
                                       NSString *format,
                                       ...) {
    va_list args;
    va_start(args, format);
    NCChatUILogWrite(level, file, line, functionName, format, args);
    va_end(args);
}

#ifndef NCLogReleaseW
#define NCLogReleaseW(format, ...)                                                                                     \
    NCChatUILogOutputAlways(@"W", __FILE__, __LINE__, __PRETTY_FUNCTION__, (format), ##__VA_ARGS__)
#endif

#if NCCHATUI_LOG_ENABLE
#ifndef NCLogD
#define NCLogD(format, ...) NCChatUILogOutput(@"D", __FILE__, __LINE__, __PRETTY_FUNCTION__, (format), ##__VA_ARGS__)
#endif

#ifndef NCLogI
#define NCLogI(format, ...) NCChatUILogOutput(@"I", __FILE__, __LINE__, __PRETTY_FUNCTION__, (format), ##__VA_ARGS__)
#endif

#ifndef NCLogW
#define NCLogW(format, ...) NCChatUILogOutput(@"W", __FILE__, __LINE__, __PRETTY_FUNCTION__, (format), ##__VA_ARGS__)
#endif

#ifndef NCLogE
#define NCLogE(format, ...) NCChatUILogOutput(@"E", __FILE__, __LINE__, __PRETTY_FUNCTION__, (format), ##__VA_ARGS__)
#endif

#ifndef NCLogF
#define NCLogF(format, ...) NCChatUILogOutput(@"F", __FILE__, __LINE__, __PRETTY_FUNCTION__, (format), ##__VA_ARGS__)
#endif
#else
#ifndef NCLogD
#define NCLogD(format, ...) do { } while (0)
#endif

#ifndef NCLogI
#define NCLogI(format, ...) do { } while (0)
#endif

#ifndef NCLogW
#define NCLogW(format, ...) do { } while (0)
#endif

#ifndef NCLogE
#define NCLogE(format, ...) do { } while (0)
#endif

#ifndef NCLogF
#define NCLogF(format, ...) do { } while (0)
#endif
#endif
