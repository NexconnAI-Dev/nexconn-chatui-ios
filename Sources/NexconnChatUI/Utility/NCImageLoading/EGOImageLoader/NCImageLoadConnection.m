//
//  EGOImageLoadConnection.m
//  EGOImageLoading
//
//  Created by Shaun Harrison on 12/1/09.
//  Copyright (c) 2009-2010 enormego
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "NCImageLoadConnection.h"
#import <NexconnChatUI/NCChatUILog.h>
#import <NexconnChatSDK/NexconnChatSDK.h>
#import "NCFileUtility.h"

@implementation NCImageLoadConnection
@synthesize imageURL = _imageURL, response = _response, delegate = _delegate, timeoutInterval = _timeoutInterval;

#if __EGOIL_USE_BLOCKS
@synthesize handlers;
#endif

- (instancetype)initWithImageURL:(NSURL *)aURL delegate:(id)delegate {
    if ((self = [super init])) {
        _imageURL = aURL;
        self.delegate = delegate;
        _responseData = [[NSMutableData alloc] init];
        self.timeoutInterval = 30;

#if __EGOIL_USE_BLOCKS
        handlers = [[NSMutableDictionary alloc] init];
#endif
    }

    return self;
}

- (void)start {
    NSString *remoteURL = self.imageURL.absoluteString;
    NSString *fileKey = [NCFileUtility fileKeyForURL:remoteURL];
    NSString *fileExtension = self.imageURL.path.pathExtension;
    if (fileExtension.length == 0) {
        fileExtension = @"img";
    }
    NSString *fileName = fileKey.length > 0
        ? [NSString stringWithFormat:@"Image_%@.%@", fileKey, fileExtension]
        : nil;
    if (remoteURL.length == 0 || fileName.length == 0) {
        [self p_finishWithError:[NSError errorWithDomain:NSURLErrorDomain
                                                    code:NSURLErrorBadURL
                                                userInfo:nil]];
        return;
    }

    _cancelled = NO;
    _downloadStarted = YES;
    __weak typeof(self) weakSelf = self;
    [NCBaseChannel downloadMediaUrl:remoteURL
                           fileName:fileName
                    progressHandler:nil
                  completionHandler:^(NSString *_Nullable mediaPath, NCError *_Nullable error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        strongSelf->_downloadStarted = NO;
        if (strongSelf->_cancelled) {
            return;
        }
        if (error || mediaPath.length == 0) {
            [strongSelf p_finishWithError:error ?: [NSError errorWithDomain:NSURLErrorDomain
                                                                        code:NSURLErrorCannotOpenFile
                                                                    userInfo:nil]];
            return;
        }
        [strongSelf p_loadDownloadedDataAtPath:mediaPath];
    }
                      cancelHandler:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        strongSelf->_downloadStarted = NO;
    }];
}

- (void)cancel {
    _cancelled = YES;
    if (_downloadStarted && self.imageURL.absoluteString.length > 0) {
        [NCBaseChannel cancelDownloadMediaUrl:self.imageURL.absoluteString completion:nil];
    }
}

- (NSData *)responseData {
    return _responseData;
}

- (void)p_loadDownloadedDataAtPath:(NSString *)mediaPath {
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
        NSError *readError = nil;
        NSData *data = [NSData dataWithContentsOfFile:mediaPath
                                             options:NSDataReadingMappedIfSafe
                                               error:&readError];
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf || strongSelf->_cancelled) {
                return;
            }
            if (!data) {
                [strongSelf p_finishWithError:readError ?: [NSError errorWithDomain:NSCocoaErrorDomain
                                                                                code:NSFileReadUnknownError
                                                                            userInfo:nil]];
                return;
            }
            [strongSelf->_responseData setData:data];
            [strongSelf p_finishWithError:nil];
        });
    });
}

- (void)p_finishWithError:(NSError *)error {
    if (![NSThread isMainThread]) {
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf p_finishWithError:error];
        });
        return;
    }
    if (_cancelled) {
        return;
    }
    if (error) {
        if ([self.delegate respondsToSelector:@selector(imageLoadConnection:didFailWithError:)]) {
            [self.delegate imageLoadConnection:self didFailWithError:error];
        }
        return;
    }
    if ([self.delegate respondsToSelector:@selector(imageLoadConnectionDidFinishLoading:)]) {
        [self.delegate imageLoadConnectionDidFinishLoading:self];
    }
}

- (void)dealloc {
    self.response = nil;
    self.delegate = nil;

#if __EGOIL_USE_BLOCKS
    [handlers release], handlers = nil;
#endif
    _imageURL = nil;
    _responseData = nil;
}

@end
