//
//  AVURLPlayer.m
//  AVURLPlayer
//
//  Created by karlcool on 2018/1/22.
//  Copyright © 2018年 karlcool. All rights reserved.
//

#import "AVURLPlayer.h"
#import <AVFoundation/AVFoundation.h>
#import "NSURL+AVURLAdd.h"
#import "AVURLCacheHandle.h"
#import "AVURLPlayerControlDelegate.h"


#pragma mark enum

/**
 播放器状态
 这个是记录播放器的真实播放状态的

 - AVURLPlayerStatusPlaying: 播放中
 - AVURLPlayerStatusPause: 暂停中
 - AVURLPlayerStatusFailed: 出错
 */
typedef NS_ENUM(NSInteger, AVURLPlayerStatus) {
    AVURLPlayerStatusPlaying,
    AVURLPlayerStatusPause,
    AVURLPlayerStatusFailed
};



/**
 这个是播放器即将的行为状态
 播放器即将执行的状态，
 eg,
 当前播放状态是 AVURLPlayerForwardStatusPlay，
 希望播放器执行即将的状态是 AVURLPlayerForwardStatusPause
 
 - AVURLPlayerForwardStatusPlay: 播放
 - AVURLPlayerForwardStatusPause: 暂停
 */
typedef NS_ENUM(NSInteger, AVURLPlayerForwardStatus) {
    AVURLPlayerForwardStatusPlay,
    AVURLPlayerForwardStatusPause
};


#pragma mark kvo
static NSString * const kPlayer_rate = @"rate";
static NSString * const kPlayer_error = @"error";
static NSString * const kPlayer_timeControlStatus = @"timeControlStatus";
static NSString * const kPlayerItem_status = @"status";
static NSString * const kPlayerItem_duration = @"duration";
static NSString * const kPlayerItem_loadedTimeRanges = @"loadedTimeRanges";
static NSString * const kPlayerItem_playbackBufferEmpty = @"playbackBufferEmpty";
static NSString * const kPlayerItem_playbackLikelyToKeepUp = @"playbackLikelyToKeepUp";
static NSString * const kPlayerItem_playbackBufferFull = @"playbackBufferFull";




@interface AVURLPlayer ()<AVURLResourceLoaderDelegate>
@property (nonatomic, strong) NSString       *urlString;
@property (nonatomic, strong) id timeObserver;

@property (nonatomic, assign) AVURLPlayerStatus playerStatus;
@property (nonatomic, assign) AVURLPlayerItemStatus playerItemStatus;
@property (nonatomic, assign) AVURLPlayerForwardStatus forwardStatus;

@property(nonatomic, assign)Float64 interval;
@property (nonatomic, assign, readwrite) NSUInteger currentRepeatCount;
@end



@implementation AVURLPlayer

#pragma mark - life circle

- (void)dealloc {
    [self removeObsever];
}


#pragma mark - init

- (instancetype)initWithUrl:(NSString *)urlString interval: (Float64)interval {
    self = [super init];
    if (self) {
        self.urlString = urlString;
        self.interval = interval;
        self.backgroundColor = [UIColor blackColor];
        [self setupPlayer];
    }
    return self;
}

+ (AVURLPlayer *)playerWithUrl:(NSString *)urlString interval: (Float64)interval {
    return [[AVURLPlayer alloc] initWithUrl:urlString interval: interval];
}

- (instancetype)initWithUrl:(NSString *)urlString {
    self = [super init];
    if (self) {
        self.urlString = urlString;
        self.interval = 0.05;
        self.backgroundColor = [UIColor blackColor];
        [self setupPlayer];
    }
    return self;
}

+ (AVURLPlayer *)playerWithUrl:(NSString *)urlString {
    return [[AVURLPlayer alloc] initWithUrl:urlString];
}

- (void)setLoaderDelegate:(id<AVURLResourceLoaderDelegate>)loaderDelegate {
    _resourceLoader.delegate = loaderDelegate;
}

- (id<AVURLResourceLoaderDelegate>)loaderDelegate {
    return _resourceLoader.delegate;
}

#pragma mark - UI

- (void)setControlView:(UIView<AVURLPlayerControlDelegate> *)controlView {
    if (controlView == _controlView) {
        // nothing
    } else {
        if (_controlView) {
            [_controlView removeFromSuperview];
        }
        
        _controlView = controlView;
        
        [self addSubview:controlView];
        
        [self layoutIfNeeded];
    }
}

