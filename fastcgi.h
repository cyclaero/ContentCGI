//  fastcgi.h
//  ContentCGI
//
//  Defines for the FastCGI protocol.
//  Copyright © 1995-1996 Open Market, Inc.
//  Copyright © 2018-2021 Dr. Rolf Jansen Ltda. All rights reserved.
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

// CGI 1.1 - https://tools.ietf.org/html/rfc3875
//  FastCGI Specification - https://fastcgi-archives.github.io/FastCGI_Specification.html
//   and more information - https://fastcgi-archives.github.io
// FastCGI Implementation - https://github.com/FastCGI-Archives

// The following is the original Open Market License for the FastCGI protocol, reproduced and
// adapted in the present header file "fastcgi.h". These terms are meant to be informational
// only, and DO NOT apply to any of the copyrighted sources in the present software package.
//
//  The Open Market License
//
//  This FastCGI application library source and object code (the "Software") and
//  its documentation (the "Documentation") are copyrighted by Open Market, Inc
//  ("Open Market").  The following terms apply to all files associated with the
//  Software and Documentation unless explicitly disclaimed in individual files.
//
//  Open Market permits you to use, copy, modify, distribute, and license this Software
//  and the Documentation for any purpose, provided that existing copyright notices are
//  retained in all copies and that this notice is included verbatim in any distributions.
//  No written agreement, license, or royalty fee is required for any of the authorized
//  uses.  Modifications to this Software and Documentation may be copyrighted by their
//  authors and need not follow the licensing terms described here.  If modifications to
//  this Software and Documentation have new licensing terms, the new terms must be clearly
//  indicated on the first page of each file where they apply.
//
//  OPEN MARKET MAKES NO EXPRESS OR IMPLIED WARRANTY WITH RESPECT TO THE SOFTWARE OR THE
//  DOCUMENTATION, INCLUDING WITHOUT LIMITATION ANY WARRANTY OF MERCHANTABILITY OR FITNESS
//  FOR A PARTICULAR PURPOSE.  IN NO EVENT SHALL OPEN MARKET BE LIABLE TO YOU OR ANY THIRD
//  PARTY FOR ANY DAMAGES ARISING FROM OR RELATING TO THIS SOFTWARE OR THE DOCUMENTATION,
//  INCLUDING, WITHOUT LIMITATION, ANY INDIRECT, SPECIAL OR CONSEQUENTIAL DAMAGES OR SIMILAR
//  DAMAGES, INCLUDING LOST PROFITS OR LOST DATA, EVEN IF OPEN MARKET HAS BEEN ADVISED OF
//  THE POSSIBILITY OF SUCH DAMAGES.  THE SOFTWARE AND DOCUMENTATION ARE PROVIDED "AS IS".
//  OPEN MARKET HAS NO LIABILITY IN CONTRACT, TORT, NEGLIGENCE OR OTHERWISE ARISING OUT OF
//  THIS SOFTWARE OR THE DOCUMENTATION.


typedef struct
{
   uint8_t  version;
   uint8_t  type;
   uint16_t requestID;
   uint16_t contentLength;
   uint8_t  paddingLength;
   uint8_t  reserved;
} FCGI_Header;

#define FCGI_HEADER_LEN          8
#define FCGI_VERSION_1           1

#define FCGI_MAX_LENGTH          0xffff
#define FCGI_PAD_LENGTH          0xff

// Values for type component of FCGI_Header
#define FCGI_BEGIN_REQUEST       1
#define FCGI_ABORT_REQUEST       2
#define FCGI_END_REQUEST         3
#define FCGI_PARAMS              4
#define FCGI_STDIN               5
#define FCGI_STDOUT              6
#define FCGI_STDERR              7
#define FCGI_DATA                8
#define FCGI_GET_VALUES          9
#define FCGI_GET_VALUES_RESULT  10
#define FCGI_UNKNOWN_TYPE       11
#define FCGI_MAXTYPE (FCGI_UNKNOWN_TYPE)

// Value for requestID component of FCGI_Header
#define FCGI_NULL_REQUEST_ID     0


