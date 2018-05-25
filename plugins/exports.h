//  exports.h
//  Responder Delegate plugins
//
//  Created by Dr. Rolf Jansen on 2018-05-15.
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


#pragma mark ••• Export Data structures for the Responder Delegate Plugins •••

#define EXPORT __attribute__((visibility("default")))

typedef struct
{
   ushort requestID;
   Node **serverTable;
   Node **QueryTable;
   Node **POSTtable;
} Request;


typedef struct
{
   boolean contdyn;
   llong   contlen;
   char   *conttag;
   char   *conttyp;
   char   *content;
} Response;


typedef struct
{
   char    *path;
   Response html;
   Response css;
   Response js;
   Response ico;
   Node   **images;
} Sources;


typedef struct Plugins
{
   // cached web app sources
   Sources cache;

   // plugin entry points
   boolean (*initialize)(Sources *sources);
   long (*respond)(char *entity, int el, Request *request, Response *response);
   void (*freeback)(Response *response);
   void (*release)(void);

   // plugin dynamic library handle
   void *pluglib;

   // next responder in the chained list of plugins
   struct Plugins *next;
} Plugins;
