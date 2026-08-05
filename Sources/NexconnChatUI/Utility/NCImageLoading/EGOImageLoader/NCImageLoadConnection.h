//
//  EGOImageLoadConnection.h
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

#import <Foundation/Foundation.h>

@protocol NCImageLoadConnectionDelegate;

@interface NCImageLoadConnection : NSObject {
  @private
    NSURL *_imageURL;
    NSURLResponse *_response;
    NSMutableData *_responseData;
    NSTimeInterval _timeoutInterval;
    BOOL _downloadStarted;
    BOOL _cancelled;

    __weak id<NCImageLoadConnectionDelegate> _delegate;
}

- (instancetype)initWithImageURL:(NSURL *)aURL delegate:(id)delegate;

- (void)start;
- (void)cancel;

@property (nonatomic, readonly) NSData *responseData;
@property (nonatomic, readonly, getter=imageURL) NSURL *imageURL;

@property (nonatomic, strong) NSURLResponse *response;
@property (nonatomic, weak) id<NCImageLoadConnectionDelegate> delegate;

@property (nonatomic, assign) NSTimeInterval timeoutInterval; // Default is 30 seconds

#if __EGOIL_USE_BLOCKS
@property (nonatomic, readonly) NSMutableDictionary *handlers;
#endif

@end

@protocol NCImageLoadConnectionDelegate <NSObject>
- (void)imageLoadConnectionDidFinishLoading:(NCImageLoadConnection *)connection;
- (void)imageLoadConnection:(NCImageLoadConnection *)connection didFailWithError:(NSError *)error;
@end
