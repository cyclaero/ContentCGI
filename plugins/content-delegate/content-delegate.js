/* Editor JS of the Content Responder Delegate */

var qargs = {};
location.search.substr(1).split("&").forEach(function(item) {
   var s = item.split("="), k = s[0], v = s[1] && decodeURIComponent(s[1]);
   (qargs[k] = qargs[k] || []).push(v)
})


ContentEdit.TRIM_WHITESPACE = false;

window.addEventListener('load', function() {
   var editor;
});

ContentTools.StylePalette.add([
   new ContentTools.Style('Stamp',        'stamp',        ['p']),
   new ContentTools.Style('Align center', 'align-center', ['img']),
   new ContentTools.Style('Shade',        'shade',        ['img']),
   new ContentTools.Style('Shade center', 'shade-center', ['img'])
]);

editor = ContentTools.EditorApp.get();
editor.init('[data-editable], [data-fixture]', 'data-name');


function getImages() {
   // Return an object containing image URLs and widths for all regions
   var descendants, i, images;

   images = "";
   for (name in editor.regions()) {
      // Search each region for images
      descendants = editor.regions()[name].descendants();
      for (i = 0; i < descendants.length; i++) {
         // Filter out elements that are not images
         if (descendants[i].type() !== 'Image')
            continue;
         images += descendants[i].attr('src') + '\n';
      }
   }

   return images;
}

editor.addEventListener('saved', function (ev) {
   var name, payload, regions, xhr;

   // Check that something changed
   regions = ev.detail().regions;
   if (Object.keys(regions).length == 0) {
      return;
   }

   // Set the editor as busy while we save our changes
   this.busy(true);

   // Collect the contents of each region into a FormData instance
   payload = new FormData();
   for (name in regions) {
      if (regions.hasOwnProperty(name)) {
         var images = getImages();
         if (images != "")
            payload.append('images', images);
         payload.append('content', regions[name]);
      }
   }

   // Send the update content to the server to be saved
   function onStateChange(ev) {
      // Check if the request is finished
      if (ev.target.readyState == 4) {
         editor.busy(false);
         switch (ev.target.status) {
            // Save was successful, notify the user with the OK flash
            case 200:
            case 204:
               new ContentTools.FlashUI('ok');
               break;

            case 201:
               new ContentTools.FlashUI('ok');
               var location = ev.target.getResponseHeader('Location');
               if (location)
                  setTimeout(function(){window.location = location}, 1000);
               break;

            // Save failed, notify the user with the nOK flash
            default:
               new ContentTools.FlashUI('no');
         }
      }
   };

   xhr = new XMLHttpRequest();
   xhr.addEventListener('readystatechange', onStateChange);
   xhr.open('POST', location.pathname);
   xhr.send(payload);
});


