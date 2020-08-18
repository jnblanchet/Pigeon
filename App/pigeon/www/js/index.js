/*
Copyrights 2020 (c) Jean-Nicola Blanchet
All rights reserved.
 */

document.addEventListener('deviceready', onDeviceReady, false);

function onDeviceReady() {
    //console.log('Running cordova-' + cordova.platformId + '@' + cordova.version);
    document.getElementById('deviceready').classList.add('ready');
}