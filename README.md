AMLoginViewController
==================

I originally created this controller for a school project in order to deliver the coolest app possible. I hope this will be useful for other people.


![Screen1](https://github.com/dimohamdy/AMLoginViewController/blob/master/screenshot1.png)



NB: this is login view, so it's not supposed to be used a long time,  the big cpu use because of the blur effect processing shouldn't have a this important impact on the mobile's battery life.

##Known issues


• when blur effect is activated, the video won't work on the simulator. You have to compile it on a device. Or just disable the blur effect to make it work on the simulator.

• arm64 devices seems not compile the demo project because of GPUImage which doesn't support it yet. 

You can disable blur effect in order to improve CPU use (from 25% to ~0%)


##Installation

It uses : 
- GPUImage Framework
- AVFundation Framework

Be sure to get those notifications in your appDelegate, in order to resume the video on app resume

```objective-c

- (void)applicationWillResignActive:(UIApplication *)application
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"PauseBgVideo"object:self];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ResumeBgVideo"object:self];
}
```


Antoine
