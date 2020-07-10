//
//  AVURLRequestDataTask.h
//  AVURLPlayer
//
//  Created by karlcool on 2018/1/26.
//  Copyright © 2018年 karlcool. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>


typedef void(^ResponseHandler)(NSURLResponse * _Nullable response, NSUInteger contentLength);
typedef void(^ReceivedHandler)(NSData * _Nullable data);
typedef void(^CompleteHandler)(NSError * _Nullable error);
typedef void(^ChallengeCompleteHandler)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable);
typedef void(^ChallengeHandler)(NSURLAuthenticationChallenge * _Nullable challenge, ChallengeCompleteHandler _Nullable completion);

@interface AVURLRequestDataTask : NSObject

- (nonnull instancetype)initWithURL:(NSURL *_Nullable)URL
             loadingRequest:(AVAssetResourceLoadingRequest *_Nullable)loadingRequest NS_DESIGNATED_INITIALIZER;

- (nonnull instancetype)init NS_UNAVAILABLE;
+ (nonnull instancetype)new NS_UNAVAILABLE;

@property (nonatomic, strong, readonly) NSURL * _Nullable requestURL;
@property (nonatomic, strong, readonly) AVAssetResourceLoadingRequest * _Nullable loadingRequest;
@property (nonatomic, assign, readonly) NSUInteger requestOffset;
@property (nonatomic, assign, readonly) NSUInteger requestLength;

@property (nonatomic, assign) NSUInteger currentOffset; ///< 当前下载偏移量
@property (nonatomic, assign) NSUInteger cachingOffset; ///< 当前缓存偏移量
@property (nonatomic, assign) NSUInteger respondOffset; ///< 当前填充偏移量


- (void)taskDidReceiveResponse:(ResponseHandler _Nullable )responseHandler
                didReceiveData:(ReceivedHandler _Nullable )receivedHandler
          didCompleteWithError:(CompleteHandler _Nullable )completeHandler
                 willChallenge:(ChallengeHandler _Nullable )challengeHandler;

- (void)start;
- (void)cancle;
@end
