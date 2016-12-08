//
//  ViewController.m
//  Estimate_PlanarWarps
//
//  Created by Simon Lucey on 9/21/15.
//  Copyright (c) 2015 CMU_16432. All rights reserved.
//

#import "ViewController.h"

#ifdef __cplusplus
#include "opencv2/core/core.hpp"
#include "opencv2/highgui/highgui.hpp"
#include "opencv2/features2d/features2d.hpp"
#include <opencv2/imgproc/imgproc.hpp>
#include <opencv2/opencv.hpp> // Includes the opencv library
#include <stdlib.h> // Include the standard library
#include "armadillo" // Includes the armadillo library
#include <iostream>
#endif

using namespace std;
using namespace arma;

@interface ViewController () {
    // Setup the view
    UIImageView *imageView_;
    //cv::SurfFeatureDetector *detector_; // Set the SURF Detector
    //cv::SurfDescriptorExtractor *extractor_; // Set the SURF Extractor
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // Read in the image
    UIImage *image = [UIImage imageNamed:@"prince_book.jpg"];
    if(image == nil) cout << "Cannot read in the first file!!" << endl;
    
    // Read in the new image
    UIImage *new_image = [UIImage imageNamed:@"new_view.jpg"];
    if(new_image == nil) cout << "Cannot read in the second file!!" << endl;
    
    // Setup the display
    // Setup the your imageView_ view, so it takes up the entire App screen......
    imageView_ = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, self.view.frame.size.height)];
    // Important: add OpenCV_View as a subview
    [self.view addSubview:imageView_];
    
    // Ensure aspect ratio looks correct
    imageView_.contentMode = UIViewContentModeScaleAspectFit;
    
    // Another way to convert between cvMat and UIImage (using member functions)
    cv::Mat cvImage = [self cvMatFromUIImage:image];
    cv::Mat new_cvImage = [self cvMatFromUIImage:new_image];
    cv::Mat imgObject; cv::cvtColor(cvImage, imgObject, CV_RGBA2GRAY); // Convert to grayscale
    cv::Mat imgScene; cv::cvtColor(new_cvImage, imgScene, CV_RGBA2GRAY); // Convert to grayscale
    
    // PROJECT CODE HERE!!!!!!
    
    cv::Ptr<cv::ORB> orb = cv::ORB::create();
    
    std::vector<cv::KeyPoint> objectKeypoints;
    std::vector<cv::KeyPoint> sceneKeypoints;
    
    cv::Mat objectDescriptors;
    cv::Mat sceneDescriptors;
    
    orb->detectAndCompute(imgObject, cv::noArray(), objectKeypoints, objectDescriptors);
    orb->detectAndCompute(imgScene, cv::noArray(), sceneKeypoints, sceneDescriptors);
    
    cout << objectKeypoints.size() << ", " << objectDescriptors.size << endl;
    cout << sceneKeypoints.size() << ", " << sceneDescriptors.size << endl;
    
    cv::BFMatcher bfMatcher(cv::NORM_HAMMING, true);
    
    std::vector<cv::DMatch> matches;
    bfMatcher.match(objectDescriptors, sceneDescriptors, matches);
    
    if (matches.size() > 0) {
        cout << "Matching features found." << endl;
    } else {
        cout << "No matching features could be found." << endl;
    }
    
    cv::Mat imgFinal;
    cv::drawMatches(imgObject, objectKeypoints, imgScene, sceneKeypoints, matches, imgFinal);
    
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
    E = findEssentialMat(obj, scene, focal, pp, cv::RANSAC, 0.999, 1.0, mask);
    recoverPose(E, obj, scene, R, t, focal, pp, mask);
    std::cout << "R = "<< std::endl << " "  << R << std::endl << std::endl;
    std::cout << "t = "<< std::endl << " "  << t << std::endl << std::endl;
    
    // Finally setup the view to display
    imageView_.image = [self UIImageFromCVMat:imgFinal];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//---------------------------------------------------------------------------------------------------------------------
// You should not have to touch these functions below to complete the assignment!!!!
//---------------------------------------------------------------------------------------------------------------------
// Quick function to draw points on an UIImage
cv::Mat DrawPts(cv::Mat &display_im, arma::fmat &pts, const cv::Scalar &pts_clr)
{
    vector<cv::Point2f> cv_pts = Arma2Points2f(pts); // Convert to vector of Point2fs
    for(int i=0; i<cv_pts.size(); i++) {
        cv::circle(display_im, cv_pts[i], 5, pts_clr,5); // Draw the points
    }
    return display_im; // Return the display image
}
// Quick function to draw lines on an UIImage
cv::Mat DrawLines(cv::Mat &display_im, arma::fmat &pts, const cv::Scalar &pts_clr)
{
    vector<cv::Point2f> cv_pts = Arma2Points2f(pts); // Convert to vector of Point2fs
    for(int i=0; i<cv_pts.size(); i++) {
        int j = i + 1; if(j == cv_pts.size()) j = 0; // Go back to first point at the enbd
        cv::line(display_im, cv_pts[i], cv_pts[j], pts_clr, 3); // Draw the line
    }
    return display_im; // Return the display image
}
// Quick function to convert Armadillo to OpenCV Points
vector<cv::Point2f> Arma2Points2f(arma::fmat &pts)
{
    vector<cv::Point2f> cv_pts;
    for(int i=0; i<pts.n_cols; i++) {
        cv_pts.push_back(cv::Point2f(pts(0,i), pts(1,i))); // Add points
    }
    return cv_pts; // Return the vector of OpenCV points
}
// Member functions for converting from cvMat to UIImage
- (cv::Mat)cvMatFromUIImage:(UIImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels (color channels + alpha)
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    return cvMat;
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
