/*
Copyrights 2020 (c) Jean-Nicola Blanchet
All rights reserved.
 */

document.addEventListener('deviceready', onDeviceReady, false);

function onDeviceReady() {
    document.getElementById('deviceready').classList.add('ready');
		
	var permissions = cordova.plugins.permissions;
	permissions.requestPermission(permissions.CAMERA, ()=>{}, (err)=>{console.log(err)});
}