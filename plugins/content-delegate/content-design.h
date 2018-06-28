//  content-design.h
//  content-delegate and search-delegate
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


#define INDEX_PREFIX_LEN 402
#define INDEX_PREFIX \
"<!--S--><!DOCTYPE html><HTML><HEAD>\n"\
"   <TITLE>Résumés</TITLE>\n"\
"   <META http-equiv=\"content-type\" content=\"text/html; charset=utf-8\">\n"\
"   <LINK rel=\"stylesheet\" href=\"styles.css\" type=\"text/css\">\n"\
"   <LINK rel=\"icon\" href=\"/favicon.ico\" type=\"image/x-icon\">\n"\
"   <SCRIPT src=\"functions.js\"></SCRIPT>\n"\
"</HEAD><BODY><DIV class=\"page\"><TABLE>\n"\
"   <TR>\n"\
"      <TH style=\"width:675px;\">\n"\
"         <H1><A href=\"./\">"

#define INDEX_BODY_FYI_LEN 555
#define INDEX_BODY_FYI \
"</A></H1>\n"\
"      </TH>\n"\
"      <TH style=\"width:167px;\"><TABLE class=\"fyi\">\n"\
"         <TR><TH><A href=\"imprint.html\">Imprint</A></TH><TD><A href=\"impressum.html\">Impressum</A></TD></TR>\n"\
"         <TR><TH><A href=\"privacy.html\">Privacy</A></TH><TD><A href=\"datenschutz.html\">Datenschutz</TD></TR>\n"\
"         <TR><TH><A href=\"disclaimer.html\">Disclaimer</A></TH><TD><A href=\"haftung.html\">Haftung</TD></TR>\n"\
"      </TH></TABLE>\n"\
"      <TH style=\"width:96px;\">\n"\
"         <A href=\"/\"><IMG style=\"width:96px;\" src=\"logo.png\"></A>\n"\
"      </TH>\n"\
"   </TR>\n"\
"   <TR>\n"\
"      <TD>\n"

#define INDEX_SUFFIX_LEN 302
#define INDEX_SUFFIX \
"      </TD>\n"\
"      <TD colspan=\"2\" style=\"padding:9px 3px 3px 27px;\">\n"\
"         <IFRAME name=\"toc\" src=\"toc.html\" align=\"top\" style=\"width:100%; border:0px;\"\n"\
"               onload=\"this.style.height=this.contentDocument.body.scrollHeight+'px';\"></IFRAME>\n"\
"      </TD>\n"\
"   </TR>\n"\
"</TABLE></DIV></BODY><HTML>\n"

#define TOC_PREFIX_LEN 413
#define TOC_PREFIX \
"<!--S--><!DOCTYPE html><HTML><HEAD>\n"\
"   <TITLE>Table of Contents</TITLE>\n"\
"   <META http-equiv=\"content-type\" content=\"text/html; charset=utf-8\">\n"\
"   <LINK rel=\"stylesheet\" href=\"styles.css\" type=\"text/css\">\n"\
"   <SCRIPT src=\"functions.js\"></SCRIPT>\n"\
"</HEAD><BODY class=\"toc\">\n"\
"   <FORM action=\"_search\" method=\"POST\" target=\"_top\"><INPUT class=\"search\" name=\"search\" type=\"text\" placeholder=\"Search the Content\"></FORM>\n"\

#define TOC_SUFFIX_LEN 15
#define TOC_SUFFIX \
"</BODY></HTML>\n"


#define STAMP_DATA_LEN 24
#define STAMP_DATA \
"<data id=\"stamp\" value=\""

#define STAMP_VALUE_LEN 12
// "xx1530060745", 12

#define CLOSE_DATA_LEN 11
#define CLOSE_DATA \
"\"></data>\r\n"

#define STAMP_PREFIX_LEN 36
#define STAMP_PREFIX \
"<p class=\"stamp\">\r\n" \
"    Copyright © "

#define DATE_TIME_STAMP_LEN 24
//" – YYYY-MM-DD hh:mm:ss", 24

#define STAMP_SUFFIX_LEN 8
#define STAMP_SUFFIX \
"\r\n" \
"</p>\r\n"

#define SEARCH_PREFIX_LEN 425
#define SEARCH_PREFIX \
"<!DOCTYPE html><HTML><HEAD>\n"\
"   <TITLE>Search Results</TITLE>\n"\
"   <META http-equiv=\"content-type\" content=\"text/html; charset=utf-8\">\n"\
"   <LINK rel=\"stylesheet\" href=\"styles.css\" type=\"text/css\">\n"\
"   <LINK rel=\"icon\" href=\"/favicon.ico\" type=\"image/x-icon\">\n"\
"   <SCRIPT src=\"functions.js\"></SCRIPT>\n"\
"</HEAD><BODY><DIV class=\"page\"><TABLE>\n"\
"   <TR>\n"\
"      <TH style=\"width:675px;\">\n"\
"         <H1 style=\"line-height:29px;\"><A href=\"./\">"

#define SEARCH_BODY_FYI_LEN 634
#define SEARCH_BODY_FYI \
"</A><BR>\n"\
"         <SPAN style=\"font-size:19px;\">Search Results</SPAN></H1>\n"\
"      </TH>\n"\
"      <TH style=\"width:167px;\"><TABLE class=\"fyi\">\n"\
"         <TR><TH><A href=\"imprint.html\">Imprint</A></TH><TD><A href=\"impressum.html\">Impressum</A></TD></TR>\n"\
"         <TR><TH><A href=\"privacy.html\">Privacy</A></TH><TD><A href=\"datenschutz.html\">Datenschutz</TD></TR>\n"\
"         <TR><TH><A href=\"disclaimer.html\">Disclaimer</A></TH><TD><A href=\"haftung.html\">Haftung</TD></TR>\n"\
"      </TH></TABLE>\n"\
"      <TH style=\"width:96px;\">\n"\
"         <A href=\"/\"><IMG style=\"width:96px;\" src=\"logo.png\"></A>\n"\
"      </TH>\n"\
"   </TR>\n"\
"   <TR>\n"\
"      <TD class=\"found\">\n"

#define SEARCH_NORESULT_LEN 24
#define SEARCH_NORESULT \
"<H1>Nothing found.</H1>\n"

#define SEARCH_SUFFIX_LEN 302
#define SEARCH_SUFFIX \
"      </TD>\n"\
"      <TD colspan=\"2\" style=\"padding:9px 3px 3px 27px;\">\n"\
"         <IFRAME name=\"toc\" src=\"toc.html\" align=\"top\" style=\"width:100%; border:0px;\"\n"\
"               onload=\"this.style.height=this.contentDocument.body.scrollHeight+'px';\"></IFRAME>\n"\
"      </TD>\n"\
"   </TR>\n"\
"</TABLE></DIV></BODY><HTML>\n"
