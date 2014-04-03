//
//  BlurView.m
//  Video Blurring
//
//  Created by Mike Jaoudi on 12/18/13.
//  Copyright (c) 2013 Mike Jaoudi. All rights reserved.
//

#import "BlurView.h"

@implementation BlurView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        CGRect deviceSize = [UIScreen mainScreen].bounds;

        self.layer.contentsRect = CGRectMake(frame.origin.x/deviceSize.size.height, frame.origin.y/deviceSize.size.width, frame.size.width/deviceSize.size.height, frame.size.height/deviceSize.size.width);
        self.fillMode = kGPUImageFillModeStretch;
    
    }
    return self;
}


@end
