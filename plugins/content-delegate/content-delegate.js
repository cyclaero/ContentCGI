
/* Editor JS of the Content Responder Delegate */

ContentTools.Tools.Underline = (function() {
  class Underline extends ContentTools.Tools.Bold {};

  ContentTools.ToolShelf.stow(Underline, 'underline');
  Underline.label = 'Underline';
  Underline.icon = 'underline';
  Underline.tagName = 'u';

  return Underline;

}).call(this);

ContentTools.Tools.Subscript = (function() {
  class Subscript extends ContentTools.Tools.Bold {};

  ContentTools.ToolShelf.stow(Subscript, 'subscript');
  Subscript.label = 'Subscript';
  Subscript.icon = 'subscript';
  Subscript.tagName = 'sub';

  return Subscript;

}).call(this);

ContentTools.Tools.Superscript = (function() {
  class Superscript extends ContentTools.Tools.Bold {};

  ContentTools.ToolShelf.stow(Superscript, 'superscript');
  Superscript.label = 'Superscript';
  Superscript.icon = 'superscript';
  Superscript.tagName = 'sup';

  return Superscript;

}).call(this);

ContentTools.Tools.Strikethrough = (function() {
  class Strikethrough extends ContentTools.Tools.Bold {};

  ContentTools.ToolShelf.stow(Strikethrough, 'strikethrough');
  Strikethrough.label = 'Strikethrough';
  Strikethrough.icon = 'strikethrough';
  Strikethrough.tagName = 's';

  return Strikethrough;

}).call(this);

ContentTools.Tools.Quotation = (function() {
  class Quotation extends ContentTools.Tools.Bold {};

  ContentTools.ToolShelf.stow(Quotation, 'quotation');
  Quotation.label = 'Quotation';
  Quotation.icon = 'quotation';
  Quotation.tagName = 'q';

  return Quotation;

}).call(this);

ContentTools.Tools.Code = (function() {
  class Code extends ContentTools.Tools.Bold {};

  ContentTools.ToolShelf.stow(Code, 'code');
  Code.label = 'Code';
  Code.icon = 'code';
  Code.tagName = 'code';

  return Code;

}).call(this);

ContentTools.Tools.Tinyheading = (function() {
  class Tinyheading extends ContentTools.Tools.Heading {};

  ContentTools.ToolShelf.stow(Tinyheading, 'tinyheading');
  Tinyheading.label = 'Tinyheading';
  Tinyheading.icon = 'tinyheading';
  Tinyheading.tagName = 'h3';

  return Tinyheading;

}).call(this);

ContentTools.Tools.Blockquote = (function() {
   class Blockquote extends ContentTools.Tools.Heading {};

   ContentTools.ToolShelf.stow(Blockquote, 'blockquote');
   Blockquote.label = 'Blockquote';
   Blockquote.icon = 'blockquote';
   Blockquote.tagName = 'blockquote';

   return Blockquote;

}).call(this);

ContentTools.DEFAULT_TOOLS =
[
   [
      'bold',
      'italic',
      'underline',

      'subscript',
      'superscript',
      'strikethrough',

      'link',
      'quotation',
      'code'

   ],

   [
      'align-left',
      'align-center',
      'align-right',

      'heading',
      'subheading',
      'tinyheading',

      'paragraph',
      'blockquote',
      'preformatted'
   ],

   [
      'unordered-list',
      'ordered-list',
      'table',

      'indent',
      'unindent',
      'image'
   ],

   [
      'undo',
      'redo',
      'remove'
   ]
];


ContentTools.INLINE_TAGS = ContentTools.INLINE_TAGS.concat(['sub', 's', 'q']);
ContentTools.HTMLCleaner.DEFAULT_TAG_WHITELIST = ContentTools.HTMLCleaner.DEFAULT_TAG_WHITELIST.concat(['sub', 's', 'q']);
ContentTools.RESTRICTED_ATTRIBUTES['*']   = [];
ContentTools.RESTRICTED_ATTRIBUTES['img'] = ['src', 'data-ce-max-width', 'data-ce-min-width'];

ContentTools.StylePalette.add([
   new ContentTools.Style('Stamp',           'stamp',        ['p']),
   new ContentTools.Style('Gray background', 'back-gray',    ['p', 'tr', 'th', 'td']),
   new ContentTools.Style('Full height',     'fullheight',   ['pre']),
   new ContentTools.Style('Align center',    'align-center', ['img']),
   new ContentTools.Style('Shade',           'shade',        ['img']),
   new ContentTools.Style('Shade center',    'shade-center', ['img'])
]);

ContentTools.HIGHLIGHT_HOLD_DURATION = 4000;
ContentEdit.DRAG_HOLD_DURATION = 750;
ContentEdit.TRIM_WHITESPACE = false;
ContentEdit.INDENT = '   ';

HTMLString.Tag.SELF_CLOSING.source = true;

window.addEventListener('load', function()
{
   var editor;
});

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
         payload.append('content', regions[name].replace(/<input(.*)( name="g[0-9]*")/gm, '<input$1'));

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
   xhr.open('POST', location.pathname+location.search, true);
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
            image = original = {url:encodeURIComponent(response[0]).replace(/%2F/g, "/"), size:[response[1], response[2]]};
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
               image = {url:encodeURIComponent(response[0]+'.png').replace(/%2F/g, "/"), size:[response[1], response[2]]};
               dialog.populate(image.url+'?'+ + Date.now(), image.size);
            }
            else
               new ContentTools.FlashUI('no');
         }

         dialog.busy(true);

         var textData = original.size + '\n' + angle + '\n';

         // Construct the rotate path
         var pathcomps = location.pathname.split('/');
         var rotpath = "/"+pathcomps[1]+"/rotate/";
         var i = 2;
         while (!original.url.startsWith(pathcomps[i], 0))
            rotpath += pathcomps[i++]+"/";
         rotpath += original.url;

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
            image = {url:encodeURIComponent(response[0]+'.png').replace(/%2F/g, "/"), size:[response[1], response[2]]};
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
      var inspath = "/"+pathcomps[1]+"/insert/";
      var i = 2;
      while (!original.url.startsWith(pathcomps[i], 0))
         inspath += pathcomps[i++]+"/";
      inspath += original.url;

      xhr = new XMLHttpRequest();
      xhr.addEventListener('readystatechange', xhrComplete);
      xhr.open('POST', inspath, true);
      xhr.setRequestHeader("Content-type", "text/plain;charset=UTF-8");
      xhr.send(textData);
   });
}

ContentTools.IMAGE_UPLOADER = imageUploader;

editor.start();
editor.ignition().state('editing');
