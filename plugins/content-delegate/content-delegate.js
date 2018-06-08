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
   new ContentTools.Style('Author', 'author', ['p'])
]);

editor = ContentTools.EditorApp.get();
editor.init('[data-editable], [data-fixture]', 'data-name');

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
         payload.append(name, regions[name]);
      }
   }

   // Send the update content to the server to be saved
   function onStateChange(ev) {
      // Check if the request is finished
      if (ev.target.readyState == 4) {
         editor.busy(false);
         switch (ev.target.status) {
            // Save was successful, notify the user with a flash
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

            // Save failed, notify the user with a flash
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
