//  hello-delegate.m
//  hello-delegate
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


#import "CyObject.h"
#import "delegate-utils.h"
#import "exports.h"


#pragma mark •••• Responder Delegate Class ••••

@interface Hello : CyObject
{
   Sources *cache;
}

- (id)initWithSources:(Sources *)sources;
- (long)hello:(char *)spec :(char *)method :(Request *)request :(Response *)response;

@end


@implementation Hello

- (id)initWithSources:(Sources *)sources
{
   if (self = [super init])
   {
      cache = sources;
   }

   return self;
}

- (void)dealloc
{
   [super dealloc];
}

- (long)hello:(char *)spec :(char *)method :(Request *)request :(Response *)response
{
   Node *node = findName(request->serverTable, "HTTP_IF_NONE_MATCH", 18);
   char *etag = (node) ? node->value.s : NULL;

   if (spec)
      if (cmp5(spec, "html"))
         if (!etag || !*etag || strstr(etag, cache->html.conttag) != etag+1)
            *response = cache->html;
         else
         {
            strmlcpy(response->conttag, cache->html.conttag, etagLen, NULL);
            return 304;
         }

      else if (cmp4(spec, "css"))
         if (!etag || strstr(etag, cache->css.conttag) != etag+1)
            *response = cache->css;
         else
         {
            strmlcpy(response->conttag, cache->css.conttag, etagLen, NULL);
            return 304;
         }

      else if (cmp3(spec, "js"))
         if (!etag || strstr(etag, cache->js.conttag) != etag+1)
            *response = cache->js;
         else
         {
            strmlcpy(response->conttag, cache->js.conttag, etagLen, NULL);
            return 304;
         }

      else if (cmp4(spec, "png"))
         if (!etag || strstr(etag, cache->png.conttag) != etag+1)
            *response = cache->png;
         else
         {
            strmlcpy(response->conttag, cache->png.conttag, etagLen, NULL);
            return 304;
         }

      else if (cmp4(spec, "ico"))
         if (!etag || strstr(etag, cache->ico.conttag) != etag+1)
            *response = cache->ico;
         else
         {
            strmlcpy(response->conttag, cache->ico.conttag, etagLen, NULL);
            return 304;
         }

   if (!response->content)
   {
      response->contlen = 40;
      response->conttyp = "text/plain";
      response->content = "The Hello Responder Delegate does work.\n";
   }

   if (response->contlen)
      return 200;

   else
   {
      response->contlen = 10;
      response->conttyp = "text/plain";
      response->content = "Not found.";
      return 404;
   }
}

@end


#pragma mark •••• Responder Delegate Plugin Entry Points ••••

Hello *lResponder = nil;

EXPORT boolean initialize(Sources *sources)
{
   lResponder = [[Hello alloc] initWithSources:sources];
   return (lResponder != nil);
}


SEL makeSelector(char *message, int ml)
{
   if (!ml)
      ml = strvlen(message);
   char sel[OSP(ml+4+1)];
   strmlcpy(sel, message, 0, &ml);
   cpy5(sel+ml, "::::");
   return sel_registerName(sel);
}

EXPORT long respond(char *entity, int el, Request *request, Response *response)
{
   char *name, *method;
   Node *node;
   if ((*(name = nextPathSegment(entity, el)) == '_'
     || cmp5(name, "edit/") && *(name += 5) == '_')                     // respond to dynamic calls only
    && (node = findName(request->serverTable, "REQUEST_METHOD", 14))
    && (cmp4(method = node->value.s, "GET") || cmp5(method, "POST")))   // only respond to GET and POST requests
   {
      int nl = el - (int)(++name - entity);
      name = strcpy(alloca(OSP(nl+1)), name);                           // make a copy for not modifying the original uri of the entity
      int dl = domlen(name);

      char *spec = NULL;
      if (dl != nl)
      {
         name[nl = dl] = '\0';
         spec = name+nl+1;
      }

      SEL selector = makeSelector(name, nl);
      if ([lResponder respondsToSelector:selector])
         return (long)objc_msgSend(lResponder, selector, (id)spec, (id)method, (id)request, (id)response);
   }

   return 0;
}


EXPORT void freeback(Response *response)
{
   if (response->contdyn)
   {
      deallocate(VPR(response->conttag), false);
      if (response->contdyn < 0)
         freeDynBuffer(response->content);
      else
         deallocate(VPR(response->content), false);
   }
}


EXPORT void release(void)
{
   [lResponder release];
   lResponder = nil;
}
