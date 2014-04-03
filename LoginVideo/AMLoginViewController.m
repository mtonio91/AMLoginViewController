//
//  AMLoginViewController.m
//  LoginVideo
//
//  Created by AMarliac on 2014-04-02.
//  Copyright (c) 2014 AMarliac. All rights reserved.
//

#import "AMLoginViewController.h"



@interface AMLoginViewController ()
{
    AVPlayer * avPlayer;
    AVPlayerLayer *avPlayerLayer;
    CMTime time;
    
    //blur
    GPUImageiOSBlurFilter *_blurFilter;
    GPUImageBuffer *_videoBuffer;
    GPUImageMovie *_liveVideo;

    
    UITextField * usernameTf;
    UITextField * passwordTf;
}

@end

@implementation AMLoginViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];

    // ---------------------------AVPLAYER STUFF -------------------------------

    
    NSString * ressource = [[NSBundle mainBundle] pathForResource:@"timeLapseMini" ofType:@".m4v"];
    

    NSURL * urlPathOfVideo = [NSURL fileURLWithPath:ressource];
    avPlayer = [AVPlayer playerWithURL:urlPathOfVideo];
    avPlayer.actionAtItemEnd = AVPlayerActionAtItemEndNone;

    avPlayerLayer = [AVPlayerLayer playerLayerWithPlayer:avPlayer];
    avPlayerLayer.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    
    [self.view.layer addSublayer: avPlayerLayer];
    
    [avPlayer play];
    time = kCMTimeZero;
    
    //prevent music coming from other app to be stopped
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error:nil];

    
    // -------------------------------------------------------------------------

    
    //AVPlayer Notifications

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:[avPlayer currentItem]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(pauseVideo)
                                                 name:@"PauseBgVideo"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(resumeVideo)
                                                 name:@"ResumeBgVideo"
                                               object:nil];
    
    
    
    
    // ---------------------------BLUR STUFF -------------------------------
    
    
    _blurFilter = [[GPUImageiOSBlurFilter alloc] init];
    _videoBuffer = [[GPUImageBuffer alloc] init];
    [_videoBuffer setBufferSize:1];
    
    // ---------------------------------------------------------------------

    

    [self setViewItems];
    
    //GESTURE - Dismiss the keyboard when tapped on the controller's view
    UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:tap];
    tap.delegate = self;
    
    //start processing BLUR with background video
    [self procesBlurWithBackgroundVideo];

}

#pragma mark - AVPlayer methods


- (void)pauseVideo
{
    [avPlayer pause];
    time = avPlayer.currentTime;
}


- (void)resumeVideo
{
    [avPlayer seekToTime:time toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    [avPlayer play];
    [self procesBlurWithBackgroundVideo];
}


- (void)playerItemDidReachEnd:(NSNotification *)notification
{
    AVPlayerItem *p = [notification object];
    [p seekToTime:kCMTimeZero];
}


- (void) procesBlurWithBackgroundVideo
{
    _liveVideo = [[GPUImageMovie alloc] initWithPlayerItem:avPlayer.currentItem];
    
    [_liveVideo addTarget:_videoBuffer];
    [_videoBuffer addTarget:_blurFilter];
    
    [_blurFilter addTarget:_usernameView];
    [_blurFilter addTarget:_passwordView];
    
    [_liveVideo startProcessing];
}


- (void) setViewItems
{
    UIImageView * loginImage = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, 110, 110)];
    [loginImage setImage:[UIImage imageNamed:@"logoclubby.png"]];
    loginImage.center = CGPointMake(self.view.frame.size.width/2, 120);
    [self.view addSubview:loginImage];
    
    _usernameView = [[BlurView alloc] initWithFrame:CGRectMake(35, 245, 250, 50)];
    _passwordView = [[BlurView alloc] initWithFrame:CGRectMake(35, 300, 250, 50)];
    
    
    _sendButtonView = [[UIView alloc] initWithFrame:CGRectMake(35, 370, 250, 50)];
    _sendButtonView.backgroundColor = [UIColor colorWithRed:0.925 green:0.941 blue:0.945 alpha:0.7];
    
    //BUTTON
    UIButton * sendButton = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, _sendButtonView.frame.size.width, _sendButtonView.frame.size.height)];
    [sendButton setTitle:@"LOGIN" forState:UIControlStateNormal];
    [sendButton setTitleColor:[UIColor colorWithRed:0.173 green:0.243 blue:0.314 alpha:1] forState:UIControlStateNormal];
    
    [_sendButtonView addSubview:sendButton];
    
    //USERNAME Text Field
    UIImageView * userImage = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, 61, 50)];
    [userImage setImage:[UIImage imageNamed:@"user.png"]];
    
    [_usernameView addSubview:userImage];
    
    
    usernameTf = [[UITextField alloc]initWithFrame:CGRectMake(60, 10, 150, 30)];
    usernameTf.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"USERNAME" attributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]}];
    usernameTf.textColor = [UIColor whiteColor];
    [_usernameView addSubview:usernameTf];
    
    
    //PASSWORD Text Field
    UIImageView * lockImage = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, 61, 50)];
    [lockImage setImage:[UIImage imageNamed:@"lock.png"]];
    [_passwordView addSubview:lockImage];
    
    passwordTf = [[UITextField alloc]initWithFrame:CGRectMake(60, 10, 150, 30)];
    passwordTf.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"PASSWORD" attributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]}];
    passwordTf.textColor = [UIColor whiteColor];
    [_passwordView addSubview:passwordTf];
    
    
    [self.view addSubview:_usernameView];
    [self.view addSubview:_passwordView];
    [self.view addSubview:_sendButtonView];

}


#pragma mark - Miscellaneous


-(void) dismissKeyboard
{
    [usernameTf resignFirstResponder];
    [passwordTf resignFirstResponder];
}


#pragma mark - Life cycle methods


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
