//  delegate-utils.h
//  Responder Delegate plugins
//
//  Created by Dr. Rolf Jansen on 2018-05-15.
//  Copyright © 2018-2021 Dr. Rolf Jansen. All rights reserved.
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


#include <stdio.h>
#include <stdlib.h>
#include <stddef.h>
#include <stdarg.h>
#include <ctype.h>
#include <dirent.h>
#include <fcntl.h>
#include <errno.h>
#include <string.h>
#include <time.h>
#include <fenv.h>
#include <math.h>
#include <complex.h>
#include <pthread.h>
#include <syslog.h>
#include <unistd.h>
#include <sys/stat.h>

#include <utf8proc.h>


#pragma mark ••• Utilities & Facilities •••

#define no_error 0
#ifndef false
#define false ((boolean)0)
#endif

#ifndef true
#define true  ((boolean)1)
#endif

typedef int                boolean;

typedef long long          llong;

typedef unsigned char      uchar;
typedef unsigned short     ushort;
typedef unsigned int       uint;
typedef unsigned long      ulong;
typedef unsigned long long ullong;

typedef unsigned int       utf8;
typedef unsigned int       utf32;

typedef void              *opaque;

typedef enum
{
   undefined = -1,
   invalid   =  false,
   valid     =  true
} tris;


#if __BYTE_ORDER__ == __ORDER_LITTLE_ENDIAN__

// PickXXX-Routine are for picking data out of or
// the PostgreSQL database that tranfers binary data
// in Network Byte Order, that is big endian.
// i386 machines operate on data in little endian
// byte order, therefore byte swapping is necessary.
   #define PickInt(x)    SwapInt32(*(int32_t *)(x))
   #define PickInt64(x)  SwapInt64(*(int64_t *)(x))
   #define PickDouble(x) SwapDouble(*(double *)(x))

   #define MapShort(x)   SwapInt16(x)
   #define MapInt(x)     SwapInt32(x)
   #define MapInt64(x)   SwapInt64(x)
   #define MapDouble(x)  SwapDouble(x)

   #define TwoChars(x)   (uint16_t)SwapInt16(*(uint16_t *)(x))
   #define ThreeChars(x) (uint32_t)SwapTri24(*(uint32_t *)(x))
   #define FourChars(x)  (uint32_t)SwapInt32(*(uint32_t *)(x))

   #if (defined(__i386__) || defined(__x86_64__)) && defined(__GNUC__)

      static inline uint16_t SwapInt16(uint16_t x)
      {
         __asm__("rolw $8,%0" : "+q" (x));
         return x;
      }

      static inline uint32_t SwapInt32(uint32_t x)
      {
         __asm__("bswapl %0" : "+q" (x));
         return x;
      }

   #else

      static inline uint16_t SwapInt16(uint16_t x)
      {
         uint16_t z;
         char *p = (char *)&x;
         char *q = (char *)&z;

         q[0] = p[1];
         q[1] = p[0];

         return z;
      }

      static inline uint32_t SwapInt32(uint32_t x)
      {
         uint32_t z;
         char *p = (char *)&x;
         char *q = (char *)&z;

         q[0] = p[3];
         q[1] = p[2];
         q[2] = p[1];
         q[3] = p[0];

         return z;
      }

   #endif

   #if defined(__x86_64__) && defined(__GNUC__)

      static inline uint64_t SwapInt64(uint64_t x)
      {
         __asm__("bswapq %0" : "+q" (x));
         return x;
      }

   #else

      static inline uint64_t SwapInt64(uint64_t x)
      {
         uint64_t z;
         char *p = (char *)&x;
         char *q = (char *)&z;

         q[0] = p[7];
         q[1] = p[6];
         q[2] = p[5];
         q[3] = p[4];
         q[4] = p[3];
         q[5] = p[2];
         q[6] = p[1];
         q[7] = p[0];

         return z;
      }

   #endif

#elif __BYTE_ORDER__ == __ORDER_BIG_ENDIAN__

// ppc machines operate on data in big endian
// byte order, therefore NO byte swapping is necessary.
   #define PickInt(x)    *(int32_t *)(x)
   #define PickInt64(x)  *(int64_t *)(x)
   #define PickDouble(x) *(double *)(x)

   #define MapShort(x)   (x)
   #define MapInt(x)     (x)
   #define MapInt64(x)   (x)
   #define MapDouble(x)  (x)

   #define TwoChars(x)   *(uint16_t *)(x)
   #define ThreeChars(x) *(uint32_t *)(x) >> 8
   #define FourChars(x)  *(uint32_t *)(x)

   #if defined(__ppc__) && defined(__GNUC__)

      static inline uint16_t SwapInt16(uint16_t x)
      {
         uint16_t z;
         __asm__("lhbrx %0,0,%1" : "=r" (z) : "r" (&x), "m" (x));
         return z;
      }

   #else

      static inline uint16_t SwapInt16(uint16_t x)
      {
         uint16_t z;
         char *p = (char *)&x;
         char *q = (char *)&z;

         q[0] = p[1];
         q[1] = p[0];

         return z;
      }

   #endif

   static inline uint32_t SwapInt32(uint32_t x)
   {
      uint32_t z;
      char *p = (char *)&x;
      char *q = (char *)&z;

      q[0] = p[3];
      q[1] = p[2];
      q[2] = p[1];
      q[3] = p[0];

      return z;
   }

   static inline uint64_t SwapInt64(uint64_t x)
   {
      uint64_t z;
      char *p = (char *)&x;
      char *q = (char *)&z;

      q[0] = p[7];
      q[1] = p[6];
      q[2] = p[5];
      q[3] = p[4];
      q[4] = p[3];
      q[5] = p[2];
      q[6] = p[1];
      q[7] = p[0];

      return z;
   }

#endif

static inline uint32_t SwapTri24(uint32_t x)
{
   uint32_t z;
   char *p = (char *)&x;
   char *q = (char *)&z;

   q[0] = p[2];
   q[1] = p[1];
   q[2] = p[0];
   q[3] = 0;

   return z;
}

static inline double SwapDouble(double x)
{
   double z;
   char *p = (char *)&x;
   char *q = (char *)&z;

   q[0] = p[7];
   q[1] = p[6];
   q[2] = p[5];
   q[3] = p[4];
   q[4] = p[3];
   q[5] = p[2];
   q[6] = p[1];
   q[7] = p[0];

   return z;
}


static inline char LoChar(char c)
{
   return ('A' <= c && c <= 'Z') ? c + 0x20 : c;
}

static inline char UpChar(char c)
{
   return ('a' <= c && c <= 'z') ? c - 0x20 : c;
}

