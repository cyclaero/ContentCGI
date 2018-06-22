//  search-delegate.m
//  search-delegate
//
//  Created by Dr. Rolf Jansen on 2018-06-11.
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


#import <iconv.h>

#import "CyObject.h"
#import "delegate-utils.h"
#import "exports.h"
#import "index.h"

#import "../content-delegate/content-design.h"


#pragma mark •••• Responder Delegate Class ••••

typedef struct
{
   struct stat           stat;
   struct index          *idx;
   struct index_load_opt lopt;
} IndexCache;

@interface Search : CyObject
{
   Sources   *cache;
   IndexCache index;
}

- (id)initWithSources:(Sources *)sources;
- (long)search:(char *)extension :(Request *)request :(Response *)response;

@end


@implementation Search

- (id)initWithSources:(Sources *)sources
{
   if (self = [super init])
   {
      cache = sources;

      if (stat(ZETTAIR_DB_PATH"index.v.0", &index.stat) == no_error)
         index.idx  = index_load(ZETTAIR_DB_PATH"index", 50*1024*1024, INDEX_LOAD_NOOPT, &index.lopt);
   }

   return self;
}

- (void)dealloc
{
   index_delete(index.idx);
   [super dealloc];
}

- (long)search:(char *)extension :(Request *)request :(Response *)response
{
   Node *node = findName(request->serverTable, "HTTP_IF_NONE_MATCH", 18);
   char *etag = (node) ? node->value.s : NULL;

   if (extension)
      if (cmp5(extension, "html"))
         if (!etag || !*etag || strstr(etag, cache->html.conttag) != etag+1)
            *response = cache->html;
         else
         {
            strmlcpy(response->conttag, cache->html.conttag, etagLen, NULL);
            return 304;
         }

      else if (cmp4(extension, "css"))
         if (!etag || strstr(etag, cache->css.conttag) != etag+1)
            *response = cache->css;
         else
         {
            strmlcpy(response->conttag, cache->css.conttag, etagLen, NULL);
            return 304;
         }

      else if (cmp3(extension, "js"))
         if (!etag || strstr(etag, cache->js.conttag) != etag+1)
            *response = cache->js;
         else
         {
            strmlcpy(response->conttag, cache->js.conttag, etagLen, NULL);
            return 304;
         }

      else if (cmp4(extension, "png"))
         if (!etag || strstr(etag, cache->png.conttag) != etag+1)
            *response = cache->png;
         else
         {
            strmlcpy(response->conttag, cache->png.conttag, etagLen, NULL);
            return 304;
         }

      else if (cmp4(extension, "ico"))
         if (!etag || strstr(etag, cache->ico.conttag) != etag+1)
            *response = cache->ico;
         else
         {
            strmlcpy(response->conttag, cache->ico.conttag, etagLen, NULL);
            return 304;
         }

   if (response->contlen)
      return 200;

   else if (request->POSTtable
         && (node = findName(request->POSTtable, "search", 6))
         && node->value.s
         && node->value.s[0] != '\0')
   {
      struct stat st;
      if (stat(ZETTAIR_DB_PATH"index.v.0", &st) == no_error)
      {
         if (st.st_mtimespec.tv_sec != index.stat.st_mtimespec.tv_sec || st.st_mtimespec.tv_nsec != index.stat.st_mtimespec.tv_nsec)
         {
            index_delete(index.idx);
            index.idx = index_load(ZETTAIR_DB_PATH"index", 50*1024*1024, INDEX_LOAD_NOOPT, &index.lopt);
         }

         struct index_search_opt opt = {.u.okapi={1.2, 1e10, 0.75}, 0, 0, INDEX_SUMMARISE_TAG};
         struct index_result    *res = allocate(100*sizeof(struct index_result), default_align, false);
         iconv_t  utfToIso, isoToUtf;
         if (index.idx && res && (utfToIso = iconv_open("ISO-8859-1//TRANSLIT//IGNORE", "UTF-8")))
         {
            size_t origLen = strvlen(node->value.s), convLen = 4*origLen;
            char  *orig = node->value.s, *conv = alloca(convLen + 1), *siso  = conv;
            iconv(utfToIso, &orig, &origLen, &conv, &convLen); *conv = '\0';
            iconv_close(utfToIso);

            unsigned i, k, n;
            double   total;
            int      estim;
            if (index_search(index.idx, siso, 0, 100, res, &n, &total, &estim, INDEX_SEARCH_SUMMARY_TYPE, &opt)
             && (isoToUtf = iconv_open("UTF-8//TRANSLIT//IGNORE", "ISO-8859-1")))
            {
               response->content = newDynBuffer().buf;
               dynAddString((dynhdl)&response->content, SEARCH_PREAMBLE, SEARCH_PREAMBLE_LEN);
               dynAddString((dynhdl)&response->content, ((node = findName(request->serverTable, "CONTENT_TITLE", 13)) && node->value.s && *node->value.s) ? node->value.s : "Content", 0);
               dynAddString((dynhdl)&response->content, SEARCH_BODY_FYI, SEARCH_BODY_FYI_LEN);

               for (i = 0, k = 0; i < n; i++)
               {
                  char *href, *hend;
                  if ((href = strstr(res[i].auxilliary, ZETTAIR_DB_PATH))
                   && (hend = strstr(href += ZETTAIR_DB_PLEN, ".iso.html")))
                  {
                     dynAddString((dynhdl)&response->content, "<H1><A href=\"", 13);
                     dynAddString((dynhdl)&response->content, href, hend-href);
                     dynAddString((dynhdl)&response->content, "\">", 2);

                     size_t origLen, convLen;
                     char  *orig, *conv, *utf8;
                     if (res[i].title[0] != '\0')
                     {
                        origLen = strvlen(res[i].title);
                        convLen = 4*origLen;
                        orig = res[i].title;
                        utf8 = conv = alloca(convLen + 1);
                        iconv(isoToUtf, &orig, &origLen, &conv, &convLen); *conv = '\0';
                        dynAddString((dynhdl)&response->content, utf8, conv-utf8);
                     }
                     else
                        dynAddString((dynhdl)&response->content, href, hend-href);
                     dynAddString((dynhdl)&response->content, "</A></H1>\n", 10);

                     if (res[i].summary[0] != '\0')
                     {
                        origLen = strvlen(res[i].summary);
                        convLen = 4*origLen;
                        orig = res[i].summary;
                        utf8 = conv = alloca(convLen + 1);
                        iconv(isoToUtf, &orig, &origLen, &conv, &convLen); *conv = '\0';
                        dynAddString((dynhdl)&response->content, "<P>", 3);
                        dynAddString((dynhdl)&response->content, utf8, conv-utf8);
                        dynAddString((dynhdl)&response->content, "</P>\n", 5);
                     }

                     k++;
                  }
               }

               if (k == 0)
                  dynAddString((dynhdl)&response->content, SEARCH_NORESULT, SEARCH_NORESULT_LEN);

               dynAddString((dynhdl)&response->content, SEARCH_ADDENDUM, SEARCH_ADDENDUM_LEN);

               iconv_close(isoToUtf);

               response->contdyn = -true;
               response->contlen = dynlen((dynptr){response->content});
               response->conttyp = "text/html; charset=utf-8";
            }

            deallocate(VPR(res), false);
         }
      }

      return (response->contlen) ? 200 : 500;
   }

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

Search *lResponder = nil;

EXPORT boolean initialize(Sources *sources)
{
   lResponder = [[Search alloc] initWithSources:sources];
   return (lResponder != nil);
}


SEL makeSelector(char *message, int ml)
{
   if (!ml)
      ml = strvlen(message);
   char sel[ml+3+1];
   strmlcpy(sel, message, 0, &ml);
   cpy4(sel+ml, ":::");
   return sel_registerName(sel);
}

EXPORT long respond(char *entity, int el, Request *request, Response *response)
{
   Node *node;
   if ((node = findName(request->serverTable, "REQUEST_METHOD", 14))
    && (cmp4(node->value.s, "GET") || cmp5(node->value.s, "POST")))  // only respond to GET and POST requests
   {
      if (cmp2(entity, "/_"))
         entity += 2, el -= 2;
      else if (cmp7(entity, "/edit/_"))
         entity += 7, el -= 7;

      char *extension = NULL;
      int dl = domlen(entity);
      if (dl != el)
      {
         entity[el = dl] = '\0';
         extension = entity+el+1;
      }

      SEL selector = makeSelector(entity, el);
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
