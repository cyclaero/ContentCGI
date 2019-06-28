//  fastcgi.c
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
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
//  IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
//  INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
//  BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
//  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
//  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
//  OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
//  OF THE POSSIBILITY OF SUCH DAMAGE.


#include <stdio.h>
#include <stdlib.h>
#include <stddef.h>
#include <stdarg.h>
#include <stdint.h>
#include <string.h>
#include <math.h>
#include <syslog.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/time.h>

#include <openssl/ssl.h>

#include "utils.h"
#include "interim.h"
#include "connection.h"
#include "fastcgi.h"


void deallocate_paramsblock(void **p, int32_t offset, boolean cleanout)
{
   if (p && *p)
   {
      if (offset)
      {
         char *q = *p;
         *p = q + offset;
      }

      deallocate(p, cleanout);
   }
}


static inline ssize_t stream_arcv(ConnExec *connex, void *buffer, size_t total)
{
   ssize_t rc, received = 0;
   while ((rc = connex->arcv(&connex->conn, buffer+received, total-received)) >= 0 && (received += rc) < total)
   #if defined(__APPLE__) && defined(DEBUG)
      usleep(10000);
   #else
      usleep(2500);
   #endif
   return received;
}

boolean FCGI_Receiver(ConnExec *connex)
{
   boolean  requestOK = false;
   boolean processing = true;
   FCGI_Header header = {};
   uint8_t   *content = NULL;

   while (processing)
   {
      if (connex->recv(&connex->conn, &header, FCGI_HEADER_LEN) != FCGI_HEADER_LEN)
         return false;

      header.requestID     = MapShort(header.requestID);
      header.contentLength = MapShort(header.contentLength);

      if (header.version == 1)                        // this works only according to CGI 1.1
      {
         if (header.requestID == connex->requestID    // on FCGI_BEGIN_REQUEST the requestID is stored into the connex record,
          || (header.type == FCGI_BEGIN_REQUEST       // and the request is processed either in case the ID's do match
           || header.type == FCGI_GET_VALUES)         // or this is a Begin ot a Manangement equest
          && !connex->requestID)                      // and an ID has not been assigned yet.
         {
            char padding[256];

            if (header.contentLength)
               if ((content = allocate(header.contentLength+1, default_align, false))
                && ((header.type == FCGI_STDIN || header.type <= FCGI_DATA)
                    ?  stream_arcv(connex,        content, header.contentLength)
                    : connex->recv(&connex->conn, content, header.contentLength)) == header.contentLength)
                  content[header.contentLength] = '\0';
               else
                  goto cleanup;

            if (header.paddingLength
             && connex->recv(&connex->conn, &padding, header.paddingLength) != header.paddingLength)
               goto cleanup;

            switch (header.type)
            {
               case FCGI_BEGIN_REQUEST:
                  connex->requestID = header.requestID;
                  if (header.contentLength != sizeof(FCGI_BeginRequestBody)
                   || MapShort(((FCGI_BeginRequestBody *)content)->role) != FCGI_RESPONDER)
                  {
                     FCGI_SendEndRequest(connex, -1, FCGI_UNKNOWN_ROLE);
                     processing = false;
                  }

                  if (content)
                     deallocate(VPR(content), false);
                  break;

               case FCGI_PARAMS:
                  if (header.contentLength)
                  {
                     int namLen, valLen;
                     char *name;
                     Value value = {{}, String*dynamic, 0, 0, deallocate_paramsblock};

                     for (uint8_t *p = content, *q = content + header.contentLength; p < q; p += valLen)
                     {
                        uint8_t *o = p;

                        if ((*p & 0x80) == 0)
                        {
                           namLen = *p & 0x7F;
                           if ((*(p+1) & 0x80) == 0)
                              valLen = *(p+1) & 0x7F, p += 2;
                           else
                              valLen = (int)MapInt(*(uint32_t *)(p+1)) & 0x7FFFFFFF, p += 5;
                        }
                        else
                        {
                           namLen = *(uint32_t *)p & 0x7FFFFFFF;
                           if ((*(p+4) & 0x80) == 0)
                              valLen = *(p+4) & 0x7F, p += 5;
                           else
                              valLen = (int)MapInt(*(uint32_t *)(p+4)) & 0x7FFFFFFF, p += 8;
                        }

                        *o = '\0';                      // mark the end of the previous value string by disposing the no more used name length byte

                        name         = (char *)p;
                        value.s      = (char *)(p += namLen);
                        value.offset = (int32_t)(o - p);
                        value.size   = (int64_t)valLen;

                        uint8_t borrow = *p; *p = '\0'; // mark the end of the current name string, by borrowing the first byte of the current value string
                        storeName(connex->serverTable, name, namLen, &value);
                        *p = borrow;                    // restore the first char of the current value string

                        if (o == content)               // all the following parameters are part of the content block, and must not be deallocated
                           value.kind = String, value.custom_deallocate = NULL;
                     }

                     content = NULL;
                  }
                  break;

               case FCGI_DATA:
                  if (header.contentLength)
                  {
                     Node *node;
                     if (node = findName(connex->serverTable, "OTHER_DATA", 10))
                     {
                        ssize_t size;
                        if (node->value.s = reallocate(node->value.s, (size = allocsize(node->value.s)) + header.contentLength, false, false))
                        {
                           memvcpy(node->value.s+size-1, content, header.contentLength+1);
                           node->value.size += header.contentLength;
                           deallocate(VPR(content), false);
                        }
                        else
                           goto cleanup;
                     }
                     else
                     {
                        Value value = (Value){{.s = (char *)content}, String*dynamic, 0, header.contentLength, NULL};
                        storeName(connex->serverTable, "OTHER_DATA", 10, &value);
                        content = NULL;
                     }
                  }
                  break;

               case FCGI_STDIN:
                  if (header.contentLength)
                  {
                     Node *node;
                     if (node = findName(connex->serverTable, "CONTENT_DATA", 12))
                     {
                        ssize_t size;
                        if (node->value.s = reallocate(node->value.s, (size = allocsize(node->value.s)) + header.contentLength, false, false))
                        {
                           memvcpy(node->value.s+size-1, content, header.contentLength+1);
                           node->value.size += header.contentLength;
                           deallocate(VPR(content), false);
                        }
                        else
                           goto cleanup;
                     }
                     else
                     {
                        Value value = (Value){{.s = (char *)content}, String*dynamic, 0, header.contentLength, NULL};
                        storeName(connex->serverTable, "CONTENT_DATA", 12, &value);
                        content = NULL;
                     }
                  }

                  else // (header.contentLength == 0)
                  {    // the web server has finished the request and we may proceed
                     Node *node;
                     if ((node = findName(connex->serverTable, "QUERY_STRING", 12)) && *node->value.s != '\0')
                     {
                        Value value = {{}, dynamic*String, 0, 0, deallocate_paramsblock};
                        int   defLen, namLen, valLen, queryLen = strvlen(node->value.s);
                        char *o, *p, *q;

                        connex->QueryTable = createTable(128);
                        strmlcpy(o = allocate(queryLen+1, default_align, false), node->value.s, queryLen+1, &queryLen);
                        for (p = o, q = p + queryLen; p < q; p += defLen+1)
                        {
                           defLen = vdeflen(p), p[defLen] = '\0';
                           namLen = vnamlen(p), p[namLen] = '\0';
                           valLen = defLen - namLen;
                           if (valLen > 0)
                              valLen--;
                           value.s = (valLen) ? uriDecode(&p[namLen+1]) : &p[namLen];
                           value.offset = (int32_t)(o - value.s);
                           value.size = strvlen(value.s);
                           storeName(connex->QueryTable, uriDecode(p), 0, &value);

                           if (p == o)
                              value.kind = String, value.custom_deallocate = NULL;
                        }
                     }

                     if ((node = findName(connex->serverTable, "REQUEST_METHOD", 14)) && cmp5(node->value.s, "POST")
                      && (node = findName(connex->serverTable, "CONTENT_TYPE",   12)) && strstr(node->value.s, "application/x-www-form-urlencoded")
                      && (node = findName(connex->serverTable, "CONTENT_DATA",   12)) && *node->value.s != '\0')
                     {
                        Value value = {{}, String, 0, 0, NULL};
                        int   defLen, namLen, valLen;
                        char *p, *q;

                        connex->POSTtable = createTable(128);
                        for (p = node->value.s, q = p + strvlen(node->value.s); p < q; p += defLen+1)
                        {
                           defLen = vdeflen(p), p[defLen] = '\0';
                           namLen = vnamlen(p), p[namLen] = '\0';
                           valLen = defLen - namLen;
                           if (valLen > 0)
                              valLen--;
                           value.s = (valLen) ? postDecode(&p[namLen+1]) : &p[namLen];
                           value.size = strvlen(value.s);
                           storeName(connex->POSTtable, postDecode(p), 0, &value);
                        }
                     }

                     processing = false;
                     requestOK = true;
                  }
                  break;

               case FCGI_GET_VALUES:
                  if (header.contentLength)
                  {
                     int namLen, valLen;
                     uint8_t  results[64] = {};   // max. 54 bytes ..FCGI_MAX_CONNS7..FCGI_MAX_REQS10..FCGI_MPXS_CONNS0
                     uint16_t resultsLen  = 0;

                     for (uint8_t *p = content, *q = content + header.contentLength; p < q; p += valLen)
                     {
                        if ((*p & 0x80) == 0)
                        {
                           namLen = *p & 0x7F;
                           if ((*(p+1) & 0x80) == 0)
                              valLen = *(p+1) & 0x7F, p += 2;
                           else
                              valLen = (int)MapInt(*(uint32_t *)(p+1)) & 0x7FFFFFFF, p += 5;
                        }
                        else
                        {
                           namLen = *(uint32_t *)p & 0x7FFFFFFF;
                           if ((*(p+4) & 0x80) == 0)
                              valLen = *(p+4) & 0x7F, p += 5;
                           else
                              valLen = (int)MapInt(*(uint32_t *)(p+4)) & 0x7FFFFFFF, p += 8;
                        }

                        p += namLen;
                        if (valLen)
                           continue;

                        if (namLen == 14 && cmp14(p, FCGI_MAX_CONNS))
                        {
                           results[resultsLen++] = 14;    // name length of FCGI_MAX_CONNS
                           results[resultsLen++] = 1;     // value length of result -> 7
                           cpy15(results+resultsLen, FCGI_MAX_CONNS"7");
                           resultsLen += 15;
                        }

                        else if (namLen == 13 && cmp13(p, FCGI_MAX_REQS))
                        {
                           results[resultsLen++] = 13;    // name length of FCGI_MAX_REQS
                           results[resultsLen++] = 2;     // value length of result -> 10
                           cpy15(results+resultsLen, FCGI_MAX_REQS"10");
                           resultsLen += 15;
                        }

                        else if (namLen == 15 && cmp15(p, FCGI_MPXS_CONNS))
                        {
                           results[resultsLen++] = 15;    // name length of FCGI_MPXS_CONNS
                           results[resultsLen++] = 1;     // value length of result -> 0
                           cpy16(results+resultsLen, FCGI_MPXS_CONNS"0");
                           resultsLen += 16;
                        }
                     }

                     if (resultsLen)
                        FCGI_SendValueResults(connex, header.requestID, resultsLen, results);

                     deallocate(VPR(content), false);
                  }

                  if (!connex->requestID)
                     processing = false;
                  break;

               case FCGI_ABORT_REQUEST:
               default:
                  FCGI_SendEndRequest(connex, -1, FCGI_REQUEST_COMPLETE);
                  processing = false;

                  if (content)
                     deallocate(VPR(content), false);
                  break;
            }
         }

         else
         {
            FCGI_SendEndRequest(connex, -1, FCGI_CANT_MPX_CONN);
            processing = false;
         }
      }

      else
      {
         FCGI_SendEndRequest(connex, -1, FCGI_UNKNOWN_ROLE);
         processing = false;
      }
   }

   return requestOK;

cleanup:
   deallocate(VPR(content), false);
   return false;
}