static inline uint32_t FourLoChars(char c[4])
{
   char C[4] = {LoChar(c[0]), LoChar(c[1]), LoChar(c[2]), LoChar(c[3])};
   return MapInt(*(uint32_t *)C);
}

static inline uint32_t FourUpChars(char c[4])
{
   char C[4] = {UpChar(c[0]), UpChar(c[1]), UpChar(c[2]), UpChar(c[3])};
   return MapInt(*(uint32_t *)C);
}

static inline char *lowercase(char *s)
{
   if (s)
   {
      char c, *p = s;
      while (c = *p)
         if ('A' <= c && c <= 'Z')
            *p++ = c + 0x20;
         else
            p++;
   }
   return s;
}

static inline char *uppercase(char *s)
{
   if (s)
   {
      char c, *p = s;
      while (c = *p)
         if ('a' <= c && c <= 'z')
            *p++ = c - 0x20;
         else
            p++;
   }
   return s;
}


#if defined(__x86_64__)

   #include <x86intrin.h>

   static const __m128i nul16 = {0x0000000000000000ULL, 0x0000000000000000ULL};  // 16 bytes with nul
   static const __m128i lfd16 = {0x0A0A0A0A0A0A0A0AULL, 0x0A0A0A0A0A0A0A0AULL};  // 16 bytes with line feed '\n'
   static const __m128i vtt16 = {0x0B0B0B0B0B0B0B0BULL, 0x0B0B0B0B0B0B0B0BULL};  // 16 bytes with vertical tabs '\v'
   static const __m128i col16 = {0x3A3A3A3A3A3A3A3AULL, 0x3A3A3A3A3A3A3A3AULL};  // 16 bytes with colon ':'
   static const __m128i grt16 = {0x3E3E3E3E3E3E3E3EULL, 0x3E3E3E3E3E3E3E3EULL};  // 16 bytes with greater sign '>'
   static const __m128i vtl16 = {0x7C7C7C7C7C7C7C7CULL, 0x7C7C7C7C7C7C7C7CULL};  // 16 bytes with vertical line '|'
   static const __m128i dot16 = {0x2E2E2E2E2E2E2E2EULL, 0x2E2E2E2E2E2E2E2EULL};  // 16 bytes with dots '.'
   static const __m128i sls16 = {0x2F2F2F2F2F2F2F2FULL, 0x2F2F2F2F2F2F2F2FULL};  // 16 bytes with slashes '/'
   static const __m128i amp16 = {0x2626262626262626ULL, 0x2626262626262626ULL};  // 16 bytes with ampersand '&'
   static const __m128i equ16 = {0x3D3D3D3D3D3D3D3DULL, 0x3D3D3D3D3D3D3D3DULL};  // 16 bytes with equal signs '='
   static const __m128i blk16 = {0x2020202020202020ULL, 0x2020202020202020ULL};  // 16 bytes with inner blank limit
   static const __m128i obl16 = {0x2121212121212121ULL, 0x2121212121212121ULL};  // 16 bytes with outer blank limit

   // Drop-in replacement for strlen() and memcpy(), utilizing some builtin SSSE3 instructions
   static inline int strvlen(const char *str)
   {
      if (!str || !*str)
         return 0;

      unsigned bmask;
      if (bmask = (unsigned)_mm_movemask_epi8(_mm_cmpeq_epi8(_mm_loadu_si128((__m128i *)str), nul16)))
         return __builtin_ctz(bmask);

      for (int len = 16 - (uintptr_t)str%16;; len += 16)
         if (bmask = (unsigned)_mm_movemask_epi8(_mm_cmpeq_epi8(_mm_load_si128((__m128i *)&str[len]), nul16)))
            return len + __builtin_ctz(bmask);
   }


#ifndef __clang_analyzer__

   static inline void memvcpy(void *dst, const void *src, size_t n)
   {
      size_t k;

      switch (n)
      {
         default:
            if ((uintptr_t)dst&0xF || (uintptr_t)src&0xF)
               for (k = 0; k  < n>>4<<1; k += 2)
                  ((uint64_t *)dst)[k] = ((uint64_t *)src)[k], ((uint64_t *)dst)[k+1] = ((uint64_t *)src)[k+1];
            else
               for (k = 0; k  < n>>4; k++)
                  _mm_store_si128(&((__m128i *)dst)[k], _mm_load_si128(&((__m128i *)src)[k]));
         case 8 ... 15:
            if ((k = n>>4<<1) < n>>3)
               ((uint64_t *)dst)[k] = ((uint64_t *)src)[k];
         case 4 ... 7:
            if ((k = n>>3<<1) < n>>2)
               ((uint32_t *)dst)[k] = ((uint32_t *)src)[k];
         case 2 ... 3:
            if ((k = n>>2<<1) < n>>1)
               ((uint16_t *)dst)[k] = ((uint16_t *)src)[k];
         case 1:
            if ((k = n>>1<<1) < n)
               (( uint8_t *)dst)[k] = (( uint8_t *)src)[k];
         case 0:
            ;
      }
   }

#else

   #define memvcpy(d,s,n) memcpy(d,s,n)

