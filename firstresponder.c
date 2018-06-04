//  firstresponder.c
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

#include <stdlib.h>
#include <stdio.h>
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

         if ((node = findName(connex->serverTable, "SCRIPT_NAME", 11)) && node->value.s)
         {
            if (cmp15(node->value.s, "/edit/requinfo") /* cmp12(node->value.s, "/_hello.css") */)
            {
               char *output = newDynBuffer().buf;
               uint  namColWidth = 0;

               dynAddString((dynhdl)&output, "SERVER ENVIRONMENT\n \n", 21);
               sprintTable(connex->serverTable, &namColWidth, (dynhdl)&output);

               if (connex->QueryTable)
               {
                  dynAddString((dynhdl)&output, " \n \nQUERY ARGUMENTS\n \n", 22);
                  sprintTable(connex->QueryTable, &namColWidth, (dynhdl)&output);
               }

               if (connex->POSTtable)
               {
                  dynAddString((dynhdl)&output, " \n \nPOST PARAMETERS\n \n", 22);
                  sprintTable(connex->POSTtable, &namColWidth, (dynhdl)&output);
               }

               boolean ok = FCGI_SendDataStream(connex, FCGI_STDOUT, dynlen((dynptr){output}), output);
               freeDynBuffer((dynptr){output});
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
                        if (response.conttag)
                           hthl = snprintf(htheader, 256, "Status: %ld\nContent-Type: %s\nContent-Length: %lld\nETag: \"%s\"\n\n",
                                           rc, response.conttyp, response.contlen, response.conttag);
                        else
                           hthl = snprintf(htheader, 256, "Status: %ld\nContent-Type: %s\nContent-Length: %lld\nCache-Control: no-cache\n\n",
                                           rc, response.conttyp, response.contlen);
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

                     case 201:
                     case 202:
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
                        if (response.conttag)
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
