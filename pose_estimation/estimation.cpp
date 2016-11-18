#include<opencv2/opencv.hpp>
#include<opencv2/core/core.hpp>
#include<opencv2/highgui/highgui.hpp>
#include<opencv2/imgproc/imgproc.hpp>
#include<opencv2/features2d.hpp>

#include<iostream>

///////////////////////////////////////////////////////////////////////////////////////////////////
int main(void) {

    cv::Mat imgObject = cv::imread("000000.png");
    cv::Mat imgScene = cv::imread("000001.png");

    if (imgObject.empty() || imgScene.empty()) {			    // if unable to open image
        std::cout << "error: image not read from file\n\n";		// show error message on command line
        
        return(0);												// and exit program
    }

    cv::Ptr<cv::ORB> orb = cv::ORB::create();

    std::vector<cv::KeyPoint> objectKeypoints;
    std::vector<cv::KeyPoint> sceneKeypoints;

    cv::Mat objectDescriptors;
    cv::Mat sceneDescriptors;

    orb->detectAndCompute(imgObject, cv::noArray(), objectKeypoints, objectDescriptors);
    orb->detectAndCompute(imgScene, cv::noArray(), sceneKeypoints, sceneDescriptors);

    cv::BFMatcher bfMatcher(cv::NORM_HAMMING, true);

    std::vector<cv::DMatch> matches;

    bfMatcher.match(objectDescriptors, sceneDescriptors, matches);

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
    cv::imshow("imgFinal", imgFinal);

    cv::waitKey(0);

    return(0);

}