#endif


   static inline int linelen(const char *line)
   {
      if (!line || !*line)
         return 0;

      unsigned bmask;
      if (bmask = (unsigned)_mm_movemask_epi8(_mm_cmpeq_epi8(_mm_loadu_si128((__m128i *)line), nul16))
                | (unsigned)_mm_movemask_epi8(_mm_cmpeq_epi8(_mm_loadu_si128((__m128i *)line), lfd16)))
         return __builtin_ctz(bmask);

      for (int len = 16 - (uintptr_t)line%16;; len += 16)
         if (bmask = (unsigned)_mm_movemask_epi8(_mm_cmpeq_epi8(_mm_load_si128((__m128i *)&line[len]), nul16))
                   | (unsigned)_mm_movemask_epi8(_mm_cmpeq_epi8(_mm_load_si128((__m128i *)&line[len]), lfd16)))
            return len + __builtin_ctz(bmask);
   }

   static inline int sectlen(const char *sect)
   {
      if (!sect || !*sect)
         return 0;

      unsigned bmask;
      if (bmask = (unsigned)_mm_movemask_epi8(_mm_cmpeq_epi8(_mm_loadu_si128((__m128i *)sect), nul16))
                | (unsigned)_mm_movemask_epi8(_mm_cmpeq_epi8(_mm_loadu_si128((__m128i *)sect), vtt16)))
         return __builtin_ctz(bmask);

      for (int len = 16 - (uintptr_t)sect%16;; len += 16)
         if (bmask = (unsigned)_mm_movemask_epi8(_mm_cmpeq_epi8(_mm_load_si128((__m128i *)&sect[len]), nul16))
                   | (unsigned)_mm_movemask_epi8(_mm_cmpeq_epi8(_mm_load_si128((__m128i *)&sect[len]), vtt16)))
            return len + __builtin_ctz(bmask);
   }

   static inline int collen(const char *col)
   {
      if (!col || !*col)
         return 0;

      unsigned bmask;
      if (bmask = (unsigned)_mm_movemask_epi8(_mm_cmpeq_epi8(_mm_loadu_si128((__m128i *)col), nul16))
                | (unsigned)_mm_movemask_epi8(_mm_cmpeq_epi8(_mm_loadu_si128((__m128i *)col), col16)))
         return __builtin_ctz(bmask);

      for (int len = 16 - (uintptr_t)col%16;; len += 16)
         if (bmask = (unsigned)_mm_movemask_epi8(_mm_cmpeq_epi8(_mm_load_si128((__m128i *)&col[len]), nul16))
                   | (unsigned)_mm_movemask_epi8(_mm_cmpeq_epi8(_mm_load_si128((__m128i *)&col[len]), col16)))
            return len + __builtin_ctz(bmask);
   }

   static inline int taglen(const char *tag)
   {
      if (!tag || !*tag)
         return 0;

      unsigned bmask;
      if (bmask = (unsigned)_mm_movemask_epi8(_mm_cmpeq_epi8(_mm_loadu_si128((__m128i *)tag), nul16))
                | (unsigned)_mm_movemask_epi8(_mm_cmpeq_epi8(_mm_loadu_si128((__m128i *)tag), grt16)))
         return __builtin_ctz(bmask);

      for (int len = 16 - (uintptr_t)tag%16;; len += 16)
         if (bmask = (unsigned)_mm_movemask_epi8(_mm_cmpeq_epi8(_mm_load_si128((__m128i *)&tag[len]), nul16))
                   | (unsigned)_mm_movemask_epi8(_mm_cmpeq_epi8(_mm_load_si128((__m128i *)&tag[len]), grt16)))
            return len + __builtin_ctz(bmask);
   }

   static inline int fieldlen(const char *field)
   {
      if (!field || !*field)
         return 0;

      unsigned bmask;
      if (bmask = (unsigned)_mm_movemask_epi8(_mm_cmpeq_epi8(_mm_loadu_si128((__m128i *)field), nul16))
                | (unsigned)_mm_movemask_epi8(_mm_cmpeq_epi8(_mm_loadu_si128((__m128i *)field), vtl16)))
         return __builtin_ctz(bmask);

      for (int len = 16 - (uintptr_t)field%16;; len += 16)
         if (bmask = (unsigned)_mm_movemask_epi8(_mm_cmpeq_epi8(_mm_load_si128((__m128i *)&field[len]), nul16))
                   | (unsigned)_mm_movemask_epi8(_mm_cmpeq_epi8(_mm_load_si128((__m128i *)&field[len]), vtl16)))
            return len + __builtin_ctz(bmask);
   }

   static inline int domlen(const char *domain)
   {
      if (!domain || !*domain)
         return 0;

      unsigned bmask;
      if (bmask = (unsigned)_mm_movemask_epi8(_mm_cmpeq_epi8(_mm_loadu_si128((__m128i *)domain), nul16))
                | (unsigned)_mm_movemask_epi8(_mm_cmpeq_epi8(_mm_loadu_si128((__m128i *)domain), dot16)))
         return __builtin_ctz(bmask);

      for (int len = 16 - (uintptr_t)domain%16;; len += 16)
         if (bmask = (unsigned)_mm_movemask_epi8(_mm_cmpeq_epi8(_mm_load_si128((__m128i *)&domain[len]), nul16))
                   | (unsigned)_mm_movemask_epi8(_mm_cmpeq_epi8(_mm_load_si128((__m128i *)&domain[len]), dot16)))
            return len + __builtin_ctz(bmask);
   }

   static inline int segmlen(const char *segm)
   {
      if (!segm || !*segm)
         return 0;

      unsigned bmask;
      if (bmask = (unsigned)_mm_movemask_epi8(_mm_cmpeq_epi8(_mm_loadu_si128((__m128i *)segm), nul16))
                | (unsigned)_mm_movemask_epi8(_mm_cmpeq_epi8(_mm_loadu_si128((__m128i *)segm), sls16)))
         return __builtin_ctz(bmask);

      for (int len = 16 - (uintptr_t)segm%16;; len += 16)
         if (bmask = (unsigned)_mm_movemask_epi8(_mm_cmpeq_epi8(_mm_load_si128((__m128i *)&segm[len]), nul16))
                   | (unsigned)_mm_movemask_epi8(_mm_cmpeq_epi8(_mm_load_si128((__m128i *)&segm[len]), sls16)))
            return len + __builtin_ctz(bmask);
   }

   static inline int vdeflen(const char *vardef)
   {
      if (!vardef || !*vardef)
         return 0;

      unsigned bmask;
      if (bmask = (unsigned)_mm_movemask_epi8(_mm_cmpeq_epi8(_mm_loadu_si128((__m128i *)vardef), nul16))
                | (unsigned)_mm_movemask_epi8(_mm_cmpeq_epi8(_mm_loadu_si128((__m128i *)vardef), amp16)))
         return __builtin_ctz(bmask);

      for (int len = 16 - (uintptr_t)vardef%16;; len += 16)
         if (bmask = (unsigned)_mm_movemask_epi8(_mm_cmpeq_epi8(_mm_load_si128((__m128i *)&vardef[len]), nul16))
                   | (unsigned)_mm_movemask_epi8(_mm_cmpeq_epi8(_mm_load_si128((__m128i *)&vardef[len]), amp16)))
            return len + __builtin_ctz(bmask);
   }

   static inline int vnamlen(const char *varname)
   {
      if (!varname || !*varname)
         return 0;

      unsigned bmask;
      if (bmask = (unsigned)_mm_movemask_epi8(_mm_cmpeq_epi8(_mm_loadu_si128((__m128i *)varname), nul16))
                | (unsigned)_mm_movemask_epi8(_mm_cmpeq_epi8(_mm_loadu_si128((__m128i *)varname), equ16)))
         return __builtin_ctz(bmask);

      for (int len = 16 - (uintptr_t)varname%16;; len += 16)
         if (bmask = (unsigned)_mm_movemask_epi8(_mm_cmpeq_epi8(_mm_load_si128((__m128i *)&varname[len]), nul16))
                   | (unsigned)_mm_movemask_epi8(_mm_cmpeq_epi8(_mm_load_si128((__m128i *)&varname[len]), equ16)))
            return len + __builtin_ctz(bmask);
   }

   static inline int wordlen(const char *word)
   {
      if (!word || !*word)
         return 0;

      unsigned bmask;
      if (bmask = (unsigned)_mm_movemask_epi8(_mm_cmpeq_epi8(blk16, _mm_max_epu8(blk16, _mm_loadu_si128((__m128i *)word)))))
         return __builtin_ctz(bmask);      // ^^^^^^^ unsigned comparison (a >= b) is identical to a == maxu(a, b) ^^^^^^^

      for (int len = 16 - (uintptr_t)word%16;; len += 16)
         if (bmask = (unsigned)_mm_movemask_epi8(_mm_cmpeq_epi8(blk16, _mm_max_epu8(blk16, _mm_load_si128((__m128i *)&word[len])))))
            return len + __builtin_ctz(bmask);
   }

   static inline int blanklen(const char *blank)
   {
      if (!blank || !*blank)
         return 0;

      unsigned bmask;
      if (bmask = (unsigned)_mm_movemask_epi8(_mm_cmpeq_epi8(_mm_loadu_si128((__m128i *)blank), nul16))
                | (unsigned)_mm_movemask_epi8(_mm_cmpeq_epi8(obl16, _mm_min_epu8(obl16, _mm_loadu_si128((__m128i *)blank)))))
         return __builtin_ctz(bmask);      // ^^^^^^^ unsigned comparison (a <= b) is identical to a == minu(a, b) ^^^^^^^

      for (int len = 16 - (uintptr_t)blank%16;; len += 16)
         if (bmask = (unsigned)_mm_movemask_epi8(_mm_cmpeq_epi8(_mm_load_si128((__m128i *)&blank[len]), nul16))
                   | (unsigned)_mm_movemask_epi8(_mm_cmpeq_epi8(obl16, _mm_min_epu8(obl16, _mm_load_si128((__m128i *)&blank[len])))))
            return len + __builtin_ctz(bmask);
   }


   // String copying from src to dst.
   // m: Max. capacity of dst, including the final nul.
   //    A value of 0 would indicate that the capacity of dst matches the size of src (including nul)
   // l: On entry, src length or 0, on exit, the length of src, maybe NULL
   // Returns the length of the resulting string in dst.
   static inline int strmlcpy(char *dst, const char *src, int m, int *l)
   {
      int k, n;

      if (l)
      {
         if (*l <= 0)
            *l = strvlen(src);
         k = *l;
      }
      else
         k = strvlen(src);

      if (!m)
         n = k;
      else
         n = (k < m) ? k : m-1;

      switch (n)
      {
         default:
            if ((uintptr_t)dst&0xF || (uintptr_t)src&0xF)
               for (k = 0; k  < n>>4<<1; k += 2)
                  ((uint64_t *)dst)[k] = ((uint64_t *)src)[k], ((uint64_t *)dst)[k+1] = ((uint64_t *)src)[k+1];
            else
               for (k = 0; k  < n>>4; k++)
                  _mm_store_si128(&((__m128i *)dst)[k], _mm_load_si128(&((__m128i *)src)[k]));
         case 8 ... 15:
            if ((k = n>>4<<1) < n>>3)
               ((uint64_t *)dst)[k] = ((uint64_t *)src)[k];
         case 4 ... 7:
            if ((k = n>>3<<1) < n>>2)
               ((uint32_t *)dst)[k] = ((uint32_t *)src)[k];
         case 2 ... 3:
            if ((k = n>>2<<1) < n>>1)
               ((uint16_t *)dst)[k] = ((uint16_t *)src)[k];
         case 1:
            if ((k = n>>1<<1) < n)
               dst[k] = src[k];
         case 0:
            ;
      }

      dst[n] = '\0';
      return n;
   }

