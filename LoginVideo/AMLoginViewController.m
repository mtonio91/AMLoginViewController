//
//  AMLoginViewController.m
//  LoginVideo
//
//  Created by AMarliac on 2014-04-02.
//  Copyright (c) 2014 AMarliac. All rights reserved.
//

#import "AMLoginViewController.h"

@import Accounts;

#import "OAuth+Additions.h"
#import "TWAPIManager.h"
#import "TWSignedRequest.h"
#import <Social/Social.h>
#import <Social/SLComposeViewController.h>

#define ERROR_TITLE_MSG @"Whoa, there cowboy"
#define ERROR_NO_ACCOUNTS @"You must add a Twitter account in Settings.app to use this demo."
#define ERROR_PERM_ACCESS @"We weren't granted access to the user's accounts"
#define ERROR_NO_KEYS @"You need to add your Twitter app keys to Info.plist to use this demo.\nPlease see README.md for more info."
#define ERROR_OK @"OK"

#define ONE_FOURTH_OF(_X) floorf(0.25f * _X)
#define THREE_FOURTHS_OF(_X) floorf(3 * ONE_FOURTH_OF(_X))

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
@property (nonatomic, strong) ACAccountStore *accountStore;
@property (nonatomic, strong) TWAPIManager *apiManager;
@property (nonatomic, strong) NSArray *accounts;
@property (nonatomic, strong) UIButton *reverseAuthBtn;
@end

@implementation AMLoginViewController
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        
    }
    return self;
}
- (void)viewDidLoad
{
    [super viewDidLoad];

    _accountStore = [[ACAccountStore alloc] init];
    _apiManager = [[TWAPIManager alloc] init];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_refreshTwitterAccounts) name:ACAccountStoreDidChangeNotification object:nil];
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    
    // ---------------------------AVPLAYER STUFF -------------------------------
    
    
    NSString * ressource = [[NSBundle mainBundle] pathForResource:@"demoVideo" ofType:@".mp4"];
    
    
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
    //change the float value in order to change the blur effect
    _blurFilter.blurRadiusInPixels = 12.0f;
    _blurFilter.downsampling = 1.0f;
    _videoBuffer = [[GPUImageBuffer alloc] init];
    [_videoBuffer setBufferSize:1];
    
    // ---------------------------------------------------------------------
    
    
    [self setViewItems];
    
    //GESTURE - Dismiss the keyboard when tapped on the controller's view
    UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:tap];
    tap.delegate = self;
    
    //start processing BLUR with background video
    [self procesBlurWithBackgroundVideoOnView:_usernameView];
    [self procesBlurWithBackgroundVideoOnView:_passwordView];
    
    
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
    [self procesBlurWithBackgroundVideoOnView:_usernameView];
    [self procesBlurWithBackgroundVideoOnView:_passwordView];
}


- (void)playerItemDidReachEnd:(NSNotification *)notification
{
    AVPlayerItem *p = [notification object];
    [p seekToTime:kCMTimeZero];
}


- (void) procesBlurWithBackgroundVideoOnView:(BlurView*)view
{
    
    //        _liveVideo = [[GPUImageMovie alloc] initWithPlayerItem:avPlayer.currentItem];
    //
    //        [_liveVideo addTarget:_videoBuffer];
    //        [_videoBuffer addTarget:_blurFilter];
    //        [_blurFilter addTarget:view];
    //        [_liveVideo startProcessing];
}


