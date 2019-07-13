//  connection.c
//  ContentCGI
//
//  Created by Dr. Rolf Jansen on 2018-05-08.
//  Copyright © 2018-2019 Dr. Rolf Jansen. All rights reserved.
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
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
//  IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
//  INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
//  BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
//  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
//  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
//  OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
//  OF THE POSSIBILITY OF SUCH DAMAGE.


#include <stdlib.h>
#include <stddef.h>
#include <stdarg.h>
#include <string.h>
#include <math.h>
#include <errno.h>
#include <fcntl.h>
#include <unistd.h>
#include <syslog.h>
#include <sys/select.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <sys/uio.h>

#include <openssl/ssl.h>

// ContentCGI modules
#include "utils.h"
#include "interim.h"
#include "connection.h"


boolean pendingReceivedBytes(int sock)
{
   static struct timeval to15s = {15, 0};  // 15 s timeout

   fd_set readfds;
   FD_ZERO(&readfds);
   FD_SET(sock, &readfds);

   // wait max. timeout s for new bytes arriving ready to be read at our socket,
   // and if something has been received at our socket, then peek the first byte,
   // and if recv() returns 1 (success), then report new bytes ready for reading.
   if (select(sock + 1, &readfds, NULL, NULL, &to15s) > 0
    && FD_ISSET(sock, &readfds)
    && recv(sock, &sock, 1, MSG_PEEK) == 1)
      return true;

   // if there is nothing to be read at our socket after timeout s, or if peeking the
   // first byte returned -1 (error), or if the peer has closed the connection
   // (return of 0), then report that there are no further bytes to read.
   else
      return false;
}


#pragma mark ••• socket calls •••

ssize_t socketRecv(ConnSpec *conn, void *buffer, size_t length)
{
   ssize_t rc = 0, rl = 0;

   while (length && (rc = recv(conn->sock, buffer+rl, length, MSG_WAITALL)) > 0)
      rl += rc, length -= rc;

   return (rc >= 0) ? rl : rc;
}


ssize_t socketARcv(ConnSpec *conn, void *buffer, size_t length)
{
   ssize_t rc;
   fcntl(conn->sock, F_SETFL, conn->flags | O_NONBLOCK);
   rc = recv(conn->sock, buffer, length, 0);
   fcntl(conn->sock, F_SETFL, conn->flags);
   return rc;
}


ssize_t socketSend(ConnSpec *conn, const void *buffer, size_t length)
{
   return send(conn->sock, buffer, length, 0);
}


ssize_t socketJSnd(ConnSpec *conn, ... /* const void *buf0, ssize_t len0, const void *buf1, ssize_t len1, ..., NULL */)
{
   struct iovec blocks[64] = {}; // max. 64 buf:len tupples
   int          n;
   const void  *buf;
   ssize_t      len;
   va_list      vl;

   va_start(vl, conn);
   for (n = 0; n < 64 && (buf = va_arg(vl, const void *)) && (len = va_arg(vl, ssize_t)) > 0; n++)
      blocks[n] = (struct iovec){(void *)buf, len};
   va_end(vl);

   if (n > 1)
      return writev(conn->sock, blocks, n);
   else
      return send(conn->sock, blocks[0].iov_base, blocks[0].iov_len, 0);
}


boolean socketShut(ConnSpec *conn, boolean force)
{
   if (!force && pendingReceivedBytes(conn->sock))
      return false;

   shutdown(conn->sock, SHUT_RDWR);
   if (close(conn->sock) < 0)
      syslog(LOG_ERR, "Error closing client connection: %d.", errno);
   return true;
}


#pragma mark ••• SSocketL calls •••

ssize_t ssocklRecv(ConnSpec *conn, void *buffer, size_t length)
{
   ssize_t rc = 0, rl = 0;

   while (length && (rc = SSL_read(conn->ssl, buffer+rl, (int)length)) > 0)
      rl += rc, length -= rc;

   return (rc >= 0) ? rl : rc;
}


ssize_t ssocklARcv(ConnSpec *conn, void *buffer, size_t length)
{
   ssize_t rc;
   fcntl(conn->sock, F_SETFL, conn->flags | O_NONBLOCK);
   rc = SSL_read(conn->ssl, buffer, (int)length);
   fcntl(conn->sock, F_SETFL, conn->flags);
   return rc;
}


ssize_t ssocklSend(ConnSpec *conn, const void *buffer, size_t length)
{
   return SSL_write(conn->ssl, buffer, (int)length);
}


ssize_t ssocklJSnd(ConnSpec *conn, ... /* const void *buf0, ssize_t len0, const void *buf1, ssize_t len1, ..., NULL */)
{
   struct iovec blocks[64] = {}; // max. 64 buf:len tupples
   int          i, n, rc, rt;
   const void  *buf;
   ssize_t      len, tlen;
   va_list      vl;

   va_start(vl, conn);
   for (n = 0, tlen = 0; n < 64 && (buf = va_arg(vl, const void *)) && (len = va_arg(vl, ssize_t)) > 0; n++)
   {
      blocks[n] = (struct iovec){(void *)buf, len};
      tlen += len;
   }
   va_end(vl);

   if (n > 1)
      if (tlen <= 8388608 && (buf = allocate(tlen, default_align, false)))
      {
         for (i = 0, len = 0; i < n; i++)
         {
            bcopy(blocks[i].iov_base, (void *)buf+len, blocks[i].iov_len);
            len += blocks[i].iov_len;
         }

         rc = SSL_write(conn->ssl, buf, (int)len);
         deallocate(VPR(buf), false);
         return rc;
      }

      else
      {
         for (i = 0, rc = 0, rt = 1; rt > 0 && i < n; i++)
            rc += rt = SSL_write(conn->ssl, blocks[i].iov_base, (int)blocks[i].iov_len);
         return (rt > 0) ? rc : rt;
      }

   else
      return SSL_write(conn->ssl, blocks[0].iov_base, (int)blocks[0].iov_len);
}


boolean ssocklShut(ConnSpec *conn, boolean force)
{
   if (!force && pendingReceivedBytes(conn->sock))
      return false;

   SSL_shutdown(conn->ssl);
   SSL_free(conn->ssl);
   shutdown(conn->sock, SHUT_RDWR);
   if (close(conn->sock) < 0)
      syslog(LOG_ERR, "Error closing client connection: %d.", errno);
   return true;
}


void connexRefresh(ConnExec *connex)
{
   releaseTable(connex->POSTtable);   connex->POSTtable   = NULL;
   releaseTable(connex->QueryTable);  connex->QueryTable  = NULL;
   releaseTable(connex->serverTable); connex->serverTable = createTable(256);
   connex->requestID = 0;
}


void connexRelease(ConnExec **connex)
{
   releaseTable((*connex)->POSTtable);
   releaseTable((*connex)->QueryTable);
   releaseTable((*connex)->serverTable);
   deallocate((void **)connex, true);
}
