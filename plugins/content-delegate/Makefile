# Makefile for a ContentCGI Responder Delegate plugin
#
# Created by Dr. Rolf Jansen on 2018-05-05.
# Copyright © 2018-2021. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification,
# are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS
# OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
# AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER
# OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
# IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
# THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# Usage examples:
#   make
#   make clean
#   make update
#   make install clean
#   make clean debug

PROJECT = content-delegate
PLUGINS = $(HOME)/plugins/ContentCGI

CC = clang

.ifmake debug
CFLAGS = $(CDEFS) -g -O0
STRIP  =
.else
CFLAGS = $(CDEFS) -g0 -O3
STRIP  = -s
.endif

.if $(MACHINE) == "i386" || $(MACHINE) == "amd64" || $(MACHINE) == "x86_64"
CFLAGS += -march=native -mssse3
.elif $(MACHINE) == "arm"
CFLAGS += -fsigned-char
.endif

CFLAGS += -std=gnu11 -fpic -fvisibility=hidden -fstrict-aliasing -fstack-protector \
          -Wno-multichar -Wno-parentheses -Wno-switch -Wno-deprecated-declarations -Wshorten-64-to-32 \
          -I/usr/local/include -I/opt/local/include -I/usr/local/include/GraphicsMagick -I/opt/local/include/GraphicsMagick -I../
LDFLAGS = -shared -L/opt/local/lib -L/usr/local/lib -L/usr/lib -lm -lpthread -liconv -lutf8proc -lGraphicsMagick -lobjc -rpath $(PLUGINS) -L$(PLUGINS) -lcyobj

SOURCESm = $(PROJECT).m
OBJECTSm = $(SOURCESm:.m=.o)
SOURCESc = ../delegate-utils.c
OBJECTSc = $(SOURCESc:.c=.o)
PRODUCT  = $(PROJECT).so

all: $(HEADERS) $(SOURCESm) $(SOURCESc) $(OBJECTSm) $(OBJECTSc) $(PRODUCT)

depend:
	$(CC) $(CFLAGS) -E -MM *.m > .depend

$(PRODUCT): $(OBJECTSm) $(OBJECTSc)
	$(CC) $(OBJECTSm) $(OBJECTSc) $(LDFLAGS) -o $@

$(OBJECTSm) $(OBJECTSc): Makefile
	$(CC) $(CFLAGS) $< -c -o $@

clean:
	rm -rf *.o ../delegate-utils.o $(PRODUCT)

debug: all

update: clean all

install: $(PRODUCT)
	mkdir -p "$(PLUGINS)/$(PROJECT)"
	install $(STRIP) $(PRODUCT) "$(PLUGINS)/$(PROJECT)/"
	cp -p  $(PROJECT).html "$(PLUGINS)/$(PROJECT)/" 2>/dev/null ||:
	cp -p  $(PROJECT).png  "$(PLUGINS)/$(PROJECT)/" 2>/dev/null ||:
	cp -p  $(PROJECT).ico  "$(PLUGINS)/$(PROJECT)/" 2>/dev/null ||:
	cp -pr models "$(PLUGINS)/$(PROJECT)/" 2>/dev/null ||:
	printf '\n\n' | cat ../../ContentTools/build/content-tools.min.css - $(PROJECT).css > "$(PLUGINS)/$(PROJECT)/$(PROJECT).css" 2>/dev/null ||:
	printf '\n\n' | cat ../../ContentTools/build/content-tools.min.js  - $(PROJECT).js  > "$(PLUGINS)/$(PROJECT)/$(PROJECT).js"  2>/dev/null ||:
	cp -pr ../../ContentTools/build/images "$(PLUGINS)/$(PROJECT)/" 2>/dev/null ||:
	cp -p  $(PROJECT).woff "$(PLUGINS)/$(PROJECT)/images/icons.woff" 2>/dev/null ||:
	sed -e 's/a\.target=this\._target/a.target=this._target,a.rel="noopener noreferrer"/' \
	    -i "" "$(PLUGINS)/$(PROJECT)/$(PROJECT).js"
