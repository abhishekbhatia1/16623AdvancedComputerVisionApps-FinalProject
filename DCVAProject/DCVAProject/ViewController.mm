//
//  ViewController.m
//  DCVAProject
//
//  Created by Mohit  Sharma on 11/27/16.
//  Copyright © 2016 Abhishek Bhatia. All rights reserved.
//

#import "ViewController.h"

#ifdef __cplusplus
#include "opencv2/core/core.hpp"
#include "opencv2/highgui/highgui.hpp"
#include "opencv2/features2d/features2d.hpp"
#include <opencv2/imgproc/imgproc.hpp>
#include <opencv2/features2d.hpp>
#include <opencv2/opencv.hpp> // Includes the opencv library
#include <stdlib.h> // Include the standard library
#include <iostream>
#include <queue>
#endif

using namespace std;
using namespace cv;

@interface ViewController(){
    
    UIImageView *imageView_; // Setup the image view
    UITextView *fpsView_; // Display the current FPS
    int64 curr_time_; // Store the current time
    
    cv::Ptr<cv::ORB> orb;
    cv::BFMatcher bfMatcher;
    
    queue<cv::Mat> descriptorsQueue;
    queue<vector<cv::KeyPoint>> keypointsQueue;
    queue<cv::Mat> imagesQueue;
    
    int flag;
    cv::Mat traj;
    cv::Mat R_f, t_f;
    cv::Mat imgObject;
    cv::Mat win_mat;
}
@end

@implementation ViewController

// Important as when you when you override a property of a superclass, you must explicitly synthesize it
@synthesize videoCamera;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // Initialize the view
    // Hacky way to initialize the view to ensure the aspect ratio looks correct
    // across all devices. Unfortunately, setting UIViewContentModeScaleAspectFill
    // does not work with the CvCamera Delegate so we have to hard code everything....
    //
    // Assuming camera input is 352x288 (set using AVCaptureSessionPreset)
    //float cam_width = 288; float cam_height = 352;
    float cam_width = 480; float cam_height = 640;
    //float cam_width = 720; float cam_height = 1280;
    
    // Take into account size of camera input
    int view_width = self.view.frame.size.width;
    int view_height = (int)(cam_height*self.view.frame.size.width/cam_width);
    int offset = (self.view.frame.size.height - view_height)/2;
    
    imageView_ = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, offset, view_width, view_height)];
    
    [self.view addSubview:imageView_]; // Add the view
    
    // Initialize the video camera
    self.videoCamera = [[CvVideoCamera alloc] initWithParentView:imageView_];
    self.videoCamera.delegate = self;
    self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
    self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
    self.videoCamera.defaultFPS = 30; // Set the frame rate
    self.videoCamera.grayscaleMode = YES; // Get grayscale
    self.videoCamera.rotateVideo = YES; // Rotate video so everything looks correct
    
    // Choose these depending on the camera input chosen
    //self.videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset352x288;
    self.videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset640x480;
    //self.videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset1280x720;
    
    // Finally add the FPS text to the view
    fpsView_ = [[UITextView alloc] initWithFrame:CGRectMake(0,15,view_width,std::max(offset,35))];
    [fpsView_ setOpaque:false]; // Set to be Opaque
    [fpsView_ setBackgroundColor:[UIColor clearColor]]; // Set background color to be clear
    [fpsView_ setTextColor:[UIColor redColor]]; // Set text to be RED
    [fpsView_ setFont:[UIFont systemFontOfSize:18]]; // Set the Font size
    [self.view addSubview:fpsView_];
    
    // Initialize the Detector and Extractor beforehand
    // we do not want to be doing this at run-time
    orb = cv::ORB::create();
    bfMatcher = cv::BFMatcher(cv::NORM_HAMMING, true);
    flag = 1;
    traj = cv::Mat::zeros(640, 480, CV_8UC1);
    imgObject = cv::Mat::zeros(640, 480, CV_8UC1);
    
    // Finally show the output
    [videoCamera start];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
    // Remember to destroy allocations
    delete orb;
}

