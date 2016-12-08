//
//  ViewController.h
//  DCVAProject
//
//  Created by Mohit  Sharma on 11/27/16.
//  Copyright © 2016 Abhishek Bhatia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <opencv2/videoio/cap_ios.h>

// Slightly changed things here to employ the CvVideoCameraDelegate
@interface ViewController : UIViewController<CvVideoCameraDelegate>
{
    CvVideoCamera *videoCamera; // OpenCV class for accessing the camera
}
// Declare internal property of videoCamera
@property (nonatomic, retain) CvVideoCamera *videoCamera;

@end

