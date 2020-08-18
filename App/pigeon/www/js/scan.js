/*
Copyrights 2020 (c) Jean-Nicola Blanchet
All rights reserved.
 */
 
var imageCapture;
var canvas = document.querySelector('#canvasoverlay');  
//var hiddenFrameCanvas = document.createElement("canvas");

  
document.addEventListener('deviceready', onDeviceReady, false);

function onDeviceReady() {
	startcamera();
}

function startcamera(){
	var video = document.querySelector("#livefeed");
	video.onresize  = () => resize_canvas(video);

	if (navigator.mediaDevices.getUserMedia) {
		navigator.mediaDevices.getUserMedia({ video: { facingMode: "environment" }, width: {exact: 1920}, height: {exact: 1080} })
			.then(function (stream) {
			video.srcObject = stream;
			
			const track = stream.getVideoTracks()[0];
			imageCapture = new ImageCapture(track);
				console.log(imageCapture);

		})
		.catch(function (err) {
			alert(err);
		});
	}
}

// frame grabber
function onGrabFrameButtonClick() {
	imageCapture.grabFrame()
		.then(function(imageBitmap) {
			console.log('Grabbed frame:', imageBitmap);
			canvas.width = imageBitmap.width;
			canvas.height = imageBitmap.height;
			canvas.getContext('2d').drawImage(imageBitmap, 0, 0);
			canvas.classList.remove('hidden');
			var ctx = canvas.getContext("2d");
			var imgData = ctx.getImageData(0, 0, canvas.width, canvas.height);
			scan_results = runLibs18cDetection(imgData);
			
			console.log("idtag: " + scan_results.idtag);
			console.log("roi: " + scan_results.roi);
			
			ctx.beginPath();
			ctx.lineWidth = "6";
			ctx.strokeStyle = "red";
			//ctx.rect(10,10,960,960/2);
			ctx.rect(scan_results.roi[0], scan_results.roi[1], scan_results.roi[2]-scan_results.roi[0], scan_results.roi[3]-scan_results.roi[1]);
			ctx.stroke();

	})
	.catch(function(error) {
		console.log('grabFrame() error: ', error);
	});
}
/*
function drawCanvas(canvas, img) {
	canvas.width = getComputedStyle(canvas).width.split('px')[0];
	canvas.height = getComputedStyle(canvas).height.split('px')[0];
	let ratio  = Math.min(canvas.width / img.width, canvas.height / img.height);
	let x = (canvas.width - img.width * ratio) / 2;
	let y = (canvas.height - img.height * ratio) / 2;
	canvas.getContext('2d').clearRect(0, 0, canvas.width, canvas.height);
	canvas.getContext('2d').drawImage(img, 0, 0, img.width, img.height,
		x, y, img.width * ratio, img.height * ratio);
}
*/


// canvas overlay
function resize_canvas(element)
{
	var w = element.offsetWidth;
	var h = element.offsetHeight;
	var cv = document.getElementById("canvasoverlay");
	cv.width = w;
	cv.height = h;
}



//** libs18c **//
// JavaScript Array to Emscripten Heap
function _arrayToHeap(typedArray) {
	var numBytes = typedArray.length * typedArray.BYTES_PER_ELEMENT;
	var ptr = Module._malloc(numBytes);
	var heapBytes = new Uint8Array(Module.HEAPU8.buffer, ptr, numBytes);
	heapBytes.set(new Uint8Array(typedArray.buffer));
	return heapBytes;
}

// Emscripten Heap to JavasSript Array
// JavaScript Array to Emscripten Heap
function _arrayToHeap(typedArray) {
	var numBytes = typedArray.length * typedArray.BYTES_PER_ELEMENT;
	var ptr = Module._malloc(numBytes);
	var heapBytes = new Uint8Array(Module.HEAPU8.buffer, ptr, numBytes);
	heapBytes.set(new Uint8Array(typedArray.buffer));
	return heapBytes;
}
// Emscripten Heap to JavasSript Array
function _heapToString(heapBytes, array) {
	return new TextDecoder("utf-8").decode(heapBytes);
}
function _heapToArray_float32(heapBytes, array) {
	return new Float32Array(
		heapBytes.buffer,
		heapBytes.byteOffset,
		heapBytes.length / array.BYTES_PER_ELEMENT);
}
// Free Heap
function _freeArray(heapBytes) {
	Module._free(heapBytes.byteOffset);
}
// Example of Passing Data Arrays
function runLibs18cDetection(imageData) {
	//var a = new Array(1920 * 1080 * 3).fill(0);;
	// Create Data    
	//var buff_input_frame = new Uint8Array(a);
	var buff_input_frame = new Uint8Array(imageData.data.buffer);
	var buff_output_code = new Uint8Array(24);
	var buff_output_roi = new Float32Array(4);
	
	// Move Data to Heap
	var bytes_input_frame = _arrayToHeap(buff_input_frame);
	var bytes_output_code = _arrayToHeap(buff_output_code);
	var bytes_output_roi = _arrayToHeap(buff_output_roi);
	// Run Function
	Module._libsc18c_initialize();
	
	var t0 = performance.now()
	Module._detectHD(bytes_input_frame.byteOffset, bytes_output_code.byteOffset,bytes_output_roi.byteOffset)
	var t1 = performance.now()
	console.log("Call to doSomething took " + (t1 - t0) + " milliseconds.")

	Module._libsc18c_terminate();
	//  Copy Data from Heap
	buff_output_code = _heapToString(bytes_output_code, buff_output_code);
	buff_output_roi = _heapToArray_float32(bytes_output_roi, buff_output_roi);
	// Free Data from Heap
	_freeArray(bytes_input_frame);
	_freeArray(bytes_output_code);
	_freeArray(bytes_output_roi);
	// Display Results
	
	return {
		idtag: buff_output_code,
		roi: buff_output_roi
	};
}



		