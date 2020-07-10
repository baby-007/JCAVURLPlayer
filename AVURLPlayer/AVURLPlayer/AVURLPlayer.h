//
//  AVURLPlayer.h
//  AVURLPlayer
//
//  Created by karlcool on 2018/1/22.
//  Copyright © 2018年 karlcool. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AVURLPlayerControlDelegate.h"
#import "AVURLResourceLoader.h"

@interface AVURLPlayer : UIView
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithUrl:(NSString *)urlString interval: (Float64)interval;
+ (AVURLPlayer *)playerWithUrl:(NSString *)urlString interval: (Float64)interval;

- (instancetype)initWithUrl:(NSString *)urlString;
+ (AVURLPlayer *)playerWithUrl:(NSString *)urlString;

@property (nonatomic, readonly) AVPlayer       *player;
@property (nonatomic, readonly) AVPlayerItem   *playerItem;
@property (nonatomic, readonly) AVPlayerLayer  *playerLayer;
@property (nonatomic, readonly) AVURLAsset     *urlAsset;
@property (nonatomic, readonly) AVURLResourceLoader *resourceLoader;
@property (nonatomic, readonly) BOOL isPlaying;

@property (nonatomic, assign) NSUInteger repeatCount;
@property (nonatomic, assign, readonly) NSUInteger currentRepeatCount;
@property (nonatomic, assign) BOOL automaticallyPlay;
@property (nonatomic, assign) BOOL muted;
@property (nonatomic, strong) UIView<AVURLPlayerControlDelegate> *controlView;
@property (nonatomic, weak) id<AVURLResourceLoaderDelegate> loaderDelegate;

- (void)play;
- (void)pause;
- (void)stop;
@end
