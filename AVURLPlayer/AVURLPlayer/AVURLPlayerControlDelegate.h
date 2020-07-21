//
//  AVURLPlayerControlDelegate.h
//  AVURLPlayer
//
//  Created by karlcool on 2018/2/2.
//  Copyright © 2018年 karlcool. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 item的实时状态
 
 - AVURLPlayerItemStatusDefault: 无
 - AVURLPlayerItemStatusUnknown: 未处理
 - AVURLPlayerItemStatusReadyToPlay: item已经准备好，可以进行播放了
 - AVURLPlayerItemStatusFailed: 播放失败
 - AVURLPlayerItemStatusBuffering: 缓冲中
 - AVURLPlayerItemStatusBufferReadyToPlay: 缓冲足够进行播放了
 - AVURLPlayerItemStatusBufferFull: 缓冲完成
 - AVURLPlayerItemStatusPlayToEndTime: 播放完成
 */
typedef NS_ENUM(NSInteger, AVURLPlayerItemStatus) {
    AVURLPlayerItemStatusDefault,
    AVURLPlayerItemStatusUnknown,
    AVURLPlayerItemStatusReadyToPlay,
    AVURLPlayerItemStatusFailed,
    AVURLPlayerItemStatusBuffering,
    AVURLPlayerItemStatusBufferReadyToPlay,
    AVURLPlayerItemStatusBufferFull,
    AVURLPlayerItemStatusPlayToEndTime,
};

@class AVURLPlayer;
@protocol AVURLPlayerControlDelegate <NSObject>
@optional

- (void)playerReadyToPlay:(AVURLPlayer *)player;
- (void)player:(AVURLPlayer *)player didUpdateItemStatus:(AVURLPlayerItemStatus)status;
- (void)player:(AVURLPlayer *)player didUpdatePlayingStatus:(BOOL)isPlaying;
- (void)player:(AVURLPlayer *)player didUpdateBuferringStatus:(BOOL)isBuffering;
- (void)player:(AVURLPlayer *)player didFinishedWithError:(NSError *)error;
- (void)player:(AVURLPlayer *)player didUpdatePlayTime:(CGFloat)time;
- (void)player:(AVURLPlayer *)player didGetDuration:(CGFloat)duration;
@end
