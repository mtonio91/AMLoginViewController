//
//  OAuth+Additions.m
//
//  Created by Loren Brichter on 6/9/10.
//  Copyright 2010 Loren Brichter. All rights reserved.
//

#import "OAuth+Additions.h"

@implementation NSURL (OAuthAdditions)

+ (NSDictionary *)ab_parseURLQueryString:(NSString *)query
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    NSArray *pairs = [query componentsSeparatedByString:@"&"];
    for(NSString *pair in pairs) {
        NSArray *keyValue = [pair componentsSeparatedByString:@"="];
        if([keyValue count] == 2) {
            NSString *key = keyValue[0];
            NSString *value = keyValue[1];
            value = [value stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            if(key && value)
                dict[key] = value;
        }
    }
    return [NSDictionary dictionaryWithDictionary:dict];
}

@end

@implementation NSString (OAuthAdditions)

- (NSString *)ab_RFC3986EncodedString // UTF-8 encodes prior to URL encoding
{
    NSMutableString *result = [NSMutableString string];
    const char *p = [self UTF8String];
    unsigned char c;
    
    for(; (c = *p); p++)
    {
        switch(c)
        {
            case '0' ... '9':
            case 'A' ... 'Z':
            case 'a' ... 'z':
            case '.':
            case '-':
            case '~':
            case '_':
                [result appendFormat:@"%c", c];
                break;
            default:
                [result appendFormat:@"%%%02X", c];
        }
    }
    return result;
}

+ (NSString *)ab_GUID
{
    CFUUIDRef u = CFUUIDCreate(kCFAllocatorDefault);
    CFStringRef s = CFUUIDCreateString(kCFAllocatorDefault, u);
    CFRelease(u);
    return [(NSString *)s autorelease];
}

@end
