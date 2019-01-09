//  tweetit.c
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


#include <stdlib.h>
#include <stdio.h>
#include <stddef.h>
#include <fcntl.h>
#include <errno.h>
#include <string.h>
#include <time.h>
#include <math.h>
#include <syslog.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/time.h>

#include "utils.h"


#define MAX_TWEET_LENGTH 280
#define TIMESTAMP_LENGTH 19
#define TWEET_URL_LENGTH 13

void usage(const char *executable)
{
   const char *r = executable + strvlen(executable);
   while (--r >= executable && *r != '/'); r++;
   printf("\nusage: %s [-t timestamp] [-u basurl] <HTML article file>\n", r);
}

int stripTags(uchar *s, ssize_t n)
{
   int i, j;

   for (i = 0, j = 0; i < n; i++)
      switch (s[i])
      {
         case '<':
            if (s[i+1] == 'a' || s[i+1] == 'A'
             || s[i+1] == 'p' || s[i+1] == 'P'
             || s[i+1] == 'h' || s[i+1] == 'H')
            {
               for (i += 2; s[i] != '>'; i++);
               for (i += 1; s[i] <= ' '; i++);
               --i;
               break;
            }

            else if (cmp2(s+i+1, "/a") || cmp2(s+i+1, "/A")
                  || cmp2(s+i+1, "/h") || cmp2(s+i+1, "/H")
                  || cmp2(s+i+1, "/p") || cmp2(s+i+1, "/P"))
            {
               for (i += 3; s[i] != '>'; i++);
               for (i += 1; s[i] <= ' '; i++);
               --i;
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


int main(int argc, char *const argv[])
{
   int         ch, bl = 0;
   time_t      tmstamp  = 0;
   char       *baseurl  = NULL;
   const char *command = argv[0];

   while ((ch = getopt(argc, argv, "bt:u:h")) != -1)
   {
      switch (ch)
      {
         case 't':
            tmstamp = strtol(optarg, NULL, 10);
            break;

         case 'u':
            baseurl = optarg;
            for (bl = strvlen(baseurl); baseurl[bl-1] == '/'; bl--);
            break;

         case 'h':
         default:
            usage(command);
            exit(0);
            break;
      }
   }
   argc -= optind;
   argv += optind;

   if (argc != 1 || argv[0][0] == '?' && argv[0][1] == '\0')
   {
      usage(command);
      exit(0);
   }

   FILE  *infile;
   struct stat st;
   char  *content = NULL;
   char  *artname = argv[0];

   if (stat(artname, &st) == no_error)
      if (content = allocate(st.st_size+1, default_align, false))
         if (infile = fopen(artname, "r"))
            if (fread(content, st.st_size, 1, infile) == 1)
            {
               content[st.st_size] = '\0';
               fclose(infile);

               char *tweet = newDynBuffer().buf;

               char *o, *p, *q, *s, *t;
               o = content;
               if ((p = strcasestr(o += 5, "<TITLE>"))
                && (q = strcasestr(p += 7, "</TITLE>"))
                && (s =     strstr(q +  8, "<!--e-->"))
                && (t = strcasestr(s += 8, "</P>")))
               {
                  struct tm tm;

                  s = skip(s);
                  t = bskip(t);

                  int n = stripTags((uchar *)s, t-s);
                  int m = mini(n, MAX_TWEET_LENGTH
                                  - 3
                                  - ((tmstamp) ? 1 + TIMESTAMP_LENGTH : 0)
                                  - ((baseurl) ? 1 + TWEET_URL_LENGTH : 0));

                  if (m < n)
                  {
                     for (p = s; p - s <= m; getu(&p))
                        q = p;
                     m = (int)(q - s);
                  }

                  dynAddString((dynhdl)&tweet, s, m);

                  if (m < n)
                     dynAddString((dynhdl)&tweet, "…", 3);

                  if (tmstamp)
                  {
                     localtime_r(&tmstamp, &tm);
                     n = dynlen((dynptr){tweet});
                     snprintf(tweet+n, DYNAMIC_BUFFER_MARGIN, "\n%04d-%02d-%02d %02d:%02d:%02d", tm.tm_year+1900, tm.tm_mon+1, tm.tm_mday, tm.tm_hour, tm.tm_min, tm.tm_sec);
                     dyninc((dynhdl)&tweet, 20);
                  }

                  if (baseurl)
                  {
                     n = strvlen(artname);
                     for (q = artname+n-1; *q != '/'; q--);
                     dynAddString((dynhdl)&tweet, "\n", 1);
                     dynAddString((dynhdl)&tweet, baseurl, bl);
                     dynAddString((dynhdl)&tweet, q, n - (int)(q - artname));
                  }
               }

               printf("%s\n", tweet);

               freeDynBuffer((dynptr){tweet});
               deallocate(VPR(content), false);
            }

            else
            {
               fclose(infile);
               deallocate(VPR(content), false);
               printf("Could not read the content of the HTML article file '%s'.\n", artname);
            }

         else
         {
            deallocate(VPR(content), false);
            printf("Could not open the HTML article file '%s' for reading.\n", artname);
         }

      else
         printf("Not enough memory for reading the contents of the HTML article file '%s'.\n", artname);

   else
      printf("The HTML article file '%s' does not exist.\n", artname);

   return 0;
}
