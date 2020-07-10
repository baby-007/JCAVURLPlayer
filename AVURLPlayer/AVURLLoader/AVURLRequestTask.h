//
//  AVURLRequestTask.h
//  AVURLPlayer
//
//  Created by karlcool on 2018/1/23.
//  Copyright © 2018年 karlcool. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AVURLCacheHandle.h"
#import <AVFoundation/AVFoundation.h>

@class AVURLRequestTask;
@protocol AVURLRequestTaskDelegate <NSObject>

@optional
- (void)requestTask:(AVURLRequestTask *_Nullable)task didReceiveResponse:(NSURLResponse *_Nullable)response;
- (void)requestTask:(AVURLRequestTask *_Nullable)task didCompleteWithError:(NSError *_Nullable)error;
- (void)requestTask:(AVURLRequestTask *_Nullable)task didReceiveData:(NSData *_Nullable)data;
- (void)requestTask:(AVURLRequestTask *_Nullable)task didReceiveChallenge:(NSURLAuthenticationChallenge *_Nullable)challenge completionHandler:(void (^_Nullable)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler;
@end





@interface AVURLRequestTask : NSObject
- (nonnull instancetype)initWithURL:(NSURL *_Nullable)URL NS_DESIGNATED_INITIALIZER;
- (nonnull instancetype)init NS_UNAVAILABLE;
+ (nonnull instancetype)new NS_UNAVAILABLE;

@property (nonatomic, weak) id<AVURLRequestTaskDelegate> _Nullable delegate;
@property (nonatomic, strong, readonly) NSURL * _Nullable requestURL;
@property (nonatomic, assign) NSUInteger contentLength;
@property (nonatomic, strong) AVURLCacheHandle * _Nullable cacheHandle;
- (void)startTaskWithLoadingRequest:(AVAssetResourceLoadingRequest *_Nullable)loadingRequest;
- (void)cancleTaskWithLoadingRequest:(AVAssetResourceLoadingRequest *_Nullable)loadingRequest;
- (void)cancle;
@end
