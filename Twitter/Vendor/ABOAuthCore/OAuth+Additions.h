//
//  OAuth+Additions.h
//
//  Created by Loren Brichter on 6/9/10.
//  Copyright 2010 Loren Brichter. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURL (OAuthAdditions)

+ (NSDictionary *)ab_parseURLQueryString:(NSString *)query;

@end

@interface NSString (OAuthAdditions)

+ (NSString *)ab_GUID;
- (NSString *)ab_RFC3986EncodedString;

@end
