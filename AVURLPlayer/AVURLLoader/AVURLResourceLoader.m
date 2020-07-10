//
//  AVURLResourceLoader.m
//  AVURLPlayer
//
//  Created by karlcool on 2018/1/22.
//  Copyright © 2018年 karlcool. All rights reserved.
//

#import "AVURLResourceLoader.h"
#import "AVURLRequestTask.h"
#import <MobileCoreServices/MobileCoreServices.h>

@interface AVURLResourceLoader ()<AVURLRequestTaskDelegate>
@property (nonatomic, strong) AVURLRequestTask *requestTask;
@property (nonatomic, strong) NSMutableArray<AVAssetResourceLoadingRequest *> *mArrRequest;
@end


@implementation AVURLResourceLoader

#pragma mark - getter

- (NSMutableArray<AVAssetResourceLoadingRequest *> *)mArrRequest {
    if (!_mArrRequest) {
        _mArrRequest = [NSMutableArray array];
    }
    return _mArrRequest;
}


#pragma mark - life circle

- (void)dealloc {
    [self.mArrRequest removeAllObjects];
    self.requestTask.delegate = nil;
}


#pragma mark - tool

- (void)appendLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest {
    if (!loadingRequest) return;
    [self.mArrRequest addObject:loadingRequest];
}

- (void)removeLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest {
    if (!loadingRequest) return;
    [self.mArrRequest removeObject:loadingRequest];
}

- (void)cancel {
    [self.requestTask cancle];
}

#pragma mark - AVAssetResourceLoaderDelegate

- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader
    shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest {
    
    if (!self.requestTask) {
        self.requestTask = [[AVURLRequestTask alloc] initWithURL:loadingRequest.request.URL];
        self.requestTask.delegate = self;
    }
    
    [self appendLoadingRequest:loadingRequest];
    [self.requestTask startTaskWithLoadingRequest:loadingRequest];
    
    return YES;
}

- (void)resourceLoader:(AVAssetResourceLoader *)resourceLoader
    didCancelLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest {
    [self removeLoadingRequest:loadingRequest];
    [self.requestTask cancleTaskWithLoadingRequest:loadingRequest];
}

#pragma mark - AVURLRequestTaskDelegate
- (void)requestTask:(AVURLRequestTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {
    if (self.delegate && [self.delegate respondsToSelector:@selector(resourceLoader:didReceiveChallenge:completionHandler:)]) {
        [self.delegate resourceLoader:self didReceiveChallenge:challenge completionHandler:completionHandler];
    }
}

@end
