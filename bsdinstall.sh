#!/bin/sh

# FreeBSD installation and updating script for the ContentCGI daemon
#
#  Created by Dr. Rolf Jansen on 2018-06-06.
#  Copyright © 2018-2021 Dr. Rolf Jansen. All rights reserved.
#
#  Redistribution and use in source and binary forms, with or without modification,
#  are permitted provided that the following conditions are met:
#
#  1. Redistributions of source code must retain the above copyright notice,
#     this list of conditions and the following disclaimer.
#
#  2. Redistributions in binary form must reproduce the above copyright notice,
#     this list of conditions and the following disclaimer in the documentation
#     and/or other materials provided with the distribution.
#
#  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
#  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
#  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
#  IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
#  INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
#  BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
#  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
#  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
#  OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
#  OF THE POSSIBILITY OF SUCH DAMAGE.

# REQUIREMENTS (install from the packages system of FreeBSD -- onetime operation)
#
#   pkg install -y apache24
#   pkg install -y clone
#   pkg install -y subversion
#   pkg install -y libobjc2
#   pkg install -y libutf8
#   pkg install -y iconv
#   pkg install -y poppler-utils
#   pkg install -y clone
#
# GraphicsMagick for the image management facility
#   pkg install -y webp
#   pkg install -y libwmf-nox11
#
#   cd /usr/ports/graphics/GraphicsMagick
#   make config
#   -- Disable Jasper, OpenMP, X11 -- Enable SSE
#   make install clean
#
# PREPARATION (cheking out the sources of ContentCGI and ContentTools from GitHub)
#
#   cd <third-party-install-dir>
#   svn checkout https://github.com/cyclaero/ContentCGI.git/trunk        ContentCGI
#   svn checkout https://github.com/GetmeUK/ContentTools.git/trunk       ContentCGI/ContentTools
#   svn checkout https://github.com/cyclaero/zettair.git/trunk/devel/src ContentCGI/plugins/search-delegate/zettair-spider
#
# USAGE:
#
#   cd <third-party-install-dir>/ContentCGI
#
#   Updating, Installation, Cleaning:
#      ./bsdinstall.sh update install clean
#
#   Installation, Cleaning
#      ./bsdinstall.sh install clean
#
#   Cleaning
#      ./bsdinstall.sh clean
#
#   Making
#      ./bsdinstall.sh


if [ "$1" == "install" ] || [ "$2" == "install" ] || [ "$3" == "install" ]; then
   service ContentCGI stop
fi

CWD=$PWD

if [ "$1" == "update" ] || [ "$2" == "update" ] || [ "$3" == "update" ]; then
   cd "$CWD/plugins/search-delegate/zettair-spider"
   svn update
   cd "$CWD/ContentTools"
   svn update
   cd "$CWD"
   svn update
fi

CPUS=$((`sysctl -n kern.smp.cpus`/2))
if [ $CPUS -gt 1 ]; then
   MAKE="make -j$CPUS"
else
   MAKE="make"
fi

if [ "$1" != "update" ]; then
   MAKE1="$MAKE $1"
   if [ "$2" != "" ]; then
      MAKE2="$MAKE $2"
   fi
else
   MAKE1="$MAKE $2"
   if [ "$3" != "" ]; then
      MAKE2="$MAKE $3"
   fi
fi

cd "$CWD/plugins/search-delegate/zettair-spider"
$MAKE1
$MAKE2

cd "$CWD/plugins"
$MAKE1
$MAKE2

for PLUGDIR in *-delegate; do
   if [ -d "$PLUGDIR" ]; then
      cd "$PLUGDIR"
      $MAKE1
      $MAKE2
      cd ..
   fi
done

cd "$CWD"
$MAKE1
$MAKE2

cd "$CWD"

if [ "$1" == "install" ] || [ "$2" == "install" ] || [ "$3" == "install" ]; then
   service ContentCGI start
fi
