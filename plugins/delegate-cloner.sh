#!/bin/sh
#
# usage:
#   cd /path/to/the/ContentCGI/plugins
#   delegate-cloner.sh <newname>

if [ "$1" != "" ]; then
   MODEL="hello-delegate"
   CLONE="$1-delegate"

   CLASS="$1"
   CLASS=`echo ${CLASS:0:1} | tr '[a-z]' '[A-Z]'`${CLASS:1}

   cp -R  "$MODEL" "$CLONE"
   cd "$CLONE"

   sed -e "s|hello|$1|g;s|Hello|$CLASS|g" -i "" hello-delegate.m
   sed -e "s|hello|$1|g;s|Hello|$CLASS|g" -i "" hello-delegate.html
   sed -e "s|hello|$1|g;s|Hello|$CLASS|g" -i "" hello-delegate.css
   sed -e "s|hello|$1|g;s|Hello|$CLASS|g" -i "" hello-delegate.js
   sed -e "s|hello|$1|g"                  -i "" Makefile

   mv hello-delegate.m    "$1-delegate.m"
   mv hello-delegate.html "$1-delegate.html"
   mv hello-delegate.css  "$1-delegate.css"
   mv hello-delegate.js   "$1-delegate.js"
   mv hello-delegate.png  "$1-delegate.png"
   mv hello-delegate.ico  "$1-delegate.ico"

   cd ..
fi