function imageUploader(dialog) {
   var image, xhr, xhrComplete, xhrProgress;

// Set up the event handlers
   // Cancel the current upload
   dialog.addEventListener('imageuploader.cancelupload', function () {
      // Stop the upload
      if (xhr) {
         xhr.upload.removeEventListener('progress', xhrProgress);
         xhr.removeEventListener('readystatechange', xhrComplete);
         xhr.abort();
      }

      // Set the dialog to empty
      dialog.state('empty');
   });

   // Clear the current image
   dialog.addEventListener('imageuploader.clear', function () {
      dialog.clear();
      image = null;
   });

// Upload a file to the server
   dialog.addEventListener('imageuploader.fileready', function (ev) {
      var formData;
      var file = ev.detail().file;

      // Define functions to handle upload progress and completion
      xhrProgress = function (ev) {
         // Set the progress for the upload
         dialog.progress((ev.loaded/ev.total)*100);
      }

      xhrComplete = function (ev) {
         var response;

         // Check the request is complete
         if (ev.target.readyState != 4) {
            return;
         }

         // Clear the request
         xhr = null
         xhrProgress = null
         xhrComplete = null

         // Handle the result of the upload
         if (parseInt(ev.target.status) == 200) {
            response = ev.target.responseText.split('\n');

            // Store the image details
            image = {url:response[0], size:[response[1], response[2]]};

            // Populate the dialog
            dialog.populate(image.url, image.size);

         } else {
            // The request failed, notify the user
            new ContentTools.FlashUI('no');
         }
      }

      // Set the dialog state to uploading and reset the progress bar to 0
      dialog.state('uploading');
      dialog.progress(0);

      // Build the form data to post to the server
      formData = new FormData();
      formData.append('image', file);

      // Construct the upload path
      var stamp, pathcomps = location.pathname.split('/');
      var i, n = pathcomps.length - 1;
      if (isNaN(stamp = parseInt(pathcomps[n])))
         stamp = document.getElementById('stamp').value;
      if (n > 2 && stamp >= 0)
      {
         var uppath = "/"+pathcomps[1]+"/upload";
         for (i = 2; i < n; i++)
            uppath += "/"+pathcomps[i];
         uppath += "/media/"+stamp;

         // Make the request
         xhr = new XMLHttpRequest();
         xhr.upload.addEventListener('progress', xhrProgress);
         xhr.addEventListener('readystatechange', xhrComplete);
         xhr.open('POST', uppath, true);
         xhr.send(formData);
      }
   });

   function rotateImage(direction) {
      // Request a rotated version of the image from the server
      var formData;

      // Define a function to handle the request completion
      xhrComplete = function (ev) {
         var response;

         // Check the request is complete
         if (ev.target.readyState != 4) {
            return;
         }

         // Clear the request
         xhr = null
         xhrComplete = null

         // Free the dialog from its busy state
         dialog.busy(false);

         // Handle the result of the rotation
         if (parseInt(ev.target.status) == 200) {
            // Unpack the response (from JSON)
            response = JSON.parse(ev.target.responseText);

            // Store the image details (use fake param to force refresh)
            image = {
               size: response.size,
               url: response.url + '?_ignore=' + Date.now()
            };

            // Populate the dialog
            dialog.populate(image.url, image.size);

         } else {
            // The request failed, notify the user
            new ContentTools.FlashUI('no');
         }
      }

      // Set the dialog to busy while the rotate is performed
      dialog.busy(true);

      // Build the form data to post to the server
      formData = new FormData();
      formData.append('url', image.url);
      formData.append('direction', direction);

      // Make the request
      xhr = new XMLHttpRequest();
      xhr.addEventListener('readystatechange', xhrComplete);
      xhr.open('POST', '/rotate-image', true);
      xhr.send(formData);
   }

   dialog.addEventListener('imageuploader.rotateccw', function () {
      rotateImage('CCW');
   });

   dialog.addEventListener('imageuploader.rotatecw', function () {
      rotateImage('CW');
   });


   dialog.addEventListener('imageuploader.save', function () {
      var crop, cropRegion, textData;

      // Define a function to handle the request completion
      xhrComplete = function (ev) {
         // Check the request is complete
         if (ev.target.readyState !== 4) {
            return;
         }

         // Clear the request
         xhr = null
         xhrComplete = null

         // Free the dialog from its busy state
         dialog.busy(false);

         // Handle the result of the rotation
         if (parseInt(ev.target.status) === 200) {
            var response = ev.target.responseText.split('\n');

            // Trigger the save event against the dialog with details of the image to be inserted.
            dialog.save(response[0], [response[1], response[2]]);

         } else {
            // The request failed, notify the user
            new ContentTools.FlashUI('no');
         }
      }

      // Set the dialog to busy while the rotate is performed
      dialog.busy(true);

      // Build the request data set
      textData = image.size + '\n' + dialog.cropRegion() + '\n';

      // Construct the insert path
      var pathcomps = location.pathname.split('/');
      var inpath = "/"+pathcomps[1]+"/insert/"+image.url;

      // Make the request
      xhr = new XMLHttpRequest();
      xhr.addEventListener('readystatechange', xhrComplete);
      xhr.open('POST', inpath, true);
      xhr.setRequestHeader("Content-type", "text/plain;charset=UTF-8");
      xhr.send(textData);
   });
}

ContentTools.IMAGE_UPLOADER = imageUploader;
