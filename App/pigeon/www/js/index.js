/*
Copyrights 2020 (c) Jean-Nicola Blanchet
All rights reserved.
 */

document.addEventListener('deviceready', onDeviceReady, false);

function onDeviceReady() {
    //console.log('Running cordova-' + cordova.platformId + '@' + cordova.version);
    document.getElementById('deviceready').classList.add('ready');
		
		
		var permissions = cordova.plugins.permissions;
		//permissions.checkPermission(permission, successCallback, errorCallback);
		permissions.requestPermission(permissions.CAMERA, ()=>{}, (err)=>{console.log(err)});
		//permissions.requestPermissions(permissions, successCallback, errorCallback);


    //alert(cordova.file.dataDirectory);
	//createPersistentStorageDirectory();
}

function writeFile(fileEntry, dataObj) {
    // Create a FileWriter object for our FileEntry (log.txt).
    fileEntry.createWriter(function (fileWriter) {

        fileWriter.onwriteend = function() {
            alert("Successful file write...");
            readFile(fileEntry);
        };

        fileWriter.onerror = function (e) {
            alert("Failed file write: " + e.toString());
        };

        // If data object is not passed in,
        // create a new Blob instead.
        if (!dataObj) {
            dataObj = new Blob(['some file data'], { type: 'text/plain' });
        }

        fileWriter.write(dataObj);
    });
}

function createPersistentStorageDirectory() {
	
	window.requestFileSystem(LocalFileSystem.PERSISTENT, 0, function (fs) {

    alert('file system open: ' + fs.name);
	alert('file system root: ' + fs.root.fullPath);
				
    fs.root.getFile("newPersistentFile.txt", { create: true, exclusive: false }, function (fileEntry) {

        alert("fileEntry is file?" + fileEntry.isFile.toString());
        // fileEntry.name == 'someFile.txt'
        // fileEntry.fullPath == '/someFile.txt'
        writeFile(fileEntry, null);

    }, handleError);

}, handleError);

function readDirectory(directory) {
  let dirReader = directory.createReader();
  let entries = [];

  let getEntries = function() {
    dirReader.readEntries(function(results) {
      if (results.length) {
        entries = entries.concat(toArray(results));
        getEntries();
      }
    }, function(error) {
		console.log(error);
    });
  };

  getEntries();
  return entries;
}


function writeFile(fileEntry, dataObj) {
    // Create a FileWriter object for our FileEntry (log.txt).
    fileEntry.createWriter(function (fileWriter) {

        fileWriter.onwriteend = function() {
            alert("Successful file write...");
            readFile(fileEntry);
        };

        fileWriter.onerror = function (e) {
            alert("Failed file write: " + e.toString());
        };

        // If data object is not passed in,
        // create a new Blob instead.
        if (!dataObj) {
            dataObj = new Blob(['some file data'], { type: 'text/plain' });
        }

        fileWriter.write(dataObj);
    });
}

function readFile(fileEntry) {

    fileEntry.file(function (file) {
        var reader = new FileReader();

        reader.onloadend = function() {
            alert("Successful file read: " + this.result);
            alert(fileEntry.fullPath + ": " + this.result);
        };

        reader.readAsText(file);

    }, handleError);
}


/*	function listDir(path){
	  window.resolveLocalFileSystemURL(path,
		function (fileSystem) {
		  var reader = fileSystem.createReader();
		  reader.readEntries(
			function (entries) {
				for (var e in entries)
					alert(entries[e]);
			},
			function (err) {
			  alert(err);
			}
		  );
		}, function (err) {
		  alert(err);
		}
	  );
	}
	//example: list of www/audio/ folder in cordova/ionic app.
	listDir(cordova.file.dataDirectory);	*/
}

function handleError(err)
{
	alert(err);
}