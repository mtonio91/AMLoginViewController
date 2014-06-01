//
//    TWAPIManager.h
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

@import Foundation;

@class ACAccount;

typedef void(^ReverseAuthResponseHandler)(NSData *responseData, NSError *error);

@interface TWAPIManager : NSObject

/**
 *  Obtains the access token and secret for |account|.
 *
 *  There are two steps required for Reverse Auth:
 *
 *  The first sends a signed request that *you* must sign to Twitter to obtain
 *      an Authorization: header. You sign the request with your own OAuth keys.
 *      All apps have access to Reverse Auth by default, so there are no special
 *      permissions required.
 *
 *  The second step uses SLRequest to sign and send the response to step 1 back
 *      to Twitter. The response to this request, if everything worked, will
 *      include an user's access token and secret which can then
 *      be used in conjunction with your consumer key and secret to make
 *      authenticated calls to Twitter.
 */
- (void)performReverseAuthForAccount:(ACAccount *)account withHandler:(ReverseAuthResponseHandler)handler;

/**
 * Returns true if there are local Twitter accounts available.
 */
+ (BOOL)isLocalTwitterAccountAvailable;

/**
 * Returns true if the Info.plist is configured properly.
 */
+ (BOOL)hasAppKeys;

@end
