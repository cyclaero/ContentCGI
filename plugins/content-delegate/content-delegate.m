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


boolean reindex(char *droot);

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
             && (content = allocate((contlen = st.st_size + 65 + 39 + 70)+1, default_align, false))
             && (file = fopen(filep, "r")))
            {
               int32_t loext = FourLoChars(spec);
               if (loext == 'html' && spec[4] == '\0' || loext == 'htm\0')
               {
                  content[contlen] = '\0';

                  llong i, k, l, m, n;

                  if ((l = n = fread(content, 1, 8, file)) == 8
                   && !cmp8(content, "<!--S-->"))
                  {
                     char *p, *q, b[1024]; cpy8(b, "********"); b[1023] = 0;

                     // inject the LINK tag of our content.css directly after the HEAD tag.
                     for (p = NULL, q = b+8; ((l += m = fread(q, 1, sizeof(b)-9, file)), m) && !(p = strcasestr(b+2, "<HEAD>")); cpy8(b, q+m-8), n += m)
                        memvcpy(content+n, q, m);
                     cpy8(b, q+m-8);

                     if (p)
                     {
                        if (p == q)
                             cpy6(content+n, p),                                                p += 6, m -= 6, n += 6;

                        else if (p < q)
                             cpy6(content+n+(k = p-q), p),                              k += 6, p += 6, m -= k, n += k;

                        else // (p > q)
                        {
                           memvcpy(content+n, q, k = p-q),                                              m -= k, n += k;
                             cpy6(content+n, p),                                                p += 6, m -= 6, n += 6;
                        }

                        memvcpy(content+n,
                                "<LINK rel=\"stylesheet\" href=\"/admin/content.css\" type=\"text/css\">", 65); n += 65;

                        // inject the DIV marker tag of the editibale content directly after the <!--e--> tag.
                        if (!(p = strstr(q = p, "<!--e-->")))
                        {
                           memvcpy(content+n, q, m);                                                            n += m;
                           for (p = NULL; q = b+8, ((l += m = fread(q, 1, sizeof(b)-9, file)), m) && !(p = strstr(b, "<!--e-->")); cpy8(b, q+m-8), n += m)
                              memvcpy(content+n, q, m);
                        }

                        if (p)
                        {
                           if (p == q)
                                cpy8(content+n, p),                                             p += 8, m -= 8, n += 8;

                           else if (p < q)
                                cpy8(content+n+(k = p-q), p),                           k += 8, p += 8, m -= k, n += k;

                           else // (p > q)
                           {
                              memvcpy(content+n, q, k = p-q),                                           m -= k, n += k;
                                cpy8(content+n, p),                                             p += 8, m -= 8, n += 8;
                           }

                           memvcpy(content+n, "<DIV data-editable data-name=\"content\">", 39);                 n += 39;
                           memvcpy(content+n, p, m);                                                            n += m;

                           if (!(l = st.st_size - l) || fread(content+n, l, 1, file) == 1)
                           {
                              n += l;

                              // inject the closing /DIV marker together with the SCRIPT tag of our content.js directly before the closing <!--E--> tag.
                              for (l = n-1; l >= 8; l--)
                                 if (cmp8(content+l-8, "<!--E-->"))
                                    break;

                              if (l >= 8)
                              {
                                 for (l -= 8, m = n-l, p = content+l, q = content+l+70, i = m-1; i >= 0; i--)
                                    q[i] = p[i];
                                 memvcpy(content+l, "</DIV><SCRIPT type=\"text/javascript\" src=\"/admin/content.js\"></SCRIPT>", 70); n += 70;

                                 response->contlen = n;
                                 response->content = content;
                                 rc = 200;
                                 goto finish;
                              }
                           }
                        }
                     }
                  }

                  rewind(file);
               }

               if (fread(content, st.st_size, 1, file) == 1)
               {
                  response->contlen = st.st_size;
                  response->content = content;
                  rc = 200;
               }

            finish:
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
                  if ((s+=3) < t)      // leave 1 line feed at the beginning of the replacement text
                  {
                     replace = s;
                     replen  = t-s;

                     int32_t loex = FourLoChars(spec);
                     if ((loex == 'html' && spec[4] == '\0' || loex == 'htm\0')
                      && (content = allocate((contlen = st.st_size + replen)+1, default_align, false))
                      && (file = fopen(filep, "r")))
                     {
                        llong i, k, l, m, n;
                        char *o, *p, *q, b[1024]; cpy8(b, "********"); b[1023] = 0;

                        // extract the preamble section of the HTML document until the <!--e--> tag
                        for (p = NULL, q = b+8, l = 0, n = 0; ((l += m = fread(q, 1, sizeof(b)-9, file)), m) && !(p = strstr(b, "<!--e-->")); cpy8(b, q+m-8), n += m)
                           memvcpy(content+n, q, m);
                        cpy8(b, q+m-8);

                        if (p)
                        {
                           if (p == q)
                                cpy8(content+n, p),                   p += 8, m -= 8, n += 8;

                           else if (p < q)
                                cpy8(content+n+(k = p-q), p), k += 8, p += 8, m -= k, n += k;

                           else // (p > q)
                           {
                              memvcpy(content+n, q, k = p-q),                 m -= k, n += k;
                                cpy8(content+n, p),                   p += 8, m -= 8, n += 8;
                           }

                           memvcpy(o = content+n, p, m);                              n += m;

                           if (!(l = st.st_size - l) || fread(content+n, l, 1, file) == 1)
                           {
                              fclose(file);
                              n += l;

                              // find the closing <!--E--> tag, and move it togehther with everything beyond it to the new end of the document
                              for (l = n-1; l >= 8; l--)
                                 if (cmp8(content+l-8, "<!--E-->"))
                                    break;

                              if (l >= 8)
                              {
                                 l -= 8;
                                 p = content+l;
                                 k = p - o;
                                 q = content+l+replen-k;
                                 if (k > replen)
                                    for (m = n-l, i = 0; i < m; i++)
                                       q[i] = p[i];
                                 else if (k < replen)
                                    for (m = n-l, i = m-1; i >= 0; i--)
                                       q[i] = p[i];

                                 memvcpy(o, replace, replen);                         n += replen-k;

                                 if (file = fopen(filep, "w"))
                                 {
                                    boolean ok = fwrite(content, n, 1, file) == 1;
                                    fclose(file);

                                    rc = (ok && reindex(droot))
                                       ? 204
                                       : 500;
                                 }
                              }
                           }
                           else
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


#pragma mark ••• Helper Functions •••

static void qdownsort(time_t *a, int l, int r)
{
   time_t m = a[(l + r)/2];
   int    i = l, j = r;

   do
   {
      while (a[i] > m) i++;
      while (a[j] < m) j--;
      if (i <= j)
      {
         time_t b = a[i]; a[i] = a[j], a[j] = b;
         i++; j--;
      }
   } while (j > i);

   if (l < j) qdownsort(a, l, j);
   if (i < r) qdownsort(a, i, r);
}


boolean reindex(char *droot)
{
   char *idx = newDynBuffer().buf;
   dynAddString((dynhdl)&idx,
"<!--S--><!DOCTYPE html><HTML><HEAD>\n"
"   <TITLE>BLog Résumés</TITLE>\n"
"   <META http-equiv=\"content-type\" content=\"text/html; charset=utf-8\">\n"
"   <LINK rel=\"stylesheet\" href=\"styles.css\" type=\"text/css\">\n"
"   <LINK rel=\"icon\" href=\"favicon.ico\" type=\"image/x-icon\">\n"
"</HEAD><BODY class=\"index\"><DIV class=\"page\"><TABLE>\n"
"   <TR>\n"
"      <TH style=\"width:675px; text-align:left;\">\n"
"         <H1><A href=\"/\" style=\"color:#000;\">BLog</A></H1>\n"
"      </TH>\n"
"      <TH>\n"
"         <A href=\"impressum.html\">Impressum</A><BR>\n"
"         <A href=\"datenschutz.html\">Datenschutzerklärung</A><BR>\n"
"         <A href=\"haftung.html\">Haftungsausschluß</A>\n"
"      </TH>\n"
"      <TH style=\"width:106px;\">\n"
"         <IMG style=\"width:96px;\" src=\"logo.png\">\n"
"      </TH>\n"
"   </TR>\n"
"   <TR>\n"
"      <TD>\n", 761);

   char *toc = newDynBuffer().buf;
   dynAddString((dynhdl)&toc,
"<!--S--><!DOCTYPE html><HTML><HEAD>\n"
"   <TITLE>Table of Contents</TITLE>\n"
"   <META http-equiv=\"content-type\" content=\"text/html; charset=utf-8\">\n"
"   <LINK rel=\"stylesheet\" href=\"styles.css\" type=\"text/css\">\n"
"</HEAD><BODY class=\"toc\">\n"
"   <FORM action=\"_search\" method=\"POST\"><P><INPUT class=\"search\" type=\"text\" placeholder=\"Search in the BLog\"></P></FORM>\n", 352);

   int   drootl = strvlen(droot);
   int   adirl  = drootl + 1 + 8 + 1;
   char  adir[adirl+1]; strmlcat(adir, adirl+1, NULL, droot, drootl, "/articles/", 10, NULL);

   struct stat st;
   if (stat(adir, &st) == no_error && S_ISDIR(st.st_mode))
   {
      DIR *dp;
      if (dp = opendir(adir))
      {
         struct dirent *ep, bp;
         int     fcnt = 0, fcap = 1024;
         time_t *stamps = allocate(fcap*sizeof(time_t), default_align, false);

         while (readdir_r(dp, &bp, &ep) == no_error && ep)
         {
            if (ep->d_name[0] != '.' && (ep->d_type == DT_REG || ep->d_type == DT_LNK))
            {
               int   artpl = adirl+ep->d_namlen;
               char  artp[artpl+1];
               strmlcat(artp, artpl+1, NULL, adir, adirl, ep->d_name, ep->d_namlen, NULL);
               if (stat(artp, &st) == no_error && S_ISREG(st.st_mode))
               {
                  char  *chk = NULL;
                  time_t stamp = strtoul(ep->d_name, &chk, 10);
                  if (stamp && chk && cmp6(chk, ".html"))
                  {
                     if (fcnt == fcap)
                        stamps = reallocate(stamps, (fcap += 1024)*sizeof(time_t), false, false);
                     stamps[fcnt++] = stamp;
                  }
               }
            }
         }

         closedir(dp);

         if (fcnt > 1)
            qdownsort(stamps, 0, fcnt-1);

         for (int j = 0; j < fcnt; j++)
         {
            FILE  *file;
            intStr stamp;
            int    stmpl = int2str(stamp, stamps[j], intLen, 0);
            int    artpl = adirl+stmpl+5;
            char   artp[artpl+1];
            char  *contemp;

            strmlcat(artp, artpl+1, NULL, adir, adirl, stamp, stmpl, ".html", 5, NULL);
            if (stat(artp, &st) == no_error && S_ISREG(st.st_mode)
             && st.st_size
             && (contemp = allocate(st.st_size+1, default_align, false)))
            {
               if (file = fopen(artp, "r"))
               {
                  contemp[st.st_size] = '\0';

                  if (fread(contemp, st.st_size, 1, file) == 1)
                  {
                     char *p, *q, *s, *t;
                     if ((p = strcasestr(contemp, "<TITLE>"))
                      && (q = strcasestr(p += 7, "</TITLE>"))
                      && (s =     strstr(q +  8, "<!--e-->"))
                      && (t = strcasestr(s += 8, "</P>")))
                     {
                        struct tm tm;
                        gmtime_r(&stamps[j], &tm);

                        dynAddString((dynhdl)&idx, "<A class=\"index\" href=\"articles/", 32);
                           dynAddInt((dynhdl)&idx, stamps[j]);
                        dynAddString((dynhdl)&idx, ".html\">\n", 8);
                        dynAddString((dynhdl)&idx, s, (int)(t-s));
                        int m =
                        dynAddString((dynhdl)&idx, "&nbsp;...</p>\n<P class=\"stamp\">", 31);
                              dyninc((dynhdl)&idx, snprintf(idx+m, 29, "%04d-%02d-%02d %02d:%02d:%02d</P></A>\n",
                                                            tm.tm_year+1900, tm.tm_mon+1, tm.tm_mday, tm.tm_hour, tm.tm_min, tm.tm_sec));

                        dynAddString((dynhdl)&toc, "   <P><A href=\"articles/", 24);
                           dynAddInt((dynhdl)&toc, stamps[j]);
                        dynAddString((dynhdl)&toc, ".html\" target=\"_top\">", 21);
                        dynAddString((dynhdl)&toc, p, (int)(q-p));
                        dynAddString((dynhdl)&toc, "</A></P>\n", 9);
                     }
                  }

                  fclose(file);
               }

               deallocate(VPR(contemp), false);
            }
         }

         deallocate(VPR(stamps), false);

         dynAddString((dynhdl)&idx,
"      </TD>\n"
"      <TD colspan=\"2\" style=\"padding:9px 3px 3px 27px;\">\n"
"         <IFRAME name=\"toc\" src=\"toc.html\" align=\"top\" style=\"width:100%; border:0px;\"\n"
"               onload=\"this.style.height=this.contentDocument.body.scrollHeight+'px';\"></IFRAME>\n"
"      </TD>\n"
"   </TR>\n"
"</TABLE></DIV></BODY><HTML>\n", 302+1);                          // +1 for including the '\0' at the end of the dyn. buffer

         dynAddString((dynhdl)&toc, "</BODY></HTML>", 14+1);      // +1 for ...

         boolean ok1 = false,
                 ok2 = false;

         int   idxfl = drootl + 1 + 11;
         char  idxf[idxfl+1]; strmlcat(idxf, idxfl+1, NULL, droot, drootl, "/", 1, "index.html", 10, NULL);
         int   tocfl = drootl + 1 + 9;
         char  tocf[tocfl+1]; strmlcat(tocf, tocfl+1, NULL, droot, drootl, "/", 1, "toc.html", 8, NULL);

         if ((stat(idxf, &st) != no_error || S_ISREG(st.st_mode) && unlink(idxf) == no_error)  // remove an old index.html file
          || (stat(tocf, &st) != no_error || S_ISREG(st.st_mode) && unlink(tocf) == no_error)) // remove an old toc.html file
         {
            FILE *file;

            if (file = fopen(idxf, "w"))
            {
               ok1 = fwrite(idx, dynlen((dynptr){idx}), 1, file) == 1;
               fclose(file);
            }

            if (file = fopen(tocf, "w"))
            {
               ok2 = fwrite(toc, dynlen((dynptr){toc}), 1, file) == 1;
               fclose(file);
            }
         }

         freeDynBuffer((dynptr){idx});
         freeDynBuffer((dynptr){toc});

         return ok1 && ok2;
      }
   }

   return false;
}
