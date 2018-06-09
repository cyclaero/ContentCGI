//  hello-delegate.m
//  hello-delegate
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


#import "CyObject.h"
#import "delegate-utils.h"
#import "cycalc.h"
#import "exports.h"


#pragma mark •••• Responder Delegate Class ••••

@interface Hello : CyObject
{
   Sources *cache;
   CalcPrep model;
   char *mathExpression;
   char  resultStr[1024];
}

- (id)initWithSources:(Sources *)sources;
- (long)hello:(char *)extension :(Request *)request :(Response *)response;

@end


@implementation Hello

- (id)initWithSources:(Sources *)sources
{
   if (self = [super init])
   {
      cache = sources;

      gDecSep = '.';
      model = prepareFunction(sharedCalculator(), mathExpression = "solve(r := 5000/24; 5000·(1+6.25%/12)^24 - r·∑(k := 0; 23; (1+6.25%/12)^k))");
   }

   return self;
}

- (void)dealloc
{
   disposeCalcPrep(&model);
   [super dealloc];
}

- (long)hello:(char *)extension :(Request *)request :(Response *)response
{
   Node *node = findName(request->serverTable, "HTTP_IF_NONE_MATCH", 18);
   char *etag = (node) ? node->value.s : NULL;

   if (extension)
      if (cmp5(extension, "html"))
         if (!etag || strstr(etag, cache->html.conttag) != etag+1)
            *response = cache->html;
         else
         {
            response->conttag = cache->html.conttag;
            return 304;
         }

      else if (cmp4(extension, "css"))
         if (!etag || strstr(etag, cache->css.conttag) != etag+1)
            *response = cache->css;
         else
         {
            response->conttag = cache->css.conttag;
            return 304;
         }

      else if (cmp3(extension, "js"))
         if (!etag || strstr(etag, cache->js.conttag) != etag+1)
            *response = cache->js;
         else
         {
            response->conttag = cache->js.conttag;
            return 304;
         }

      else if (cmp4(extension, "ico"))
         if (!etag || strstr(etag, cache->ico.conttag) != etag+1)
            *response = cache->ico;
         else
         {
            response->conttag = cache->ico.conttag;
            return 304;
         }

   if (!response->content)
   {
      char *tmpStr = NULL;

      response->contdyn = true;
      response->contlen = snprintf(resultStr, 1024, "Hello Responder Delegate at \"%s\".\n \n"
                                                    "Demonstration of the CyCalc Library:\n \n"
                                                    "  CyCalc example evaluating a prepared math. expression:\n     %s = %-10.6f\n \n"
                                                    "  CyCalc example calculating a onetime algebraic term:  \n     %s = %s \n",
                                                    cache->path,
                                                    mathExpression, evaluatePrepFunc(model.func, 0, &model.errRec),
                                                    "(4.79 - 5.41)/(100 - 60)*(80.37 - 60) + 5.41",
                                                    tmpStr = calculate(sharedCalculator(), "(4.79 - 5.41)/(100 - 60)*(80.37 - 60) + 5.41", 0));
      response->conttag = NULL;
      response->conttyp = "text/plain";
      response->content = strcpy(allocate((long)response->contlen+1, default_align, false), resultStr);
      deallocate(VPR(tmpStr), false);
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


EXPORT long respond(char *entity, int el, Request *request, Response *response)
{
   Node *node;
   if ((node = findName(request->serverTable, "REQUEST_METHOD", 14))
    && cmp4(node->value.s, "GET"))                                   // only respond to GET requests
   {
      if (cmp2(entity, "/_"))
         entity += 2, el -= 2;

      char *extension = NULL;
      int dl = domlen(entity);
      if (dl != el)
      {
         entity[el = dl] = '\0';
         extension = entity+el+1;
      }

      entity = strcpy(alloca(el+4), entity); cpy4(entity+el, ":::");

      SEL selector = sel_registerName(entity);
      if ([lResponder respondsToSelector:selector])
         return (long)objc_msgSend(lResponder, selector, (id)extension, (id)request, (id)response);
   }

   return 0;
}


EXPORT void freeback(Response *response)
{
   if (response->contdyn)
   {
      deallocate(VPR(response->conttag), false);
      if (response->contdyn < 0)
         freeDynBuffer((dynptr){response->content});
      else
         deallocate(VPR(response->content), false);
   }
}


EXPORT void release(void)
{
   [lResponder release];
   lResponder = nil;
}
