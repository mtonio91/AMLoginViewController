//
//    TWViewController.m
//    TWiOSReverseAuthExample
//
//    Copyright (c) 2011-2014 Sean Cook
//
//    Permission is hereby granted, free of charge, to any person obtaining a
//    copy of this software and associated documentation files (the
//    "Software"), to deal in the Software without restriction, including
//    without limitation the rights to use, copy, modify, merge, publish,
//    distribute, sublicense, and/or sell copies of the Software, and to permit
//    persons to whom the Software is furnished to do so, subject to the
//    following conditions:
//
//    The above copyright notice and this permission notice shall be included
//    in all copies or substantial portions of the Software.
//
//    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
//    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
//    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
//    NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
//    DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
//    OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
//    USE OR OTHER DEALINGS IN THE SOFTWARE.
//

@import Accounts;

#import "OAuth+Additions.h"
#import "TWAPIManager.h"
#import "TWSignedRequest.h"
#import "TWViewController.h"
#import <Social/Social.h>
#import <Social/SLComposeViewController.h>

#define ERROR_TITLE_MSG @"Whoa, there cowboy"
#define ERROR_NO_ACCOUNTS @"You must add a Twitter account in Settings.app to use this demo."
#define ERROR_PERM_ACCESS @"We weren't granted access to the user's accounts"
#define ERROR_NO_KEYS @"You need to add your Twitter app keys to Info.plist to use this demo.\nPlease see README.md for more info."
#define ERROR_OK @"OK"

#define ONE_FOURTH_OF(_X) floorf(0.25f * _X)
#define THREE_FOURTHS_OF(_X) floorf(3 * ONE_FOURTH_OF(_X))

@interface TWViewController()

@property (nonatomic, strong) ACAccountStore *accountStore;
@property (nonatomic, strong) TWAPIManager *apiManager;
@property (nonatomic, strong) NSArray *accounts;
@property (nonatomic, strong) UIButton *reverseAuthBtn;

@end

@implementation TWViewController

#pragma mark - UIViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _accountStore = [[ACAccountStore alloc] init];
        _apiManager = [[TWAPIManager alloc] init];
    }
    return self;
}

//- (void)loadView
//{
//    CGRect appFrame = [UIScreen mainScreen].applicationFrame;
//    
//    CGRect buttonFrame = appFrame;
//    buttonFrame.origin.y = THREE_FOURTHS_OF(appFrame.size.height);  //floorf(THREE_FOURTHS_OF * appFrame.size.height);
//    buttonFrame.size.height = 44.0f;
//    buttonFrame = CGRectInset(buttonFrame, 20, 0);
//    
//    UIView *view = [[UIView alloc] initWithFrame:appFrame];
//    [view setBackgroundColor:[UIColor colorWithWhite:0.502 alpha:1.000]];
//    
//    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"twitter.png"]];
//    [view addSubview:imageView];
//    [imageView sizeToFit];
//    imageView.center = view.center;
//    
//    CGRect imageFrame = imageView.frame;
//    imageFrame.origin.y = ONE_FOURTH_OF(appFrame.size.height);
//    imageView.frame = imageFrame;
//    
//    _reverseAuthBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
//    [_reverseAuthBtn setTitle:@"Perform Token Exchange" forState:UIControlStateNormal];
//    [_reverseAuthBtn addTarget:self action:@selector(performReverseAuth:) forControlEvents:UIControlEventTouchUpInside];
//    _reverseAuthBtn.frame = buttonFrame;
//    _reverseAuthBtn.enabled = NO;
//    [_reverseAuthBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
//    [view addSubview:_reverseAuthBtn];
//    
//    self.view = view;
//}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self _refreshTwitterAccounts];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_refreshTwitterAccounts) name:ACAccountStoreDidChangeNotification object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

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
    
    //[tweetSheet setInitialText:@"this is a test"];
    [self presentViewController:tweetSheet animated:NO completion:nil];
    
    
    
    

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

- (IBAction)auth:(id)sender {
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Choose an Account" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    if ([_accounts count]>0) {
        for (ACAccount *acct in _accounts) {
            [sheet addButtonWithTitle:acct.username];
        }
        sheet.cancelButtonIndex = [sheet addButtonWithTitle:@"Cancel"];
        [sheet showInView:self.view];
    }

    
    
    
    [self _displayAlertWithMessage:@""];

}

- (IBAction)getpic:(id)sender {
//    
//     NSURL *url =
//    [NSURL URLWithString:@"http://api.twitter.com/1/users/show.json"];
//    
//    NSDictionary *params = [NSDictionary dictionaryWithObject:@"theSeanCook"
//                                                       forKey:@"screen_name"];
//    
//    TWRequest *request = [[TWRequest alloc] initWithURL:url
//                                             parameters:params
//                                          requestMethod:TWRequestMethodGET];
//    
//    [request performRequestWithHandler:
//     ^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
//         if (responseData) {
//             NSDictionary *user =
//             [NSJSONSerialization JSONObjectWithData:responseData
//                                             options:NSJSONReadingAllowFragments
//                                               error:NULL];
//             
//             NSString *profileImageUrl = [user objectForKey:@"profile_image_url"];
//             
//             //  As an example we could set an image's content to the image
//             dispatch_async
//             (dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//                 NSData *imageData =
//                 [NSData dataWithContentsOfURL:
//                  [NSURL URLWithString:profileImageUrl]];
//                 
//                 UIImage *image = [UIImage imageWithData:imageData];
//                 
//                 dispatch_async(dispatch_get_main_queue(), ^{
//                     self.profileImageView.image = image;
//                 });
//             });
//         }
//     }];
}
@end
