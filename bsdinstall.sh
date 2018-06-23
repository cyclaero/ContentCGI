#!/bin/sh

# FreeBSD installation and updating script for the ContentCGI daemon
#
#  Created by Dr. Rolf Jansen on 2018-06-06.
#  Copyright © 2018 Dr. Rolf Jansen. All rights reserved.
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
#  WARRANTIES OF MERCHANTABILITYAND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
#  IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
#  INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
#  BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
#  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
#  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
#  OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
#  OF THE POSSIBILITY OF SUCH DAMAGE.

# REQUIREMENTS (install from the packages system of FreeBSD -- onetime operation)
#
#   pkg install subversion
#   pkg install libojc2
#   pkg install icu
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

CPUS=$((`sysctl -n kern.smp.cpus`/2))
if [ $CPUS < 10 ]; then
   MAKE="make"
else
   MAKE="make -j$CPUS"
fi

if [ "$1" != "update" ]; then
   MAKE="$MAKE $1 $2"
else
   MAKE="$MAKE $2 $3"
fi

if [ "$1" == "install" ] || [ "$2" == "install" ] || [ "$3" == "install" ]; then
   service ContentCGI stop
fi

CWD=$PWD

if [ "$1" == "update" ]; then
   cd "$CWD/plugins/search-delegate/zettair-spider"
   svn update
   cd "$CWD/ContentTools"
   svn update
   cd "$CWD"
   svn update
fi

cd "$CWD/plugins/search-delegate/zettair-spider"
$MAKE clean

cd "$CWD/plugins"
$MAKE

for PLUGDIR in *-delegate; do
   if [ -d "$PLUGDIR" ]; then
      cd "$PLUGDIR"
      $MAKE
      cd ..
   fi
done

cd "$CWD"
$MAKE

cd "$CWD"

if [ "$1" == "install" ] || [ "$2" == "install" ] || [ "$3" == "install" ]; then
   service ContentCGI start
fi
