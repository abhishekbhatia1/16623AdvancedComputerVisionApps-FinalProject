# 16623 - Advanced Computer Vision Apps 

Project Proposal
Abhishek Bhatia (abhatia1), Shiyu Dong (shiyud)

Title: Real-time Monocular Visual Odometry on an IOS Device.

Summary: The idea is to develop an application for efficient real-time trajectory generation using the monocular visual odometry method. We intend to utilize the concepts learnt in the class to develop the complete pipeline that includes feature extraction and matching, essential matrix estimation, and calculating the rotation and translation to generate the trajectory. We may, if time permits, modify this project for reliable relative scale estimation. 

Background: Visual Odometry is an interesting topic to study in mobile applications. Localization and odometry with mobile devices are widely used in drones, virtual reality and other platforms. Several things need to be taken into consideration for developing visual odometry on mobile phones.
1) Calibration of phone camera.
2) Efficient keypoint detectors and descriptors for mobile development.
3) Incorporating IMU data to save computation while recovering the essential matrix.

The Challenge: 
1) Scale factor estimation.
2) Extracting ground truth for performance evaluation.

Goals & Deliverables: 
Baseline:
1) Implementing the visual odometry algorithm on laptop using OpenCV, and testing using the KITTI dataset. We should be able to generate trajectory from camera frames and find the accuracy comparing our output with the ground truth from the dataset.
2) We’ll then implement the algorithm on the IOS device. We’ll show that when holding the phone in hand (or on a moving robot), we’re able to generate a real-time trajectory.

Further Improvements:
1) Instead of using five-point algorithm from camera view, we’ll try to incorporate IMU data in finding the essential matrix. We’ll try using a three-point algorithm or five-point algorithm with IMU data. 
2) We’ll further show that with the use of IMU data, we can achieve higher frame rate with similar accuracy.

Schedule: 
Abhishek:
1) 11/06 - 11/12: Literature Review
2) 11/13 - 11/19: Algorithm Development (Feature Detection and Matching) 
3) 11/20 - 11/26: Porting and Optimization
4) 11/27 - 12/03: Testing on the IOS device
5) 12/04 - 12/11: Modifications and wrap up

Shiyu:
1) 11/06 - 11/12: Figuring out methods for ground truth generation
2) 11/13 - 11/19: Algorithm Development (Essential Matrix Estimation based on RANSAC)
3) 11/20 - 11/26: Porting and Optimization
4) 11/27 - 12/03: Improvements based on the test results
5) 12/04 - 12/11: Modifications and wrap up

Reference:
http://avisingh599.github.io/vision/monocular-vo/