- (void)setupPlayer {
    NSURL *playUrl  = [NSURL URLWithString:self.urlString];
    NSString *cachePath = [AVURLCacheHandle cacheFileExistsWithURL:playUrl];
    cachePath = nil;
    if (cachePath.length) {
        _playerItem = [AVPlayerItem playerItemWithURL:[NSURL fileURLWithPath:cachePath]];
    } else if (playUrl.scheme.length == 0) {
        //scheme为空就作为本地文件路径处理
        _playerItem = [AVPlayerItem playerItemWithURL:[NSURL fileURLWithPath:self.urlString]];
    } else {
        if ([playUrl.scheme isEqualToString:@"https"]) {
            _urlAsset = [AVURLAsset URLAssetWithURL:[playUrl au_customSchemeURL] options:nil];
            _playerItem = [AVPlayerItem playerItemWithAsset:_urlAsset];
            _resourceLoader = [[AVURLResourceLoader alloc] init];
            _resourceLoader.delegate = self;
            [_urlAsset.resourceLoader setDelegate:_resourceLoader queue:dispatch_get_main_queue()];
        } else {
            _urlAsset = [AVURLAsset URLAssetWithURL:playUrl options:nil];
            _playerItem = [AVPlayerItem playerItemWithAsset:_urlAsset];
        }
    }
    
    _player = [AVPlayer playerWithPlayerItem:_playerItem];
    if (@available(iOS 10, *)) {
        _player.automaticallyWaitsToMinimizeStalling = NO;
    }
    _playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
    _playerLayer.frame = CGRectMake(0, 44, self.bounds.size.width, self.bounds.size.height-44);
    [self.layer addSublayer:_playerLayer];
    
    [self addObserver];
    [self addNotification];
    
    self.forwardStatus = AVURLPlayerForwardStatusPause;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    _playerLayer.frame = self.bounds;
    self.controlView.frame = self.bounds;
}

- (void)setAutomaticallyPlay:(BOOL)automaticallyPlay {
    _automaticallyPlay = automaticallyPlay;
    if (automaticallyPlay) {
        [self play];
    } else {
        [self pause];
    }
}


#pragma mark - public

- (void)play {
    self.forwardStatus = AVURLPlayerForwardStatusPlay;
    
    if (CMTimeGetSeconds(_player.currentItem.currentTime) >=
        CMTimeGetSeconds(_player.currentItem.duration)) {
        [_player seekToTime:CMTimeMakeWithSeconds(4, 600)];
    }
    [AVAudioSession.sharedInstance setCategory:AVAudioSessionCategoryPlayback error:nil];
    [_player play];
}

- (void)pause {
    self.forwardStatus = AVURLPlayerForwardStatusPause;
    [_player pause];
}

- (void)stop {
    [self pause];
    [self.resourceLoader cancel];
}

#pragma mark - action

- (void)setForwardStatus:(AVURLPlayerForwardStatus)forwardStatus {
    _forwardStatus = forwardStatus;
    
    [self updatePlayerItemStatus:_playerItemStatus];
}

- (void)setPlayerItemStatus:(AVURLPlayerItemStatus)playerItemStatus {
    _playerItemStatus = playerItemStatus;
    
    [self updatePlayerItemStatus:playerItemStatus];
}

- (void)setPlayerStatus:(AVURLPlayerStatus)playerStatus {
    _playerStatus = playerStatus;
    
    if (playerStatus == AVURLPlayerStatusFailed) {                                //NSLog(@"debug-AVURLPlayerStatusFailed");
        [self hidePlayingStatusView];
        [self hideBufferLoadingView];
    } else if (playerStatus == AVURLPlayerStatusPlaying) {                        //NSLog(@"debug-AVURLPlayerStatusPlaying");
        
    } else if (playerStatus == AVURLPlayerStatusPause) {                          //NSLog(@"debug-AVURLPlayerStatusPause");
        
    }
}

