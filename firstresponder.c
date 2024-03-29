//  firstresponder.c
//  ContentCGI
//
//  Created by Dr. Rolf Jansen on 2018-05-08.
//  Copyright © 2018-2021 Dr. Rolf Jansen. All rights reserved.
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
#include <stdint.h>
#include <string.h>
#include <math.h>
#include <syslog.h>
#include <sys/stat.h>
#include <sys/time.h>

#include <openssl/ssl.h>

#include "utils.h"
#include "interim.h"
#include "connection.h"
#include "fastcgi.h"

#include "plugins/exports.h"


Plugins *gPlugins;

void *firstresponder(ConnExec *connex)
{
   boolean force;

   do
   {
      force = true;

      if (FCGI_Receiver(connex))
      {
         Node *node;

         if ((node = findName(connex->serverTable, "SCRIPT_NAME", 11)) && node->value.s && *node->value.s)
         {
            if (cmp15(node->value.s, "/edit/requinfo") /* || cmp9(node->value.s, "/_search") */)
            {
               char *output = newDynBuffer();
               uint  namColWidth = 0;

               dynAddString(&output, "SERVER ENVIRONMENT\n \n", 21);
               sprintTable(connex->serverTable, &namColWidth, &output);

               if (connex->QueryTable)
               {
                  dynAddString(&output, " \n \nQUERY ARGUMENTS\n \n", 22);
                  sprintTable(connex->QueryTable, &namColWidth, &output);
               }

               if (connex->POSTtable)
               {
                  dynAddString(&output, " \n \nPOST PARAMETERS\n \n", 22);
                  sprintTable(connex->POSTtable, &namColWidth, &output);
               }

               boolean ok = FCGI_SendDataStream(connex, FCGI_STDOUT, dynlen(output), output);
               freeDynBuffer(output);
               if (ok)
                  force = false;
               else
                  goto killconn;
            }

            else
            {
               int   el;
               char *entity;
               if (*node->value.s)
                  entity = node->value.s, el = strvlen(entity);
               else
                  entity ="index.html",   el = 10;

               long     rc = 0;
               int      hthl;
               char     htheader[256];
               Request  request  = {connex->requestID, connex->serverTable, connex->QueryTable, connex->POSTtable};
               Response response = {};

               for (Plugins *plugins = gPlugins; plugins; plugins = plugins->next)
                  switch (rc = plugins->respond(entity, el, &request, &response))
                  {
                     case 0:
                        continue;

                     case 200:
                     {
                        char modate[dateLen];
                        httpDate(modate, (response.contdat) ?: time(NULL));

                        if (*response.conttag)
                           hthl = snprintf(htheader, 256, "Status: %ld\nContent-Type: %s\nAccept-Ranges: bytes\nContent-Length: %lld\nLast-Modified: %s\nETag: \"%s\"\n\n",
                                           rc, response.conttyp, response.contlen, modate, response.conttag);
                        else
                           hthl = snprintf(htheader, 256, "Status: %ld\nContent-Type: %s\nAccept-Ranges: bytes\nContent-Length: %lld\nLast-Modified: %s\nCache-Control: no-cache\n\n",
                                           rc, response.conttyp, response.contlen, modate);
                        boolean ok = FCGI_SendDataStream(connex, FCGI_STDOUT, hthl, htheader)
                                  && FCGI_SendDataStream(connex, FCGI_STDOUT, response.contlen, response.content);
                        plugins->freeback(&response);

                        if (ok)
                        {
                           force = false;
                           goto sendOK;
                        }
                        else
                           goto killconn;
                     }

                     case 206:
                        if (response.contrgs)
                        {
                           char modate[dateLen];
                           httpDate(modate, (response.contdat) ?: time(NULL));

                           if (response.contrgs->next == NULL)    // a single range
                           {
                              llong rngl = response.contrgs->last - response.contrgs->first + 1;
                              if (*response.conttag)
                                 hthl = snprintf(htheader, 256, "Status: %ld\nContent-Type: %s\nAccept-Ranges: bytes\nContent-Length: %lld\nContent-Range: bytes %lld-%lld/%lld\nLast-Modified: %s\nETag: \"%s\"\n\n",
                                                 rc, response.conttyp, rngl, response.contrgs->first, response.contrgs->last, response.contlen, modate, response.conttag);
                              else
                                 hthl = snprintf(htheader, 256, "Status: %ld\nContent-Type: %s\nAccept-Ranges: bytes\nContent-Length: %lld\nContent-Range: bytes %lld-%lld/%lld\nLast-Modified: %s\nCache-Control: no-cache\n\n",
                                                 rc, response.conttyp, rngl, response.contrgs->first, response.contrgs->last, response.contlen, modate);
                              boolean ok = FCGI_SendDataStream(connex, FCGI_STDOUT, hthl, htheader)
                                        && FCGI_SendDataStream(connex, FCGI_STDOUT, rngl, response.content+response.contrgs->first);
                              plugins->freeback(&response);

                              if (ok)
                              {
                                 force = false;
                                 goto sendOK;
                              }
                              else
                                 goto killconn;
                           }

                           else
                           {
                              struct timeval tv;
                              gettimeofday(&tv, NULL);

                              int n = (int)response.contrgs->first;
                              llong l, ptsl, msgl;
                              char *parts, boundary[41];
                              msgl  = snprintf(boundary, 41, "%llx%08x", (ullong)tv.tv_sec*1000000LL + tv.tv_usec, (uint)connex->conn.sock);
                              msgl  = (n+1)*(4+msgl+2)+2                                          // (n+1)*"\r\n--boundary\r\n" + "--"
                                   +      n*strvlen(response.conttyp)                             //     n*"Content-Type: type\r\n"
                                   +      n*(21+3*sprintf(htheader, "%lld", response.contlen)+6); //     n*"Content-Range: bytes len-len/len\r\n\r\n"
                              msgl += response.contrgs->last;

                              if (parts = allocate(msgl, default_align, false))
                              {
                                 ptsl = 0;
                                 for (Ranges *next = response.contrgs->next; next; next = next->next)
                                 {
                                    ptsl += snprintf(parts+ptsl, msgl-ptsl, "\r\n--%s\r\n%sContent-Range: bytes %lld-%lld/%lld\r\n\r\n", boundary, response.conttyp, next->first, next->last, response.contlen);
                                    bcopy(response.content+next->first, parts+ptsl, l = next->last - next->first + 1);
                                    ptsl += l;
                                 }
                                 ptsl += snprintf(parts+ptsl, msgl-ptsl, "\r\n--%s--\r\n", boundary);

                                 if (*response.conttag)
                                    hthl = snprintf(htheader, 256, "Status: %ld\nContent-Type: multipart/byteranges; boundary=%s\nAccept-Ranges: bytes\nContent-Length: %lld\nLast-Modified: %s\nETag: \"%s\"\n\n",
                                                    rc, boundary, ptsl, modate, response.conttag);
                                 else
                                    hthl = snprintf(htheader, 256, "Status: %ld\nContent-Type: multipart/byteranges; boundary=%s\nAccept-Ranges: bytes\nContent-Length: %lld\nLast-Modified: %s\nCache-Control: no-cache\n\n",
                                                 rc, boundary, ptsl, modate);
                                 boolean ok = FCGI_SendDataStream(connex, FCGI_STDOUT, hthl, htheader)
                                           && FCGI_SendDataStream(connex, FCGI_STDOUT, ptsl, parts);
                                 deallocate(VPR(parts), false);
                                 plugins->freeback(&response);

                                 if (ok)
                                 {
                                    force = false;
                                    goto sendOK;
                                 }
                                 else
                                    goto killconn;
                              }
                              else
                                 goto error500;
                           }
                        }
                        else
                           goto error500;

                     case 201:
                     case 303:
                        if ((node = findName(connex->serverTable, "HTTP_HOST", 9)) && node->value.s && *node->value.s)
                        {
                           hthl = snprintf(htheader, 256, "Status: %ld\nLocation: https://%s/edit/%s\nContent-Length: 0\n\n",
                                           rc, node->value.s, (response.content) ?: "");
                           plugins->freeback(&response);
                           if (FCGI_SendDataStream(connex, FCGI_STDOUT, hthl, htheader))
                           {
                              force = false;
                              goto sendOK;
                           }
                           else
                              goto killconn;
                        }
                        else
                           goto error500;

                     case 202:
                        entity = "Status: 202\nContent-Type: text/plain\nContent-Length: 16\nConnection: close\n\n202 - Accepted.\n", el = 91;
                        goto sendmsg;

                     case 204:
                        hthl = snprintf(htheader, 256, "Status: %ld\nContent-Length: 0\n\n", rc);
                        if (FCGI_SendDataStream(connex, FCGI_STDOUT, hthl, htheader))
                        {
                           force = false;
                           goto sendOK;
                        }
                        else
                           goto killconn;

                     case 304:
                        if (*response.conttag)
                        {
                           hthl = snprintf(htheader, 256, "Status: %ld\nETag: \"%s\"\nContent-Length: 0\n\n", rc, response.conttag);
                           if (FCGI_SendDataStream(connex, FCGI_STDOUT, hthl, htheader))
                           {
                              force = false;
                              goto sendOK;
                           }
                           else
                              goto killconn;
                        }

                     default:
                     case 400:
                        entity = "Status: 400\nContent-Type: text/plain\nContent-Length: 19\nConnection: close\n\n400 - Bad request.\n", el = 94;
                        goto sendmsg;

                     case 404:
                        entity = "Status: 404\nContent-Type: text/plain\nContent-Length: 17\nConnection: close\n\n404 - Not found.\n", el = 92;
                        goto sendmsg;

                     error500:
                     case 500:
                        entity = "Status: 500\nContent-Type: text/plain\nContent-Length: 29\nConnection: close\n\n500 - Internal Server Error.\n", el = 104;

                     sendmsg:
                        if (FCGI_SendDataStream(connex, FCGI_STDOUT, el, entity))
                           goto sendOK;
                        else
                           goto killconn;
                  }

               if (rc == 0)
                  if (FCGI_SendDataStream(connex, FCGI_STDOUT, 101, "Status: 404\nContent-Type: text/plain\nContent-Length: 44\n\n404 - The requested resource was not found.\n"))
                     force = false;
                  else
                     goto killconn;
            }
         }
         else
            goto killconn;

      sendOK:
         if (!FCGI_SendDataStream(connex, FCGI_STDOUT, 0, NULL))
            goto killconn;

         if (!FCGI_SendEndRequest(connex, 0, FCGI_REQUEST_COMPLETE))
            goto killconn;
      }

      if (!force)
         connexRefresh(connex);

   } while (!connex->shut(&connex->conn, force));

   connexRelease(&connex);
   return NULL;

killconn:
   connex->shut(&connex->conn, true);
   connexRelease(&connex);
   return (void *)-1;
}
