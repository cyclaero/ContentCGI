/* Editor JS of the Content Responder Delegate */

ContentEdit.TRIM_WHITESPACE    = false;

window.addEventListener('load', function()
{
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


var IMG_MAX_WIDTH = 675.0,
    ROTATION_STEP = 15;


editor.addEventListener('saved', function (ev)
{
   var name, payload, regions, xhr;

   regions = ev.detail().regions;
   if (Object.keys(regions).length == 0)
      return;

   this.busy(true);

   payload = new FormData();
   for (name in regions)
      if (regions.hasOwnProperty(name))
         payload.append('content', regions[name]);

   function onStateChange(ev)
   {
      if (ev.target.readyState == 4)
      {
         editor.busy(false);

         switch (ev.target.status)
         {
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


function imageUploader(dialog)
{
   var original, image, angle, xhr, xhrComplete, xhrProgress;

   dialog.addEventListener('imageuploader.cancelupload', function ()
   {
      if (xhr)
      {
         xhr.upload.removeEventListener('progress', xhrProgress);
         xhr.removeEventListener('readystatechange', xhrComplete);
         xhr.abort();
      }

      dialog.state('empty');
   });


   dialog.addEventListener('imageuploader.clear', function ()
   {
      dialog.clear();
      image = null;
   });


   dialog.addEventListener('imageuploader.fileready', function (ev)
   {
      var formData, file = ev.detail().file;

      xhrProgress = function (ev)
      {
         dialog.progress((ev.loaded/ev.total)*100);
      }

      xhrComplete = function (ev)
      {
         if (ev.target.readyState != 4)
            return;

         xhr = null
         xhrProgress = null
         xhrComplete = null

         if (parseInt(ev.target.status) == 200)
         {
            var response = ev.target.responseText.split('\n');
            image = original = {url:encodeURI(response[0]), size:[response[1], response[2]]};
            angle = 0;
            dialog.populate(image.url, image.size);
         }
         else
            new ContentTools.FlashUI('no');
      }

      dialog.state('uploading');
      dialog.progress(0);

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

         xhr = new XMLHttpRequest();
         xhr.upload.addEventListener('progress', xhrProgress);
         xhr.addEventListener('readystatechange', xhrComplete);
         xhr.open('POST', uppath, true);
         xhr.send(formData);
      }
   });


   function rotateImage()
   {
      if (Math.abs(angle) < 0.001)
         dialog.populate(original.url, original.size);

      else
      {
         xhrComplete = function (ev)
         {
            if (ev.target.readyState !== 4)
               return;

            xhr = null
            xhrComplete = null

            dialog.busy(false);

            if (parseInt(ev.target.status) === 200)
            {
               var response = ev.target.responseText.split('\n');
               image = {url:encodeURI(response[0]+'.png'), size:[response[1], response[2]]};
               dialog.populate(image.url+'?'+ + Date.now(), image.size);
            }
            else
               new ContentTools.FlashUI('no');
         }

         dialog.busy(true);

         var textData = original.size + '\n' + angle + '\n';

         // Construct the rotate path
         var pathcomps = location.pathname.split('/');
         var rotpath = "/"+pathcomps[1]+"/rotate/"+original.url;

         xhr = new XMLHttpRequest();
         xhr.addEventListener('readystatechange', xhrComplete);
         xhr.open('POST', rotpath, true);
         xhr.setRequestHeader("Content-type", "text/plain;charset=UTF-8");
         xhr.send(textData);
      }
   }

   dialog.addEventListener('imageuploader.rotateccw', function ()
   {
      angle -= ROTATION_STEP;
      rotateImage();
   });

   dialog.addEventListener('imageuploader.rotatecw', function ()
   {
      angle += ROTATION_STEP;
      rotateImage();
   });


   dialog.addEventListener('imageuploader.save', function ()
   {
      xhrComplete = function (ev)
      {
         if (ev.target.readyState !== 4)
            return;

         xhr = null
         xhrComplete = null

         dialog.busy(false);

         if (parseInt(ev.target.status) === 200)
         {
            var response = ev.target.responseText.split('\n');
            image = {url:encodeURI(response[0]+'.png'), size:[response[1], response[2]]};
            if (image.size[0] > IMG_MAX_WIDTH)
            {
               image.size[1] = Math.round((IMG_MAX_WIDTH*image.size[1])/image.size[0]);
               image.size[0] = Math.round(IMG_MAX_WIDTH);
            }
            dialog.save(image.url, image.size);
         }
         else
            new ContentTools.FlashUI('no');
      }

      dialog.busy(true);

      var textData = image.size + '\n' + angle + '\n' + dialog.cropRegion() + '\n';

      // Construct the insert path
      var pathcomps = location.pathname.split('/');
      var inpath = "/"+pathcomps[1]+"/insert/"+original.url;

      xhr = new XMLHttpRequest();
      xhr.addEventListener('readystatechange', xhrComplete);
      xhr.open('POST', inpath, true);
      xhr.setRequestHeader("Content-type", "text/plain;charset=UTF-8");
      xhr.send(textData);
   });
}

ContentTools.IMAGE_UPLOADER = imageUploader;

editor.ignition().edit();
