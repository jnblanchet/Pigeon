# Pigeon app

Submission for the d-Code CTT postal service competition 2020.

[![Introduction Video](https://img.youtube.com/vi/JVCmVBui2V4/0.jpg)](https://www.youtube.com/watch?v=JVCmVBui2V4)


# Quick start

1. Clone or download the repository.
2. Download and install Cordova (https://cordova.apache.org/)
3. cd <path/to/repository>/App/pigeon
4. cordova build [android|ios|browser]

# Features 

 * UPU S18C 4 state barcode detection 🔎 and parsing from mobile camera 📸
 * No internet connection required ⚡
 * Photographs stored with meta data in JSON files 💾
 * History browsing 📋, and deletion ❌
 * Visual user feedback while scanning 🟥🟨🟩
 * Double check feature: an ID-Tag is only returned after two consecutive reads
 * The phone's flash light is used to remove shadows and improve detection 💡
 * Works in daylight 🌞, indoors, and low light conditions 🌙
 * Solomon-Reed error correction 🚫 to correct up to 6 binary errors (unit tested)
 * Classic computer vision 👁 with high explainability 🧠
 * Detection library returns different error codes to explain detection result
 * Detection and parsing in less than 400 ms ⌛
 * Entire capture process takes 5 seconds on average.
 * No requirements on the orientation or position of the barcode 🔄 
 * Efficient single threaded CPU detection for easy maintenance and fewer dependencies
 * Well documented novel detection method
 * Detection library can be directly used in a NodeJS webservice
 * Detection library uses web assembly for platform independent execution speeds competitive with compiled code
 * Tested and optimized with over 900 real-world images
 * Android build available ✔
 * iOS compatible 🍎

# How to?

## Scanning a new ID-Tag

From the main menu, select the scan option on the left. Once the camera is started hold the envelope 15 cm away from the camera. There are no prior assumptions on the position or orientation of the barcode. The phone and the camera should be parallel to each other for best results.

If you are having trouble scanning a barcode, try these: press the envelope against a flat surface, slowly rotate the phone to improve the angle, try moving around to improve the lighting.

When the barcode is successfully detected, the ID-Tag information is displayed on screen. The formatting output of this code is likely to evolve in the future, and can be changed easily by updating the scan.HTML and scan.js files.

Two buttons appear following a successful capture: Reset and Archive. Reset will instantly discard the result and start up the camera again. Archive will write the image and its meta data to a JSON file which can be viewed or deleted from the history menu.

## Deleting old photographs

In the history browsing menu, the user can delete a specific entry by pressing the DELETE button next to it. A confirmation message will appear to prevent accidental deletion.

It is also possible to delete all photographs at once by connecting the phone to a computer as a USB storage device, and browsing to the storage folder. The exact path to this folder is displayed at the top of the history menu.

## Transferring all photographs to a new phone

All files are archived in simple JSON text format (including jpeg data and meta data) on the phone's internal storage. The exact path is displayed at the top of the history window. The user can connect the phone to a computer as a USB storage device, and copy the files from the phone or to the phone.

_Note: photographs are stored as base64 jpeg in HD resolution. If storage becomes an issue, it is possible to reduce resolution prior to saving_.

## Using the detection library

The detection library returns up to 5 different error codes as follow:

 * 0: detection success
 * -1: best region candidate was not rectangular
 * -2: unable to locate 75 bars
 * -3: sync codes are wrong, envelope is probably too bent
 * -4: the barcode had an unexpected format (e.g. S18D)
 * -5: error correction has failed, too many errors due to low image quality
 
It will also return a bounding box containing the last region it was focusing on. This can help provide the user with feedback.

 For an example on how to call the vision module, check out function `runLibs18cDetection(imageData)` in scan.js. In the library's detection function (`Module._detect`), data is passed as a list of packed RGBA pixels. data is returned in a JSON object with the following fields: UPU\_identifier, format\_identifier, issuer\_code, equipement\_id, item\_priority, serial\_number\_month, serial\_number\_day, serial\_number\_hour, serial\_number\_10min, serial\_number\_item, tracking\_indicator
 
## Repurposing the detection in a web service
 
The code inside scan.js shows how to use the detection library. This code can be directly used in a NodeJS webservice. Simply include the 
`libsc18c.js` and `libsc18c.wasm` files, and call the `_detect` method. The library uses web assembly and is compatible with windows, linux, iOS and others.

_Note: although the app uses images from the camera, the images can come from any source_

## Building the detection library

See instructions in `Pigeon/MATLAB_prototyping/libs18c/readme.txt`


## Opportunities to further optimize

While the detection runs in less 400 ms on a phone, we've identified some low hanging fruits that could speed up the process to less than 100m:
 * Memory buffer preallocation, and re-use between frames.
 * Detection module pre-initialization
 * Image resize and Sobel filter can be written as an OpenGL shader instead of running on CPU. This is possible in a platform independent way through libraries such as gpu.js.
 
# A discussion on accuracy

We've estimated the following probabilities:
 * Probability of a corrupted bit: 0.08% (measured)
 * Probability of a false positive from the Solomon-Reed correction, knowing 2 bits are corrupted: ~1.2% (from simulation)
 * Probability of two consecutive identical false positive: ~1 in 4 billion (estimated from numbers above)
 
 
