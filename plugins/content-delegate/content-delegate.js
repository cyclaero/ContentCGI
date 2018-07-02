/* Editor JS of the Content Responder Delegate */

ContentEdit.TRIM_WHITESPACE = false;

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


function getImages()
{
   var descendants, i, images;

   images = "";
   for (name in editor.regions())
   {
      descendants = editor.regions()[name].descendants();
      for (i = 0; i < descendants.length; i++)
      {
         if (descendants[i].type() !== 'Image')
            continue;
         images += descendants[i].attr('src') + '\n';
      }
   }

   return images;
}

editor.addEventListener('saved', function (ev)
{
   var name, payload, regions, xhr;

   regions = ev.detail().regions;
   if (Object.keys(regions).length == 0)
      return;

   this.busy(true);

   payload = new FormData();
   for (name in regions)
   {
      if (regions.hasOwnProperty(name))
      {
         var images = getImages();
         if (images != "")
            payload.append('images', images);
         payload.append('content', regions[name]);
      }
   }

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
   var image, xhr, xhrComplete, xhrProgress;

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
            image = {url:encodeURI(response[0]), size:[response[1], response[2]]};
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


   function rotateImage(angle)
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
            image = {url:encodeURI(response[0]), size:[response[1], response[2]]};
            dialog.save(image.url, image.size);
         }
         else
            new ContentTools.FlashUI('no');
      }

      dialog.busy(true);

      var textData = image.size + '\n' + angle + '\n';

      // Construct the rotate path
      var pathcomps = location.pathname.split('/');
      var rotpath = "/"+pathcomps[1]+"/rotate/"+image.url;

      xhr = new XMLHttpRequest();
      xhr.addEventListener('readystatechange', xhrComplete);
      xhr.open('POST', rotpath, true);
      xhr.setRequestHeader("Content-type", "text/plain;charset=UTF-8");
      xhr.send(textData);
   }

   dialog.addEventListener('imageuploader.rotateccw', function ()
   {
      rotateImage(90);
   });

   dialog.addEventListener('imageuploader.rotatecw', function ()
   {
      rotateImage(-90);
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
            image = {url:encodeURI(response[0]), size:[response[1], response[2]]};
            dialog.save(image.url, image.size);
         }
         else
            new ContentTools.FlashUI('no');
      }

      dialog.busy(true);

      var textData = image.size + '\n' + dialog.cropRegion() + '\n';

      // Construct the insert path
      var pathcomps = location.pathname.split('/');
      var inpath = "/"+pathcomps[1]+"/insert/"+image.url;

      xhr = new XMLHttpRequest();
      xhr.addEventListener('readystatechange', xhrComplete);
      xhr.open('POST', inpath, true);
      xhr.setRequestHeader("Content-type", "text/plain;charset=UTF-8");
      xhr.send(textData);
   });
}

ContentTools.IMAGE_UPLOADER = imageUploader;
