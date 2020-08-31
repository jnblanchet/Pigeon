# Pigeon app

Submission for the d-Code CTT postal service competition 2020.

[![Introduction Video](https://img.youtube.com/vi/JVCmVBui2V4/0.jpg)](https://www.youtube.com/watch?v=JVCmVBui2V4)


# Quick start

1. Clone or download the repository.
2. Download and install Cordova (https://cordova.apache.org/)
3. cd <path/to/repository>/App/pigeon
4. cordova build [android|ios|browser]

# Features 

-UPU S18C 4 state barcode detection 🔎 and parsing from mobile camera 📸
-No internet connection required ⚡
-Photographs stored with meta data in JSON files 💾
-History browsing 📋, and deletion ❌
-Visual user feedback while scanning 🟥🟨🟩
-The phone's flash light is used to remove shadows and improve detection 💡
-Works in daylight 🌞, indoors, and low light conditions 🌙
-Solomon-Reed error correction 🚫 to correct up to 6 binary errors (unit tested)
-Classic computer vision 👁 with high explainability 🧠
-Detection library returns different error codes to explain detection result
-Detection and parsing in less than 400 ms ⌛
-Entire capture process takes 5 seconds on average.
-No requirements on the orientation or position of the barcode 🔄 
-Efficient single threaded CPU detection for easy maintenance and fewer dependencies
-Well documented novel detection method
-Detection library can be directly used in a NodeJS webservice
-Detection library uses web assembly for platform independent execution speeds competitive with compiled code
-Tested and optimized with over 900 real-world images
-Android build available ✔
-iOS compatible 🍎

