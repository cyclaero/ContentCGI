//  content-delegate.m
//  content-delegate
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


#import <magick/api.h>

#import "CyObject.h"
#import "delegate-utils.h"
#import "exports.h"
#import "content-design.h"


static pthread_mutex_t EDIT_mutex = PTHREAD_MUTEX_INITIALIZER;

#pragma mark •••• Responder Delegate Class ••••

@interface Content : CyObject
{
   Sources *cache;
}

- (id)initWithSources:(Sources *)sources;
- (long)content:(char *)spec :(char *)method :(Request *)request :(Response *)response;

- (long)models: (char *)name :(char *)method :(Request *)request :(Response *)response;
- (long)images: (char *)name :(char *)method :(Request *)request :(Response *)response;
- (long)upload: (char *)name :(char *)method :(Request *)request :(Response *)response;
- (long)insert: (char *)name :(char *)method :(Request *)request :(Response *)response;
- (long)rotate: (char *)name :(char *)method :(Request *)request :(Response *)response;

- (long)create: (char *)base :(char *)method :(Request *)request :(Response *)response;
- (long)delete: (char *)base :(char *)method :(Request *)request :(Response *)response;
- (long)revive: (char *)base :(char *)method :(Request *)request :(Response *)response;

@end


@implementation Content

- (id)initWithSources:(Sources *)sources
{
   if (self = [super init])
      cache = sources;

   return self;
}

- (void)dealloc
{
   [super dealloc];
}


- (long)content:(char *)spec :(char *)method :(Request *)request :(Response *)response
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
      response->contdyn = true;
      response->contlen = 42;
      response->conttyp = "text/plain";
      response->content = strcpy(allocate((long)response->contlen+1, default_align, false), "The Content Responder Delegate does work.\n");
   }

   return (response->contlen) ? 200 : 0;
}


