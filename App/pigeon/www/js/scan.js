/*
Copyrights 2020 (c) Jean-Nicola Blanchet
All rights reserved.
 */
 
var imageCapture;
var hiddenFrameCanvas = document.createElement("canvas"); // used to convert imageBitmap into pixel data
var validCodeCache = [];
var lastCode = "";

document.addEventListener('deviceready', onDeviceReady, false);
document.getElementById("btnrestart").addEventListener("click", function(event){
  event.preventDefault();
  startCamera();
  codeCapturedGUI(true);
});

document.getElementById("btnaccept").addEventListener("click", function(event) {
	if(validCodeCache) {
		event.preventDefault();
		archiveObject(validCodeCache, function(){window.location.replace("./index.html");}); // write to storage (see storage.js)
	}
});


function onDeviceReady() {
	startCamera();
}

function startCamera() {
	var video = document.querySelector("#livefeed");
	video.onresize  = () => resize_canvas(video);

	if (navigator.mediaDevices.getUserMedia) {
		navigator.mediaDevices.getUserMedia({ video: { facingMode: "environment", width: { ideal: 1280, max: 1920 }, height: { ideal: 1920, max: 2400  }}})
			.then(function (stream) {
			video.srcObject = stream;
			
			const track = stream.getVideoTracks()[0];
			
			// also turn on torch if available
			video.addEventListener('loadedmetadata', (e) => {  
				window.setTimeout(() => (
				onCapabilitiesReady(track.getCapabilities())
			), 500);
			});

			function onCapabilitiesReady(capabilities) {
				if (capabilities.torch) {
					track.applyConstraints({advanced: [{torch: true}]})
					.catch(e => alert("cannot apply constraint: " + e));
				} else {
					alert('Torch not available on this device');
				}
			}			
			imageCapture = new ImageCapture(track);
			requestAnimationFrame(runDetection);

		})
		.catch(function (err) {
			alert(err);
		});
	}
}

function stopCamera() {
	var video = document.querySelector("#livefeed");
	video.srcObject.getVideoTracks()[0].stop();
}

function codeCapturedGUI(isCaptureMode) {
	// isCaptureMode == true: live camera capture mode
	// isCaptureMode == false: display captured code and parsed data
	document.getElementById("btncancel").style.display = (isCaptureMode ? "block" : "none");
	document.getElementById("btnrestart").style.display = (isCaptureMode ? "none" : "block");
	document.getElementById("btnaccept").style.display = (isCaptureMode ? "none" : "block");
	document.getElementById("btnaccept").style.display = (isCaptureMode ? "none" : "block");
	document.getElementById("tableresults").style.display = (isCaptureMode ? "none" : "block");
}

function displayS18cFields(code) {
	var fields = parseS18cFields(code);
	
	document.querySelector("#field_upu").innerHTML = fields.UPU_identifier;
	document.querySelector("#field_format").innerHTML = fields.format_identifier;
	document.querySelector("#field_issuer").innerHTML = fields.issuer_code;
	document.querySelector("#field_equip").innerHTML = fields.equipement_id;
	document.querySelector("#field_priority").innerHTML = fields.item_priority;
	document.querySelector("#field_sn_month").innerHTML = fields.serial_number_month;
	document.querySelector("#field_sn_day").innerHTML = fields.serial_number_day;
	document.querySelector("#field_sn_hour").innerHTML = fields.serial_number_hour;
	document.querySelector("#field_sn_min").innerHTML = fields.serial_number_10min;
	document.querySelector("#field_sn_itemno").innerHTML = fields.serial_number_item;
	document.querySelector("#field_tracking").innerHTML = fields.tracking_indicator;	
}

function parseS18cFields(code)
{	
	return {
		UPU_identifier: code.substring(0, 1),
		format_identifier: code.substring(1, 4),
		issuer_code: code.substring(4, 7),
		equipement_id: code.substring(7, 10),
		item_priority: code.substring(10, 11),
		serial_number_month: code.substring(11, 13),
		serial_number_day: code.substring(13, 15),
		serial_number_hour: code.substring(15, 17),
		serial_number_10min: code.substring(17, 18),
		serial_number_item: code.substring(18, 23),
		tracking_indicator: code.substring(23, 24)
	};
}

function validCodeFound(scan_results){
	displayS18cFields(scan_results.idtag);
	codeCapturedGUI(false);
	stopCamera();
	validCodeCache = scan_results;
	lastCode = "";
}

