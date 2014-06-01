//
//  OAuthCore.m
//
//  Created by Loren Brichter on 6/9/10.
//  Copyright 2010 Loren Brichter. All rights reserved.
//

#import "OAuthCore.h"
#import "OAuth+Additions.h"
#import "NSData+Base64.h"
#import <CommonCrypto/CommonHMAC.h>

static NSInteger SortParameter(NSString *key1, NSString *key2, void *context) {
    NSComparisonResult r = [key1 compare:key2];
    if(r == NSOrderedSame) { // compare by value in this case
        NSDictionary *dict = (NSDictionary *)context;
        NSString *value1 = dict[key1];
        NSString *value2 = dict[key2];
        return [value1 compare:value2];
    }
    return r;
}

static NSData *HMAC_SHA1(NSString *data, NSString *key) {
    unsigned char buf[CC_SHA1_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA1, [key UTF8String], [key length], [data UTF8String], [data length], buf);
    return [NSData dataWithBytes:buf length:CC_SHA1_DIGEST_LENGTH];
}

NSString *OAuthorizationHeader(NSURL *url, NSString *method, NSData *body, NSString *_oAuthConsumerKey, NSString *_oAuthConsumerSecret, NSString *_oAuthToken, NSString *_oAuthTokenSecret)
{
    NSString *_oAuthNonce = [NSString ab_GUID];
    NSString *_oAuthTimestamp = [NSString stringWithFormat:@"%d", (int)[[NSDate date] timeIntervalSince1970]];
    NSString *_oAuthSignatureMethod = @"HMAC-SHA1";
    NSString *_oAuthVersion = @"1.0";

    NSMutableDictionary *oAuthAuthorizationParameters = [NSMutableDictionary dictionary];
    oAuthAuthorizationParameters[@"oauth_nonce"] = _oAuthNonce;
    oAuthAuthorizationParameters[@"oauth_timestamp"] = _oAuthTimestamp;
    oAuthAuthorizationParameters[@"oauth_signature_method"] = _oAuthSignatureMethod;
    oAuthAuthorizationParameters[@"oauth_version"] = _oAuthVersion;
    oAuthAuthorizationParameters[@"oauth_consumer_key"] = _oAuthConsumerKey;
    if(_oAuthToken)
        oAuthAuthorizationParameters[@"oauth_token"] = _oAuthToken;

    // get query and body parameters
    NSDictionary *additionalQueryParameters = [NSURL ab_parseURLQueryString:[url query]];
    NSDictionary *additionalBodyParameters = nil;
    if(body) {
        NSString *string = [[[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding] autorelease];
        if(string) {
            additionalBodyParameters = [NSURL ab_parseURLQueryString:string];
        }
    }

    // combine all parameters
    NSMutableDictionary *parameters = [[oAuthAuthorizationParameters mutableCopy] autorelease];
    if(additionalQueryParameters) [parameters addEntriesFromDictionary:additionalQueryParameters];
    if(additionalBodyParameters) [parameters addEntriesFromDictionary:additionalBodyParameters];

    // -> UTF-8 -> RFC3986
    NSMutableDictionary *encodedParameters = [NSMutableDictionary dictionary];
    for(NSString *key in parameters) {
        NSString *value = parameters[key];
        encodedParameters[[key ab_RFC3986EncodedString]] = [value ab_RFC3986EncodedString];
    }

    NSArray *sortedKeys = [[encodedParameters allKeys] sortedArrayUsingFunction:SortParameter context:encodedParameters];

    NSMutableArray *parameterArray = [NSMutableArray array];
    for(NSString *key in sortedKeys) {
        [parameterArray addObject:[NSString stringWithFormat:@"%@=%@", key, encodedParameters[key]]];
    }
    NSString *normalizedParameterString = [parameterArray componentsJoinedByString:@"&"];

    NSString *normalizedURLString = [NSString stringWithFormat:@"%@://%@%@", [url scheme], [url host], [url path]];

    NSString *signatureBaseString = [NSString stringWithFormat:@"%@&%@&%@",
                                     [method ab_RFC3986EncodedString],
                                     [normalizedURLString ab_RFC3986EncodedString],
                                     [normalizedParameterString ab_RFC3986EncodedString]];

    // Updated this from original to allow us to pass in nil to method
    NSString *key = [NSString stringWithFormat:@"%@&%@",
                     [_oAuthConsumerSecret ab_RFC3986EncodedString],
                     (_oAuthTokenSecret) ? [_oAuthTokenSecret ab_RFC3986EncodedString] : @""];

    NSData *signature = HMAC_SHA1(signatureBaseString, key);
    NSString *base64Signature = [signature base64EncodedString];

    NSMutableDictionary *authorizationHeaderDictionary = [[oAuthAuthorizationParameters mutableCopy] autorelease];
    authorizationHeaderDictionary[@"oauth_signature"] = base64Signature;

    NSMutableArray *authorizationHeaderItems = [NSMutableArray array];
    for(NSString *key in authorizationHeaderDictionary) {
        NSString *value = authorizationHeaderDictionary[key];
        [authorizationHeaderItems addObject:[NSString stringWithFormat:@"%@=\"%@\"",
                                             [key ab_RFC3986EncodedString],
                                             [value ab_RFC3986EncodedString]]];
    }

    NSString *authorizationHeaderString = [authorizationHeaderItems componentsJoinedByString:@", "];

    authorizationHeaderString = [NSString stringWithFormat:@"OAuth %@", authorizationHeaderString];

    return authorizationHeaderString;
}
