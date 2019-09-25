"use strict";

var qargs = {};
location.search.substr(1).split("&").forEach(function(item) {
   var s = item.split("="), k = s[0], v = s[1] && decodeURIComponent(s[1]);
   (qargs[k] = qargs[k] || []).push(v)
});