// frame grabber
function runDetection() {
	imageCapture.grabFrame() // todo takePicture() when a code is yellow? (higher quality)
		.then(function(imageBitmap) {
			hiddenFrameCanvas.width = imageBitmap.width;
			hiddenFrameCanvas.height = imageBitmap.height;
			var ctx = hiddenFrameCanvas.getContext("2d");
			var offset_H = Math.round(hiddenFrameCanvas.height / 4);
			ctx.drawImage(imageBitmap, 0, 0);
			var imgData = ctx.getImageData(0, offset_H, hiddenFrameCanvas.width, hiddenFrameCanvas.height - 2*offset_H);
			scan_results = runLibs18cDetection(imgData);
			
			var canvas = document.querySelector('#canvasoverlay');
			canvas.width = imageBitmap.width;
			canvas.height = imageBitmap.height;
			var ctx = canvas.getContext("2d");
			
			ctx.beginPath();
			ctx.lineWidth = "6";
			
			var done = false;
			if (scan_results.exitcode == 0 && !(lastCode === scan_results.idtag))
			{
				lastCode = scan_results.idtag;
				ctx.strokeStyle = "blue";
			}
			else if (scan_results.exitcode == 0 && lastCode === scan_results.idtag)
			{
				// success!
				ctx.strokeStyle = "green";
				ctx.drawImage(imageBitmap, 0, 0); // freeze on the good frame.
				scan_results.picture = hiddenFrameCanvas.toDataURL('image/jpeg', 0.95);
				validCodeFound(scan_results);
				done = true;
			}
			else if (scan_results.exitcode == -1)
			{
				ctx.strokeStyle = "red";
			}
			else if (scan_results.exitcode == -2)
			{
				ctx.strokeStyle = "yellow";
			}
			else
			{
				ctx.strokeStyle = "orange";
			}
			
			// display rectangular region of interest (user feedback)
			ctx.rect(scan_results.roi[0], scan_results.roi[1] + offset_H, scan_results.roi[2]-scan_results.roi[0], scan_results.roi[3]-scan_results.roi[1]);
			ctx.stroke();
			
			// display result message (etiher IDTag or output message)
			if (scan_results.exitcode == 0)
			{
				ctx.fillStyle = "green";
				ctx.font = '24px serif';
				ctx.fillText(scan_results.idtag, 20, 50);
			}
			else
			{
				ctx.fillStyle = "red";
				ctx.font = '24px serif';
				ctx.fillText(scan_results.msg, 20, 50);
			}
			
			// avoid memory leaks
			imgData = null;
			ctx = null;
			
			// request another detection if the code was not found.
			if (!done)
				requestAnimationFrame(runDetection);
	})
	.catch(function(error) {
		console.log('grabFrame() error: ', error);
	});
}

// canvas overlay (needs to resize with video)
function resize_canvas(element)
{
	var w = element.offsetWidth;
	var h = element.offsetHeight;
	var cv = document.getElementById("canvasoverlay");
	cv.width = w;
	cv.height = h;
	hiddenFrameCanvas.width = w;
	hiddenFrameCanvas.height = h;
}


//** storage **//



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
function _heapToArray_int32(heapBytes, array) {
	return new Int32Array(
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
	// Create Data
	var buff_input_frame = new Uint8Array(imageData.data.buffer); // library will accept up to 4K resolution here (total pixels)
	var buff_exit_code = new Int32Array(1);
	var buff_output_idtag = new Uint8Array(24);
	var buff_output_buscode = new Uint8Array(75);
	var buff_output_roi = new Float32Array(4);
	
	// Move Data to Heap
	var bytes_input_frame = _arrayToHeap(buff_input_frame);			
	var bytes_exit_code = _arrayToHeap(buff_exit_code);
	var bytes_output_idtag = _arrayToHeap(buff_output_idtag);
	var bytes_output_buscode = _arrayToHeap(buff_output_buscode);
	var bytes_output_roi = _arrayToHeap(buff_output_roi);
	// Run Function
	Module._libsc18c_initialize();
	
	//var t0 = performance.now()
	Module._detect(
		bytes_input_frame.byteOffset,
		imageData.height,
		imageData.width,
		bytes_exit_code.byteOffset,
		bytes_output_idtag.byteOffset,
		bytes_output_buscode.byteOffset,
		bytes_output_roi.byteOffset);
	//var t1 = performance.now()
	//console.log("Call to _detect took " + (t1 - t0) + " milliseconds.")

	Module._libsc18c_terminate();
	// Copy Data from Heap
	buff_exit_code = _heapToArray_int32(bytes_exit_code, buff_exit_code);
	buff_output_idtag = _heapToString(bytes_output_idtag, buff_output_idtag);
	buff_output_buscode = _heapToString(bytes_output_buscode, buff_output_buscode);
	buff_output_roi = _heapToArray_float32(bytes_output_roi, buff_output_roi);
	
	// Free Data from Heap
	_freeArray(bytes_input_frame);
	_freeArray(bytes_exit_code);
	_freeArray(bytes_output_idtag);
	_freeArray(bytes_output_buscode);
	_freeArray(bytes_output_roi);
	
	// Display Results
	var error_message = "";
	if(buff_exit_code == 0)
		error_message = "success";
	else if(buff_exit_code == -1)
		error_message = "best region is not rectangular";
	else if(buff_exit_code == -2)
		error_message = "unable to find all bars";
	else if(buff_exit_code == -3)
		error_message = "envelope is too bent";
	else if(buff_exit_code == -4)
		error_message = "unexpected barcode format";
	else if(buff_exit_code == -5)
		error_message = "error correction failed";
	else
		error_message = "unknown error code";
	
	return {
		exitcode: buff_exit_code,
		msg: error_message,
		idtag: buff_output_idtag,
		buscode: buff_output_buscode,
		roi: buff_output_roi
	};
}



		