#else

   #define strvlen(s) (int)strlen(s)
   #define memvcpy(d,s,n) memcpy(d,s,n)

   static inline int linelen(const char *line)
   {
      if (!line || !*line)
         return 0;

      int l;
      for (l = 0; line[l] && line[l] != '\n'; l++)
         ;
      return l;
   }

   static inline int sectlen(const char *sect)
   {
      if (!sect || !*sect)
         return 0;

      int l;
      for (l = 0; sect[l] && sect[l] != '\v'; l++)
         ;
      return l;
   }

   static inline int collen(const char *col)
   {
      if (!col || !*col)
         return 0;

      int l;
      for (l = 0; col[l] && col[l] != ':'; l++)
         ;
      return l;
   }

   static inline int taglen(const char *tag)
   {
      if (!tag || !*tag)
         return 0;

      int l;
      for (l = 0; tag[l] && tag[l] != '>'; l++)
         ;
      return l;
   }

   static inline int fieldlen(const char *field)
   {
      if (!field || !*field)
         return 0;

      int l;
      for (l = 0; field[l] && field[l] != '|'; l++)
         ;
      return l;
   }

   static inline int domlen(const char *domain)
   {
      if (!domain || !*domain)
         return 0;

      int l;
      for (l = 0; domain[l] && domain[l] != '.'; l++)
         ;
      return l;
   }

   static inline int segmlen(const char *segm)
   {
      if (!segm || !*segm)
         return 0;

      int l;
      for (l = 0; segm[l] && segm[l] != '/'; l++)
         ;
      return l;
   }

   static inline int vdeflen(const char *vardef)
   {
      if (!vardef || !*vardef)
         return 0;

      int l;
      for (l = 0; vardef[l] && vardef[l] != '&'; l++)
         ;
      return l;
   }

   static inline int vnamlen(const char *varname)
   {
      if (!varname || !*varname)
         return 0;

      int l;
      for (l = 0; varname[l] && varname[l] != '='; l++)
         ;
      return l;
   }

   static inline int wordlen(const char *word)
   {
      if (!word || !*word)
         return 0;

      int l;
      for (l = 0; (uint8_t)word[l] > ' '; l++)
         ;
      return l;
   }

   static inline int blanklen(const char *blank)
   {
      if (!blank || !*blank)
         return 0;

      int l;
      for (l = 0; blank[l] && (uint8_t)blank[l] <= ' '; l++)
         ;
      return l;
   }


   // String copying from src to dst.
   // m: Max. capacity of dst, including the final nul.
   //    A value of 0 would indicate that the capacity of dst matches the size of src (including nul)
   // l: On entry, src length or 0, on exit, the length of src, maybe NULL
   // Returns the length of the resulting string in dst.
   static inline int strmlcpy(char *dst, const char *src, int m, int *l)
   {
      int k, n;

      if (l)
      {
         if (*l <= 0)
            *l = (int)strlen(src);
         k = *l;
      }
      else
         k = (int)strlen(src);

      if (!m)
         n = k;
      else
         n = (k < m) ? k : m-1;

      strlcpy(dst, src, n+1);
      return n;
   }

