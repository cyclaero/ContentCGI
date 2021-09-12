# Makefile for a ContentCGI Responder Delegate plugin
#
# Created by Dr. Rolf Jansen on 2018-06-11.
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

PROJECT = search-delegate
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
          -Wno-multichar -Wno-parentheses -Wno-empty-body -Wno-switch -Wno-deprecated-declarations \
          -I/usr/local/include -I../ -Izettair-spider/include/  -Izettair-spider/include/compat/
LDFLAGS = -shared -L/usr/local/lib -lm -lpthread -liconv -lz -lobjc -rpath $(PLUGINS) -L$(PLUGINS) -lcyobj

SOURCESm = $(PROJECT).m
OBJECTSm = $(SOURCESm:.m=.o)
SOURCESc = ../delegate-utils.c \
           zettair-spider/alloc.c \
           zettair-spider/binsearch.c \
           zettair-spider/bit.c \
           zettair-spider/btbucket.c \
           zettair-spider/btbulk.c \
           zettair-spider/bucket.c \
           zettair-spider/chash.c \
           zettair-spider/cosine.c \
           zettair-spider/crc.c \
           zettair-spider/detectfilter.c \
           zettair-spider/dirichlet.c \
           zettair-spider/docmap.c \
           zettair-spider/error.c \
           zettair-spider/fdset.c \
           zettair-spider/freemap.c \
           zettair-spider/getmaxfsize.c \
           zettair-spider/gunzipfilter.c \
           zettair-spider/hawkapi.c \
           zettair-spider/heap.c \
           zettair-spider/impact_build.c \
           zettair-spider/impact.c \
           zettair-spider/index_querybuild.c \
           zettair-spider/index.c \
           zettair-spider/iobtree.c \
           zettair-spider/ioutil.c \
           zettair-spider/lcrand.c \
           zettair-spider/makeindex.c \
           zettair-spider/mem.c \
           zettair-spider/merge.c \
           zettair-spider/mime.c \
           zettair-spider/mlparse_wrap.c \
           zettair-spider/mlparse.c \
           zettair-spider/mrwlock.c \
           zettair-spider/objalloc.c \
           zettair-spider/okapi.c \
           zettair-spider/pcosine.c \
           zettair-spider/poolalloc.c \
           zettair-spider/postings.c \
           zettair-spider/psettings_default.c \
           zettair-spider/psettings.c \
           zettair-spider/pyramid.c \
           zettair-spider/queryparse.c \
           zettair-spider/rbtree.c \
           zettair-spider/remerge.c \
           zettair-spider/reposset.c \
           zettair-spider/search.c \
           zettair-spider/stack.c \
           zettair-spider/stem.c \
           zettair-spider/stop_default.c \
           zettair-spider/stop.c \
           zettair-spider/storagep.c \
           zettair-spider/str.c \
           zettair-spider/stream.c \
           zettair-spider/summarise.c \
           zettair-spider/vec.c \
           zettair-spider/vocab.c
OBJECTSc = $(SOURCESc:.c=.o)
PRODUCT  = $(PROJECT).so

all: $(HEADERS) $(SOURCESm) $(SOURCESc) $(OBJECTSm) $(OBJECTSc) $(PRODUCT)

depend:
	$(CC) $(CFLAGS) -E -MM *.m > .depend

$(PRODUCT): $(OBJECTSm) $(OBJECTSc)
	$(CC) $(OBJECTSm) $(OBJECTSc) $(LDFLAGS) -o $@

$(OBJECTSm) $(OBJECTSc):
	$(CC) $(CFLAGS) $< -c -o $@

clean:
	rm -rf *.o ../delegate-utils.o zettair-spider/*.o $(PRODUCT)

debug: all

update: clean all

install: $(PRODUCT)
	mkdir -p "$(PLUGINS)/$(PROJECT)"
	install $(PRODUCT) "$(PLUGINS)/$(PROJECT)/"
	cp -p  $(PROJECT).html "$(PLUGINS)/$(PROJECT)/" 2>/dev/null ||:
	cp -p  $(PROJECT).css  "$(PLUGINS)/$(PROJECT)/" 2>/dev/null ||:
	cp -p  $(PROJECT).js   "$(PLUGINS)/$(PROJECT)/" 2>/dev/null ||:
	cp -p  $(PROJECT).png  "$(PLUGINS)/$(PROJECT)/" 2>/dev/null ||:
	cp -p  $(PROJECT).ico  "$(PLUGINS)/$(PROJECT)/" 2>/dev/null ||:
