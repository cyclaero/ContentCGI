//  connection.h
//  ContentCGI
//
//  Created by Dr. Rolf Jansen on 2018-05-08.
//  Copyright © 2018 Dr. Rolf Jansen. All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without modification,
//  are permitted provided that the following conditions are met:
//
//  1. Redistributions of source code must retain the above copyright notice,
//     this list of conditions and the following disclaimer.
//
//  2. Redistributions in binary form must reproduce the above copyright notice,
//     this list of conditions and the following disclaimer in the documentation
//     and/or other materials provided with the distribution.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
//  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//  WARRANTIES OF MERCHANTABILITYAND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
//  IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
//  INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
//  BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
//  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
//  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
//  OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
//  OF THE POSSIBILITY OF SUCH DAMAGE.


// types
typedef struct
{
   int sock, flags;
   union
   {
      SSL  *ssl;
      BIO  *bio;
   };
} ConnSpec;


typedef struct ConnExec ConnExec;
typedef struct ConnExec
{
   ConnSpec conn;
   uint16_t requestID;
   Node   **serverTable;
   Node   **QueryTable;
   Node   **POSTtable;

   ssize_t (*recv)(ConnSpec *, void *, size_t);
   ssize_t (*arcv)(ConnSpec *, void *, size_t);
   ssize_t (*send)(ConnSpec *, const void *, size_t);
   ssize_t (*jsnd)(ConnSpec *, ...);
   boolean (*shut)(ConnSpec *, boolean);
} ConnExec;


// subroutine definitions
ssize_t socketRecv(ConnSpec *conn, void *buffer, size_t length);
ssize_t socketARcv(ConnSpec *conn, void *buffer, size_t length);
ssize_t socketSend(ConnSpec *conn, const void *buffer, size_t length);
ssize_t socketJSnd(ConnSpec *conn, ... /* const void *buf0, size_t len0, const void *buf1, size_t len1, ..., NULL */);
boolean socketShut(ConnSpec *conn, boolean force);

ssize_t ssocklRecv(ConnSpec *conn, void *buffer, size_t length);
ssize_t ssocklARcv(ConnSpec *conn, void *buffer, size_t length);
ssize_t ssocklSend(ConnSpec *conn, const void *buffer, size_t length);
ssize_t ssocklJSnd(ConnSpec *conn, ... /* const void *buf0, size_t len0, const void *buf1, size_t len1, ..., NULL */);
boolean ssocklShut(ConnSpec *conn, boolean force);

ssize_t tlsBIORecv(ConnSpec *conn, void *buffer, size_t length);
ssize_t tlsBIOARcv(ConnSpec *conn, void *buffer, size_t length);
ssize_t tlsBIOSend(ConnSpec *conn, const void *buffer, size_t length);
ssize_t tlsBIOJSnd(ConnSpec *conn, ... /* const void *buf0, size_t len0, const void *buf1, size_t len1, ..., NULL */);
boolean tlsBIOShut(ConnSpec *conn, boolean force);

void connexRefresh(ConnExec  *connex);
void connexRelease(ConnExec **connex);
