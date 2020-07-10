//
//  AVURLRequestTask.m
//  AVURLPlayer
//
//  Created by karlcool on 2018/1/23.
//  Copyright © 2018年 karlcool. All rights reserved.
//

#import "AVURLRequestTask.h"
#import "NSURL+AVURLAdd.h"
#import "AVURLCacheHandle.h"
#import "AVURLRequestDataTask.h"
#import <MobileCoreServices/MobileCoreServices.h>



typedef struct _AVURLRange {
    NSUInteger startOffset;
    NSUInteger endOffset;
    NSUInteger length;
} AVURLRange;


NS_INLINE AVURLRange AVURLMakeRange(NSUInteger startOffset, NSUInteger endOffset) {
    AVURLRange range;
    range.startOffset = startOffset;
    range.endOffset = endOffset;
    range.length = endOffset - startOffset;
    return range;
}

NS_INLINE AVURLRange AVURLRangeFromTask(AVURLRequestDataTask *dataTask) {
    return AVURLMakeRange(dataTask.requestOffset, dataTask.currentOffset);
}

NS_INLINE BOOL AVURLIntersectionRange(AVURLRange range1, AVURLRange range2) {
    if (range2.startOffset > range1.endOffset || range2.startOffset > range1.endOffset) {
        return NO;
    }
    return YES;
}






@interface AVURLRequestTask () <NSURLSessionTaskDelegate>
@property (nonatomic, strong, readwrite) NSURL *requestURL;
@property (nonatomic, strong) NSMutableArray<AVURLRequestDataTask *> *mArrDataTask;
@end


@implementation AVURLRequestTask

#pragma mark - getter

- (NSMutableArray<AVURLRequestDataTask *> *)mArrDataTask {
    if (!_mArrDataTask) {
        _mArrDataTask = [NSMutableArray array];
    }
    return _mArrDataTask;
}


#pragma mark - init

- (nonnull instancetype)initWithURL:(NSURL *)URL {
    self = [super init];
    if (self) {
        self.requestURL = URL;
    }
    return self;
}


#pragma mark - action

- (void)startTaskWithLoadingRequest:(AVAssetResourceLoadingRequest * _Nullable)loadingRequest {
    AVURLRequestDataTask *dataTask = [[AVURLRequestDataTask alloc] initWithURL:self.requestURL
                                                            loadingRequest:loadingRequest];
    [self.mArrDataTask addObject:dataTask];

    [dataTask taskDidReceiveResponse:^(NSURLResponse *response, NSUInteger contentLength) {
        self.contentLength = contentLength;
        
        [self fillContentInformationRequest:dataTask.loadingRequest.contentInformationRequest];
        
        if (!self.cacheHandle) {
            self.cacheHandle = [[AVURLCacheHandle alloc] initWithFileLength:self.contentLength];
        }
    } didReceiveData:^(NSData *data) {
        if (dataTask.respondOffset >= dataTask.requestOffset + dataTask.requestLength /* 填充数据越界 */ ||
            dataTask.loadingRequest.isFinished /* 请求完成了 */ ||
            dataTask.loadingRequest.isCancelled /* 请求取消了 */) {
            return;
        }
        
        @autoreleasepool {
            NSUInteger queuingLength =
            dataTask.requestOffset + dataTask.requestLength - dataTask.respondOffset;
            
            NSUInteger availableLength = MIN(queuingLength, data.length);
            NSData *availableData = [data subdataWithRange:NSMakeRange(0, availableLength)];
            
            // 这里给 loadingRequest.dataRequest 填充数据，并且将数据进行缓存
            // 排除极端情况，这里填充的数据和缓存到磁盘的数据应该是保持一致的
            [dataTask.loadingRequest.dataRequest respondWithData:availableData];
            dataTask.respondOffset += availableData.length;
            
            [self.cacheHandle writeTempFileData:availableData offset:dataTask.cachingOffset];
            dataTask.cachingOffset += availableData.length;
            
            if (availableLength >= queuingLength) {
                [dataTask.loadingRequest finishLoading];
                [dataTask cancle];
            }
        }
    } didCompleteWithError:^(NSError *error) {
        NSError *resultError = error;
        if (error.code == NSURLErrorCancelled) {
            resultError = nil;
        }
        
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(requestTask:didCompleteWithError:)]) {
            [self.delegate requestTask:self didCompleteWithError:error];
        }
        
        [self checkCache];
    } willChallenge:^(NSURLAuthenticationChallenge *challenge, ChallengeCompleteHandler completion) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(requestTask:didReceiveChallenge:completionHandler:)]) {
            [self.delegate requestTask:self didReceiveChallenge:challenge completionHandler:completion];
        }
    }];

    
    [dataTask start];
}

- (void)cancleTaskWithLoadingRequest:(AVAssetResourceLoadingRequest * _Nullable)loadingRequest {
    AVURLRequestDataTask *targetTask = nil;
    for (AVURLRequestDataTask *dataTask in self.mArrDataTask) {
        if (dataTask.loadingRequest == loadingRequest) {
            targetTask = dataTask;
            break;
        }
    }
    
    if (targetTask)
        [targetTask cancle];
}

- (void)cancle {
    for (AVURLRequestDataTask *dataTask in self.mArrDataTask) {
        [dataTask cancle];
    }
}


#pragma mark - tool

- (void)checkCache {
    NSSortDescriptor *sorter = [NSSortDescriptor sortDescriptorWithKey:@"requestOffset" ascending:YES];
    NSSortDescriptor *sorter1 = [NSSortDescriptor sortDescriptorWithKey:@"cachingOffset" ascending:YES];
    [self.mArrDataTask sortUsingDescriptors:@[sorter, sorter1]];
    
    AVURLRequestDataTask *tempTask = self.mArrDataTask.firstObject;
    AVURLRange unionRange = AVURLRangeFromTask(tempTask);
    for (AVURLRequestDataTask *task in self.mArrDataTask) {
        AVURLRange range = AVURLRangeFromTask(task);
        if (AVURLIntersectionRange(unionRange, range)) {
            unionRange = AVURLMakeRange(MIN(unionRange.startOffset, range.startOffset),
                                      MAX(unionRange.endOffset, range.endOffset));
        }
    }
    
    if (unionRange.endOffset == self.contentLength) {
        [self.cacheHandle cacheTempFileWithURL:[self.requestURL au_originalSchemeURL]];
        [self.cacheHandle clearTempFile];
    }
}

- (void)fillContentInformationRequest:(AVAssetResourceLoadingContentInformationRequest *)contentInformationRequest  {
    NSString *strContentType = @"video/mp4";
    CFStringRef inTag = (__bridge CFStringRef)(strContentType);
    CFStringRef contentType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, inTag, NULL);
    contentInformationRequest.contentType = CFBridgingRelease(contentType);
    contentInformationRequest.byteRangeAccessSupported = YES;
    contentInformationRequest.contentLength = self.contentLength;
}
@end