- (void) setViewItems
{
    UIImageView * loginImage = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, 110, 110)];
    [loginImage setImage:[UIImage imageNamed:@"logoclubby.png"]];
    loginImage.center = CGPointMake(self.view.frame.size.width/2, 120);
    [self.view addSubview:loginImage];
    
    _usernameView = [[BlurView alloc] initWithFrame:CGRectMake(35, 245, 250, 50)];
    _passwordView = [[BlurView alloc] initWithFrame:CGRectMake(35, 300, 250, 50)];
    
    
    _sendButtonView   = [[UIView alloc] initWithFrame:CGRectMake(35, 370, 250, 50)];
    _loginWithTWTView = [[UIView alloc] initWithFrame:CGRectMake(35, 430, 250, 50)];
    _loginWithFBView  = [[UIView alloc] initWithFrame:CGRectMake(35, 490, 250, 50)];
    
    
    
    
    _sendButtonView.backgroundColor = [UIColor colorWithRed:0.925 green:0.941 blue:0.945 alpha:0.7];
    _loginWithTWTView.backgroundColor = [UIColor colorWithRed:0.925 green:0.941 blue:0.945 alpha:0.7];
    //_loginWithFBView.backgroundColor = [UIColor colorWithRed:0.925 green:0.941 blue:0.945 alpha:0.7];
    
    
    //BUTTON
    UIButton * sendButton = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, _sendButtonView.frame.size.width, _sendButtonView.frame.size.height)];
    [sendButton setTitle:@"LOGIN" forState:UIControlStateNormal];
    [sendButton setTitleColor:[UIColor colorWithRed:0.173 green:0.243 blue:0.314 alpha:1] forState:UIControlStateNormal];
    
    [_sendButtonView addSubview:sendButton];
    
    
    //BUTTON Twitter
    UIButton * twtButton = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, _loginWithTWTView.frame.size.width, _loginWithTWTView.frame.size.height)];
    [twtButton setTitle:@"LOGIN With Twitter" forState:UIControlStateNormal];
    [twtButton setTitleColor:[UIColor colorWithRed:0.173 green:0.243 blue:0.314 alpha:1] forState:UIControlStateNormal];
    
    
    
    [_loginWithTWTView addSubview:twtButton];
    [twtButton addTarget:self action:@selector(auth) forControlEvents:UIControlEventTouchUpInside];
    
    
    //BUTTON  Facebook
    //    UIButton * fbButton = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, _loginWithFBView.frame.size.width, _loginWithFBView.frame.size.height)];
    //    [fbButton setTitle:@"LOGIN With FaceBook" forState:UIControlStateNormal];
    //    [fbButton setTitleColor:[UIColor colorWithRed:0.173 green:0.243 blue:0.314 alpha:1] forState:UIControlStateNormal];
    //
    //    [_loginWithFBView addSubview:fbButton];
    //    [fbButton addTarget:self action:@selector(yourMethod:) forControlEvents:UIControlEventTouchUpInside];
    
    
    // Create a FBLoginView to log the user in with basic, email and friend list permissions
    // You should ALWAYS ask for basic permissions (public_profile) when logging the user in
    FBLoginView *loginView = [[FBLoginView alloc] initWithReadPermissions:@[@"public_profile", @"email", @"user_friends"]];
    
    // Set this loginUIViewController to be the loginView button's delegate
    loginView.delegate = self;
    
    // Align the button in the center horizontally
    loginView.frame = CGRectMake(0, 0, _loginWithFBView.frame.size.width, _loginWithFBView.frame.size.height);
    
    // Align the button in the center vertically
    //loginView.center = self.view.center;
    
    // Add the button to the view
    [_loginWithFBView addSubview:loginView];
    
    
    
    
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
    
    [self.view addSubview:_loginWithTWTView];
    [self.view addSubview:_loginWithFBView];
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
/**************************************/
// This method will be called when the user information has been fetched
- (void)loginViewFetchedUserInfo:(FBLoginView *)loginView
                            user:(id<FBGraphUser>)user {
    //    self.profilePictureView.profileID = user.id;
    //    self.nameLabel.text = user.name;
}

// Implement the loginViewShowingLoggedInUser: delegate method to modify your app's UI for a logged-in user experience
- (void)loginViewShowingLoggedInUser:(FBLoginView *)loginView {
    // self.statusLabel.text = @"You're logged in as";
}

// Implement the loginViewShowingLoggedOutUser: delegate method to modify your app's UI for a logged-out user experience
- (void)loginViewShowingLoggedOutUser:(FBLoginView *)loginView {
    //    self.profilePictureView.profileID = nil;
    //    self.nameLabel.text = @"";
    //    self.statusLabel.text= @"You're not logged in!";
}