// Function to run apply image on
- (void) processImage:(cv:: Mat &)image
{
    Mat intrinsic = (Mat_<double>(3,3) << 593.09900, 0, 320.26862, 0, 590.09473, 237.86729, 0, 0, 1);
    Mat distCoeffs = (Mat_<double>(1, 4) << 0.1571472287, -0.3774241507, -0.0006767344, 0.0022913516);
    
    cv::Mat unDistortImage;
    undistort(image, unDistortImage, intrinsic, distCoeffs);
    image = unDistortImage;
    
    Mat dst;
    int kernel_size = 3;
    int scale = 1;
    int delta = 0;
    int ddepth = CV_16S;
    Laplacian( image, dst, ddepth, kernel_size, scale, delta, BORDER_DEFAULT );
    Mat tmp_m, tmp_sd;
    meanStdDev(dst, tmp_m, tmp_sd);
    double sd = tmp_sd.at<double>(0,0);
    cout << "Bluriness: " << sd << endl;
    
    // Version 1
    /*std::vector<cv::KeyPoint> objectKeypoints;
    std::vector<cv::KeyPoint> sceneKeypoints;
    
    cv::Mat objectDescriptors;
    cv::Mat sceneDescriptors;
    
    orb->detectAndCompute(image, cv::noArray(), objectKeypoints, objectDescriptors);
    orb->detectAndCompute(image, cv::noArray(), sceneKeypoints, sceneDescriptors);
    
    cout << objectKeypoints.size() << ", " << objectDescriptors.size << endl;
    cout << sceneKeypoints.size() << ", " << sceneDescriptors.size << endl;
    
    std::vector<cv::DMatch> matches;
    bfMatcher.match(objectDescriptors, sceneDescriptors, matches);
    
    if (matches.size() > 0) {
        cout << "Matching features found." << endl;
    
        cv::Mat imgFinal;
        cv::drawMatches(image, objectKeypoints, image, sceneKeypoints, matches, imgFinal);
        
        std::vector<cv::Point2f> obj;
        std::vector<cv::Point2f> scene;
        for( int i = 0; i < matches.size(); i++ )
        {
            //-- Get the keypoints from the good matches
            obj.push_back( objectKeypoints[ matches[i].queryIdx ].pt );
            scene.push_back( sceneKeypoints[ matches[i].trainIdx ].pt );
        }
        
        //cv::Mat H = findHomography( obj, scene, CV_RANSAC);
        double focal = 718.8560;
        cv::Point2d pp(607.1928, 185.2157);
        cv::Mat E, R, t, mask;
        if (matches.size() > 5) {
            E = findEssentialMat(obj, scene, focal, pp, cv::RANSAC, 0.999, 1.0, mask);
            recoverPose(E, obj, scene, R, t, focal, pp, mask);
            std::cout << "R = "<< std::endl << " "  << R << std::endl << std::endl;
            std::cout << "t = "<< std::endl << " "  << t << std::endl << std::endl;
        } else
            cout << "Less than 5 matches found, no R and t." << endl;
    } else {
        cout << "No matching features could be found." << endl;
    }
    
    // Finally estimate the frames per second (FPS)
    int64 next_time = cv::getTickCount(); // Get the next time stamp
    float fps = (float)cv::getTickFrequency()/(next_time - curr_time_); // Estimate the fps
    curr_time_ = next_time; // Update the time
    NSString *fps_NSStr = [NSString stringWithFormat:@"FPS = %2.2f",fps];
    
    // Have to do this so as to communicate with the main thread
    // to update the text display
    dispatch_sync(dispatch_get_main_queue(), ^{
        fpsView_.text = fps_NSStr;
    });*/
    
    // Version 2
    /*std::vector<cv::KeyPoint> Keypoints;
    cv::Mat Descriptors;
    
    orb->detectAndCompute(image, cv::noArray(), Keypoints, Descriptors);
    cout << Keypoints.size() << ", " << Descriptors.size << endl;
    
    descriptorsQueue.push(Descriptors);
    keypointsQueue.push(Keypoints);
    
    if (descriptorsQueue.size() >= 20 && keypointsQueue.size() >= 20) {
        std::vector<cv::KeyPoint> objectKeypoints = keypointsQueue.front();
        while (keypointsQueue.size() > 1)
            keypointsQueue.pop();
        std::vector<cv::KeyPoint> sceneKeypoints = keypointsQueue.front();
        keypointsQueue.pop();
        
        cv::Mat objectDescriptors = descriptorsQueue.front();
        while (descriptorsQueue.size() > 1)
            descriptorsQueue.pop();
        cv::Mat sceneDescriptors = descriptorsQueue.front();
        descriptorsQueue.pop();
        
        std::vector<cv::DMatch> matches;
        if (objectKeypoints.size() != 0 && sceneKeypoints.size() != 0)
            bfMatcher.match(objectDescriptors, sceneDescriptors, matches);
        
        if (matches.size() > 0) {
            cout << "Matching features found." << endl;
            
            cv::Mat imgFinal;
            cv::drawMatches(image, objectKeypoints, image, sceneKeypoints, matches, imgFinal);
            image = imgFinal;
            
            std::vector<cv::Point2f> obj;
            std::vector<cv::Point2f> scene;
            for( int i = 0; i < matches.size(); i++ )
            {
                //-- Get the keypoints from the good matches
                obj.push_back( objectKeypoints[ matches[i].queryIdx ].pt );
                scene.push_back( sceneKeypoints[ matches[i].trainIdx ].pt );
            }
            
            //cv::Mat H = findHomography( obj, scene, CV_RANSAC);
            double focal = 593.09900; //718.8560;
            cv::Point2d pp(320.26862, 237.86729); //pp(607.1928, 185.2157);
            cv::Mat E, R, t, mask;
            if (matches.size() > 5) {
                E = findEssentialMat(obj, scene, focal, pp, cv::RANSAC, 0.999, 1.0, mask);
                recoverPose(E, obj, scene, R, t, focal, pp, mask);
                std::cout << "R = "<< std::endl << " "  << R << std::endl << std::endl;
                std::cout << "t = "<< std::endl << " "  << t << std::endl << std::endl;
                
                if (flag){
                    t_f = t;
                    R_f = R;
                    flag = 0;
                }
                else{
                    t_f = t_f + (R_f*t);
                    R_f = R*R_f;
                }
                
                int x = int(t_f.at<double>(0)) + 300;
                int y = int(t_f.at<double>(2)) + 300;
                
                cv::circle(traj, cv::Point(x, y) ,1, CV_RGB(255,0,0), 2);
                
            } else
                cout << "Less than 5 matches found, no R and t." << endl;
        } else {
            cout << "No matching features could be found." << endl;
        }
        
        // Finally estimate the frames per second (FPS)
        int64 next_time = cv::getTickCount(); // Get the next time stamp
        float fps = (float)cv::getTickFrequency()/(next_time - curr_time_); // Estimate the fps
        curr_time_ = next_time; // Update the time
        NSString *fps_NSStr = [NSString stringWithFormat:@"FPS = %2.2f",fps];
        
        // Have to do this so as to communicate with the main thread
        // to update the text display
        dispatch_sync(dispatch_get_main_queue(), ^{
            fpsView_.text = fps_NSStr;
        });
        //image = traj;
    }
    image = traj;*/
    
    // Version 3: KLT Tracker
    if (sd > 0.0)
        imagesQueue.push(image);
    
    if (imagesQueue.size() >= 10) {
        cv::Mat imgScene = imagesQueue.front();
        while (imagesQueue.size() > 1)
            imagesQueue.pop();
        imgObject = imagesQueue.front();
        imagesQueue.pop();
        
        std::vector<cv::KeyPoint> sceneKeypoints;
        cv::Mat sceneDescriptors;
        orb->detectAndCompute(imgScene, cv::noArray(), sceneKeypoints, sceneDescriptors);
        
        if (sceneKeypoints.size() > 5) {
        
            std::vector<cv::Point2f> obj;
            std::vector<cv::Point2f> scene;
            KeyPoint::convert(sceneKeypoints, scene, std::vector<int>());
            std::vector<uchar> status;
            std::vector<float> err;
            calcOpticalFlowPyrLK(imgScene,imgObject, scene, obj, status, err, cv::Size(21,21), 3, TermCriteria(TermCriteria::COUNT+TermCriteria::EPS, 30, 0.01), 0, 0.001);
            
            int indexCorrection = 0;
            for( int i=0; i<status.size(); i++)
            {  Point2f pt = obj.at(i- indexCorrection);
                if ((status.at(i) == 0)||(pt.x<0)||(pt.y<0))	{
                    if((pt.x<0)||(pt.y<0))	{
                        status.at(i) = 0;
                    }
                    scene.erase (scene.begin() + (i - indexCorrection));
                    obj.erase (obj.begin() + (i - indexCorrection));
                    indexCorrection++;
                }
            }
            
            for(int j=0; j<obj.size(); j++){
                if(status[j]){
                    line(imgObject,scene[j],obj[j], CV_RGB(255,0,0));
                }
            }
            
            double focal = 593.09900; //718.8560;
            cv::Point2d pp(320.26862, 237.86729); //pp(607.1928, 185.2157);
            cv::Mat E, R, t, mask;
            if (obj.size() > 5 && scene.size() > 5) {
                E = findEssentialMat(obj, scene, focal, pp, cv::RANSAC, 0.999, 1.0, mask);
                recoverPose(E, obj, scene, R, t, focal, pp, mask);
                //std::cout << "R = "<< std::endl << " "  << R << std::endl << std::endl;
                //std::cout << "t = "<< std::endl << " "  << t << std::endl << std::endl;
                
                if (flag){
                    t_f = t;
                    R_f = R;
                    flag = 0;
                }
                else{
                    t_f = t_f + (R_f*t);
                    R_f = R*R_f;
                }
                
                int x = int(t_f.at<double>(0)) + 300;
                int y = int(t_f.at<double>(2)) + 300;
                
                cv::circle(traj, cv::Point(x, y) ,1, CV_RGB(255,255,255), 2);
            } else {
                cout << "Less than 5 matches found, no R and t." << endl;
            }
        
            // Finally estimate the frames per second (FPS)
            int64 next_time = cv::getTickCount(); // Get the next time stamp
            float fps = (float)cv::getTickFrequency()/(next_time - curr_time_); // Estimate the fps
            curr_time_ = next_time; // Update the time
            NSString *fps_NSStr = [NSString stringWithFormat:@"FPS = %2.2f",fps];
        
            // Have to do this so as to communicate with the main thread
            // to update the text display
            dispatch_sync(dispatch_get_main_queue(), ^{
                fpsView_.text = fps_NSStr;
            });
        } else
            cout << "Less than 5 keypoints found." << endl;
        //image = imgObject;
        // Copy small images into big mat
        //cout << imgObject.rows << ", " << imgObject.cols << endl;
        //cout << traj.rows << ", " << traj.cols << endl;
        
        cv::Mat win_mat_new;
        win_mat_new.push_back(imgObject);
        win_mat_new.push_back(traj);
        
        win_mat = win_mat_new;
        
        cv::resize(win_mat, win_mat, cv::Size(640,480));
        //cout << win_mat.rows << ", " << win_mat.cols << endl;
        //image = traj;
    }
    image = win_mat;
    //image = imgObject;
}

// Member functions for converting from UIImage to cvMat
-(UIImage *)UIImageFromCVMat:(cv::Mat)cvMat
{
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace;
    
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                        cvMat.rows,                                 //height
                                        8,                                          //bits per component
                                        8 * cvMat.elemSize(),                       //bits per pixel
                                        cvMat.step[0],                            //bytesPerRow
                                        colorSpace,                                 //colorspace
                                        kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
                                        provider,                                   //CGDataProviderRef
                                        NULL,                                       //decode
                                        false,                                      //should interpolate
                                        kCGRenderingIntentDefault                   //intent
                                        );
    
    
    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
}

@end
