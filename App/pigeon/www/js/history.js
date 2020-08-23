/*
Copyrights 2020 (c) Jean-Nicola Blanchet
All rights reserved.
 */

document.addEventListener('deviceready', onDeviceReady, false);

function onDeviceReady() {
	
	// display storage path
	getStorageFullPath((path) => {
		document.getElementById('divpath').innerHTML = "<p>Path to file storage on the device: <br /> <span style='font-weight: bold;'>" + path + "</span></p>"
	});
	
    // displayed populate storage files
	getArchivedFiles((file) => {
		readArchivedObject(file, (data) => {
			var node = document.createElement('div');
			node.id = "div"+file;
			var deletestring = 'deleteAndRemoveEntry("' + file + '")';
			node.innerHTML =
			"<h3>" + file + "</h3>" +
			"<div style='padding-left:25px;'>" +
			"<p><span style='font-weight: bold; word-wrap: break-word;'>IDTag: </span>" + data.idtag + "</p>" +
			"<p><span style='font-weight: bold; word-wrap: break-word;'>Bus Code: </span>" + data.buscode + "</p>" +
			"<a href='#' onclick='" + deletestring + "'>DELETE</a>" +
			"<div class='centered'>" +
			"<img src='" + data.picture + "' class='thumbnail' />" +
			"</div>" + 
			"</div>";
			document.getElementById('divhistory').appendChild(node);
		});
	});
}

function deleteAndRemoveEntry(fileName) {
	if (confirm("Delete " + fileName + "?"))
	{
		document.getElementById("div"+fileName).innerHTML = ""; // remove from list
		deleteFile(fileName); // remove from storage
	}
}
	
	/*
	// 1) getStorageFullPath()
	console.log('getStorageFullPath(): ');
	
	// 2) getArchivedFiles()
	console.log('getArchivedFiles(): ');
	getArchivedFiles((file) =>
		deleteFile(file)
		//console.log(file)
		);
	// 3) archiveObject(object)
	console.log(getTimestampString());
	const data = [{
	  "data": "some data"
	}];
	//archiveObject(data);
	// 4) readobject(path)
	readArchivedobject("2020-08-23_15-03-07.txt", (data) =>
		console.log(data)
	);
	// 5) deleteFile(path)
	deleteFile("newPersistentFile.txt");
	*/