// You need to override loginView:handleError in order to handle possible errors that can occur during login
- (void)loginView:(FBLoginView *)loginView handleError:(NSError *)error {
    NSString *alertMessage, *alertTitle;
    
    // If the user should perform an action outside of you app to recover,
    // the SDK will provide a message for the user, you just need to surface it.
    // This conveniently handles cases like Facebook password change or unverified Facebook accounts.
    if ([FBErrorUtility shouldNotifyUserForError:error]) {
        alertTitle = @"Facebook error";
        alertMessage = [FBErrorUtility userMessageForError:error];
        
        // This code will handle session closures since that happen outside of the app.
        // You can take a look at our error handling guide to know more about it
        // https://developers.facebook.com/docs/ios/errors
    } else if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryAuthenticationReopenSession) {
        alertTitle = @"Session Error";
        alertMessage = @"Your current session is no longer valid. Please log in again.";
        
        // If the user has cancelled a login, we will do nothing.
        // You can also choose to show the user a message if cancelling login will result in
        // the user not being able to complete a task they had initiated in your app
        // (like accessing FB-stored information or posting to Facebook)
    } else if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryUserCancelled) {
        NSLog(@"user cancelled login");
        
        // For simplicity, this sample handles other errors with a generic message
        // You can checkout our error handling guide for more detailed information
        // https://developers.facebook.com/docs/ios/errors
    } else {
        alertTitle  = @"Something went wrong";
        alertMessage = @"Please try again later.";
        NSLog(@"Unexpected error:%@", error);
    }
    
    if (alertMessage) {
        [[[UIAlertView alloc] initWithTitle:alertTitle
                                    message:alertMessage
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
    }
}
/*********************************************/
#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != actionSheet.cancelButtonIndex) {
        [_apiManager performReverseAuthForAccount:_accounts[buttonIndex] withHandler:^(NSData *responseData, NSError *error) {
            if (responseData) {
                NSString *responseStr = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
                
                //TWDLog(@"Reverse Auth process returned: %@", responseStr);
                
                NSArray *parts = [responseStr componentsSeparatedByString:@"&"];
                NSString *lined = [parts componentsJoinedByString:@"\n"];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Success!" message:lined delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    [alert show];
                });
            }
            else {
                //TWALog(@"Reverse Auth process failed. Error returned was: %@\n", [error localizedDescription]);
            }
        }];
    }
}

#pragma mark - Private
- (void)_displayAlertWithMessage:(NSString *)message
{
    //    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:ERROR_TITLE_MSG message:message delegate:nil cancelButtonTitle:ERROR_OK otherButtonTitles:nil];
    //    [alert show];
    SLComposeViewController *tweetSheet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
    tweetSheet.view.hidden=YES;

    
    [self presentViewController:tweetSheet animated:NO completion:nil];
    [tweetSheet resignFirstResponder];
    [tweetSheet.view resignFirstResponder];

    //tweetSheet.editing=NO;
   [tweetSheet.view endEditing:YES];
    
    
    //[tweetSheet setInitialText:@"this is a test"];

    
    
    
    
}

/**
 *  Checks for the current Twitter configuration on the device / simulator.
 *
 *  First, we check to make sure that we've got keys to work with inside Info.plist (see README)
 *
 *  Then we check to see if the device has accounts available via +[TWAPIManager isLocalTwitterAccountAvailable].
 *
 *  Next, we ask the user for permission to access his/her accounts.
 *
 *  Upon completion, the button to continue will be displayed, or the user will be presented with a status message.
 */
- (void)_refreshTwitterAccounts
{
    //TWDLog(@"Refreshing Twitter Accounts \n");
    
    if (![TWAPIManager hasAppKeys]) {
        [self _displayAlertWithMessage:ERROR_NO_KEYS];
    }
    else if (![TWAPIManager isLocalTwitterAccountAvailable]) {
        [self _displayAlertWithMessage:ERROR_NO_ACCOUNTS];
    }
    else {
        [self _obtainAccessToAccountsWithBlock:^(BOOL granted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (granted) {
                    _reverseAuthBtn.enabled = YES;
                }
                else {
                    [self _displayAlertWithMessage:ERROR_PERM_ACCESS];
                    //TWALog(@"You were not granted access to the Twitter accounts.");
                }
            });
        }];
    }
}

- (void)_obtainAccessToAccountsWithBlock:(void (^)(BOOL))block
{
    ACAccountType *twitterType = [_accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    ACAccountStoreRequestAccessCompletionHandler handler = ^(BOOL granted, NSError *error) {
        if (granted) {
            self.accounts = [_accountStore accountsWithAccountType:twitterType];
        }
        
        block(granted);
    };
    [_accountStore requestAccessToAccountsWithType:twitterType options:NULL completion:handler];
}

/**
 *  Handles the button press that initiates the token exchange.
 *
 *  We check the current configuration inside -[UIViewController viewDidAppear].
 */
- (void)performReverseAuth:(id)sender
{
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Choose an Account" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    for (ACAccount *acct in _accounts) {
        [sheet addButtonWithTitle:acct.username];
    }
    sheet.cancelButtonIndex = [sheet addButtonWithTitle:@"Cancel"];
    [sheet showInView:self.view];
}

- (void)auth {
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Choose an Account" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    if (_accounts !=nil) {
        for (ACAccount *acct in _accounts) {
            [sheet addButtonWithTitle:acct.username];
        }
        sheet.cancelButtonIndex = [sheet addButtonWithTitle:@"Cancel"];
        [sheet showInView:self.view];
    }
    
    
    
    [self _displayAlertWithMessage:@""];
    
}
-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    // Here You can do additional code or task instead of writing with keyboard
    return NO;
}


@end
