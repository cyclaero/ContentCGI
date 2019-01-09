#  BSD Makefile for building the ContentCGI daemon
#
#  Created by Dr. Rolf Jansen on 2018-05-19.
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
#  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
#  IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
#  INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
#  BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
#  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
#  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
#  OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
#  OF THE POSSIBILITY OF SUCH DAMAGE.
#
#  Usage examples:
#    make
#    make clean
#    make update
#    make install clean
#    make clean install CDEFS="-DDEBUG"

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

CFLAGS += -DNOBIOSSL -std=gnu11 -fno-pic -fvisibility=hidden -fstrict-aliasing -fno-common -fstack-protector \
          -Wno-multichar -Wno-parentheses -Wno-empty-body -Wno-switch -Wno-deprecated-declarations -Wshorten-64-to-32 \
          -I/usr/local/include
LDFLAGS = -L/usr/local/lib -lm -lpthread -lcrypto -lssl
SOURCES = firstresponder.c fastcgi.c connection.c interim.c utils.c main.c
OBJECTS = $(SOURCES:.c=.o)
PRODUCT = ContentCGI
TWEETIT = tweetit

all: $(SOURCES) $(PRODUCT) tweetit.c $(TWEETIT)

depend:
	$(CC) $(CFLAGS) -E -MM *.c > .depend

$(PRODUCT): $(OBJECTS)
	$(CC) $(OBJECTS) $(LDFLAGS) -o $@

$(TWEETIT): $(OBJECTS) tweetit.c
	$(CC) $(CFLAGS) tweetit.c utils.o -lm -o $@

$(OBJECTS): Makefile
	$(CC) $(CFLAGS) $< -c -o $@

clean:
	rm -rf *.o *.core $(PRODUCT) $(TWEETIT)

debug: all

update: clean all

install: $(PRODUCT)
	install $(STRIP) $(PRODUCT) /usr/local/bin/
	install $(STRIP) $(TWEETIT) /usr/local/bin/
	cp $(PRODUCT).rc /usr/local/etc/rc.d/$(PRODUCT)
	chmod 555 /usr/local/etc/rc.d/$(PRODUCT)
