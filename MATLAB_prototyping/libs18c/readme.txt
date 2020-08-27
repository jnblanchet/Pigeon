## libsc18c.js
This folder contains the code to build Pigeon's libs18c detection library.
Two files are compiled: the javascript wrapper (libsc18c.js) and the cross
platform webassembly compiled code (libsc18c.wasm).


##Tests
To run tests:
open and run the following files
test_solomon.m
test_detect.m

You may need to update the path in test_detect.m to fit your data naming
convention.

## Build
The build process is performed as follow:
1) Download, install and configure Geoff McVittie's toolbox:
https://www.mathworks.com/matlabcentral/fileexchange/69973-generate-javascript-using-matlab-coder
Follow the instructions to install the dependencies.

2) Run the build script
build_helper.m

Tested on Windows, with MATLAB 2019b and MinGW64 Compiler (C++).