#endif


// String concat to dst with variable number of src/len pairs, whereby each len
// serves as the l parameter in strmlcpy(), i.e. strmlcpy(dst, src, ml, &len)
// m: Max. capacity of dst, including the final nul.
//    If m == 0, then the sum of the length of all src strings is returned in l - nothing is copied though.
// l: On entry, offset into dst or -1, when -1, the offset is the end of the initial string in dst
//    On exit, the length of the total concat, even if it would not fit into dst, maybe NULL.
// Returns the length of the resulting string in dst.
int strmlcat(char *dst, int m, int *l, ...);


#define CMP(a, b, len) cmp##len(a, b)
#define cmp(a, b, len) CMP(a, b, len)

static inline boolean cmp1(const void *a, const void *b)
{
   return *(uint8_t *)a == *(uint8_t *)b;
}

static inline boolean cmp2(const void *a, const void *b)
{
   return *(uint16_t *)a == *(uint16_t *)b;
}

static inline boolean cmp3(const void *a, const void *b)
{
   return cmp1(a, b) && cmp2((uint8_t *)a+1, (uint8_t *)b+1);
}

static inline boolean cmp4(const void *a, const void *b)
{
   return *(uint32_t *)a == *(uint32_t *)b;
}

static inline boolean cmp5(const void *a, const void *b)
{
   return cmp1(a, b) && cmp4((uint8_t *)a+1, (uint8_t *)b+1);
}

static inline boolean cmp6(const void *a, const void *b)
{
   return cmp2(a, b) && cmp4((uint8_t *)a+2, (uint8_t *)b+2);
}

static inline boolean cmp7(const void *a, const void *b)
{
   return cmp3(a, b) && cmp4((uint8_t *)a+3, (uint8_t *)b+3);
}

static inline boolean cmp8(const void *a, const void *b)
{
#if !defined(__arm__)
   return *(uint64_t *)a == *(uint64_t *)b;
#else
   return cmp4(a, b) && cmp4((uint8_t *)a+4, (uint8_t *)b+4);
#endif
}

static inline boolean cmp9(const void *a, const void *b)
{
   return cmp1(a, b) && cmp8((uint8_t *)a+1, (uint8_t *)b+1);
}

static inline boolean cmp10(const void *a, const void *b)
{
   return cmp2(a, b) && cmp8((uint8_t *)a+2, (uint8_t *)b+2);
}

static inline boolean cmp11(const void *a, const void *b)
{
   return cmp3(a, b) && cmp8((uint8_t *)a+3, (uint8_t *)b+3);
}

static inline boolean cmp12(const void *a, const void *b)
{
   return cmp4(a, b) && cmp8((uint8_t *)a+4, (uint8_t *)b+4);
}

static inline boolean cmp13(const void *a, const void *b)
{
   return cmp5(a, b) && cmp8((uint8_t *)a+5, (uint8_t *)b+5);
}

static inline boolean cmp14(const void *a, const void *b)
{
   return cmp6(a, b) && cmp8((uint8_t *)a+6, (uint8_t *)b+6);
}

static inline boolean cmp15(const void *a, const void *b)
{
   return cmp7(a, b) && cmp8((uint8_t *)a+7, (uint8_t *)b+7);
}

static inline boolean cmp16(const void *a, const void *b)
{
   return cmp8(a, b) && cmp8((uint8_t *)a+8, (uint8_t *)b+8);
}


#define CPY(a, b, len) cpy##len(a, b)
#define cpy(a, b, len) CPY(a, b, len)

static inline void cpy1(void *a, const void *b)
{
  *(uint8_t *)a = *(uint8_t *)b;
}

static inline void cpy2(void *a, const void *b)
{
  *(uint16_t *)a = *(uint16_t *)b;
}

static inline void cpy3(void *a, const void *b)
{
   cpy2(a, b), cpy1((uint8_t *)a+2, (uint8_t *)b+2);
}

static inline void cpy4(void *a, const void *b)
{
   *(uint32_t *)a = *(uint32_t *)b;
}

static inline void cpy5(void *a, const void *b)
{
   cpy4(a, b), cpy1((uint8_t *)a+4, (uint8_t *)b+4);
}

static inline void cpy6(void *a, const void *b)
{
   cpy4(a, b), cpy2((uint8_t *)a+4, (uint8_t *)b+4);
}

static inline void cpy7(void *a, const void *b)
{
   cpy4(a, b), cpy3((uint8_t *)a+4, (uint8_t *)b+4);
}

static inline void cpy8(void *a, const void *b)
{
#if !defined(__arm__)
   *(uint64_t *)a = *(uint64_t *)b;
#else
   cpy4(a, b), cpy4((uint8_t *)a+4, (uint8_t *)b+4);
#endif
}

static inline void cpy9(void *a, const void *b)
{
   cpy8(a, b), cpy1((uint8_t *)a+8, (uint8_t *)b+8);
}

static inline void cpy10(void *a, const void *b)
{
   cpy8(a, b), cpy2((uint8_t *)a+8, (uint8_t *)b+8);
}

static inline void cpy11(void *a, const void *b)
{
   cpy8(a, b), cpy3((uint8_t *)a+8, (uint8_t *)b+8);
}

static inline void cpy12(void *a, const void *b)
{
   cpy8(a, b), cpy4((uint8_t *)a+8, (uint8_t *)b+8);
}

static inline void cpy13(void *a, const void *b)
{
   cpy8(a, b), cpy5((uint8_t *)a+8, (uint8_t *)b+8);
}

static inline void cpy14(void *a, const void *b)
{
   cpy8(a, b), cpy6((uint8_t *)a+8, (uint8_t *)b+8);
}

static inline void cpy15(void *a, const void *b)
{
   cpy8(a, b), cpy7((uint8_t *)a+8, (uint8_t *)b+8);
}

static inline void cpy16(void *a, const void *b)
{
   cpy8(a, b), cpy8((uint8_t *)a+8, (uint8_t *)b+8);
}


static inline double sqr(double x)
{
   return x*x;
}

static inline long double sqrl(long double x)
{
   return x*x;
}

static inline int32_t intlgf(float x)
{
   return (int32_t)floorf(log10f(x));
}

static inline int32_t intlg(double x)
{
   return (int32_t)floor(log10(x));
}

static inline int32_t intlgl(long double x)
{
   return (int32_t)floorl(log10l(x));
}


#define intLen 32             // actually it's 21 incl. '\0', however pad it to a 128 bit boundary
typedef char intStr[intLen];

int int2str(char *ist, llong i, int m, int width);

#define hexLen 32             // actually it's 19 incl. '0x' and the trailing '\0', however pad it to a 128 bit boundary
typedef char hexStr[hexLen];

