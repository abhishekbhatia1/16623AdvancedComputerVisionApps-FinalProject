#include<opencv2/opencv.hpp>
#include<opencv2/core/core.hpp>
#include<opencv2/highgui/highgui.hpp>
#include<opencv2/imgproc/imgproc.hpp>
#include<opencv2/features2d.hpp>

#include<iostream>

///////////////////////////////////////////////////////////////////////////////////////////////////

using namespace std;
using namespace cv;

#define MAX_FRAME 1000



int main(void) {

	char scenefile[100];
	char objfile[100];
	int flag = 1;
	cv::Mat traj = cv::Mat::zeros(600, 600, CV_8UC3);
	cv::namedWindow( "Trajectory", cv::WINDOW_AUTOSIZE);// Create a window for display.

	cv::Mat R_f, t_f;


	// char filename1[200];
	//  	char filename2[200];
	//  	sprintf(filename1, "/home/shiyu/mono-vo/dataset/sequences/00/image_1/%06d.png", 0);
	//  	sprintf(filename2, "/home/shiyu/mono-vo/dataset/sequences/00/image_1/%06d.png", 1);
	// cv::Mat imgScene = cv::imread(filename1);
	// if (imgScene.empty()) {			    // if unable to open image
	//        std::cout << "error: image not read from file\n\n";		// show error message on command line
	//        return(0);												// and exit program
	// }

	// cv::Ptr<cv::ORB> orb = cv::ORB::create();
	// std::vector<cv::KeyPoint> sceneKeypoints;
	// cv::Mat sceneDescriptors;
	// orb->detectAndCompute(imgScene, cv::noArray(), sceneKeypoints, sceneDescriptors);
	// std::vector<cv::Point2f> scene;
	// KeyPoint::convert(sceneKeypoints, scene, std::vector<int>());


	for(int numFrame = 0; numFrame < MAX_FRAME; numFrame++)	{

		std::cout << "numFrame: " << numFrame << std::endl;

	  	sprintf(scenefile, "/home/shiyu/mono-vo/dataset/sequences/00/image_0/%06d.png", numFrame);
	  	sprintf(objfile, "/home/shiyu/mono-vo/dataset/sequences/00/image_0/%06d.png", numFrame+1);

	    cv::Mat imgScene = cv::imread(scenefile);
	    cv::Mat imgObject = cv::imread(objfile);
	    

	    

	    cv::Ptr<cv::ORB> orb = cv::ORB::create();

	    //std::vector<cv::KeyPoint> objectKeypoints;
	    std::vector<cv::KeyPoint> sceneKeypoints;

	    //cv::Mat objectDescriptors;
	    cv::Mat sceneDescriptors;

	    //orb->detectAndCompute(imgObject, cv::noArray(), objectKeypoints, objectDescriptors);
	    orb->detectAndCompute(imgScene, cv::noArray(), sceneKeypoints, sceneDescriptors);

	    //cv::BFMatcher bfMatcher(cv::NORM_HAMMING, true);

	    //std::vector<cv::DMatch> matches;

	    //bfMatcher.match(objectDescriptors, sceneDescriptors, matches);

	    //cv::Mat imgFinal;

	    //cv::drawMatches(imgObject, objectKeypoints, imgScene, sceneKeypoints, matches, imgFinal);

	    std::vector<cv::Point2f> obj;
	  	std::vector<cv::Point2f> scene;
	  	KeyPoint::convert(sceneKeypoints, scene, std::vector<int>());


	 	//for( int i = 0; i < matches.size(); i++ )
		// {
		// 	//-- Get the keypoints from the good matches
		// 	//obj.push_back( objectKeypoints[ matches[i].queryIdx ].pt );
		// 	scene.push_back( sceneKeypoints[ matches[i].trainIdx ].pt );
		// }


		std::vector<uchar> status;
		std::vector<float> err;
		calcOpticalFlowPyrLK(imgScene,imgObject, scene, obj, status, err, Size(21,21), 3, TermCriteria(TermCriteria::COUNT+TermCriteria::EPS, 30, 0.01), 0, 0.001);

  		// int indexCorrection = 0;
		// for( int i=0; i<status.size(); i++)
		//  {  Point2f pt = obj.at(i- indexCorrection);
		//  	if ((status.at(i) == 0)||(pt.x<0)||(pt.y<0))	{
		//  		  if((pt.x<0)||(pt.y<0))	{
		//  		  	status.at(i) = 0;
		//  		  }
		//  		  scene.erase (scene.begin() + (i - indexCorrection));
		//  		  obj.erase (obj.begin() + (i - indexCorrection));
		//  		  indexCorrection++;
		//  	}

		//  }

		for(int j=0; j<obj.size(); j++){
                if(status[j]){
                    line(imgObject,scene[j],obj[j], CV_RGB(255,0,0));
                }
        }


	    //cv::Mat H = findHomography( obj, scene, CV_RANSAC);
		double focal = 718.8560;
	  	cv::Point2d pp(607.1928, 185.2157);
	    cv::Mat E, R, t, mask;
		E = findEssentialMat(obj, scene, focal, pp, cv::RANSAC, 0.999, 1.0, mask);
		recoverPose(E, obj, scene, R, t, focal, pp, mask);
		std::cout << "R = "<< std::endl << " "  << R << std::endl << std::endl;
		std::cout << "t = "<< std::endl << " "  << t << std::endl << std::endl;
	    
	    if ( t.at<double>(2) > t.at<double>(0) && t.at<double>(2) > t.at<double>(1) ){

	    	if (flag){
				t_f = t;
				R_f = R;
				flag = 0;
			}
			else{
				t_f = t_f + 0.5*(R_f*t);
	      		R_f = R*R_f;
			}

	    }
		
	    scene = obj;
		int x = int(t_f.at<double>(0)) + 300;
    	int y = int(t_f.at<double>(2)) + 100;
    	cv::circle(traj, cv::Point(x, y) ,1, CV_RGB(255,0,0), 2);
    	imshow( "Road facing camera", imgObject );
    	cv::imshow( "Trajectory", traj );
		cv::waitKey(1);

	    //cv::imshow("imgFinal", imgFinal);
	    //cv::waitKey(0);
	}
    return(0);

}
