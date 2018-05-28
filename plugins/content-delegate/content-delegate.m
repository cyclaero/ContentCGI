//  content-delegate.m
//  content-delegate
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
#import "exports.h"


#pragma mark •••• Responder Delegate Class ••••

@interface Content : CyObject
{
   Sources *cache;
}

- (id)initWithSources:(Sources *)sources;
- (long)content:(char *)extension :(Request *)request :(Response *)response;
- (long)images:(char *)name :(Request *)request :(Response *)response;

@end


@implementation Content

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

- (long)content:(char *)extension :(Request *)request :(Response *)response
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
      response->contdyn = true;
      response->contlen = 42;
      response->conttag = NULL;
      response->conttyp = "text/plain";
      response->content = strcpy(allocate((long)response->contlen+1, default_align, false), "The Content Responder Delegate does work.\n");
   }

   return (response->contlen) ? 200 : 0;
}

- (long)images:(char *)name :(Request *)request :(Response *)response
{
   Node *node = findName(request->serverTable, "HTTP_IF_NONE_MATCH", 18);
   char *etag = (node) ? node->value.s : NULL;

   if (node = findName(cache->images, name, strvlen(name)))
      if (!etag || strstr(etag, ((Response *)node->value.p)->conttag) != etag+1)
         *response = *(Response *)node->value.p;
      else
      {
         response->conttag = ((Response *)node->value.p)->conttag;
         return 304;
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

Content *lResponder = nil;

EXPORT boolean initialize(Sources *sources)
{
   lResponder = [[Content alloc] initWithSources:sources];
   return (lResponder != nil);
}


EXPORT long respond(char *entity, int el, Request *request, Response *response)
{
   long  rc = 0;
   Node *node;
   char *method = NULL;

   if ((node = findName(request->serverTable, "REQUEST_METHOD", 14))
    && (cmp4(method = node->value.s, "GET") || cmp5(method, "POST"))       // only respond to GET or POST requests
    && cmp7(entity, "/admin/"))                                            // only be reponsible for everything below the /admin/ path
   {
      if (*(entity += 7) != '\0')
         el -= 7;
      else
         el = 10, entity = "index.html";

      char *spec = NULL;
      char  *msg = strcpy(alloca(el+4), entity);
      int dl, ml = el;

      if (cmp7(msg, "images/"))
         spec = msg+7, msg = "images:::";
      else
      {
         if ((dl = domlen(msg)) != ml)
         {
            msg[ml = dl] = '\0';
            spec = entity+ml+1;
         }

         cpy4(msg+ml, ":::");
      }

      SEL selector = sel_registerName(msg);
      if ([lResponder respondsToSelector:selector]                         // return cached resources
       && (rc = (long)objc_msgSend(lResponder, selector, (id)spec, (id)request, (id)response)))
         return rc;

      else if (node = findName(request->serverTable, "DOCUMENT_ROOT", 13)) // access resource from DOCUMENT_RROT
      {
         char  *droot  = node->value.s;
         int    drootl = strvlen(droot);
         int    filepl = drootl + 1 + el;
         char   filep[filepl+1]; strmlcat(filep, filepl+1, NULL, droot, drootl, "/", 1, entity, el, NULL);
         struct stat st;

         if (stat(filep, &st) == no_error && S_ISREG(st.st_mode) && st.st_size)
         {
            char *content = NULL;
            char *conttyp;
            llong contlen;
            FILE *file;

            // GET method
            if (cmp4(method, "GET")
             && (content = allocate((contlen = st.st_size + 58 + 39 + 63)+1, default_align, false))
             && (file = fopen(filep, "r")))
            {
               int32_t loext = FourLoChars(spec);
               if ((loext == 'html' && spec[4] == '\0' || loext == 'htm\0')
                && !cmp6(entity, "index."))
               {
                  content[contlen] = '\0';

                  llong i, k, l, m, n;
                  char *p, *q, b[256]; cpy6(b, "******"); b[255] = 0;

                  // inject the LINK tag of our content.css directly after the HEAD tag.
                  for (p = NULL, q = b+6, l = 0, n = 0; ((l += m = fread(q, 1, sizeof(b)-7, file)), m) && !(p = strcasestr(b, "<HEAD>")); cpy6(b, q+m-6), n += m)
                     memcpy(content+n, q, m);
                  cpy6(b, q+m-6);

                  if (p)
                  {
                     if (p == q)
                          cpy6(content+n, p),                                                   p += 6, m -= 6, n += 6;

                     else if (p < q)
                          cpy6(content+n+(k = p-q), p),                                 k += 6, p += 6, m -= k, n += k;

                     else // (p > q)
                     {
                        memcpy(content+n, q, k = p-q),                                                  m -= k, n += k;
                          cpy6(content+n, p),                                                   p += 6, m -= 6, n += 6;
                     }

                     memcpy(content+n, "<LINK rel=\"stylesheet\" href=\"content.css\" type=\"text/css\">", 58); n += 58;

                     // inject the DIV marker tag of the editibale content directly after the BODY tag.
                     if (!(p = strcasestr(q = p, "<BODY>")))
                     {
                        memcpy(content+n, q, m);                                                                n += m;
                        for (p = NULL; q = b+6, ((l += m = fread(q, 1, sizeof(b)-7, file)), m) && !(p = strcasestr(b, "<BODY>")); cpy6(b, q+m-6), n += m)
                           memcpy(content+n, q, m);
                     }

                     if (p)
                     {
                        if (p == q)
                             cpy6(content+n, p),                                                p += 6, m -= 6, n += 6;

                        else if (p < q)
                             cpy6(content+n+(k = p-q), p),                              k += 6, p += 6, m -= k, n += k;

                        else // (p > q)
                        {
                           memcpy(content+n, q, k = p-q),                                               m -= k, n += k;
                             cpy6(content+n, p),                                                p += 6, m -= 6, n += 6;
                        }

                        memcpy(content+n, "<DIV data-editable data-name=\"content\">", 39);                     n += 39;
                        memcpy(content+n, p, m);                                                                n += m;

                        if (!(l = st.st_size - l) || fread(content+n, l, 1, file) == 1)
                        {
                           n += l;

                           // inject the closing /DIV marker together with the SCRIPT tag of our content.js directly before the closing /BODY tag.
                           for (l = n-1; l >= 6; l--)
                              if (content[l] == '>' && cmp2(content+l-6, "</") && FourUpChars(content+l-4) == 'BODY')
                                 break;

                           if (l >= 6)
                           {
                              for (l -= 6, m = n-l, p = content+l, q = content+l+63, i = 0; i < m; i++)
                                 q[i] = p[i];
                              memcpy(content+l, "</DIV><SCRIPT type=\"text/javascript\" src=\"content.js\"></SCRIPT>", 63); n += 63;

                              response->contlen = n;
                              response->content = content;
                              rc = 200;
                           }
                        }
                     }
                  }
               }

               else if (fread(content, st.st_size, 1, file) == 1)
               {
                  response->contlen = st.st_size;
                  response->content = content;
                  rc = 200;
               }

               if (rc == 200)
               {
                  response->contdyn = true;
                  response->conttyp = (char *)extensionToType(entity, el);
               }
               else
                  deallocate(VPR(content), false);

               fclose(file);
            }

            // POST method
            else if ((node = findName(request->serverTable, "CONTENT_TYPE", 12)) && (conttyp = strstr(node->value.s, "multipart/form-data"))
                  && (node = findName(request->serverTable, "CONTENT_DATA", 12)) && (contlen = node->value.size))
            {
               rc = 400;

               char *boundary = conttyp+vnamlen(conttyp)-1; cpy2(boundary, "--");
               int   boundlen = strvlen(boundary);
               char *replace  = node->value.s;
               llong replen   = 0;
               char *s, *t;

               for (s = strstr(replace, boundary) + boundlen, t = replace+contlen-1; t > s && !(cmp2(t, "--") && strstr(t-boundlen, boundary) == t-boundlen); t--);
               if (t > s)
               {
                  *(t -= boundlen) = '\0';
                  for (; s < t && !cmp4(s, "\r\n\r\n"); s++);
                  if ((s+=4) < t)
                  {
                     replace = s;
                     replen  = t-s;

                     int32_t loex = FourLoChars(spec);
                     if ((loex == 'html' && spec[4] == '\0' || loex == 'htm\0')
                      && !cmp6(entity, "index.")
                      && (content = allocate((contlen = st.st_size + replen)+1, default_align, false))
                      && (file = fopen(filep, "r")))
                     {
                        llong k, l, m, n;
                        char *p, *q, b[256]; cpy6(b, "******"); b[255] = 0;

                        // extract the HEAD section of the HTML document
                        for (p = NULL, q = b+6, l = 0, n = 0; ((l += m = fread(q, 1, sizeof(b)-7, file)), m) && !(p = strcasestr(b, "<BODY>")); cpy6(b, q+m-6), n += m)
                           memcpy(content+n, q, m);
                        cpy6(b, q+m-6);
                        fclose(file);

                        if (p
                         && (file = fopen(filep, "w")))
                        {
                           if (p == q)
                                cpy7(content+n, "<BODY>\n"),           n += 7;

                           else if (p < q)
                                cpy7(content+n+(k = p-q), "<BODY>\n"), k += 7, n += k;

                           else // (p > q)
                           {
                              memcpy(content+n, q, k = p-q),           n += k;
                                cpy7(content+n, "<BODY>\n"),           n += 7;
                           }

                           memcpy(content+n, replace, replen);    n += replen;
                            cpy16(content+n, "</BODY></HTML>\n"); n += 15;

                           rc = (fwrite(content, n, 1, file) == 1) ? 204 : 500;
                           fclose(file);
                        }
                     }

                     deallocate(VPR(content), false);
                  }
               }
            }
         }
      }
   }

   return rc;
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