typedef struct
{
   uint16_t role;
   uint8_t  flags;
   uint8_t  reserved[5];
} FCGI_BeginRequestBody;

typedef struct
{
   FCGI_Header           header;
   FCGI_BeginRequestBody body;
} FCGI_BeginRequestRecord;

// Mask for flags component of FCGI_BeginRequestBody
#define FCGI_KEEP_CONN  1

// Values for role component of FCGI_BeginRequestBody
#define FCGI_RESPONDER  1
#define FCGI_AUTHORIZER 2
#define FCGI_FILTER     3


typedef struct
{
   uint32_t appStatus;
   uint8_t  protocolStatus;
   uint8_t  reserved[3];
} FCGI_EndRequestBody;

typedef struct
{
   FCGI_Header         header;
   FCGI_EndRequestBody body;
} FCGI_EndRequestRecord;

// Values for protocolStatus component of FCGI_EndRequestBody
#define FCGI_REQUEST_COMPLETE 0
#define FCGI_CANT_MPX_CONN    1
#define FCGI_OVERLOADED       2
#define FCGI_UNKNOWN_ROLE     3

// Variable names for FCGI_GET_VALUES / FCGI_GET_VALUES_RESULT records
// FCGI_MAX_CONNS:  The maximum number of concurrent transport connections this application will accept, e.g. "1" or "10".
// FCGI_MAX_REQS:   The maximum number of concurrent requests this application will accept, e.g. "1" or "50".
// FCGI_MPXS_CONNS: "0" if this application does not multiplex connections (i.e. handle concurrent requests over each connection), "1" otherwise.
#define FCGI_MAX_CONNS  "FCGI_MAX_CONNS"
#define FCGI_MAX_REQS   "FCGI_MAX_REQS"
#define FCGI_MPXS_CONNS "FCGI_MPXS_CONNS"


typedef struct
{
   uint8_t  type;
   uint8_t  reserved[7];
} FCGI_UnknownTypeBody;

typedef struct
{
   FCGI_Header          header;
   FCGI_UnknownTypeBody body;
} FCGI_UnknownTypeRecord;


typedef struct
{
   uint8_t  nameLength;  // (*(uint8_t *)&nameLength  & 0x80) == 0
   uint8_t  valueLength; // (*(uint8_t *)&valueLength & 0x80) == 0
   uint8_t *nameData;    // buffer of length nameLength
   uint8_t *valueData;   // buffer of length valueLength
} FCGI_NameValuePair11;

typedef struct
{
   uint8_t  nameLength;  // (*(uint8_t *)&nameLength  & 0x80) == 0
   uint32_t valueLength; // (*(uint8_t *)&valueLength & 0x80) == 1
   uint8_t *nameData;    // buffer of length nameLength
   uint8_t *valueData;   // buffer of length MapInt32(valueLength)
} FCGI_NameValuePair14;

typedef struct
{
   uint32_t nameLength;  // (*(uint8_t *)&nameLength  & 0x80) == 1
   uint8_t  valueLength; // (*(uint8_t *)&valueLength & 0x80) == 0
   uint8_t *nameData;    // buffer of length MapInt32(nameLength)
   uint8_t *valueData;   // buffer of length valueLength
} FCGI_NameValuePair41;

typedef struct
{
   uint32_t nameLength;  // (*(uint8_t *)&nameLength  & 0x80) == 1
   uint32_t valueLength; // (*(uint8_t *)&valueLength & 0x80) == 1
   uint8_t *nameData;    // buffer of length MapInt32(nameLength)
   uint8_t *valueData;   // buffer of length MapInt32(valueLength)
} FCGI_NameValuePair44;


boolean FCGI_Receiver(ConnExec *connex);

boolean FCGI_SendEndRequest(ConnExec *connex, uint32_t appStatus, uint8_t protocolStatus);
boolean FCGI_SendValueResults(ConnExec *connex, ushort requestID, ushort resultsLength, uint8_t *results);
boolean FCGI_SendDataStream(ConnExec *connex, uint8_t streamType, size_t totalLength, char *data);
