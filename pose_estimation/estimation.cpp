#include<opencv2/opencv.hpp>
#include<opencv2/core/core.hpp>
#include<opencv2/highgui/highgui.hpp>
#include<opencv2/imgproc/imgproc.hpp>
#include<opencv2/features2d.hpp>

#include<iostream>

///////////////////////////////////////////////////////////////////////////////////////////////////


#define MAX_FRAME 1000



int main(void) {

	char scenefile[100];
	char objfile[100];
	int flag = 1;
	cv::Mat traj = cv::Mat::zeros(600, 600, CV_8UC3);
	cv::namedWindow( "Trajectory", cv::WINDOW_AUTOSIZE );// Create a window for display.

	cv::Mat R_f, t_f;

	for(int numFrame = 0; numFrame < MAX_FRAME; numFrame++)	{

		std::cout << "numFrame: " << numFrame << std::endl;

	  	sprintf(scenefile, "/home/shiyu/mono-vo/dataset/sequences/00/image_0/%06d.png", numFrame);
	  	sprintf(objfile, "/home/shiyu/mono-vo/dataset/sequences/00/image_0/%06d.png", numFrame+1);

	    cv::Mat imgScene = cv::imread(scenefile);
	    cv::Mat imgObject = cv::imread(objfile);
	    

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
    	int y = int(t_f.at<double>(2)) + 100;
    	cv::circle(traj, cv::Point(x, y) ,1, CV_RGB(255,0,0), 2);

    	cv::imshow( "Trajectory", traj );
		cv::waitKey(1);

	    //cv::imshow("imgFinal", imgFinal);
	    //cv::waitKey(0);
	}
    return(0);

}