int int2hex(char *hex, llong i, int m, int width);

#define decLen 64
typedef char decStr[decLen];

enum
{
   // basic formats
   d_form   =    1,     // like f_form, but 'digits' are significant and not decimal, and a possible dangling ds would be suppressed
   e_form   =    2,
   f_form   =    4,
   g_form   =    8,
   b_mask   =   15,     // basic mask

   // modifiers
   alt_form =   16,     // don't strip trailing zeros from the fraction
   pls_sign =   32,     // emit plus signs
   noe_sign =   64,     // suppress plus signs in the exponent
   nod_dsep =  128,     // suppress a dangling decimal separator
   sup_dsep =  256,     // suppress outputting the decimal separator
   non_zero =  512,     // no negative zero
   cap_litr = 1024      // emit the literals 'e', 'inf', and 'nan' in capital letters, i.e.: 'E', 'INF', 'NAN'
};

int num2str(char *dst, long double x, int m, int width, int digits, int formsel, char decsep);


// Essence of MurmurHash3_x86_32()
//
//  Original at: https://github.com/aappleby/smhasher/blob/master/src/MurmurHash3.cpp
//
//  Quote from the Source:
//  "MurmurHash3 was written by Austin Appleby, and is placed in the public
//   domain. The author hereby disclaims copyright to this source code."
//
// Many thanks to Austin!

static inline uint32_t mmh3(const char *name, ssize_t naml)
{
   int32_t   i, n   = (int32_t)(naml/4);
   uint32_t  k1, h1 = (uint32_t)naml;  // quite tiny (0.2 %) better distribution by seeding the name length
   uint32_t *quads  = (uint32_t *)(name + n*4);
   uint8_t  *tail   = (uint8_t *)quads;

   for (i = -n; i; i++)
   {
      k1  = quads[i];
      k1 *= 0xCC9E2D51;
      k1  = (k1<<15)|(k1>>17);
      k1 *= 0x1B873593;

      h1 ^= k1;
      h1  = (h1<<13)|(h1>>19);
      h1  = h1*5 + 0xE6546B64;
   }

   k1 = 0;
   switch (naml & 3)
   {
      case 3: k1 ^= (uint32_t)(tail[2] << 16);
      case 2: k1 ^= (uint32_t)(tail[1] << 8);
      case 1: k1 ^= (uint32_t)(tail[0]);
         k1 *= 0xCC9E2D51;
         k1  = (k1<<15)|(k1>>17);
         k1 *= 0x1B873593;
         h1 ^= k1;
   };

   h1 ^= naml;
   h1 ^= h1 >> 16;
   h1 *= 0x85EBCA6B;
   h1 ^= h1 >> 13;
   h1 *= 0xC2B2AE35;
   h1 ^= h1 >> 16;

   return h1;
}


// forward skip white space  !!! s MUST NOT be NULL !!!
static inline char *skip(char *s)
{
   for (;;)
      switch (*s)
      {
         case '\t'...'\r':
         case ' ':
            s++;
            break;

         default:
            return s;
      }
}

// backward skip white space  !!! s MUST NOT be NULL !!!
static inline char *bskip(char *s)
{
   for (;;)
      switch (*--s)
      {
         case '\t'...'\r':
         case ' ':
            break;

         default:
            return s+1;
      }
}

static inline char *trim(char *s)
{
   *bskip(s+strvlen(s)) = '\0';
   return skip(s);
}


// jump to the stop mark  !!! s MUST NOT be NULL !!!
static inline char *jump(char *s, char stop)
{
   boolean q, sq, dq;
   char    c;

   for (q = sq = dq = false; (c = *s) && (c != stop || q); s++)
      if (c == '\'' && !dq)
         q = sq = !sq;
      else if (c == '"' && !sq)
         q = dq = !dq;

   return s;
}


static inline utf8 getu(char **s)
{
   utf8 u = 0;
   char c = **s;

   if ((uint8_t)c < 0x80)
      u = c;

   else if ((*s)[1] != '\0')
      if ((c & 0xE0) == 0xC0)
         u = TwoChars(*s), *s += 1;

      else if ((*s)[2] != '\0')
         if ((c & 0xF0) == 0xE0)
            u = ThreeChars(*s), *s += 2;

         else if ((*s)[3] != '\0')
            if ((c & 0xF8) == 0xF0)
               u = FourChars(*s), *s += 3;

   *s += 1;
   return u;
}

static inline int putu(utf8 u, char *t)
{
   int l;

   if (u <= 0x7F)
      *t = (char)u,                           l = 1;

   else if (u <= 0xFFFF)
      *(uint16_t *)t = MapShort((uint16_t)u), l = 2;

   else if (u <= 0xFFFFFF)
   {
      char v[4] = {};
      *(uint32_t *)v = MapInt(u);
      t[0] = v[1];
      t[1] = v[2];
      t[2] = v[3],                            l = 3;
   }

   else
      *(uint32_t *)t = MapInt(u),             l = 4;

   return l;
}


char *uriDecode(char *element);                                                     // does in-place decoding
char *uriEncode(char *element, char *buffer);                                       // if buffer is NULL, the space for the encded string is allocated and it needs to be freed
char *entEncode(char *element, char *buffer);                                       // if buffer is NULL, the space for the encded string is allocated and it needs to be freed

static inline char *postDecode(char *element)
{
   for (char *p = element; *p; p++)
      if (*p == '+') *p = ' ';
   return uriDecode(element);
}


#pragma mark ••• Oversize Protection for variable length arrays and alloca() •••
#define OSP(cnt) ((cnt <= 4096) ? cnt : (exit(EXIT_FAILURE), 1))


#pragma mark ••• Fencing Memory Allocation Wrappers •••
// void pointer reference
#define VPR(p) (void **)&(p)

#define default_align   0

#if defined __AVX512F__
   #define vector_align 64
#elif defined __AVX__
   #define vector_align 32
#else
   #define vector_align 16
#endif

typedef struct
{
   ssize_t  size;
   uint32_t check;
   uint16_t fence;
   uint8_t  align;
   uint8_t  padis;
   char     payload[];
// size_t   zerowall;   // the allocation routines allocate sizeof(size_t) extra space and set this to zero
} allocation;

#define allocationMetaSize (offsetof(allocation, payload) - offsetof(allocation, size))

void *allocate(ssize_t size, uint8_t align, boolean cleanout);
void *reallocate(void *p, ssize_t size, boolean cleanout, boolean free_on_error);
void deallocate(void **p, boolean cleanout);
void deallocate_batch(int cleanout, ...);

ssize_t allocsize(void *p);