boolean FCGI_SendEndRequest(ConnExec *connex, uint32_t appStatus, uint8_t protocolStatus)
{
   FCGI_EndRequestRecord request = {{FCGI_VERSION_1, FCGI_END_REQUEST, MapShort(connex->requestID), MapShort((uint16_t)sizeof(FCGI_EndRequestBody)), 0, 0},
                                    {MapInt(appStatus), protocolStatus, {}}};
   return connex->send(&connex->conn, &request, sizeof(FCGI_EndRequestRecord)) == sizeof(FCGI_EndRequestRecord);
}

boolean FCGI_SendValueResults(ConnExec *connex, ushort requestID, ushort resultsLength, uint8_t *results)
{
   FCGI_Header header = {FCGI_VERSION_1, FCGI_GET_VALUES_RESULT, MapShort(requestID), MapShort(resultsLength), 0, 0};
   return connex->jsnd(&connex->conn, &header, sizeof(FCGI_Header), results, resultsLength, NULL) == sizeof(FCGI_Header) + resultsLength;
}

boolean FCGI_SendDataStream(ConnExec *connex, uint8_t streamType, size_t totalLength, char *data)
{
   FCGI_Header header = {FCGI_VERSION_1, streamType, MapShort(connex->requestID), 0, 0, 0};

   if (totalLength && data)
      for (size_t i = 0, chunkLength = (totalLength <= FCGI_MAX_LENGTH) ? totalLength : FCGI_MAX_LENGTH;
           totalLength > 0; i += chunkLength, totalLength -= chunkLength, chunkLength = (totalLength <= FCGI_MAX_LENGTH) ? totalLength : FCGI_MAX_LENGTH)
      {
         header.contentLength = MapShort((ushort)chunkLength);
         if (connex->jsnd(&connex->conn, &header, sizeof(FCGI_Header), &data[i], chunkLength, NULL) != sizeof(FCGI_Header) + chunkLength)
            return false;
      }

   else
      return connex->send(&connex->conn, &header, sizeof(FCGI_Header)) == sizeof(FCGI_Header);

   return true;
}
