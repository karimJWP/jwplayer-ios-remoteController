//
//  ViewController.m
//  JWRemoteController
//
//  Created by Karim Mourra on 11/27/15.
//  Copyright © 2015 Karim Mourra. All rights reserved.
//

#import "ViewController.h"
#import <JWPlayer-iOS-SDK/JWPlayerController.h>
#import "JWRCommunicationHelper.h"

#define videoFile @"http://content.bitsontherun.com/videos/bkaovAYt-52qL9xLP.mp4"

@interface ViewController () <WCSessionDelegate, JWPlayerDelegate>

@property (nonatomic) JWPlayerController *player;
@property (nonatomic) WCSession *session;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setUpSession];
    [self createPlayer];
}

- (void)setUpSession
{
    if ([WCSession isSupported]) {
        self.session = [WCSession defaultSession];
        self.session.delegate = self;
        [self.session activateSession];
    }
}

-(void)viewDidAppear:(BOOL)animated
{
    [self.view addSubview:self.player.view];
}

- (void)createPlayer
{
    JWConfig* config = [[JWConfig alloc]initWithContentUrl:videoFile];
    config.size = CGSizeMake(self.view.frame.size.width, self.view.frame.size.width);
    config.repeat = YES;
    
    self.player = [[JWPlayerController alloc]initWithConfig:config];
    self.player.forceLandscapeOnFullScreen = YES;
    self.player.forceFullScreenOnLandscape = YES;
    self.player.view.center = self.view.center;
    self.player.delegate = self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma Mark - Session delegate methods

-(void)session:(WCSession *)session didReceiveMessage:(NSDictionary<NSString *,id> *)message replyHandler:(void (^)(NSDictionary<NSString *,id> * _Nonnull))replyHandler
{
    if (message[JWRControlMessage]) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self.player performSelector:NSSelectorFromString(message[JWRControlMessage])];
        });
    } else if (message[JWRSeekMessage]) {
        NSNumber *seekPercentage = message[JWRSeekMessage];
        CGFloat seekTime = (seekPercentage.floatValue / 100) * self.player.duration;
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self.player seek:seekTime];
        });
    }
}

#pragma Mark - Player delegate methods

-(void)onPlay
{
    [self.session sendMessage:@{JWRCallbackMessage: JWROnPlayCallback}
                 replyHandler:^(NSDictionary<NSString *,id> * _Nonnull replyMessage) {}
                 errorHandler:^(NSError * _Nonnull error) {}];
}

-(void)onPause
{
    [self.session sendMessage:@{JWRCallbackMessage: JWROnPauseCallback}
                 replyHandler:^(NSDictionary<NSString *,id> * _Nonnull replyMessage) {}
                 errorHandler:^(NSError * _Nonnull error) {}];
}

-(void)onTime:(double)position ofDuration:(double)duration
{
    NSDictionary *onTimeMessage = @{JWRCallbackMessage: JWROnTimeCallback,
                                    JWROnTimePosition: @(position),
                                    JWROnTimeDuration: @(duration)};
    
    [self.session sendMessage: onTimeMessage
                 replyHandler:^(NSDictionary<NSString *,id> * _Nonnull replyMessage) {}
                 errorHandler:^(NSError * _Nonnull error) {}];
}

@end