- (void)updatePlayerItemStatus:(AVURLPlayerItemStatus)playerItemStatus {
    
    // 部分情况处理逻辑相同，暂时全部独立，待扩展
    
    if (playerItemStatus == AVURLPlayerItemStatusDefault) {                       //NSLog(@"debug--AVURLPlayerItemStatusDefault");
        if (self.forwardStatus == AVURLPlayerForwardStatusPlay) {                 //NSLog(@"debug----AVURLPlayerForwardStatusPlay");
            [self hidePlayingStatusView];
            [self showBufferLoadingView];
        } else if (self.forwardStatus == AVURLPlayerForwardStatusPause) {         //NSLog(@"debug----AVURLPlayerForwardStatusPause");
            [self showPlayingStatusView];
            [self hideBufferLoadingView];
        }
        
    } else if (playerItemStatus == AVURLPlayerItemStatusReadyToPlay) {            //NSLog(@"debug--AVURLPlayerItemStatusReadyToPlay");
        if (self.forwardStatus == AVURLPlayerForwardStatusPlay) {                 //NSLog(@"debug----AVURLPlayerForwardStatusPlay");
            [self hidePlayingStatusView];
            [self hideBufferLoadingView];
            [_player play];
        } else if (self.forwardStatus == AVURLPlayerForwardStatusPause) {         //NSLog(@"debug----AVURLPlayerForwardStatusPause");
            [self showPlayingStatusView];
            [self hideBufferLoadingView];
        }
        
    } else if (playerItemStatus == AVURLPlayerItemStatusBuffering) {              //NSLog(@"debug--AVURLPlayerItemStatusBuffering");
        if (self.forwardStatus == AVURLPlayerForwardStatusPlay) {                 //NSLog(@"debug----AVURLPlayerForwardStatusPlay");
            [self hidePlayingStatusView];
            [self showBufferLoadingView];
        } else if (self.forwardStatus == AVURLPlayerForwardStatusPause) {         //NSLog(@"debug----AVURLPlayerForwardStatusPlay");
            [self showPlayingStatusView];
            [self hideBufferLoadingView];
        }
        
    } else if (playerItemStatus == AVURLPlayerItemStatusBufferReadyToPlay) {      //NSLog(@"debug--AVURLPlayerItemStatusBufferReadyToPlay");
        if (self.forwardStatus == AVURLPlayerForwardStatusPlay) {                 //NSLog(@"debug----AVURLPlayerForwardStatusPlay");
            [self hidePlayingStatusView];
            [self hideBufferLoadingView];
            [_player play];
        } else if (self.forwardStatus == AVURLPlayerForwardStatusPause) {         //NSLog(@"debug----AVURLPlayerForwardStatusPause");
            [self showPlayingStatusView];
            [self hideBufferLoadingView];
        }
        
    } else if (playerItemStatus == AVURLPlayerItemStatusBufferFull) {             //NSLog(@"debug--AVURLPlayerItemStatusBufferFull");
        if (self.forwardStatus == AVURLPlayerForwardStatusPlay) {                 //NSLog(@"debug----AVURLPlayerForwardStatusPlay");
            [self hidePlayingStatusView];
            [self hideBufferLoadingView];
            [_player play];
        } else if (self.forwardStatus == AVURLPlayerForwardStatusPause) {         //NSLog(@"debug----AVURLPlayerForwardStatusPause");
            [self showPlayingStatusView];
            [self hideBufferLoadingView];
        }
    } else if (playerItemStatus == AVURLPlayerItemStatusFailed) {                 //NSLog(@"debug--AVURLPlayerItemStatusFailed");
        [self hidePlayingStatusView];
        [self hideBufferLoadingView];
        [self playFinishedWithError];
    } else if (playerItemStatus == AVURLPlayerItemStatusUnknown) {                //NSLog(@"debug--AVURLPlayerItemStatusUnknown");
        
    }
    
    [self.controlView player:self didUpdateItemStatus:playerItemStatus];
//    else if (playerItemStatus == AVURLPlayerItemStatusPlayToEndTime) {          //NSLog(@"debug--AVURLPlayerItemStatusPlayToEndTime");
//        [self showPlayingStatusView];
//        [self hideBufferLoadingView];
//    }
}


#pragma mark - notification

- (void)addNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleAVPlayerItemDidPlayToEndTime:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:_playerItem];
}