- (long)models:(char *)name :(char *)method :(Request *)request :(Response *)response
{
   Node *node = findName(request->serverTable, "HTTP_IF_NONE_MATCH", 18);
   char *etag = (node) ? node->value.s : NULL;

   if (node = findName(cache->models, name, strvlen(name)))
      if (!etag || strstr(etag, ((Response *)node->value.p)->conttag) != etag+1)
         *response = *(Response *)node->value.p;
      else
      {
         strmlcpy(response->conttag, ((Response *)node->value.p)->conttag, etagLen, NULL);
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


- (long)images:(char *)name :(char *)method :(Request *)request :(Response *)response
{
   Node *node = findName(request->serverTable, "HTTP_IF_NONE_MATCH", 18);
   char *etag = (node) ? node->value.s : NULL;

   if (node = findName(cache->images, name, strvlen(name)))
      if (!etag || strstr(etag, ((Response *)node->value.p)->conttag) != etag+1)
         *response = *(Response *)node->value.p;
      else
      {
         strmlcpy(response->conttag, ((Response *)node->value.p)->conttag, etagLen, NULL);
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


- (long)upload:(char *)name :(char *)method :(Request *)request :(Response *)response
{
   long  rc = 500;

   char *conttyp, *content, *droot;
   llong contlen;
   Node *node;
   if ((node = findName(request->serverTable, "DOCUMENT_ROOT", 13)) && (droot   = node->value.s) && *droot
    && (node = findName(request->serverTable, "CONTENT_TYPE",  12)) && (conttyp = strstr(node->value.s, "multipart/form-data"))
    && (node = findName(request->serverTable, "CONTENT_DATA",  12)) && (contlen = node->value.size) && (content = node->value.s))
   {
      rc = 400;

      char *boundary = conttyp+vnamlen(conttyp)-1; cpy2(boundary, "--");
      int   boundlen = strvlen(boundary);
      char *r, *s, *t;

      for (s = strstr(content, boundary) + boundlen, t = content+contlen-1; t > s
                                                                         && !(cmp2(t, "--")
                                                                         && strstr(t-boundlen, boundary) == t-boundlen); t--);
      if (t > s)
      {
         t -= boundlen;
         if (cmp2(t-2, "\r\n"))
            t -= 2;
         else if (*(t-1) == '\n' || *(t-1) == '\r')
            t--;
         *t = '\0';

         char *filename, *imagtype;
         for (r = s; r < t && !cmp4(r, "\r\n\r\n"); r++); *r = '\0'; r += 4;
         if (r >= t)
            return rc;

         if (strstr(s, "name=\"image\"")
          && (filename = strstr(s, "filename=\"")))
         {
            imagtype = strstr(s, "Content-Type: ");

            char *p;
            for (p = filename += 10; *p && *p != '"'; p++); *p = 0;
            int fl = (int)(p-filename);

            if (imagtype)
            {
               imagtype += 14;
               imagtype[wordlen(imagtype)] = '\0';
            }
            else
               imagtype = (char *)extensionToType(filename, fl);

            if (cmp6(imagtype, "image/"))
            {
               int  cl,
                    rl = strvlen(droot),
                    nl = strvlen(name),
                    imgpl = rl + 1 + nl + 1 + fl;     // for example $DOCUMENT_ROOT/articles/media/1527627185/image_to_be_uploaded.jpg
               char imgp[OSP(imgpl+1)];
               cl = strmlcat(imgp, imgpl+1, NULL,  droot, rl, "/", 1, name, nl, NULL);

               struct stat st;                        // check whether the target directory exist
               if ((stat(imgp, &st) == no_error       // in case it does not
                || (mkdir(imgp, 0775) == no_error     // then try to create it
                 && stat(imgp, &st) == no_error))     // by purpose, don't care for intermediate path failures
                && S_ISDIR(st.st_mode))               // final check, and let's go
               {
                  FILE *file;
                  cl += strmlcat(imgp+cl, imgpl-cl+1, NULL, "/", 1, filename, fl, NULL);
                  if (file = fopen(imgp, "w"))
                     if (fwrite(r, t-r, 1, file) == 1)
                     {
                        fclose(file);

                        // involve GraphicsMagick
                        InitializeMagick(NULL);
                        ExceptionInfo excepInfo = {};
                        GetExceptionInfo(&excepInfo);
                        ImageInfo *imageInfo = CloneImageInfo(0);

                        // infer the image format conforming to the uploded file name
                        strmlcpy(imageInfo->filename, imgp, MaxTextExtent, &cl);
                        Image *image;

                        if ((image = PingBlob(imageInfo, r, t-r, &excepInfo))       // ping the blob first, however, some image formats can not
                         || (image = BlobToImage(imageInfo, r, t-r, &excepInfo)))   // be pinged from blob, so try again by reading the whole thing
                        {
                           // only the image dimensions are neded in this stage
                           ulong imgWidth  = image->columns;
                           ulong imgHeight = image->rows;
                           DestroyImage(image);
                           DestroyImageInfo(imageInfo);
                           DestroyExceptionInfo(&excepInfo);
                           DestroyMagick();

                           char *cp = imgp+rl-1;
                           while (p = strstr(cp+1, "/"MEDIA_DIR"/"))
                              cp = p;
                           if (cp != imgp+rl-1)
                           {
                              for (p = cp-1; p > imgp+rl && *p != '/'; p--);
                              cl = strvlen(cp = p+1);
                                                                 // vv -- max. string size of ulong is 20 -- 18446744073709551616
                              response->content = allocate(cl + 1 + 20 + 1 + 20, default_align, false);
                              strmlcpy(response->content, cp, 0, &cl);
                              response->content[cl++] = '\n';
                              cl += int2str(response->content+cl, imgWidth, 21, 0);
                              response->content[cl++] = '\n';
                              cl += int2str(response->content+cl, imgHeight, 21, 0);
                              response->contlen = cl;
                              response->contdyn = true;
                              response->conttyp = "text/plain";

                              rc = 200;
                           }
                        }
                     }
                     else
                        fclose(file);
               }
            }
         }
      }
   }

   return rc;
}


- (long)insert:(char *)name :(char *)method :(Request *)request :(Response *)response
{
   long  rc = 500;

   char *conttyp, *content, *droot;
   llong contlen;
   Node *node;
   if ((node = findName(request->serverTable, "DOCUMENT_ROOT", 13)) && (droot   = node->value.s)
    && (node = findName(request->serverTable, "CONTENT_TYPE",  12)) && (conttyp = strstr(node->value.s, "text/plain"))
    && (node = findName(request->serverTable, "CONTENT_DATA",  12)) && (contlen = node->value.size) && (content = node->value.s))
   {
      rc = 400;

      int   rl, nl, sl, al, cl;
      char *size  = content,
           *angle = NULL,
           *crop  = NULL;

      if ((rl = strvlen(droot))
       && (nl = strvlen(name))
       && (sl = linelen(size))
       && (al = linelen(angle = size + sl+1))
       && (cl = linelen(crop = angle + al+1)))
      {
         size[sl] = angle[al] = crop[cl] = '\0';

         int  imgpl = rl + 1 + nl + MEDIA_DIR_LEN;    // for example $DOCUMENT_ROOT/articles/media/1527627185/image_to_be_inserted.jpg[.png]
         char imgp[OSP(imgpl+1)];
         nl = strmlcat(imgp, imgpl+1, NULL,  droot, rl, "/", 1, name, nl, NULL);

         struct stat st;
         ulong  imgWidth, imgHeight;
         double top, left, bottom, right;
         double alpha;
         char  *h;
         if (stat(imgp, &st) == no_error && S_ISREG(st.st_mode)
          && (imgWidth  = strtoul(size, &h, 10))
          && (imgHeight = strtoul(h+1, NULL, 10))
          && -180 <= (alpha  = strtod(angle, NULL)) && alpha  <= 180
          &&    0 <= (top    = strtod(crop, &h))    && top     <   1
          &&    0 <= (left   = strtod(h+1,  &h))    && left    <   1
          &&  top  < (bottom = strtod(h+1,  &h))    && bottom <=   1
          && left  < (right  = strtod(h+1,  &h))    && right  <=   1)
         {
            // involve GraphicsMagick
            InitializeMagick(NULL);
            ExceptionInfo excepInfo = {};
            GetExceptionInfo(&excepInfo);
            ImageInfo *imageInfo = CloneImageInfo(0);

            // infer the image format conforming to the uploaded file name
            strmlcpy(imageInfo->filename, imgp, MaxTextExtent, &nl);
            Image *working;
            if (working = ReadImage(imageInfo, &excepInfo))
            {
               if (fabs(alpha) >= 0.001)
               {
                  Image *image = RotateImage(working, alpha, &excepInfo);
                  DestroyImage(working);
                  working = image;
                  if (!working)
                     goto destroy;
               }

               RectangleInfo croprect = {lround((right - left)*imgWidth),
                                         lround((bottom - top)*imgHeight),
                                         lround(left*imgWidth),
                                         lround(top*imgHeight)};

               if (croprect.width < imgWidth || croprect.height < imgHeight)
               {
                  Image *image = CropImage(working, &croprect, &excepInfo);
                  DestroyImage(working);
                  working = image;
                  if (!working)
                     goto destroy;
               }

               cpy5(working->filename+nl, ".png");
               cpy4(working->magick, "PNG");
               WriteImage(imageInfo, working);
               imgWidth  = working->columns;
               imgHeight = working->rows;
               DestroyImage(working);

               char *p, *np = imgp+rl-1;
               while (p = strstr(np+1, "/"MEDIA_DIR"/"))
                  np = p;
               if (np != imgp+rl-1)
               {
                  for (p = np-1; p > imgp+rl && *p != '/'; p--);
                  nl = strvlen(np = p+1);
                                                     // vv -- max. string size of uint is 10 -- 4294967294
                  response->content = allocate(nl + 1 + 10 + 1 + 10, default_align, false);
                  strmlcpy(response->content, np, 0, &nl);
                  response->content[nl++] = '\n';
                  nl += int2str(response->content+nl, imgWidth, 11, 0);
                  response->content[nl++] = '\n';
                  nl += int2str(response->content+nl, imgHeight, 11, 0);
                  response->contlen = nl;
                  response->contdyn = true;
                  response->conttyp = "text/plain";

                  rc = 200;
               }
            }

         destroy:
            DestroyImageInfo(imageInfo);
            DestroyExceptionInfo(&excepInfo);
            DestroyMagick();
         }
      }
   }

   return rc;
}


- (long)rotate:(char *)name :(char *)method :(Request *)request :(Response *)response
{
   long  rc = 500;

   char *conttyp, *content, *droot;
   llong contlen;
   Node *node;
   if ((node = findName(request->serverTable, "DOCUMENT_ROOT", 13)) && (droot   = node->value.s)
    && (node = findName(request->serverTable, "CONTENT_TYPE",  12)) && (conttyp = strstr(node->value.s, "text/plain"))
    && (node = findName(request->serverTable, "CONTENT_DATA",  12)) && (contlen = node->value.size) && (content = node->value.s))
   {
      rc = 400;

      int   rl, nl, sl, al;
      char *size  = content,
           *angle = NULL;

      if ((rl = strvlen(droot))
       && (nl = strvlen(name))
       && (sl = linelen(size))
       && (al = linelen(angle = size + sl+1)))
      {
         size[sl] = angle[al] = '\0';

         int  imgpl = rl + 1 + nl + MEDIA_DIR_LEN;    // for example $DOCUMENT_ROOT/articles/media/1527627185/image_to_be_rotated.jpg[.png]
         char imgp[OSP(imgpl+1)];
         nl = strmlcat(imgp, imgpl+1, NULL,  droot, rl, "/", 1, name, nl, NULL);

         struct stat st;
         ulong  imgWidth, imgHeight;
         double alpha;
         char  *h;
         if (stat(imgp, &st) == no_error && S_ISREG(st.st_mode)
          && (imgWidth  = strtoul(size, &h, 10))
          && (imgHeight = strtoul(h+1, NULL, 10))
          && -180 <= (alpha = strtod(angle, NULL)) && alpha <= 180)
         {
            // involve GraphicsMagick
            InitializeMagick(NULL);
            ExceptionInfo excepInfo = {};
            GetExceptionInfo(&excepInfo);
            ImageInfo *imageInfo = CloneImageInfo(0);

            // infer the image format conforming to the uploaded file name
            strmlcpy(imageInfo->filename, imgp, MaxTextExtent, &nl);
            Image *original, *working;
            if (original = ReadImage(imageInfo, &excepInfo))
            {
               working = RotateImage(original, alpha, &excepInfo);
               DestroyImage(original);
               if (working)
               {
                  cpy5(working->filename+nl, ".png");
                  cpy4(working->magick, "PNG");
                  WriteImage(imageInfo, working);
                  imgWidth  = working->columns;
                  imgHeight = working->rows;
                  DestroyImage(working);

                  char *p, *np = imgp+rl-1;
                  while (p = strstr(np+1, "/"MEDIA_DIR"/"))
                     np = p;
                  if (np != imgp+rl-1)
                  {
                     for (p = np-1; p > imgp+rl && *p != '/'; p--);
                     nl = strvlen(np = p+1);
                                                        // vv -- max. string size of uint is 10 -- 4294967294
                     response->content = allocate(nl + 1 + 10 + 1 + 10, default_align, false);
                     strmlcpy(response->content, np, 0, &nl);
                     response->content[nl++] = '\n';
                     nl += int2str(response->content+nl, imgWidth, 11, 0);
                     response->content[nl++] = '\n';
                     nl += int2str(response->content+nl, imgHeight, 11, 0);
                     response->contlen = nl;
                     response->contdyn = true;
                     response->conttyp = "text/plain";

                     rc = 200;
                  }
               }
            }

            DestroyImageInfo(imageInfo);
            DestroyExceptionInfo(&excepInfo);
            DestroyMagick();
         }
      }
   }

   return rc;
}


long  GEThandler(char *droot, int drootl, char *entity, int el, char *spec, Request *request, Response *response, Response *cache);
long POSThandler(char *droot, int drootl, char *entity, int el, char *spec, Request *request, Response *response, Response *cache);
boolean  reindex(char *droot, int drootl, char *base, int bl, time_t updtstamp, Node **serverTable, boolean create_empty);

- (long)create:(char *)base :(char *)method :(Request *)request :(Response *)response;
{
   if (base && *base)
   {
      char *droot;
      if (droot = docRoot(request->serverTable))
      {
         int  drootl = strvlen(droot);

         int  bl = strvlen(base);
         int  artdl = drootl + 1 + bl; // for example $DOCUMENT_ROOT/articles
         char artd[OSP(artdl+1)];
         strmlcat(artd, artdl+1, NULL, droot, drootl, "/", 1, base, bl, NULL);

         struct stat st;
         if (stat(artd, &st) == no_error && S_ISDIR(st.st_mode))
         {
            char *storeName = lastPathSegment(base, bl);
            int   storeNaml = bl - (int)(storeName - base);

            Node    *node;
            Response modelData = {};
            char    *modelName = strcpy(alloca(OSP(storeNaml+5+1)), storeName);
            cpy6(modelName+storeNaml, ".html");
            if (!(node = findName(cache->models, modelName, storeNaml+5)))
            {
               cpy6(modelName+storeNaml-1, ".html");
               if (!(node = findName(cache->models, modelName, storeNaml+4)))
                  node = findName(cache->models, "model.html", 10);
            }

            if (node && ((Response *)node->value.p)->contlen)
            {
               // Need to replace the generic title 'CONTENT_TITLE' by the real one, which must be informed by the respective server environment variable
               llong contlen = ((Response *)node->value.p)->contlen;
               char *content = ((Response *)node->value.p)->content;
               char *titlpos = strstr(content, "CONTENT_TITLE");
               if (titlpos)
               {
                  char *contitl = conTitle(request->serverTable);
                  int   titllen = strvlen(contitl);
                  modelData.contlen = contlen + titllen - 13;
                  modelData.content = allocate(modelData.contlen+1, default_align, false);
                  llong p = titlpos - content, q = contlen - p - 13;
                  memvcpy(modelData.content, content, p);
                  p += strmlcpy(modelData.content+p, contitl, 0, &titllen);
                  memvcpy(modelData.content+p, titlpos+13, q);
               }

               else
               {
                  modelData.contlen = contlen;
                  modelData.content = allocate(modelData.contlen+1, default_align, false);
                  memvcpy(modelData.content, content, contlen);
               }

               modelData.content[contlen] = '\0';
               modelData.conttyp = "text/html; charset=utf-8";

               if (cmp4(method, "GET"))
               {
                  char *plang, *qlang = (request->QueryTable && (node = findName(request->QueryTable, "lang", 4)) && node->value.s && node->value.size == 2)
                                      ? node->value.s : NULL;
                  if (qlang && (plang = strcasestr(modelData.content, "<HTML lang=\"")))
                     cpy2(plang+12, qlang);

                  return  GEThandler(droot, drootl, "model", 5, "html", request, response, &modelData);
               }
               else // POST
                  return POSThandler(droot, drootl, base, bl, "html", request, response, &modelData);
            }
         }

         else
            return 404;
      }

      return 500;
   }

   return 400;
}


- (long)delete:(char *)base :(char *)method :(Request *)request :(Response *)response;
{
   int rc = 400;

   if (base && *base && cmp4(method, "GET"))
   {
      char *droot;
      if (droot = docRoot(request->serverTable))
      {
         int  drootl = strvlen(droot);

         Node *node;
         if (((node = findName(request->QueryTable, "a",       1))
           || (node = findName(request->QueryTable, "art",     3))
           || (node = findName(request->QueryTable, "article", 7)))
          && node->value.s && *node->value.s)
         {
            pthread_mutex_lock(&EDIT_mutex);

            char *article = node->value.s;
            int  bl = strvlen(base),
                 al = strvlen(article);
            int  artpl = drootl + 1 + bl + 1 + al;                      // for example $DOCUMENT_ROOT/articles/1527627185.html
            char artp[OSP(artpl+1)];
            strmlcat(artp, artpl+1, NULL, droot, drootl, "/", 1, base, bl, "/", 1, article, al, NULL);

            int  dl = domlen(article);
            int  medpl = drootl + 1 + bl + 1 + MEDIA_DIR_LEN + 1 + dl;  // for example $DOCUMENT_ROOT/articles/media/1527627185
            char medp[OSP(medpl+1)];
            strmlcat(medp, medpl+1, NULL, droot, drootl, "/", 1, base, bl, "/"MEDIA_DIR"/", MEDIA_DIR_LEN+2, article, dl, NULL);

            int  datpl = drootl + 1 + bl + 1 + DATA_DIR_LEN + 1 + dl;   // for example $DOCUMENT_ROOT/articles/data/1527627185
            char datp[OSP(datpl+1)];
            strmlcat(datp, datpl+1, NULL, droot, drootl, "/", 1, base, bl, "/"DATA_DIR"/", DATA_DIR_LEN+2, article, dl, NULL);

            struct stat st;
            int  tmppl = 11+al;                                         // for example /tmp/media_1527627185
            char tmpp[OSP(tmppl+1)];                                    //          or /tmp/data_1527627185
                                                                        //          or /tmp/1527627185.html
            // 1. move the respective media directory into /tmp/
            strmlcat(tmpp, tmppl+1, NULL, "/tmp/media_", 11, article, dl, NULL);
            if (stat(medp, &st) == no_error && S_ISDIR(st.st_mode))
               rename(medp, tmpp);

            // 2. move the respective data directory into /tmp/
            strmlcat(tmpp, tmppl+1, NULL, "/tmp/data_", 10, article, dl, NULL);
            if (stat(datp, &st) == no_error && S_ISDIR(st.st_mode))
               rename(datp, tmpp);

            // 3. move the given article file into /tmp/ (actually do a copy/delete, s. below)
            strmlcat(tmpp, tmppl+1, NULL, "/tmp/", 5, article, al, NULL);
            if (stat(artp, &st) == no_error && S_ISREG(st.st_mode)
             && fileCopy(artp, tmpp, &st) == no_error // the spider of the search-deleagte determines changes by observing the number of hard links for a given
             && unlink(artp) == no_error)             // inode. For this reason we cannot simply rename the deleted file, because its nlink value wont't change.
            {
               if (!reindex(droot, drootl, base, bl, 0, request->serverTable, true))
               {
                  if (bl = strvlen(base))             // reindex may have changed the base path, so check its length
                     if (response->content = allocate(bl+1, default_align, false))
                     {
                        response->contdyn = true;
                        response->contlen = strmlcpy(response->content, base, bl+1, &bl);
                     }
                     else
                        rc = 500;
               }

               rc = 303;
            }
            else
               rc = 404;

            pthread_mutex_unlock(&EDIT_mutex);
         }

         else if ((node = findName(request->QueryTable, "data", 4))
               && node->value.s && *node->value.s)
         {
            pthread_mutex_lock(&EDIT_mutex);

            char *datdir = node->value.s;
            int  bl = strvlen(base),
                 dl = domlen(datdir);

            int  datpl = drootl + 1 + bl + 1 + DATA_DIR_LEN + 1 + dl;   // for example $DOCUMENT_ROOT/articles/data/1527627185
            char datp[OSP(datpl+1)];
            strmlcat(datp, datpl+1, NULL, droot, drootl, "/", 1, base, bl, "/"DATA_DIR"/", DATA_DIR_LEN+2, datdir, dl, NULL);

            struct stat st;
            int  tmppl = 10+dl;                                         // for example /tmp/data_1527627185
            char tmpp[OSP(tmppl+1)];

            // move the respective data directory into /tmp/
            strmlcat(tmpp, tmppl+1, NULL, "/tmp/data_", 10, datdir, dl, NULL);
            if (stat(datp, &st) == no_error && S_ISDIR(st.st_mode))
            {
               rename(datp, tmpp);
               rc = 202;
            }
            else
               rc = 404;

            pthread_mutex_unlock(&EDIT_mutex);
         }

         // else rc = 400
      }
      else
         rc = 500;
   }

   return rc;
}


- (long)revive:(char *)base :(char *)method :(Request *)request :(Response *)response;
{
   int rc = 400;

   if (base && *base && cmp4(method, "GET"))
   {
      char *droot;
      if (droot = docRoot(request->serverTable))
      {
         pthread_mutex_lock(&EDIT_mutex);

         if (reindex(droot, strvlen(droot), base, strvlen(base), 0, request->serverTable, false))
         {
            int bl;
            if (bl = strvlen(base))    // reindex may have changed the base path, so check its length
               if (response->content = allocate(bl+1, default_align, false))
               {
                  response->contdyn = true;
                  response->contlen = strmlcpy(response->content, base, bl+1, &bl);
               }
               else
                  rc = 500;
         }

         rc = 303;

         pthread_mutex_unlock(&EDIT_mutex);
      }
      else
         rc = 500;
   }

   return rc;
}

@end


#pragma mark •••• Responder Delegate Plugin Entry Points ••••

Content *lResponder = nil;

EXPORT boolean initialize(Sources *sources)
{
   lResponder = [[Content alloc] initWithSources:sources];
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
   long  rc = 0;
   char *name, *method;
   Node *node;
   if (*nextPathSegment(entity, el) != '_'                                    // do not respond to non-editing dynamic calls
    && (node = findName(request->serverTable, "REQUEST_METHOD", 14))
    && (cmp4(method = node->value.s, "GET") || cmp5(method, "POST"))          // only respond to GET or POST requests
    && cmp6(entity, "/edit/") && entity[6] != '/')                            // only be responsible for everything below the /edit/ path
   {
      char *spec = NULL;
      int   rl, nl;

      if (*(entity += 6) != '\0')
         el -= 6;
      else
         el  = 10, entity = "index.html";

      if (entity[el-1] == '/')
         nl = strmlcat(name = alloca(OSP(el+10+1)), el+10+1, NULL, entity, el, "index.html", 10, NULL), entity = name, el = nl;
      else
         name = strcpy(alloca(OSP((nl = el)+1)), entity);

      if (cmp8(name, "content."))
         spec = name+8, name[nl = 7] = '\0';

      else if (cmp7(name, "models/")
            || cmp7(name, "images/")
            || cmp7(name, "upload/")
            || cmp7(name, "insert/")
            || cmp7(name, "rotate/"))
         spec = name+7, name[nl = 6] = '\0';

      else if (cmp8(name+nl-7, "/create")
            || cmp8(name+nl-7, "/delete")
            || cmp8(name+nl-7, "/revive"))
         spec = name, name += nl-6, spec[nl-7] = '\0', nl = 6;

      else
      {
         char *dom = lastPathSegment(name, nl);
         int   dl;
         if ((dl = domlen(dom)) && dom[dl] == '.')
         {
            spec = dom+dl+1;
            nl = (int)(dom - name) + dl;
         }
      }

      SEL selector = makeSelector(name, nl);
      if ([lResponder respondsToSelector:selector]                            // return a cached or generated resource
       && (rc = (long)objc_msgSend(lResponder, selector, (id)spec, (id)method, (id)request, (id)response)))
         return rc;

      else if ((node = findName(request->serverTable, "DOCUMENT_ROOT", 13))   // access a resource from DOCUMENT_RROT
            && node->value.s && (rl = (int)node->value.size))
         return (cmp4(method, "GET"))
                ?  GEThandler(node->value.s, rl, entity, el, spec, request, response, NULL)
                : POSThandler(node->value.s, rl, entity, el, spec, request, response, NULL);
   }

   return rc;
}


EXPORT void freeback(Response *response)
{
   if (response->contdyn)
   {
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

static inline int articlePathAndName(char *path, int plen, char **name)
{
   char *p = lastPathSegment(path, plen);
   if (p > path)
   {
      *name = p;
      plen = (int)(p - path);
      if (path[plen-1] == '/')
         path[--plen] = '\0';
   }
   else
      *name = NULL;

   return plen;
}

static inline llong contread(char *buf, llong size, llong count, FILE *file, Response *cache, llong *pos)
{
   if (cache && pos && 0 <= *pos && *pos < cache->contlen - 1)
   {
      llong bytes = count*size;
      if (bytes > cache->contlen - *pos)
         bytes = cache->contlen - *pos;
      memvcpy(buf, cache->content + *pos, bytes);
      *pos += bytes;
      return bytes/size;
   }

   else if (file)
      return fread(buf, size, count, file);

   else
      return 0;
}


static inline llong contstat(char *filep, struct stat *st, Response *cache)
{
   if (cache)
      return cache->contlen;
   else if (filep)
      return (stat(filep, st) == no_error && S_ISREG(st->st_mode)) ? st->st_size : 0;
   else
      return 0;
}


long GEThandler(char *droot, int drootl, char *entity, int el, char *spec, Request *request, Response *response, Response *cache)
{
   long   rc      = 0;
   int    filepl  = 0;
   char  *filep   = NULL;
   struct stat st = {};
   llong  filesize;

   if (!cache && droot)
   {
      filepl = drootl + 1 + el;
      filep  = alloca(OSP(filepl+1));
      strmlcat(filep, filepl+1, NULL, droot, drootl, "/", 1, entity, el, NULL);
   }

   if (filesize = contstat(filep, &st, cache))
   {
      FILE *file    = NULL;
      char *content = NULL;
      llong contlen, contpos = 0;
      if ((content = allocate((contlen = filesize + 64 + 39 + STAMP_DATA_LEN + STAMP_VALUE_LEN + CLOSE_DATA_LEN + 69)+1, default_align, false))
       && (cache || (file = fopen(filep, "r"))))
      {
         int32_t loext = FourLoChars(spec);
         if (loext == 'html' && spec[4] == '\0' || loext == 'htm\0')
         {
            content[contlen] = '\0';

            llong i, k, l, m, n;

            if ((l = n = contread(content, 1, 8, file, cache, &contpos)) == 8
             && !cmp8(content, "<!--S-->"))
            {
               pthread_mutex_lock(&EDIT_mutex);

               char *p, *q, b[1536]; cpy8(b, "********"); b[1535] = 0;

               // inject the LINK tag of our content.css directly after the HEAD tag.
               for (p = NULL, q = b+8; ((l += m = contread(q, 1, sizeof(b)-9, file, cache, &contpos)), m) && !(p = strcasestr(b+2, "<HEAD>")); cpy8(b, q+m-8), n += m)
                  memvcpy(content+n, q, m);
               cpy8(b, q+m-8);

               if (p)
               {
                  if (p == q)
                        cpy6(content+n, p),                                               p += 6, m -= 6, n += 6;

                  else if (p < q)
                        cpy6(content+n+(k = p-q), p),                             k += 6, p += 6, m -= k, n += k;

                  else // (p > q)
                  {
                     memvcpy(content+n, q, k = p-q),                                              m -= k, n += k;
                        cpy6(content+n, p),                                               p += 6, m -= 6, n += 6;
                  }

                  memvcpy(content+n,
                          "<LINK rel=\"stylesheet\" href=\"/edit/content.css\" type=\"text/css\">", 64);  n += 64;

                  // inject the DIV marker tag of the editibale content directly after the <!--e--> tag.
                  if (!(p = strstr(q = p, "<!--e-->")))
                  {
                     memvcpy(content+n, q, m);                                                            n += m;
                     for (p = NULL; q = b+8, ((l += m = contread(q, 1, sizeof(b)-9, file, cache, &contpos)), m) && !(p = strstr(b, "<!--e-->")); cpy8(b, q+m-8), n += m)
                        memvcpy(content+n, q, m);
                  }

                  if (p)
                  {
                     if (p == q)
                           cpy8(content+n, p),                                            p += 8, m -= 8, n += 8;

                     else if (p < q)
                           cpy8(content+n+(k = p-q), p),                          k += 8, p += 8, m -= k, n += k;

                     else // (p > q)
                     {
                        memvcpy(content+n, q, k = p-q),                                           m -= k, n += k;
                           cpy8(content+n, p),                                            p += 8, m -= 8, n += 8;
                     }

                     memvcpy(content+n, "<DIV data-editable data-name=\"content\">", 39);                 n += 39;
                     memvcpy(content+n, p, m);                                                            n += m;

                     if (!(l = filesize - l) || contread(content+n, l, 1, file, cache, &contpos) == 1)
                     {
                        n += l;

                        // inject the closing /DIV marker together with the SCRIPT tag of our content.js directly before the closing <!--E--> tag.
                        for (l = n-1; l >= 8; l--)
                           if (cmp8(content+l-8, "<!--E-->"))
                              break;

                        if (l >= 8)
                        {
                           intStr stamp;
                           k = (cache) ? int2str(stamp, time(NULL), intLen, 0) : 0;
                           for (l -= 8, m = n-l, p = content+l, q = content+l+((cache)?STAMP_DATA_LEN+k+CLOSE_DATA_LEN:0)+69, i = m-1; i >= 0; i--)
                              q[i] = p[i];

                           if (cache)
                           {
                              memvcpy(content+l, STAMP_DATA, STAMP_DATA_LEN);        l += STAMP_DATA_LEN, n += STAMP_DATA_LEN;
                              memvcpy(content+l, stamp, k);                          l += k,              n += k;
                              memvcpy(content+l, CLOSE_DATA, CLOSE_DATA_LEN);        l += CLOSE_DATA_LEN, n += CLOSE_DATA_LEN;
                           }
                           memvcpy(content+l, "</DIV><SCRIPT type=\"text/javascript\" src=\"/edit/content.js\"></SCRIPT>", 69);
                           response->contlen =                                                            n += 69;
                           response->content = content;
                           rc = 200;

                           pthread_mutex_unlock(&EDIT_mutex);
                           goto finish;
                        }
                     }
                  }
               }

               pthread_mutex_unlock(&EDIT_mutex);
            }

            if (file)
               rewind(file);
            else // cache
               contpos = 0;
         }

         if (file)
         {
            Node *node;
            char *etag;
            httpETag(response->conttag, &st);

            if ((node = findName(request->serverTable, "HTTP_IF_NONE_MATCH", 18))
             && (etag = node->value.s) && *etag
             && strstr(etag, response->conttag) == etag+1)
            {
               rc = 304;
               goto finish;
            }
         }

         if (contread(content, filesize, 1, file, cache, &contpos) == 1)
         {
            response->contlen = filesize;
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

         if (file)
            fclose(file);

         if (cache)
            deallocate(VPR(cache->content), false);
      }
   }

   return rc;
}


int stripATags(char *s, ssize_t n)
{
   int i, j;

   for (i = 0, j = 0; i < n; i++)
      switch (s[i])
      {
         case '<':
            if (s[i+1] == 'a' || s[i+1] == 'A')
            {
               for (i += 2; s[i] != '>'; i++);
               break;
            }
            else if (cmp2(s+i+1, "/a") || cmp2(s+i+1, "/A"))
            {
               for (i += 3; s[i] != '>'; i++);
               break;
            }

         default:
            if (i != j)
               s[j] = s[i];
            j++;
            break;
      }

   s[j] = '\0';
   return j;
}


long POSThandler(char *droot, int drootl, char *entity, int el, char *spec, Request *request, Response *response, Response *cache)
{
   long   rc       = 500;
   int    filepl   = 0;
   char  *filep    = NULL;
   time_t creatime = 0;
   struct stat  st = {};
   llong  filesize;

   if (droot)
   {
      if (!cache)
      {
         filepl = drootl + 1 + el;
         filep  = alloca(OSP(filepl+1));
         strmlcat(filep, filepl+1, NULL, droot, drootl, "/", 1, entity, el, NULL);
      }

      if (filesize = contstat(filep, &st, cache))
      {
         char *conttyp, *content = NULL;
         llong contlen,  contpos = 0;
         Node *node;
         if ((node = findName(request->serverTable, "CONTENT_TYPE", 12)) && (conttyp = strstr(node->value.s, "multipart/form-data"))
          && (node = findName(request->serverTable, "CONTENT_DATA", 12)) && (contlen = node->value.size))
         {
            rc = 400;

            char *boundary = conttyp+vnamlen(conttyp)-1; cpy2(boundary, "--");
            int   boundlen = strvlen(boundary);
            char *replace  = node->value.s;
            llong replen   = 0;
            char *r, *s, *t;

            for (s = strstr(replace, boundary) + boundlen, t = replace+contlen-1; t > s
                                                                               && !(cmp2(t, "--")
                                                                               && strstr(t-boundlen, boundary) == t-boundlen); t--);
            if (t > s)
            {
               *(t -= boundlen) = '\0';

               for (r = s; r < t && !cmp4(r, "\r\n\r\n"); r++); *r = '\0'; r += 3;     // leave 1 line feed at the beginning of the replacement text
               if (r >= t)
                  return rc;

               if (strstr(s, "name=\"images\""))
               {
               /* parse the image URI list
                  int ll;
                  for (r++; !cmp2(r, "\r\n") && (ll = linelen(r)); r += ll+1)
                  {
                     if (r[ll-1] == '\r')
                        r[ll-1] = '\0';
                     else
                        r[ll] = '\0';

                     printf("%s\n", uriDecode(r));
                  }

                  printf("%s\n", entity);
               */

                  s = strstr(r, boundary) + boundlen;
                  for (r = s; r < t && !cmp4(r, "\r\n\r\n"); r++); *r = '\0'; r += 3;  // leave 1 line feed at the beginning of the replacement text
                  if (r >= t)
                     return rc;
               }

               if (strstr(s, "name=\"content\""))
               {
                  int stampl = 0;
                  char *user = NULL;
                  if (cache)
                  {
                     user   = ((node = findName(request->serverTable, "REMOTE_USER", 11)) && node->value.s) ? node->value.s : "";
                     stampl = STAMP_PREFIX_LEN
                            + strvlen(user)
                            + DATE_TIME_STAMP_LEN
                            + STAMP_SUFFIX_LEN;

                     if (s = strstr(t - CLOSE_DATA_LEN - STAMP_VALUE_LEN - STAMP_DATA_LEN, STAMP_DATA))
                        t = s, creatime = strtoul(t + STAMP_DATA_LEN, NULL, 10);

                     if (!creatime)
                        creatime = time(NULL);
                  }

                  replace = r;
                  replen  = t-r;
                  llong extlen = replen + stampl;

                  int32_t loex = FourLoChars(spec);
                  FILE   *file = NULL;
                  if ((loex == 'html' && spec[4] == '\0' || loex == 'htm\0')
                   && (content = allocate(filesize + extlen+1, default_align, false))
                   && (cache || (file = fopen(filep, "r"))))
                  {
                     pthread_mutex_lock(&EDIT_mutex);

                     llong i, k, l, m, n;
                     char  b[1536]; cpy8(b, "********"); b[1535] = 0;
                     char *o, *p, *q = b+8;

                     // find the heading in the replacement tag by purposely being restrictive on what to accept as a new title to be injected
                     char *heading = (*replace == '\n' && cmp4(replace+1, "<h1>"))
                                   ? skip(replace+5) : NULL;
                     llong headlen = (heading && (p = strstr(heading, "</h1>")))
                                   ? bskip(p) - heading : 0;

                     // extract the preamble section of the HTML document until the <!--e--> tag
                     // and in case a heading has been found, replace the content of <TITLE> by it
                     if (heading && headlen)
                     {
                        memvcpy(p = alloca(OSP(headlen+1)), heading, headlen);
                        headlen = stripATags(heading = p, headlen);
                        p = NULL, n = 0;

                        char *tb, *te;
                        if ((l = m = contread(q, 1, sizeof(b)-9, file, cache, &contpos))
                            && (tb = strstr(q, "<TITLE>"))     // inject the new title only if the respective
                            && (te = strstr(q, "</TITLE>")))   // tags are all in capital letters
                        {
                           cpy8(b, q+m-8);

                           tb += 7;
                           memvcpy(content,   q, k = tb-q);                         n  = k;
                           memvcpy(content+n, heading, headlen);         m -= te-q, n += headlen;
                              cpy8(content+n, te);                q = te+8, m -= 8, n += 8;

                           if (!(p = strstr(b, "<!--e-->")))
                           {
                              memvcpy(content+n, q, m);                             n += m;
                              for (p = NULL; q = b+8, ((l += m = contread(q, 1, sizeof(b)-9, file, cache, &contpos)), m) && !(p = strstr(b, "<!--e-->")); cpy8(b, q+m-8), n += m)
                                 memvcpy(content+n, q, m);
                           }
                        }
                     }
                     else
                        for (p = NULL, l = 0, n = 0; ((l += m = contread(q, 1, sizeof(b)-9, file, cache, &contpos)), m) && !(p = strstr(b, "<!--e-->")); cpy8(b, q+m-8), n += m)
                           memvcpy(content+n, q, m);

                     if (p)
                     {
                        if (p == q)
                              cpy8(content+n, p),                   p += 8, m -= 8, n += 8;

                        else if (p < q)
                              cpy8(content+n+(k = p-q), p), k += 8, p += 8, m -= k, n += k;

                        else // (p > q)
                        {
                           memvcpy(content+n, q, k = p-q),                  m -= k, n += k;
                              cpy8(content+n, p),                   p += 8, m -= 8, n += 8;
                        }

                        memvcpy(o = content+n, p, m);                               n += m;

                        if (!(l = filesize - l) || contread(content+n, l, 1, file, cache, &contpos) == 1)
                        {
                           if (file)
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
                              q = content+l+extlen-k;
                              if (k > extlen)
                                 for (m = n-l, i = 0; i < m; i++)
                                    q[i] = p[i];
                              else if (k < extlen)
                                 for (m = n-l, i = m-1; i >= 0; i--)
                                    q[i] = p[i];

                              memvcpy(o, replace, replen),                          n += replen-k;
                              if (cache)
                              {
                                 struct tm tm;
                                 localtime_r(&creatime, &tm);
                                 char c = o[replen+stampl];                   // backup the char where snprintf() puts the terminating '\0'
                                 n += snprintf(o+replen, stampl+1,
                                               STAMP_PREFIX"%s - %04d-%02d-%02d %02d:%02d:%02d"STAMP_SUFFIX,
                                               user, tm.tm_year+1900, tm.tm_mon+1, tm.tm_mday, tm.tm_hour, tm.tm_min, tm.tm_sec);
                                 o[replen+stampl] = c;                        // restore
                              }

                              // write out the changes to the file in a safe manner
                              rc = 500;

                              int  tmpfpl, j;
                              char *tmpfp = NULL;
                              if (!cache)
                              {
                                 for (j = 1; entity[el-j] != '/' && j <= el; j++);
                                 tmpfpl = 5 + --j;
                                 tmpfp = alloca(OSP(tmpfpl+1));
                                 strmlcat(tmpfp, tmpfpl+1, NULL, "/tmp/", 5, filep+filepl-j, j, NULL);
                                 file = fopen(tmpfp, "w");
                              }
                              else
                              {
                                 int pl, sl = strvlen(spec);
                                 filepl = drootl + 1 + el + 1 + 12 + 1 + sl;  // for example $DOCUMENT_ROOT/articles/1527627185.html
                                 filep  = alloca(OSP(filepl+1));
                                 pl  = strmlcat(filep, filepl+1, NULL, droot, drootl, "/", 1, entity, el, "/", 1, NULL);
                                 pl += int2str(filep+pl, creatime, 13, 0);
                                 filep[pl++] = '.';
                                 strmlcpy(filep+pl, spec, 0, &sl);
                                 file = fopen(filep, "w");
                              }

                              if (file)
                              {
                                 boolean ok = (fwrite(content, n, 1, file) == 1);
                                 fclose(file);

                                 if (ok && (cache || rename(tmpfp, filep) == no_error))
                                 {
                                    time_t updtstamp;
                                    char  *name, *check;
                                    el = articlePathAndName(entity, el, &name);
                                    if (name && (updtstamp = strtoul(name, &check, 10)) > 0
                                     && cmp6(check++, ".html"))               // for reindex() require matching of the strict filename specification
                                       reindex(droot, drootl, entity, el, updtstamp, request->serverTable, true);

                                    if (!cache)
                                       rc = 204;

                                    else if (response->content = allocate(filepl -= drootl+1, default_align, false))
                                    {
                                       response->contdyn = true;
                                       response->contlen = strmlcpy(response->content, filep+drootl+1, 0, &filepl);
                                       rc = 201;
                                    }
                                 }
                              }
                           }
                        }
                        else if (file)
                           fclose(file);
                     }
                     else if (file)
                        fclose(file);

                     if (cache)
                        deallocate(VPR(cache->content), false);

                     pthread_mutex_unlock(&EDIT_mutex);
                  }

                  deallocate(VPR(content), false);
               }
            }
         }
      }
      else
         return 0;
   }

   return rc;
}


void enumerateImageTags(Node **imageFileNames, char *contemp, time_t stamp, int prefixLen)
{
   char *p, *q = contemp;

   skip: while (p = strcasestr(q, "<img "))
   {
      char *u, *v = q;
      while (u = strcasestr(v, "<pre"))
      {
         if (u < p && p < (q = strcasestr(u, "</pre")))
            goto skip;
         v = u + 4;
      }

      boolean sglq = false,
              dblq = false;

      for (q = p += 5; *q != '>' || sglq || dblq; q++)
         if (*q == '\'')
            sglq = !sglq && !dblq;
         else if (*q == '"')
            dblq = !dblq && !sglq;
      *q++ = '\0';

      if ((p = strcasestr(p, "src")) && p < q)
      {
         for (; *p != '\'' && *p != '"'; p++);

         char *imgName = ++p;

         if (*(p-1) == '\'')
            for (; *p != '\''; p++);
         else if (*(p-1) == '"')
            for (; *p != '"'; p++);
         *p = '\0';

         if (strtoul(imgName+prefixLen, NULL, 10) == stamp)
            storeName(imageFileNames, uriDecode(imgName+prefixLen), 0, NULL);
      }
   }
}

#ifdef __APPLE__

   Node *findImageName(Node **imageFileNames, const char *name, ssize_t naml)
   {
      naml = utf8proc_map((uchar *)name, naml, (uchar **)&name, UTF8PROC_NULLTERM|UTF8PROC_COMPOSE);
      Node *result = (naml > 0)
                   ? findName(imageFileNames, name, naml)
                   : NULL;
      free((void *)name);
      return result;
   }

#else

   #define findImageName(imageFileNames, name, naml) findName(imageFileNames, name, naml)

#endif


void qdownsort(time_t *a, int l, int r)
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

boolean reindex(char *droot, int drootl, char *base, int bl, time_t updtstamp, Node **serverTable, boolean create_empty)
{
   int  adirl = drootl + 1 + bl + 1;  // articles directory, e.g.:  $DOCUMENT_ROOT/articles/
   int  mdofs = MEDIA_DIR_LEN + 1;
   int  mdirl = adirl + mdofs;        // extent for the media dir:  $DOCUMENT_ROOT/articles/media/
   char adir[OSP(mdirl+1)]; strmlcat(adir, mdirl+1, NULL, droot, drootl, "/", 1, base, bl, "/", 1, NULL);

   int   index_prefix_len,
         toc_prefix_len,
         articles_dir_len;

   char *index_prefix,
        *toc_prefix,
        *articles_dir = lastPathSegment(base, bl);

   if (cmp(articles_dir, ARTICLES_DIR, ARTICLES_DIR_SIZ))
   {
      index_prefix = INDEX_PREFIX,     index_prefix_len = INDEX_PREFIX_LEN;
      toc_prefix   = TOC_PREFIX,       toc_prefix_len   = TOC_PREFIX_LEN;
      articles_dir = ARTICLES_DIR,     articles_dir_len = ARTICLES_DIR_LEN;
      if (bl -= ARTICLES_DIR_LEN)
         cpy2(base+bl-1, "/");             // prepare the entity path (without the articles dir) for redirection
      else
         *base = '\0';
   }
   else
   {
      index_prefix = SUB_INDEX_PREFIX, index_prefix_len = SUB_INDEX_PREFIX_LEN;
      toc_prefix   = SUB_TOC_PREFIX,   toc_prefix_len   = SUB_TOC_PREFIX_LEN;
      articles_dir_len = bl - (int)(articles_dir - base);
      cpy2(base+bl++, "/");                // prepare the entity path (without the articles dir) for redirection
   }
   mdofs += articles_dir_len + 1;

   struct stat st;
   if (stat(adir, &st) == no_error && S_ISDIR(st.st_mode))
   {
      DIR *dp;
      if (dp = opendir(adir))
      {
         Node **imageFileNames = createTable(256);

         char *idx = newDynBuffer().buf;
         dynAddString((dynhdl)&idx, index_prefix, index_prefix_len);
         dynAddString((dynhdl)&idx, conTitle(serverTable), 0);
         dynAddString((dynhdl)&idx, INDEX_BODY_FYI, INDEX_BODY_FYI_LEN);

         char *toc = newDynBuffer().buf;
         dynAddString((dynhdl)&toc, toc_prefix, toc_prefix_len);

         struct dirent *ep, bp;
         int     fcnt = 0, fcap = 1024;
         time_t *stamps = allocate(fcap*sizeof(time_t), default_align, false);

         while (readdir_r(dp, &bp, &ep) == no_error && ep)
            if (ep->d_name[0] != '.' && (ep->d_type == DT_REG || ep->d_type == DT_LNK))
            {
               char  *check;
               time_t stamp = strtoul(ep->d_name, &check, 10);
               if (stamp && check && cmp6(check, ".html"))
               {
                  if (fcnt == fcap)
                     stamps = reallocate(stamps, (fcap += 1024)*sizeof(time_t), false, false);
                  stamps[fcnt++] = stamp;
               }
            }

         closedir(dp);

         if (fcnt > 1)
            qdownsort(stamps, 0, fcnt-1);

         if (fcnt)
            for (int j = 0; j < fcnt; j++)
            {
               FILE  *file;
               intStr stamp;
               int    stmpl = int2str(stamp, stamps[j], intLen, 0);
               int    artpl = adirl+stmpl+5;
               char   artp[OSP(artpl+1)];
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
                        char *o, *p, *q, *s, *t;
                        o = (strcasestr(contemp, "<HTML lang=")) ?: contemp;
                        if ((p = strcasestr(o += 5, "<TITLE>"))
                         && (q = strcasestr(p += 7, "</TITLE>"))
                         && (s =     strstr(q +  8, "<!--e-->"))
                         && (t = strcasestr(s += 8, "</P>")))
                        {
                           if (updtstamp == 0 || updtstamp == stamps[j])
                              enumerateImageTags(imageFileNames, s, stamps[j], mdofs);

                           boolean needEllipsis = !cmp16(t+6, "<p class=\"stamp\"");
                           boolean insertLangAttr = cmp7(o,   " lang=\"") && o[9] == '"';
                           struct tm tm; localtime_r(&stamps[j], &tm);

                           s = skip(s);
                           t = bskip(t);
                           dynAddString((dynhdl)&idx, "<A", 2);
                           if (insertLangAttr)
                              dynAddString((dynhdl)&idx, o, 10);
                           dynAddString((dynhdl)&idx, " id=\"", 5);
                              dynAddInt((dynhdl)&idx, stamps[j]);
                           dynAddString((dynhdl)&idx, "\" class=\"index\" href=\"", 22);
                           dynAddString((dynhdl)&idx, articles_dir, articles_dir_len);
                           dynAddString((dynhdl)&idx, "/", 1);
                              dynAddInt((dynhdl)&idx, stamps[j]);
                           dynAddString((dynhdl)&idx, ".html\">\n", 8);
                           dynAddString((dynhdl)&idx, s, stripATags(s, t-s));
                           if (needEllipsis)
                              dynAddString((dynhdl)&idx, " ...", 4);
                           dynAddString((dynhdl)&idx, "\n</p>\n<P class=\"stamp\">", 23);
                           dyninc((dynhdl)&idx, 28);
                           snprintf(idx+dynlen((dynptr){idx})-28, 29, "%04d-%02d-%02d %02d:%02d:%02d</P></A>\n",
                                                                      tm.tm_year+1900, tm.tm_mon+1, tm.tm_mday, tm.tm_hour, tm.tm_min, tm.tm_sec);

                           dynAddString((dynhdl)&toc, "   <A", 5);
                           if (insertLangAttr)
                              dynAddString((dynhdl)&toc, o, 10);
                           dynAddString((dynhdl)&toc, " href=\"", 7);
                           dynAddString((dynhdl)&toc, articles_dir, articles_dir_len);
                           dynAddString((dynhdl)&toc, "/", 1);
                              dynAddInt((dynhdl)&toc, stamps[j]);
                           dynAddString((dynhdl)&toc, ".html\" target=\"_top\"><P>", 24);
                           dynAddString((dynhdl)&toc, p, (int)(q-p));
                           dynAddString((dynhdl)&toc, "</P></A>\n", 9);
                        }
                     }

                     fclose(file);
                  }

                  deallocate(VPR(contemp), false);
               }
            }

         else if (create_empty || articles_dir == ARTICLES_DIR)
         {
            dynAddString((dynhdl)&idx, "<H1>No ", 7);
            dynAddString((dynhdl)&idx, articles_dir, articles_dir_len);
            dynAddString((dynhdl)&idx, " yet</H1>\n", 10);

            dynAddString((dynhdl)&toc, "<P>No ",  6);
            dynAddString((dynhdl)&toc, articles_dir, articles_dir_len);
            dynAddString((dynhdl)&toc, " yet</P>\n", 9);
         }

         else // do nothing, just clean-up and exit
         {
            deallocate(VPR(stamps), false);
            freeDynBuffer((dynptr){toc});
            freeDynBuffer((dynptr){idx});
            releaseTable(imageFileNames);
            return false;
         }

         deallocate(VPR(stamps), false);

         if (articles_dir == ARTICLES_DIR)
            articles_dir = "", articles_dir_len = 0;
         else
            articles_dir_len++;

         int index_suffix_len = INDEX_SUFFIX_LEN + articles_dir_len;
         dyninc((dynhdl)&idx, index_suffix_len);
         snprintf(idx+dynlen((dynptr){idx})-index_suffix_len, index_suffix_len+1, INDEX_SUFFIX, articles_dir);
         dynAddString((dynhdl)&toc, TOC_SUFFIX, TOC_SUFFIX_LEN);

         boolean ok1 = false, ok2 = false;

         int  idxfl = drootl + 1 + bl + 10 + 1;
         int  tocfl = drootl + 1 + bl +  8 + 1;
         char idxf[OSP(idxfl+1)];
         char tocf[OSP(tocfl+1)];
         if (bl == 0)
         {
            strmlcat(idxf, idxfl+1, NULL, droot, drootl, "/", 1, "index.html", 10, NULL);
            strmlcat(tocf, tocfl+1, NULL, droot, drootl, "/", 1, "toc.html", 8, NULL);
         }
         else
         {
            strmlcat(idxf, idxfl+1, NULL, droot, drootl, "/", 1, base, bl, "index.html", 10, NULL);
            strmlcat(tocf, tocfl+1, NULL, droot, drootl, "/", 1, base, bl, "toc.html", 8, NULL);
         }

         if ((stat(idxf, &st) != no_error || S_ISREG(st.st_mode) && unlink(idxf) == no_error)   // remove an old index.html file
          || (stat(tocf, &st) != no_error || S_ISREG(st.st_mode) && unlink(tocf) == no_error))  // remove an old toc.html file
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

            // touch the re-index token in the zettair index directory
            char *site = httpHost(serverTable);
            int   slen = strvlen(site);
            int   zlen = ZETTAIR_DB_PLEN + slen + 6;
            char  zetp[OSP(zlen+1)]; strmlcat(zetp, zlen+1, NULL, ZETTAIR_DB_PATH, ZETTAIR_DB_PLEN, site, slen, "/token", 6, NULL);
            if (file = fopen(zetp, "w"))
               fclose(file);
         }

         freeDynBuffer((dynptr){toc});
         freeDynBuffer((dynptr){idx});

         // image garbage collection in articles/media
         int l = MEDIA_DIR_LEN+1;
         strmlcpy(adir+adirl, MEDIA_DIR"/", MEDIA_DIR_LEN+2, &l);
         if (dp = opendir(adir))
         {
            while (readdir_r(dp, &bp, &ep) == no_error && ep)
               if (ep->d_name[0] != '.' && ep->d_type == DT_DIR
                && (updtstamp == 0 || updtstamp == strtoul(ep->d_name, NULL, 10)))
               {
                  int  mdl = mdirl + ep->d_namlen + 1;
                  char mdir[OSP(mdl+1)];
                  strmlcat(mdir, mdl+1, NULL, adir, mdirl, ep->d_name, ep->d_namlen, "/", 1, NULL);
                  DIR *mdp;
                  if (mdp = opendir(mdir))
                  {
                     int found = 0;
                     struct dirent *mep, mbp;
                     while (readdir_r(mdp, &mbp, &mep) == no_error && mep)
                        if (mep->d_name[0] != '.' && mep->d_type == DT_REG)
                        {
                           int  mfl = mdl + mep->d_namlen;
                           char mfil[OSP(mfl+5)];
                           strmlcat(mfil, mfl+1, NULL, mdir, mdl, mep->d_name, mep->d_namlen, NULL);
                           if (findImageName(imageFileNames, mfil+mdirl, ep->d_namlen + 1 + mep->d_namlen))
                              found++;
                           else
                           {
                              cpy5(mfil+mfl, ".png");
                              if (findImageName(imageFileNames, mfil+mdirl, ep->d_namlen + 1 + mep->d_namlen + 4))
                                 found++;
                              else
                              {
                                 mfil[mfl] = '\0';
                                 printf("unlink(%s);\n", mfil);
                              }
                           }
                        }

                     closedir(mdp);

                     if (found == 0)
                        printf("deleteDirEntity(%s, %d, S_IFDIR);\n", mdir, mdirl);
                  }
               }

            closedir(dp);
         }

         releaseTable(imageFileNames);

         return ok1 && ok2;
      }
   }

   return false;
}
