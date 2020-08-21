/*
Copyrights 2020 (c) Jean-Nicola Blanchet
All rights reserved.
 */
 
var imageCapture;
var hiddenFrameCanvas = document.createElement("canvas"); // used to convert imageBitmap into pixel data

  
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

		})
		.catch(function (err) {
			alert(err);
		});
	}
}

function codeCapturedGUI() {
	document.getElementById("btncancel").style.display = "none";
	document.getElementById("btnrestart").style.display = "block";
	document.getElementById("btnaccept").style.display = "block";
	document.getElementById("btnaccept").style.display = "block";
	document.getElementById("tableresults").style.display = "block";
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

// frame grabber
function onGrabFrameButtonClick() {
	/*
	// this is probably possible for a phone!
	const photoBlob = imageCapture.takePhoto({fillLightMode: "auto"}).then(function(imageBitmap) {
		console.log(photoBlob)
	});
	return;
	*/
	  
	imageCapture.grabFrame()
		.then(function(imageBitmap) {
			hiddenFrameCanvas.width = imageBitmap.width;
			hiddenFrameCanvas.height = imageBitmap.height;
			hiddenFrameCanvas.getContext('2d').drawImage(imageBitmap, 0, 0);
			var ctx = hiddenFrameCanvas.getContext("2d");
			var imgData = ctx.getImageData(0, 0, hiddenFrameCanvas.width, hiddenFrameCanvas.height);
			scan_results = runLibs18cDetection(imgData);
			
			var canvas = document.querySelector('#canvasoverlay');
			canvas.width = imageBitmap.width;
			canvas.height = imageBitmap.height;
			var ctx = canvas.getContext("2d");
			
			console.log("idtag: " + scan_results.idtag);
			console.log("roi: " + scan_results.roi);
			console.log("exitcode: " + scan_results.exitcode);
			console.log("msg: " + scan_results.msg);
			
			ctx.beginPath();
			ctx.lineWidth = "6";
			if (scan_results.exitcode == -1)
				ctx.strokeStyle = "red";
			else if (scan_results.exitcode == 0) {
				// success!
				ctx.strokeStyle = "green";
				displayS18cFields(scan_results.idtag);
				codeCapturedGUI();
			}else
				ctx.strokeStyle = "yellow";
			
			ctx.rect(scan_results.roi[0], scan_results.roi[1], scan_results.roi[2]-scan_results.roi[0], scan_results.roi[3]-scan_results.roi[1]);
			ctx.stroke();
			
			if (scan_results.exitcode == 0)
			{
				ctx.fillStyle = "green";
				ctx.font = '48px serif';
				ctx.fillText(scan_results.idtag, 10, 50);
			}
			else
			{
				ctx.fillStyle = "red";
				ctx.font = '48px serif';
				ctx.fillText(scan_results.msg, 10, 50);
			}
			
			// avoid memory leaks
			scan_results = null;
			imgData = null;
			ctx = null;

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
	hiddenFrameCanvas.width = w;
	hiddenFrameCanvas.height = h;
	
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
	var buff_output_code = new Uint8Array(24);
	var buff_output_roi = new Float32Array(4);
	
	// Move Data to Heap
	var bytes_input_frame = _arrayToHeap(buff_input_frame);			
	var bytes_exit_code = _arrayToHeap(buff_exit_code);
	var bytes_output_code = _arrayToHeap(buff_output_code);
	var bytes_output_roi = _arrayToHeap(buff_output_roi);
	// Run Function
	Module._libsc18c_initialize();
	
	var t0 = performance.now()
	Module._detectHD(
		bytes_input_frame.byteOffset,
		imageData.height,
		imageData.width,
		bytes_exit_code.byteOffset,
		bytes_output_code.byteOffset,
		bytes_output_roi.byteOffset);
	var t1 = performance.now()
	console.log("Call to _detectHD took " + (t1 - t0) + " milliseconds.")

	Module._libsc18c_terminate();
	//  Copy Data from Heap
	buff_exit_code = _heapToArray_int32(bytes_exit_code, buff_exit_code);
	buff_output_code = _heapToString(bytes_output_code, buff_output_code);
	buff_output_roi = _heapToArray_float32(bytes_output_roi, buff_output_roi);
	
	// Free Data from Heap
	_freeArray(bytes_input_frame);
	_freeArray(bytes_exit_code);
	_freeArray(bytes_output_code);
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
		error_message = "unexpected code format";
	else if(buff_exit_code == -5)
		error_message = "error correction failed";
	else
		error_message = "unknown error code";
	
	return {
		exitcode: buff_exit_code,
		msg: error_message,
		idtag: buff_output_code,
		roi: buff_output_roi
	};
}



		