#pragma mark ••• Dynamic Buffer facility •••

#define DYNAMIC_BUFFER_SIZE 8192
#define DYNAMIC_BUFFER_MARGIN 32

typedef struct
{
   int  len, cap;
   char buf[DYNAMIC_BUFFER_SIZE];
} dynbuf;

#define dynbufMetaSize (offsetof(dynbuf, buf) - offsetof(dynbuf, len))

static inline char *newDynBuffer(void)
{
   dynbuf *db;
   if (db = (dynbuf *)allocate(sizeof(dynbuf) + DYNAMIC_BUFFER_MARGIN, default_align, false))
   {
      db->len = 0;
      db->cap = DYNAMIC_BUFFER_SIZE;
      return (char *)&db->buf;
   }
   else
   {
      syslog(LOG_ERR, "Allocation of memory for a dynamic buffer failed.");
      exit(EXIT_FAILURE);
   }
}

static inline void freeDynBuffer(char *buf)
{
   dynbuf *db = (dynbuf *)(buf - dynbufMetaSize);
   deallocate(VPR(db), false);
}

static inline int dynava(char *buf)
{
   dynbuf *db = ((dynbuf *)(buf - dynbufMetaSize));
   return db->cap - db->len;
}

static inline int dynlen(char *buf)
{
   return ((dynbuf *)(buf - dynbufMetaSize))->len;
}

static inline void dyninc(char **buf, int len)
{
   dynbuf *db = (dynbuf *)(*buf - dynbufMetaSize);
   if (db->len+len >= db->cap)
   {
      if (db = (dynbuf *)reallocate(db, sizeof(dynbuf) + db->cap + DYNAMIC_BUFFER_MARGIN, false, true))
         *buf = (char *)&db->buf, db->cap += DYNAMIC_BUFFER_SIZE;
      else
      {
         syslog(LOG_ERR, "Reallocation of memory for a dynamic buffer failed.");
         exit(EXIT_FAILURE);
      }
   }
   db->len += len;
}

static inline int dynAddString(char **buf, char *s, int len)
{
   dynbuf *db = (dynbuf *)(*buf - dynbufMetaSize);
   if (s)
   {
      if (*s)
      {
         if (len <= 0)
            len = strvlen(s);
         if (db->len+len >= db->cap)
         {
            if (db = (dynbuf *)reallocate(db, sizeof(dynbuf) + db->cap + DYNAMIC_BUFFER_MARGIN, false, true))
               *buf = (char *)&db->buf, db->cap += DYNAMIC_BUFFER_SIZE;
            else
            {
               syslog(LOG_ERR, "Reallocation of memory for a dynamic buffer failed.");
               exit(EXIT_FAILURE);
            }
         }
         db->len += strmlcpy(*buf+db->len, s, db->cap-db->len, &len);
      }
   }

   return db->len;
}

static inline void dynAddStrField(char **buf, char *s, int len)
{
   dynbuf *db = (dynbuf *)(*buf - dynbufMetaSize);
   if (s)
   {
      if (*s)
      {
         if (len <= 0)
            len = strvlen(s);
         if (db->len+len >= db->cap)
         {
            if (db = (dynbuf *)reallocate(db, sizeof(dynbuf) + db->cap + DYNAMIC_BUFFER_MARGIN, false, true))
               *buf = (char *)&db->buf, db->cap += DYNAMIC_BUFFER_SIZE;
            else
            {
               syslog(LOG_ERR, "Reallocation of memory for a dynamic buffer failed.");
               exit(EXIT_FAILURE);
            }
         }
         db->len += strmlcpy(*buf+db->len, s, db->cap-db->len, &len);
      }
      (*buf)[db->len++] = '|';      // capacity checking is not necessary here, because of the added DYNAMIC_BUFFER_MARGIN
   }
}

static inline void dynAddInt(char **buf, llong i)
{
   dynbuf *db = (dynbuf *)(*buf - dynbufMetaSize);
   if (db->len+intLen >= db->cap)
   {
      if (db = (dynbuf *)reallocate(db, sizeof(dynbuf) + db->cap + DYNAMIC_BUFFER_MARGIN, false, true))
         *buf = (char *)&db->buf, db->cap += DYNAMIC_BUFFER_SIZE;
      else
      {
         syslog(LOG_ERR, "Reallocation of memory for a dynamic buffer failed.");
         exit(EXIT_FAILURE);
      }
   }
   db->len += int2str(*buf+db->len, i, db->cap-db->len, 0);
}

static inline void dynAddIntField(char **buf, llong i)
{
   dynbuf *db = (dynbuf *)(*buf - dynbufMetaSize);
   if (db->len+intLen >= db->cap)
   {
      if (db = (dynbuf *)reallocate(db, sizeof(dynbuf) + db->cap + DYNAMIC_BUFFER_MARGIN, false, true))
         *buf = (char *)&db->buf, db->cap += DYNAMIC_BUFFER_SIZE;
      else
      {
         syslog(LOG_ERR, "Reallocation of memory for a dynamic buffer failed.");
         exit(EXIT_FAILURE);
      }
   }
   db->len += int2str(*buf+db->len, i, db->cap-db->len, 0);
   (*buf)[db->len++] = '|';
}

static inline void dynAddNumField(char **buf, double d, int sigdig, char decsep)
{
   dynbuf *db = (dynbuf *)(*buf - dynbufMetaSize);
   if (decLen >= db->cap)
   {
      if (db = (dynbuf *)reallocate(db, sizeof(dynbuf) + db->cap + DYNAMIC_BUFFER_MARGIN, false, true))
         *buf = (char *)&db->buf, db->cap += DYNAMIC_BUFFER_SIZE;
      else
      {
         syslog(LOG_ERR, "Reallocation of memory for a dynamic buffer failed.");
         exit(EXIT_FAILURE);
      }
   }
   db->len += num2str(*buf+db->len, d, db->cap-db->len, 0, sigdig, d_form, decsep);
   (*buf)[db->len++] = '|';
}

static inline void dynAddStrLine(char **buf, char *s, int len)
{
   dynbuf *db = (dynbuf *)(*buf - dynbufMetaSize);
   if (s)
   {
      if (*s)
      {
         if (len <= 0)
            len = strvlen(s);
         if (db->len+len >= db->cap)
         {
            if (db = (dynbuf *)reallocate(db, sizeof(dynbuf) + db->cap + DYNAMIC_BUFFER_MARGIN, false, true))
               *buf = (char *)&db->buf, db->cap += DYNAMIC_BUFFER_SIZE;
            else
            {
               syslog(LOG_ERR, "Reallocation of memory for a dynamic buffer failed.");
               exit(EXIT_FAILURE);
            }
         }
         db->len += strmlcpy(*buf+db->len, s, db->cap-db->len, &len);
      }
      (*buf)[db->len++] = '\n';     // capacity checking is not necessary here, because of the added DYNAMIC_BUFFER_MARGIN
   }
}

