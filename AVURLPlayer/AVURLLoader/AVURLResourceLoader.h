//
//  AVURLResourceLoader.h
//  AVURLPlayer
//
//  Created by karlcool on 2018/1/22.
//  Copyright © 2018年 karlcool. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@class AVURLResourceLoader;
@protocol AVURLResourceLoaderDelegate <NSObject>
@optional

- (void)resourceLoader:(AVURLResourceLoader *_Nullable)loader didReceiveChallenge:(NSURLAuthenticationChallenge *_Nullable)challenge completionHandler:(void (^_Nullable)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler;

@end


@interface AVURLResourceLoader : NSObject <AVAssetResourceLoaderDelegate>
@property (nonatomic, weak) id<AVURLResourceLoaderDelegate> _Nullable delegate;

- (void)cancel;

@end
