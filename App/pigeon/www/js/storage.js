/*
Copyrights 2020 (c) Jean-Nicola Blanchet
All rights reserved.
 */
 
 // the following functions are defined here:
	// 1) getTimestampString()
	//		example :
	//			console.log(getTimestampString());
	//					
	// 2) getStorageFullPath()
	//		example :
	//			getStorageFullPath((path) => console.log(path));
	//					
	// 3) getArchivedFiles()
	//		example :
	//			getArchivedFiles((file) =>
	//				console.log(file)
	//			);
	// 4) archiveObject(object)
	//		example :
	//			const data = [{
	//				"data": "some data"
	//			}];
	//			archiveObject(data);
	// 5) readobject(path)
	//		example :
	//			readArchivedObject("somefile.txt", (data) =>
	//				console.log(data)
	//			);
	// 6) deleteFile(path)
	//		example :
	//			deleteFile("newPersistentFile.txt");
	// 7) handleError: can be changed to support another error handling method
 
function getTimestampString() {
	var m = new Date();
	var dateString = m.getFullYear() +"-"+
			(m.getMonth()+1).toString().padStart(2,'0') +"-"+
			m.getDate().toString().padStart(2,'0') + "_" +
			m.getHours().toString().padStart(2,'0') + "-" +
			m.getMinutes().toString().padStart(2,'0') + "-"
			+ m.getSeconds().toString().padStart(2,'0');
			
	return dateString;
}

function getStorageFullPath(callback) {
	window.requestFileSystem(LocalFileSystem.PERSISTENT, 0, function (fs) { callback(fs.root.fullPath)});
}

function getArchivedFiles(functionPerFile) {
	window.requestFileSystem(LocalFileSystem.PERSISTENT, 0, function (fs) {
		// recursive function to parse the files
		function readDirectory(directory) {
			let dirReader = directory.createReader();
			let entries = new Array();

			let getEntries = function() {
				dirReader.readEntries(function(results) {
				if (results.length) {
					for (var file in results)
						functionPerFile(results[file].name);
					getEntries();
				}
				}, handleError
				);
			};
			getEntries();
		}
		readDirectory(fs.root);
	});
}

function archiveObject(object, callback) {
	// file writing function
	function writeFile(fileEntry, dataObj) {
		fileEntry.createWriter(function (fileWriter) {

			fileWriter.onwriteend = function() {
				if (callback)
					callback();
			};

			fileWriter.onerror = handleError;

			fileWriter.write(dataObj);
		});
	}

	let json = JSON.stringify(object);
	const blob = new Blob([json], {type:"application/json"});

	// request the creation of a new file, and write the data to the new file
	window.requestFileSystem(LocalFileSystem.PERSISTENT, 0, function (fs) {
		fs.root.getFile(getTimestampString() + ".txt", { create: true, exclusive: false }, function (fileEntry) {
				writeFile(fileEntry, blob);
		}, handleError);
	});
}


function readArchivedObject(name, applyLogic) {
	// file read logic
	function readFile(fileEntry) {
		fileEntry.file(function (file) {
			var reader = new FileReader();
			
			reader.onloadend = e => {
				try {
					let object = JSON.parse(reader.result);
					applyLogic(object)
				} catch(err) {
					handleError("unable to parse json for file " + file);
				}
			};
			
			reader.readAsText(file);
		}, handleError);
	}
	// request the file handle
	window.requestFileSystem(LocalFileSystem.PERSISTENT, 0, function (fs) {
		fs.root.getFile(name, { create: false, exclusive: false }, function (fileEntry) {
			readFile(fileEntry);
		}, handleError);
	});

}

function deleteFile(path) {
	// request the file, and delete it
	window.requestFileSystem(LocalFileSystem.PERSISTENT, 0, function (fs) {
		fs.root.getFile(path, { create: false }, function (fileEntry) {
			fileEntry.remove(
				function () {
					// this may be useful for debugging
				}, handleError);
		
		}, handleError);
	});
}

function handleError(err)
{
	console.log(err);
}