- (void)removeNotification {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)handleAVPlayerItemDidPlayToEndTime:(NSNotification *)aNotification {
    AVPlayerItem *item = aNotification.object;
    
    // kCMTimeZero 触发 AVPlayerItemDidPlayToEndTimeNotification
    if (CMTimeGetSeconds(item.currentTime) >=
        CMTimeGetSeconds(item.duration)) {
        //NSLog(@"debug-----handleAVPlayerItemDidPlayToEndTime");
        [self showPlayingStatusView];
        [self hideBufferLoadingView];
        [self playFinished];
        if (self.repeatCount > 0 && self.repeatCount >= ++self.currentRepeatCount) {
            [self hidePlayingStatusView];
            [self hideBufferLoadingView];
            [_player seekToTime:kCMTimeZero];
            [_player play];
        }
    }
}


#pragma mark - observer

- (void)addObserver {
    [_playerItem addObserver:self
                      forKeyPath:kPlayerItem_status
                         options:NSKeyValueObservingOptionNew
                         context:nil];
    [_playerItem addObserver:self
                      forKeyPath:kPlayerItem_loadedTimeRanges
                         options:NSKeyValueObservingOptionNew
                         context:nil];
    [_playerItem addObserver:self
                      forKeyPath:kPlayerItem_playbackBufferEmpty
                         options:NSKeyValueObservingOptionNew
                         context:nil];
    [_playerItem addObserver:self
                      forKeyPath:kPlayerItem_playbackLikelyToKeepUp
                         options:NSKeyValueObservingOptionNew
                         context:nil];
    [_playerItem addObserver:self
                      forKeyPath:kPlayerItem_playbackBufferFull
                         options:NSKeyValueObservingOptionNew
                         context:nil];
    [_playerItem addObserver:self
                      forKeyPath:kPlayerItem_duration
                         options:NSKeyValueObservingOptionNew
                         context:nil];
    
    [_player addObserver:self
                  forKeyPath:kPlayer_error
                     options:NSKeyValueObservingOptionNew
                     context:nil];
    [_player addObserver:self
                  forKeyPath:kPlayer_rate
                     options:NSKeyValueObservingOptionNew
                     context:nil];
    [_player addObserver:self
                  forKeyPath:kPlayer_timeControlStatus
                     options:NSKeyValueObservingOptionNew
                     context:nil];
    __weak AVURLPlayer *weakPlayer = self;
    self.timeObserver = [_player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(_interval, 600)
                                                                  queue:dispatch_get_main_queue()
                                                             usingBlock:^(CMTime time) {
                                                                 [weakPlayer.controlView player:weakPlayer didUpdatePlayTime:CMTimeGetSeconds(time)];
    }];
}