static inline void dynAddSetLine(char **buf, char *nam, double val)
{
   dynbuf *db = (dynbuf *)(*buf - dynbufMetaSize);
   if (4+decLen >= db->cap)
   {
      if (db = (dynbuf *)reallocate(db, sizeof(dynbuf) + db->cap + DYNAMIC_BUFFER_MARGIN, false, true))
         *buf = (char *)&db->buf, db->cap += DYNAMIC_BUFFER_SIZE;
      else
      {
         syslog(LOG_ERR, "Reallocation of memory for a dynamic buffer failed.");
         exit(EXIT_FAILURE);
      }
   }
   cpy4(*buf+db->len, nam); db->len += 4;
   db->len += num2str(*buf+db->len, val, db->cap-db->len, 12, 7, d_form, '.');
   (*buf)[db->len++] = '\n';
}

static inline boolean readInt(char *str, int *val, int min, int max)
{
   char *chk;
   int i = (int)strtol(str, &chk, 10);
   if (chk != str && min <= i && i <= max)
   {
      *val = i;
      return true;
   }
   else
      return false;
}

static inline boolean readDouble(char *str, double *val, double min, double max)
{
   char *chk;
   double d = strtod(str, &chk);
   if (chk != str && min <= d && d <= max)
   {
      *val = d;
      return true;
   }
   else
      return false;
}


#pragma mark ••• AVL Tree •••
#pragma mark ••• Value Data Types •••

// Data Types in the key/name-value store -- negative values are dynamic.
enum
{
   dynamic    = -1,     // multiply kind with -1 if the data has been dynamically allocated
   Empty      =  0,     // the key is the data
   Simple     =  1,     // boolean, integer, floating point, etc. values
   Data       =  2,     // any kind of structured or unstructured data
   String     =  3,     // a nul terminated string
   Dictionary =  5,     // a dictionary table, i.e. another key/name-value store
   Opaque     =  6      // an opaque objective-c object, call [obj release], when releasing the table
};


typedef struct
{
   union                // the payload
   {
      boolean b;        // a boolean value
      int64_t i;        // an integer
      double  d;        // a floating point number
      time_t  t;        // a time stamp

      char   *s;        // a string
      void   *p;        // a pointer to anything
      opaque  o;        // an opaque objective-c object
   };

   int32_t kind;        // negative kinds indicate dynamically allocated data
   int32_t offset;      // offset of payload from the beginning of a dynamic allocation
   int64_t size;        // size of the payload

   // custom deallocate() function
   void (*custom_deallocate)(void **p, int32_t offset, boolean cleanout);
} Value;


typedef struct Node
{
   // key
   char   *name;     // the name is the key
   ssize_t naml;     // char length of the name

   // value
   Value   value;

   // house holding
   int          B;
   struct Node *L, *R;
} Node;


// CAUTION: The following recursive functions must not be called with name == NULL.
//          For performace reasons no extra error cheking is done.
Node *findTreeNode(const char *name, Node  *node);
int    addTreeNode(const char *name, ssize_t naml, Value *value, Node **node, Node **passed);
int removeTreeNode(const char *name, Node **node);
void   releaseTree(Node *node);
void     printTree(Node *node, uint naml);


#pragma mark ••• Hash Table •••
Node **createTable(uint n);
void  releaseTable(Node *table[]);

// Storing and retrieving values by name
Node  *findName(Node *table[], const char *name, ssize_t naml);
Node *storeName(Node *table[], const char *name, ssize_t naml, Value *value);
void removeName(Node *table[], const char *name, ssize_t naml);
void printTable(Node *table[], uint *nameWidth);
int sprintTable(Node *table[], uint *nameWidth, char **output);


#pragma mark ••• File Copying & Recursive Directory Deletion •••
int fileCopy(char *src, char *dst, struct stat *st);
int deleteDirEntity(char *path, size_t pl, llong st_mode);
int deleteDirectory(char *path, size_t pl);


#pragma mark ••• MIME Types •••
const char *extensionToType(char *fnam, int flen);

#pragma mark ••• HTTP-Date & HTTP-ETag •••
#define dateLen 32
static inline char *httpDate(char *date, time_t tod)
{
   struct tm tm;
   strftime(date, dateLen, "%a, %d %b %Y %H:%M:%S GMT", gmtime_r(&tod, &tm));
   return date;
}

#define etagLen 54
static inline void httpETag(char *etag, struct stat *st)
{
   snprintf(etag, etagLen, "%llx-%llx-%llx", (ullong)st->st_ino,
                                             (ullong)st->st_size,
                                             (ullong)st->st_mtimespec.tv_sec*1000000LL + (ullong)st->st_mtimespec.tv_nsec/1000LL);
}

#pragma mark ••• Path to the Zettair index directory •••
#define ZETTAIR_DB_PATH "/var/db/zettair/"
#define ZETTAIR_DB_PLEN 16


#pragma mark ••• Helper functions •••

static inline char *nextPathSegment(char *path, int plen)
{
   int i;
   for (i = 0; i < plen && path[i] != '/'; i++);
   for (     ; i < plen && path[i] == '/'; i++);
   return path + i;
}

static inline char *lastPathSegment(char *path, int plen)
{
   int i;
   for (i = plen-1; i >= 0 && path[i] != '/'; i--);
   return (path[i++] == '/' && path[i]) ? path+i : path;
}

static inline char *httpHost(Node **serverTable)
{
   Node *node;
   return ((node = findName(serverTable, "HTTP_HOST", 9)) && node->value.s && *node->value.s)
          ? node->value.s
          : "";
}

static inline char *scriptName(Node **serverTable)
{
   Node *node;
   return ((node = findName(serverTable, "SCRIPT_NAME", 11)) && node->value.s && *node->value.s)
          ? node->value.s
          : "";
}

static inline char *docRoot(Node **serverTable)
{
   Node *node;
   return ((node = findName(serverTable, "DOCUMENT_ROOT", 13)) && node->value.s && *node->value.s)
          ? node->value.s
          : NULL;
}

static inline char *contTitle(Node **serverTable)
{
   Node *node;
   return ((node = findName(serverTable, "CONTENT_TITLE", 13)) && node->value.s && *node->value.s)
          ? node->value.s
          : "Content";
}

static inline char *contLangs(Node **serverTable)
{
   Node *node;
   return ((node = findName(serverTable, "CONTENT_LANGS", 13)) && node->value.s && *node->value.s)
          ? node->value.s
          : "";
}
