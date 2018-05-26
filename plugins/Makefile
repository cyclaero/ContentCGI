# Makefile for the cyobj library for ContentCGI Responder Delegate plugins
#
# Created by Dr. Rolf Jansen on 2018-05-05.
# Copyright © 2018. All rights reserved.
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

PLUGINS = $(HOME)/plugins/ContentCGI

CC = clang

.ifmake debug
CFLAGS = $(CDEFS) -g -O0
.else
CFLAGS = $(CDEFS) -g0 -O3
.endif

.if $(MACHINE) == "i386" || $(MACHINE) == "amd64" || $(MACHINE) == "x86_64"
CFLAGS += -march=native -mssse3
.elif $(MACHINE) == "arm"
CFLAGS += -fsigned-char
.endif

CFLAGS += -std=c11 -fpic -fstrict-aliasing -fno-common -fobjc-nonfragile-abi \
          -Wno-multichar -Wno-parentheses -Wno-empty-body -Wno-switch -Wno-deprecated-declarations -Wshorten-64-to-32 \
          -I/usr/local/include -I../
LDFLAGS = -shared -L/usr/local/lib -lm -lpthread -lobjc

SOURCES = CyObject.m
OBJECTS = $(SOURCES:.m=.o)
PRODUCT = libcyobj.so

all: $(HEADERS) $(SOURCES) $(OBJECTS) $(PRODUCT)

depend:
	$(CC) $(CFLAGS) -E -MM *.m > .depend

$(PRODUCT): $(OBJECTS)
	$(CC) $(OBJECTS) $(LDFLAGS) -o $@

$(OBJECTS): Makefile
	$(CC) $(CFLAGS) $< -c -o $@

clean:
	rm -rf *.o $(PRODUCT)

debug: all

update: clean all

install: $(PRODUCT)
	mkdir -p     "$(PLUGINS)"
	strip -x -o  "$(PLUGINS)/$(PRODUCT)" $(PRODUCT)