- (void)removeObsever {
    @try {
        [_playerItem removeObserver:self forKeyPath:kPlayerItem_status];
        [_playerItem removeObserver:self forKeyPath:kPlayerItem_duration];
        [_playerItem removeObserver:self forKeyPath:kPlayerItem_loadedTimeRanges];
        [_playerItem removeObserver:self forKeyPath:kPlayerItem_playbackBufferFull];
        [_playerItem removeObserver:self forKeyPath:kPlayerItem_playbackBufferEmpty];
        [_playerItem removeObserver:self forKeyPath:kPlayerItem_playbackLikelyToKeepUp];
        [_player removeObserver:self forKeyPath:kPlayer_error];
        [_player removeObserver:self forKeyPath:kPlayer_rate];
        [_player removeObserver:self forKeyPath:kPlayer_timeControlStatus];
        [_player removeTimeObserver:self.timeObserver];
        self.timeObserver = nil;
    } @catch (NSException *exception) {
        
    } @finally {
        
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    
    AVPlayerItem *playerItem = nil;
    if ([object isKindOfClass:[AVPlayerItem class]]) {
        playerItem = (AVPlayerItem *)object;
    }
    
    if ([keyPath isEqualToString:kPlayerItem_status]) {                         // item状态
        if (playerItem.status == AVPlayerItemStatusReadyToPlay) {
            _playerItemStatus = AVURLPlayerItemStatusReadyToPlay;
        } else if (playerItem.status == AVPlayerItemStatusFailed) {
            _playerItemStatus = AVURLPlayerItemStatusFailed;
            //NSLog(@"_player.currentItem.error:%@", _player.currentItem.error);
        } else if (playerItem.status == AVPlayerItemStatusUnknown) {
            _playerItemStatus = AVURLPlayerItemStatusUnknown;
        }
    } else if ([keyPath isEqualToString:kPlayerItem_loadedTimeRanges]) {        // 缓存进度更新
    } else if ([keyPath isEqualToString:kPlayerItem_playbackBufferEmpty]) {     // 缓存是空
        if (playerItem.isPlaybackBufferEmpty) {
            _playerItemStatus = AVURLPlayerItemStatusBuffering;
        }

    } else if ([keyPath isEqualToString:kPlayerItem_playbackLikelyToKeepUp]) {  // 缓存好了
        if (playerItem.playbackLikelyToKeepUp) {
            _playerItemStatus = AVURLPlayerItemStatusBufferReadyToPlay;
        }
    } else if ([keyPath isEqualToString:kPlayerItem_playbackBufferFull]) {      // 全部缓存完
        if (playerItem.playbackBufferFull) {
            _playerItemStatus = AVURLPlayerItemStatusBufferFull;
        }
    } else if ([keyPath isEqualToString:kPlayerItem_duration]) {
        // 获取到视频时间
        CMTime time = playerItem.duration;
        uint32_t indefinite = time.flags & kCMTimeFlags_Indefinite;//未知时间
        uint32_t valid = time.flags & kCMTimeFlags_Valid;//是有有效
        if (valid != 0 && indefinite == 0) {
            CGFloat dur = CMTimeGetSeconds(playerItem.duration);
            [self didGetDuration:dur];
        }
    } else if ([keyPath isEqualToString:kPlayer_rate]) {                        // player播放状态变化
        if (_player.rate == 0.0) {
            _playerStatus = AVURLPlayerStatusPause;
        } else if (_player.rate == 1.0) {
            _playerStatus = AVURLPlayerStatusPlaying;
        }
    } else if ([keyPath isEqualToString:kPlayer_timeControlStatus]) {           // player播放状态变化
        
    } else if ([keyPath isEqualToString:kPlayer_error]) {                       // player出错
        _playerStatus = AVURLPlayerStatusFailed;
        //NSLog(@"_player.error:%@", _player.error);
    }
}


#pragma mark - tool

- (void)didGetDuration:(CGFloat)duration {
    if ([self.controlView respondsToSelector:@selector(player:didGetDuration:)]) {
        [self.controlView player:self didGetDuration:duration];
    }
}

- (void)hidePlayingStatusView {
    if ([self.controlView respondsToSelector:@selector(player:didUpdatePlayingStatus:)]) {
        [self.controlView player:self didUpdatePlayingStatus:YES];
    }
}

- (void)showPlayingStatusView {
    if ([self.controlView respondsToSelector:@selector(player:didUpdatePlayingStatus:)]) {
        [self.controlView player:self didUpdatePlayingStatus:NO];
    }
}

- (void)showBufferLoadingView {
    if ([self.controlView respondsToSelector:@selector(player:didUpdateBuferringStatus:)]) {
        [self.controlView player:self didUpdateBuferringStatus:YES];
    }
}

- (void)hideBufferLoadingView {
    if ([self.controlView respondsToSelector:@selector(player:didUpdateBuferringStatus:)]) {
        [self.controlView player:self didUpdateBuferringStatus:NO];
    }
}

- (void)playFinishedWithError {
    if ([self.controlView respondsToSelector:@selector(player:didFinishedWithError:)]) {
        [self.controlView player:self didFinishedWithError:_playerItem.error];
    }
}

- (void)playFinished {
    if ([self.controlView respondsToSelector:@selector(player:didFinishedWithError:)]) {
        [self.controlView player:self didFinishedWithError:nil];
    }
}

- (BOOL)isPlaying {
    if ([[UIDevice currentDevice] systemVersion].intValue >= 10) {
        return _player.timeControlStatus == AVPlayerTimeControlStatusPlaying;
    } else {
        return _player.rate == 1;
    }
}
- (BOOL)isPause {
    if ([[UIDevice currentDevice] systemVersion].intValue >= 10) {
        return _player.timeControlStatus == AVPlayerTimeControlStatusPaused;
    } else {
        return _player.rate == 0;
    }
}


- (void)bufferingSomeSecond {
    __block BOOL isBuffering = NO;
    if (isBuffering) return;
    isBuffering = YES;
    
    [_player pause];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self->_player play];
        if (!self->_playerItem.isPlaybackLikelyToKeepUp) {
            [self bufferingSomeSecond];
        }
    });
}
@end
