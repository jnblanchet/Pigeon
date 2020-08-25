/*
Copyrights 2020 (c) Jean-Nicola Blanchet
All rights reserved.
 */

document.addEventListener('deviceready', onDeviceReady, false);

function onDeviceReady() {
	// display storage path
	getStorageFullPath((path) => {
		document.getElementById('divpath').innerHTML = "<p>Device storage directory: <br /> <span style='font-weight: bold;'>" + path + "</span></p>"
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