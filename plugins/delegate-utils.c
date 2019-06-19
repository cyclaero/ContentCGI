//  delegate-utils.c
//  Responder Delegate plugins
//
//  Created by Dr. Rolf Jansen on 2018-05-15.
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


#include "delegate-utils.h"


#pragma mark ••• Unicode conversions •••

static const uchar trailingBytesForUTF8[256] =
{
   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
   1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1, 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
   2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2, 3,3,3,3,3,3,3,3,4,4,4,4,5,5,5,5
};

static const utf32 offsetsFromUTF8[6] = { 0x00000000, 0x00003080, 0x000E2080, 0x03C82080, 0xFA082080, 0x82082080 };
static const uchar firstByteMark[7]   = { 0x00, 0x00, 0xC0, 0xE0, 0xF0, 0xF8, 0xFC };
static const utf32 byteMask = 0xBF;
static const utf32 byteMark = 0x80;

utf32 utf8to32(uchar **v)
{
   utf32 u32 = 0;
   uchar tl, *u = (*v)++;

   if (*u < 0x80)
      return *u;

   else switch (tl = trailingBytesForUTF8[*u])
   {
      default:
         return 0xFFFD;

      case 3: u32 += *u++; u32 <<= 6;
      case 2: u32 += *u++; u32 <<= 6;
      case 1: u32 += *u++; u32 <<= 6;
      case 0: u32 += *u++;
   }
   *v = u;

   return u32 - offsetsFromUTF8[tl];
}


utf8 utf32to8(utf32 u32)
{
   utf8  u8 = 0;
   uchar l;

   if      (u32 < 0x80)     l = 1;
   else if (u32 < 0x800)    l = 2;
   else if (u32 < 0x10000)  l = 3;
   else if (u32 < 0x110000) l = 4;
   else   { u32 = 0xFFFD;   l = 3; }

   uchar *u =(uchar *)&u8 + l;
   switch (l)
   {
      case 4: *--u = (uchar)((u32 | byteMark) & byteMask); u32 >>= 6;
      case 3: *--u = (uchar)((u32 | byteMark) & byteMask); u32 >>= 6;
      case 2: *--u = (uchar)((u32 | byteMark) & byteMask); u32 >>= 6;
      case 1: *--u = (uchar) (u32 | firstByteMark[l]);
   }

   return u8;
}


#pragma mark ••• URI encoding/decoding and HTML entity encoding •••

char *uriDecode(char *element)
{
   static const char hex[256] =
   {
      -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,  -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
      -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,   0,  1,  2,  3,  4,  5,  6,  7,  8,  9, -1, -1, -1, -1, -1, -1,
      -1, 10, 11, 12, 13, 14, 15, -1, -1, -1, -1, -1, -1, -1, -1, -1,  -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
      -1, 10, 11, 12, 13, 14, 15, -1, -1, -1, -1, -1, -1, -1, -1, -1,  -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
      -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,  -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
      -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,  -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
      -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,  -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
      -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,  -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1
   };

   if (element)
   {
      uchar c, *p, *q;
      char h1, h2;
      p = q = (uchar *)element;

      while (*p)
      {
         if ((c = *p++) == '%' && (h1 = hex[*p]) != -1 && (h2 = hex[*(p+1)]) != -1)
            p += 2, c = h2 + (uchar)((uchar)h1 << 4);
         *q++ = c;
      }
      *q = '\0';
   }

   return element;
}


char *uriEncode(char *element, char *buffer)       // if buffer is NULL, then the space for the encoded string will be
{                                                  // allocated, and it needs to be deallocated by the caller.
   if (element)
   {
      char *p = element;
      char *q = element = (buffer) ?: allocate(strvlen(p)*3 + 1, default_align, false);

      if (q)
      {
         char  c, h;
         while (c = *p++)
            switch (c)
            {
               case '0' ... '9':
               case 'A' ... 'Z':
               case 'a' ... 'z':
               case '/':
               case ':':
               case '-':
               case '_':
               case '.':
               case '~':
                  *q++ = c;
                  break;

               default:
                  *q++ = '%';
                  h = (c >> 4) & 0xF;
                  *q++ = (h <= 9) ? (h + '0') : (h + 'A' - 10);
                  h = c & 0xF;
                  *q++ = (h <= 9) ? (h + '0') : (h + 'A' - 10);
            }

         *q = '\0';
      }
   }

   return element;
}


char *entEncode(char *element, char *buffer)       // if buffer is NULL, then the space for the encoded string will be
{                                                  // allocated, and it needs to be deallocated by the caller.
   if (element)
   {
      char *p = element;
      char *q = element = (buffer) ?: allocate(strvlen(p)*6 + 1, default_align, false);

      if (q)
      {
         boolean b;
         int     k;
         char    h;
         utf8    c;
         utf32   u;

         while (c = *p)
            switch (c)
            {
               case '0' ... '9':
               case 'A' ... 'Z':
               case 'a' ... 'z':
                  *q++ = *p++;
                  break;

               default:
                  u = utf8to32((uchar **)&p);
                  cpy4(q, "&#x"), q += 3;
                  for (k = 28, b = false; k >= 8; k -= 4)
                     if ((h = (u >> k) & 0xF) || b)
                     {
                        *q++ = (h <= 9) ? (h + '0') : (h + 'A' - 10);
                        b = true;
                     }
                  h = (u >> 4) & 0xF;
                  *q++ = (h <= 9) ? (h + '0') : (h + 'A' - 10);
                  h = u & 0xF;
                  *q++ = (h <= 9) ? (h + '0') : (h + 'A' - 10);
                  *q++ = ';';
            }

         *q = '\0';
      }
   }

   return element;
}


#pragma mark ••• Number to String conversions int2str(), int2hex() and num2str() •••

int int2str(char *ist, llong i, int m, int width)
{
   if (i == 0)
      if (m > 1)
      {
         int k;
         for (k = 0; k < width-1 && k < m-2; k++)
            ist[k] = ' ';
         cpy2(ist+k, "0");
         return k+1;
      }
      else            // result won't fit
         return 0;
   else
   {
      boolean neg = (i < 0);
      if (neg)
         i = llabs(i);

      int n = intlg(i) + 1 + neg;
      if (n > m-1)    // result won't fit
         return 0;

      if (n < width && width < m)
         n = width;

      ist[n] = '\0';

      for (m = n-1; i; i /= 10, m--)
        ist[m] = '0' + i%10;

      if (neg)
         ist[m--] = '-';

      while (m >= 0)
         ist[m--] = ' ';

      return n;
   }
}


int int2hex(char *hex, llong i, int m, int width)
{
   if (m < 3)
   {
      *hex = '\0';
      return 0;
   }

   union
   {
      llong l;
      uchar b[sizeof(llong)];
   } bin = {.l = (llong)MapInt64(i)};

   uchar c;
   int   o, j, k;

   cpy2(hex, "0x");
   hex += 2, m -= 2;
   for (j = 0, k = 0; j < sizeof(llong) && k < m; j++)
   {
      if ((c = (bin.b[j] >> 4) & 0xF) || k)
         hex[k++] = (c <= 9) ? (c + '0') : (c + 'a' - 10);

      if ((c = bin.b[j] & 0xF) || k)
         hex[k++] = (c <= 9) ? (c + '0') : (c + 'a' - 10);
   }

   if (width > m-1)
      width = m-1;

   if ((j = width - k) > 0)
   {
      for (o = k; o >= 0; o--)
         hex[o+j] = hex[o];

      for (o = 0; o < j; o++)
         hex[o] = '0';

      k += j;
   }

   if (k > 0)
      hex[k] = '\0';
   else
      cpy2(&hex[k++], "0");

   return k+2;
}


static inline long double pow10pl(int n)                 // ...pl => n must be positive
{
   long double z = 1.0L;

   if (n < 9)
      for (int i = 0; i < n; i++)                        // power base 10 by repeated multiplication
         z *= 10.0L;
   else
      for (long double b = 10.0L;; b *= b)               // power base 10 by repeated squaring
      {
         if (n & 1)
            z *= b;

         if (!(n >>= 1))
            break;
      }

   return z;
}

static inline long double pow11pl(int n)                 // ...pl => n must be positive
{
   long double z = 1e+100L; n -= 100;

   if (n < 9)
      for (int i = 0; i < n; i++)                        // power base 10 by repeated multiplication
         z *= 10.0L;
   else
      for (long double b = 10.0L;; b *= b)               // power base 10 by repeated squaring
      {
         if (n & 1)
            z *= b;

         if (!(n >>= 1))
            break;
      }

   return z;
}

static inline llong mgnround(long double x, int mgn)
{
   static long double pow10pi[100] =
   {
      1e+00L,1e+01L,1e+02L,1e+03L,1e+04L,1e+05L,1e+06L,1e+07L,1e+08L,1e+09L, 1e+10L,1e+11L,1e+12L,1e+13L,1e+14L,1e+15L,1e+16L,1e+17L,1e+18L,1e+19L,
      1e+20L,1e+21L,1e+22L,1e+23L,1e+24L,1e+25L,1e+26L,1e+27L,1e+28L,1e+29L, 1e+30L,1e+31L,1e+32L,1e+33L,1e+34L,1e+35L,1e+36L,1e+37L,1e+38L,1e+39L,
      1e+40L,1e+41L,1e+42L,1e+43L,1e+44L,1e+45L,1e+46L,1e+47L,1e+48L,1e+49L, 1e+50L,1e+51L,1e+52L,1e+53L,1e+54L,1e+55L,1e+56L,1e+57L,1e+58L,1e+59L,
      1e+60L,1e+61L,1e+62L,1e+63L,1e+64L,1e+65L,1e+66L,1e+67L,1e+68L,1e+69L, 1e+70L,1e+71L,1e+72L,1e+73L,1e+74L,1e+75L,1e+76L,1e+77L,1e+78L,1e+79L,
      1e+80L,1e+81L,1e+82L,1e+83L,1e+84L,1e+85L,1e+86L,1e+87L,1e+88L,1e+89L, 1e+90L,1e+91L,1e+92L,1e+93L,1e+94L,1e+95L,1e+96L,1e+97L,1e+98L,1e+99L
   };

   if (!mgn)
      return llroundl(x);
   else
   {
      long double z;
      boolean pos = (mgn > 0);
      int n = (pos) ? mgn : -mgn;

      if      (n <= 29)
         z = pow10pl(n);
      else if (n <= 99)
         z = pow10pi[n];
      else
         z = pow11pl(n);

      return llroundl(((pos) ? x*z : x/z));
   }
}

int num2str(char *dst, long double x, int m, int width, int digits, int formsel, char decsep)
{
   if (m < 2 || width < 0 || digits < 0)
      return 0;

   boolean minussign = signbit(x);
   boolean negzero   = (formsel&non_zero) == 0;
   boolean plussign  = (formsel&pls_sign) != 0;
   boolean exposign  = (formsel&noe_sign) == 0;
   boolean capitals  = (formsel&cap_litr) != 0;
   boolean nostrip0  = (formsel&alt_form) || (formsel&f_form) || (formsel&e_form);
   boolean dangleds  = (formsel&alt_form) &&!(formsel&d_form) &&!(formsel&nod_dsep);
   boolean dsspace   = (formsel&sup_dsep)?0:1;                    //space for the decimal separator -- 0 in case it shall be suppressed
   formsel &= b_mask;

   if (digits && (formsel&(d_form|g_form)))
      digits--;

   if (width > m-1)
      width = m-1;

   int k, l = 0;
   if (isfinite(x))
   {
      if (x != 0.0L)
      {
         int ilg = intlgl(x = fabsl(x));
         int xtd = digits;
         if (formsel != f_form)
         {
            if (digits > 17)
               digits = 17;
            digits -= ilg;
            xtd -= ilg;
         }
         else if (digits + ilg > 17)
            digits = 17 - ilg;
         else if (digits + ilg < -1)                              // -1 instead of 0 leaves space for a possible rounding up
            goto zero;                                            // in the exact f_form, the number of desired decimal digits is not sufficient for anything else than zero.
         xtd -= digits;

         if (formsel == g_form)
            formsel = (-4 <= ilg && 0 <= digits) ? f_form : e_form;

      // Magnitude rounding and BCD conversion
         llong v = (digits <= __LDBL_MAX_10_EXP__)
                 ? mgnround(x, digits)
                 : mgnround(x*1e100, digits-100);                 // in the case of numbers which are close to __LDBL_DENORM_MIN__, do the magnround() in 2 steps

         if (v == 0LL)
            goto zero;                                            // the value has been rounded to zero and we may skip the BCD stage

         int o, p, q, w;
         uchar bcd[32] __attribute__((aligned(16))) = {};         // size of 18 bytes would be sufficient, however, we want this to be aligned on a 16byte boundary anyway
         for (p = -1; v && p < 31; v /= 10)                       // at the end of the loop, p points to the position of the most significant non-zero byte in the BCD buffer
            bcd[++p] = v % 10;
         ilg = p - digits;                                        // rounding in the course of BCD conversion may have resulted in an incremented intlg

      // Digit extraction from the BCD buffer
         // Determine various characteristic indexes
         //  p - q: range of significant bytes in the reversed BCD buffer               |o    |p  |q
         //  o    : extension of zeros to the left of the siginificant digits - example 0.000054321
         //                                                   otherwise o = p - example 3.141593
         //                                                                             |o=p   |q
         //  k    : decimal separator + number of trailing zeros

         if (p < ilg+digits && formsel == e_form)
            ilg--, digits++, xtd++;

         o = (p > digits || formsel == e_form) ? p : digits;      // extension of zeros to the left of the siginificant digits

         if (0 < digits && digits <= o || formsel == e_form)      // does the number contain a fraction, or has a fraction by definition (e_form)
         {
            if (nostrip0)                                         // no stripping of non-significant zeros?
            {
               q = 0;
               if (formsel != e_form)
                  k = (dangleds || digits) ? dsspace : 0;         // reserve 1 byte for the decimal separator
               else
                  k = (dangleds || digits+ilg) ? dsspace : 0;     // reserve 1 byte for the decimal separator
            }

            else
            {
               xtd = 0;
               for (q = 0; q < p && bcd[q] == 0; q++);            // strip trailing non-significant zeros; q points to the position of the least significant non-zero digit
               if (formsel != e_form)
               {
                  if (p - q < ilg)
                     q = (p > ilg) ? p - ilg : 0;                 // don't strip off zeros before the decimal separator
                  k = (p - q > ilg || ilg < 0) ? dsspace : 0;     // strip the decicmal separator or not?
               }
               else
                  k = (p - q) ? dsspace : 0;                      // strip the decicmal separator or not?
            }
         }

         else                                                     // no fraction
         {
            q = 0;
            if (digits <= 0 && xtd)                               // very large integral numbers > 18 digits must
               xtd += digits,                                     // be extended by significant zeros to the right
               k = (xtd || dangleds) ? dsspace-digits : -digits;  // number of trailing zeros of an integral number + perhaps a dangling decimal separator
            else
               k = (dangleds) ? dsspace-digits : -digits;         // number of trailing zeros of an integral number + perhaps a dangling decimal separator
         }

      // Calcultate the length of the number and check it against the supplied buffer
         boolean kpow = (ilg < -999 || 999 < ilg);
         boolean hpow = kpow ||
                         (ilg < -99 || 99 < ilg);
         k += o - q + 1;                                          // decimal separator (k) + number of digits
         m -= w = ((minussign || plussign) ? 1 : 0) + k + xtd;    // actual width of the number
         if (formsel == e_form)
         {
            m -= (ilg < 0 || exposign) ? 4 : 3;
            if (kpow)
               m -= 2;
            else if (hpow)
               m--;
         }

         if (m < 1)
         {
            cpy2(dst, "!");                                       // the result won't fit into the supplied buffer
            return 1;
         }


      // Construct the actual number, by directly placing the parts into the supplied buffer
         // Left padding
         if (width)
            for (width -= w; l < width; l++)
               dst[l] = ' ';                                      // left-padding with spaces

         // Signs
         if (minussign)
            dst[l++] = '-';
         else if (plussign)
            dst[l++] = '+';

      // Digit extraction and placement of the decimal separator
         int dsm = l + k;                                         // decimals stop mark
         int dsp = l + ((formsel == e_form)?1:1+o-digits);        // decimal separator position
         for (; o && o > p; o--)
         {
            dst[l++] = '0';
            if (l == dsp && dsspace)
               dst[l++] = decsep;
         }

      // Transfer the BCD buffer
         for (; p >= q && l != dsm; p--)                          // add the significant digits
         {
            if (l == dsp && dsspace)
               dst[l++] = decsep;
            if (l != dsm)
               dst[l++] = '0' + bcd[p];
         }

         for (; l < dsm && l < dsp; l++)                          // add siginficant zeros after the digits and before the decimal separator
            dst[l] = '0';

         if (l == dsp && (dangleds || xtd) && dsspace)            // add a dangling decimal separator
            dst[l++] = decsep;
                                                                  //                                                   |<- xtd ->|
         while (xtd--)                                            // add the extended zero trail                       V         V
            dst[l++] = '0';                                       // 3141592653589793000000000000000000000000000000000.00000000000

      // Exponent
         if (formsel == e_form)
         {
            dst[l++] = (!capitals) ? 'e' : 'E';
            if (ilg < 0)
            {
               dst[l++] = '-';
               ilg = -ilg;
            }
            else if (exposign)
               dst[l++] = '+';

            if (kpow)
            {
              dst[l++] = '0'+(ilg/1000)%10;
              dst[l++] = '0'+(ilg/100)%10;
            }
            else if (hpow)
              dst[l++] = '0'+(ilg/100)%10;
            dst[l++] = '0'+(ilg/10)%10;
            dst[l++] = '0'+ ilg%10;
         }
      }

      else // (x == 0.0L)
      {
      zero:
         minussign = minussign && negzero;

         m -= k = ((formsel == e_form)?(exposign)?4:3:0)
                  + ((digits && nostrip0 || dangleds)?digits+1+dsspace:1)
                  + ((minussign || plussign)?1:0);
         if (m < 1)
            return 0;                                             // the result won't fit into the supplied buffer

         if (width)
            for (; l < width - k; l++)
               dst[l] = ' ';                                      // padding with spaces

         if (minussign)
            dst[l++] = '-';
         else if (plussign)
            dst[l++] = '+';

         if (digits && nostrip0 || dangleds)
         {
            dst[l++] = '0';
            if (dsspace)
               dst[l++] = decsep;
            for (int i = 0; i < digits; i++)
               dst[l++] = '0';
         }
         else
            dst[l++] = '0';

         if (formsel == e_form)
         {
            if (!capitals)
               if (!exposign)
                  cpy4(dst+l, "e00\0"), l += 3;
               else
                  cpy4(dst+l, "e+00" ), l += 4;
            else
               if (!exposign)
                  cpy4(dst+l, "E00\0"), l += 3;
               else
                  cpy4(dst+l, "E+00" ), l += 4;
         }
      }
   }

   else // (isinf(x) || isnan(x))
   {
      m -= k = ((minussign || plussign)?4:3);
      if (m < 1)
         return 0;                                                // the result won't fit into the supplied buffer

      if (width)
         for (; l < width - k; l++)
            dst[l] = ' ';                                         // padding with spaces

      if (isinf(x))
      {
         if (!capitals)
         {
            if (minussign)
               cpy4(dst+l, "-inf"), l += 4;
            else if (plussign)
               cpy4(dst+l, "+inf"), l += 4;
            else
               cpy4(dst+l,  "inf"), l += 3;
         }
         else
         {
            if (minussign)
               cpy4(dst+l, "-INF"), l += 4;
            else if (plussign)
               cpy4(dst+l, "+INF"), l += 4;
            else
               cpy4(dst+l,  "INF"), l += 3;
         }
      }

      else // isnan(x)
      {
         if (!capitals)
         {
            if (minussign)
               cpy4(dst+l, "-nan"), l += 4;
            else if (plussign)
               cpy4(dst+l, "+nan"), l += 4;
            else
               cpy4(dst+l,  "nan"), l += 3;
         }
         else
         {
            if (minussign)
               cpy4(dst+l, "-NAN"), l += 4;
            else if (plussign)
               cpy4(dst+l, "+NAN"), l += 4;
            else
               cpy4(dst+l,  "NAN"), l += 3;
         }
      }
   }

   dst[l] = '\0';
   return l;
}


#pragma mark ••• Fencing Memory Allocation Wrappers •••
// FEATURES
// -- optional clean-out in all stage, allocation, re-allocation and de-allocation
// -- specify explicit alignment
// -- check fence below the payload
// -- zero  fence above the payload
// -- deallocate via handle which places NULL into the pointer

ssize_t gAllocationTotal = 0;

static inline void countAllocation(ssize_t size)
{
   if (__atomic_add_fetch(&gAllocationTotal, size, __ATOMIC_RELAXED) < 0)
   {
      syslog(LOG_ERR, "Corruption of allocated memory detected by countAllocation().");
      exit(EXIT_FAILURE);
   }
}

static inline uint8_t padcalc(void *ptr, uint8_t align)
{
   if (align > 1)
   {
      uint8_t padis = ((uintptr_t)ptr%align);
      return (padis) ? align - padis : 0;
   }
   else
      return 0;
}

void *allocate(ssize_t size, uint8_t align, boolean cleanout)
{
   if (size >= 0)
   {
      allocation *a;

      if ((a = malloc(allocationMetaSize + align + size + sizeof(size_t))) == NULL)
         return NULL;

      if (cleanout)
         memset((void *)a, 0, allocationMetaSize + align + size + sizeof(size_t));
      else
         *(size_t *)((void *)a + allocationMetaSize + align + size) = 0;   // place a (size_t)0 just above the payload as the upper boundary of the allocation

      a->size  = size;
      a->check = (unsigned)(size | (size_t)a);
      a->fence = 'lf';     // lower fence
      a->align = align;
      a->padis = padcalc(a->payload, align);

      void *p = a->payload + a->padis;
      *(uint8_t *)(p-2) = a->align;
      *(uint8_t *)(p-1) = a->padis;

      countAllocation(size);
      return p;
   }

   else
      return NULL;
}

void *reallocate(void *p, ssize_t size, boolean cleanout, boolean free_on_error)
{
   if (size >= 0)
      if (p)
      {
         uint8_t align = *(uint8_t *)(p-2);
         uint8_t padis = *(uint8_t *)(p-1);
         allocation *a = p - allocationMetaSize - padis;

         if (a->check != (unsigned)(a->size | (size_t)a) || a->fence != 'lf' || a->align != align || a->padis != padis
          || *(ssize_t *)((void *)a + allocationMetaSize + align + a->size) != 0)
         {
            syslog(LOG_ERR, "Corruption of allocated memory detected by reallocate().");
            exit(EXIT_FAILURE);
         }

         allocation *b;
         if ((b = malloc(allocationMetaSize + align + size + sizeof(size_t))) == NULL)
         {
            if (free_on_error)
            {
               if (cleanout)
                  memset((void *)a, 0, allocationMetaSize + align + a->size + sizeof(size_t));
               countAllocation(-a->size);
               free(a);
            }

            return NULL;
         }

         else
         {
            if (cleanout)
               memset((void *)b, 0, allocationMetaSize + align + size + sizeof(size_t));
            else
               *(size_t *)((void *)b + allocationMetaSize + align + size) = 0;   // place a (size_t)0 just above the payload as the upper boundary of the allocation

            b->size  = size;
            b->check = (unsigned)(size | (size_t)b);
            b->fence = 'lf';     // lower fence
            b->align = align;
            b->padis = padcalc(b->payload, align);

            void *q = b->payload + b->padis;
            *(uint8_t *)(q-2) = b->align;
            *(uint8_t *)(q-1) = b->padis;
            memvcpy(q, p, (a->size <= size) ? a->size : size);

            if (cleanout)
               memset((void *)a, 0, allocationMetaSize + align + a->size + sizeof(size_t));
            countAllocation(size - a->size);
            free(a);
            return q;
         }
      }
      else
         return allocate(size, default_align, cleanout);

   return NULL;
}

void deallocate(void **p, boolean cleanout)
{
   if (p && *p)
   {
      uint8_t align = *(uint8_t *)(*p-2);
      uint8_t padis = *(uint8_t *)(*p-1);
      allocation *a = *p - allocationMetaSize - padis;
      *p = NULL;

      if (a->check != (unsigned)(a->size | (size_t)a) || a->fence != 'lf' || a->align != align || a->padis != padis
       || *(ssize_t *)((void *)a + allocationMetaSize + align + a->size) != 0)
      {
         syslog(LOG_ERR, "Corruption of allocated memory detected by deallocate().");
         exit(EXIT_FAILURE);
      }

      if (cleanout)
         memset((void *)a, 0, allocationMetaSize + align + a->size + sizeof(size_t));
      countAllocation(-a->size);
      free(a);
   }
}

void deallocate_batch(int cleanout, ...)
{
   void   **p;
   va_list  vl;
   va_start(vl, cleanout);

   while (p = va_arg(vl, void **))
      if (*p)
      {
         uint8_t align = *(uint8_t *)(*p-2);
         uint8_t padis = *(uint8_t *)(*p-1);
         allocation *a = *p - allocationMetaSize - padis;
         *p = NULL;

         if (a->check != (unsigned)(a->size | (size_t)a) || a->fence != 'lf' || a->align != align || a->padis != padis
          || *(ssize_t *)((void *)a + allocationMetaSize + align + a->size) != 0)
         {
            syslog(LOG_ERR, "Corruption of allocated memory detected by deallocate_batch().");
            exit(EXIT_FAILURE);
         }

         if (cleanout)
            memset((void *)a, 0, allocationMetaSize + align + a->size + sizeof(size_t));
         countAllocation(-a->size);
         free(a);
      }

   va_end(vl);
}

ssize_t allocsize(void *p)
{
   return (p)
      ? ((allocation *)(p - allocationMetaSize - *(uint8_t *)(p-1)))->size
      : 0;
}


// String concat to dst with variable number of src/len pairs, whereby each len
// serves as the l parameter in strmlcpy(), i.e. strmlcpy(dst, src, ml, &len)
// m: Max. capacity of dst, including the final nul.
//    If m == 0, then the sum of the length of all src strings is returned in l - nothing is copied though.
// l: On entry, offset into dst or -1, when -1, the offset is the end of the initial string in dst
//    On exit, the length of the total concat, even if it would not fit into dst, maybe NULL.
// Returns the length of the resulting string in dst.
int strmlcat(char *dst, int m, int *l, ...)
{
   va_list     vl;
   int         k, n;
   const char *s;

   if (l && *l)
   {
      if (*l == -1)
         *l = strvlen(dst);
      n = k = *l;
   }
   else
      n = k = 0;

   va_start(vl, l);
   while (s = va_arg(vl, const char *))
   {
      if (k = va_arg(vl, int))
         if (n < m)
         {
            n += strmlcpy(&dst[n], s, m-n, &k);
            if (l) *l += k;
         }
         else
            if (l) *l += (k) ?: strvlen(s);
   }
   va_end(vl);

   return n;
}


#pragma mark ••• AVL Tree •••
#pragma mark ••• Value Data householding •••

static inline void releaseValue(Value *value)
{
   switch (-value->kind)   // dynamic data, has to be released
   {
      case String:
         if (value->custom_deallocate)
            value->custom_deallocate(VPR(value->s), value->offset, false);
         else
            deallocate(VPR(value->s), false);
         break;

      case Simple:
      case Data:
      case Dictionary:
         if (value->custom_deallocate)
            value->custom_deallocate(VPR(value->p), value->offset, false);
         else
            deallocate(VPR(value->p), false);
         break;
   }
}


static int balanceNode(Node **node)
{
   int   change = 0;
   Node *o = *node;
   Node *p, *q;

   if (o->B == -2)
   {
      if (p = o->L)                    // make the static analyzer happy
         if (p->B == +1)
         {
            change = 1;                // double left-right rotation
            q      = p->R;             // left rotation
            p->R   = q->L;
            q->L   = p;
            o->L   = q->R;             // right rotation
            q->R   = o;
            o->B   = +(q->B < 0);
            p->B   = -(q->B > 0);
            q->B   = 0;
            *node  = q;
         }

         else
         {
            change = p->B;             // single right rotation
            o->L   = p->R;
            p->R   = o;
            o->B   = -(++p->B);
            *node  = p;
         }
   }

   else if (o->B == +2)
   {
      if (q = o->R)                    // make the static analyzer happy
         if (q->B == -1)
         {
            change = 1;                // double right-left rotation
            p      = q->L;             // right rotation
            q->L   = p->R;
            p->R   = q;
            o->R   = p->L;             // left rotation
            p->L   = o;
            o->B   = -(p->B > 0);
            q->B   = +(p->B < 0);
            p->B   = 0;
            *node  = p;
         }

         else
         {
            change = q->B;             // single left rotation
            o->R   = q->L;
            q->L   = o;
            o->B   = -(--q->B);
            *node  = q;
         }
   }

   return change != 0;
}


static int pickPrevNode(Node **node, Node **exch)
{                                       // *exch on entry = parent node
   Node *o = *node;                     // *exch on exit  = picked previous value node

   if (o->R)
   {
      *exch = o;
      int change = -pickPrevNode(&o->R, exch);
      if (change)
         if (abs(o->B += change) > 1)
            return balanceNode(node);
         else
            return o->B == 0;
      else
         return 0;
   }

   else if (o->L)
   {
      Node *p = o->L;
      o->L = NULL;
      (*exch)->R = p;
      *exch = o;
      return p->B == 0;
   }

   else
   {
      (*exch)->R = NULL;
      *exch = o;
      return 1;
   }
}


static int pickNextNode(Node **node, Node **exch)
{                                       // *exch on entry = parent node
   Node *o = *node;                     // *exch on exit  = picked next value node

   if (o->L)
   {
      *exch = o;
      int change = +pickNextNode(&o->L, exch);
      if (change)
         if (abs(o->B += change) > 1)
            return balanceNode(node);
         else
            return o->B == 0;
      else
         return 0;
   }

   else if (o->R)
   {
      Node *q = o->R;
      o->R = NULL;
      (*exch)->L = q;
      *exch = o;
      return q->B == 0;
   }

   else
   {
      (*exch)->L = NULL;
      *exch = o;
      return 1;
   }
}


// CAUTION: The following recursive functions must not be called with name == NULL.
//          For performace reasons no extra error cheking is done.

Node *findTreeNode(const char *name, Node *node)
{
   if (node)
   {
      int ord = strcmp(name, node->name);

      if (ord == 0)
         return node;

      else if (ord < 0)
         return findTreeNode(name, node->L);

      else // (ord > 0)
         return findTreeNode(name, node->R);
   }

   else
      return NULL;
}

int addTreeNode(const char *name, ssize_t naml, Value *value, Node **node, Node **passed)
{
   static const Value zeros = {{.i = 0}, 0, 0, 0, NULL};

   Node *o = *node;

   if (o == NULL)                         // if the name is not in the tree
   {                                      // then add it into a new leaf
      if (o = allocate(sizeof(Node), default_align, true))
         if (o->name = allocate(naml+1, default_align, false))
         {
            strcpy(o->name, name);
            o->naml = naml;
            if (value)
               o->value = *value;
            *node = *passed = o;          // report back the new node into which the new value has been entered
            return 1;                     // add the weight of 1 leaf onto the balance
         }
         else
            deallocate(VPR(o), false);

      *passed = NULL;
      return 0;                           // Out of Memory situation, nothing changed
   }

   else
   {
      int change;
      int ord = strcmp(name, o->name);

      if (ord == 0)                       // if the name is already in the tree then
      {
         releaseValue(&o->value);         // release the old value - if kind is empty then releaseValue() does nothing
         o->value = (value) ? *value      // either store the new value or
                            :  zeros;     // zero-out the value struct
         *passed = o;                     // report back the node in which the value was modified
         return 0;
      }

      else if (ord < 0)
         change = -addTreeNode(name, naml, value, &o->L, passed);

      else // (ord > 0)
         change = +addTreeNode(name, naml, value, &o->R, passed);

      if (change)
         if (abs(o->B += change) > 1)
            return 1 - balanceNode(node);
         else
            return o->B != 0;
      else
         return 0;
   }
}

int removeTreeNode(const char *name, Node **node)
{
   Node *o = *node;

   if (o == NULL)
      return 0;                              // not found -> recursively do nothing

   else
   {
      int change;
      int ord = strcmp(name, o->name);

      if (ord == 0)
      {
         int    b = o->B;
         Node  *p = o->L;
         Node  *q = o->R;

         if (!p || !q)
         {
            releaseValue(&(*node)->value);
            deallocate_batch(false, VPR((*node)->name),
                                    VPR(*node), NULL);
            *node = (p > q) ? p : q;
            return 1;                        // remove the weight of 1 leaf from the balance
         }

         else
         {
            if (b == -1)
            {
               if (!p->R)
               {
                  change = +1;
                  o      =  p;
                  o->R   =  q;
               }
               else
               {
                  change = +pickPrevNode(&p, &o);
                  o->L   =  p;
                  o->R   =  q;
               }
            }

            else
            {
               if (!q->L)
               {
                  change = -1;
                  o      =  q;
                  o->L   =  p;
               }
               else
               {
                  change = -pickNextNode(&q, &o);
                  o->L   =  p;
                  o->R   =  q;
               }
            }

            o->B = b;
            releaseValue(&(*node)->value);
            deallocate_batch(false, VPR((*node)->name),
                                    VPR(*node), NULL);
            *node = o;
         }
      }

      else if (ord < 0)
         change = +removeTreeNode(name, &o->L);

      else // (ord > 0)
         change = -removeTreeNode(name, &o->R);

      if (change)
         if (abs(o->B += change) > 1)
            return balanceNode(node);
         else
            return o->B == 0;
      else
         return 0;
   }
}

void releaseTree(Node *node)
{
   if (node)
   {
      if (node->L)
         releaseTree(node->L);
      if (node->R)
         releaseTree(node->R);

      releaseValue(&node->value);
      deallocate_batch(false, VPR(node->name),
                              VPR(node), NULL);
   }
}

void serializeTree(Node *table[], uint *namColWidth, uint *m, Node *node)
{
   if (node)
   {
      if (node->L)
         serializeTree(table, namColWidth, m, node->L);

      table[(*m)++] = node;
      if (node->naml > *namColWidth)
         *namColWidth = (uint)node->naml;

      if (node->R)
         serializeTree(table, namColWidth, m, node->R);
   }
}


void printTree(Node *node, uint naml)
{
   if (node->L)
      printTree(node->L, naml);

   printf(" %*s: %s\n", naml, node->name, node->value.s);

   if (node->R)
      printTree(node->R, naml);
}


#pragma mark ••• Hash Table •••

// Table creation and release
Node **createTable(uint n)
{
   Node **table = allocate((n+2)*sizeof(Node *), default_align, true);
   if (table)
      *(uint *)table = n;
   return table;
}

void releaseTable(Node *table[])
{
   if (table)
   {
      uint i, n = 2 + *(uint *)&table[0];
      for (i = 2; i < n; i++)
         releaseTree(table[i]);
      deallocate(VPR(table), false);
   }
}


// Storing and retrieving values by name
Node *findName(Node *table[], const char *name, ssize_t naml)
{
   if (name && *name)
   {
      if (naml <= 0)
         naml = strvlen(name);
      uint n = *(uint *)&table[0];
      return findTreeNode(name, table[mmh3(name, naml)%n + 2]);
   }
   else
      return NULL;
}

Node *storeName(Node *table[], const char *name, ssize_t naml, Value *value)
{
   if (name && *name)
   {
      Node *passed;

      if (naml <= 0)
         naml = strvlen(name);
      uint n = *(uint *)&table[0];
      addTreeNode(name, naml, value, &table[mmh3(name, naml)%n + 2], &passed);
      (*(uint *)&table[1])++;

      return passed;
   }
   else
      return NULL;
}

void removeName(Node *table[], const char *name, ssize_t naml)
{
   if (name && *name)
   {
      if (naml <= 0)
         naml = strvlen(name);
      uint tidx = mmh3(name, naml) % *(uint*)&table[0] + 2;
      Node *node = table[tidx];
      if (node)
      {
         if (!node->L && !node->R)
         {
            releaseValue(&node->value);
            deallocate_batch(false, VPR(node->name),
                                    VPR(table[tidx]), NULL);
         }
         else
            removeTreeNode(name, &table[tidx]);

         (*(uint *)&table[1])--;
      }
   }
}


static void quicksort(Node *a[], int l, int r)
{
   char *m = a[(l + r)/2]->name;
   int   i = l, j = r;
   Node *b;

   do
   {
      while (strcmp(a[i]->name, m) < 0) i++;
      while (strcmp(a[j]->name, m) > 0) j--;
      if (i <= j)
      {
         b = a[i]; a[i] = a[j]; a[j] = b;
         i++; j--;
      }
   } while (j > i);

   if (l < j) quicksort(a, l, j);
   if (i < r) quicksort(a, i, r);
}


void printTable(Node *table[], uint *nameColWidth)
{
   uint  i, m = 0, n = 2 + *(uint *)&table[0];
   Node *sort[OSP(*(uint *)&table[1])];
   for (m = 0, i = 2; i < n; i++)
      if (table[i])
         serializeTree(sort, nameColWidth, &m, table[i]);

   if (m)
   {
      quicksort(sort, 0, m-1);
      for (i = 0; i < m; i++)
         printf(" %*s: %s\n", *nameColWidth, sort[i]->name, sort[i]->value.s);
   }
}

int sprintTable(Node *table[], uint *namColWidth, dynhdl output)
{
   if (output)
   {
      if (!output->buf)
         *output = newDynBuffer();

      uint  i, m = 0, n = 2 + *(uint *)&table[0];
      Node *sort[OSP(*(uint *)&table[1])];
      for (m = 0, i = 2; i < n; i++)
         if (table[i])
            serializeTree(sort, namColWidth, &m, table[i]);

      if (m)
      {
         quicksort(sort, 0, m-1);

         char namColumn[OSP(1+*namColWidth+5+1)];
         for (i = 0; i < m; i++)
         {
            dynAddString(output, namColumn, snprintf(namColumn, 3+*namColWidth+2+1, "   %*s: ", *namColWidth, sort[i]->name));
            dynAddString(output, sort[i]->value.s, strvlen(sort[i]->value.s));
            dynAddString(output, "\n", 1);
         }
      }

      return dynlen(*output);
   }
   else
      return 0;
}


#pragma mark ••• File Copying & Recursive Directory Deletion •••

#if defined (__APPLE__)

   #define fnocache(fd) fcntl(fd, F_NOCACHE, 1)

#elif defined (__FreeBSD__)

   #define fnocache(fd) fcntl(fd, F_SETFL, O_DIRECT)

#endif

int fileCopy(char *src, char *dst, struct stat *st)
{
#define bufsiz 131072

   int infd, outfd;

   if ((infd = open(src, O_RDONLY)) != -1)
      if ((outfd = open(dst, O_WRONLY|O_CREAT|O_TRUNC|O_EXLOCK, st->st_mode&ALLPERMS)) != -1)
      {
         fnocache(infd);
         fnocache(outfd);

         int    rc = no_error;
         size_t size, filesize = 0;
         char  *buffer = allocate(bufsiz, default_align, false);

         do
         {
            if ((size = read(infd, buffer, bufsiz)) == -1)
               rc = -errno;
            else if (size != 0 && write(outfd, buffer, size) == -1)
               rc =  errno;
            else
               filesize += size;
         } while (rc == no_error && size == bufsiz);

         deallocate(VPR(buffer), false);

         close(outfd);
         close(infd);

         if (rc == no_error && filesize != st->st_size &&   // if the filesize changed then most probably
             lstat(src, st) != no_error)                    // other things changed too, so lstat() again.
            rc = -errno;

         return rc;
      }

      else  // !out
      {
         close(infd);
         return errno;
      }

   else     // !in
      return -errno;

#undef bufsiz
}

int dtType2stFmt(int d_type)
{
   switch (d_type)
   {
      default:
      case DT_UNKNOWN:  //  0 - The type is unknown.
         return 0;
      case DT_FIFO:     //  1 - A named pipe or FIFO.
         return DT_FIFO;
      case DT_CHR:      //  2 - A character device.
         return DT_CHR;
      case DT_DIR:      //  4 - A directory.
         return S_IFDIR;
      case DT_BLK:      //  6 - A block device.
         return S_IFBLK;
      case DT_REG:      //  8 - A regular file.
         return S_IFREG;
      case DT_LNK:      // 10 - A symbolic link.
         return S_IFLNK;
      case DT_SOCK:     // 12 - A local-domain socket.
         return S_IFSOCK;
      case DT_WHT:      // 14 - A whiteout file. (somehow deleted, but not eventually yet)
         return S_IFWHT;
   }
}


int deleteDirEntity(char *path, size_t pl, llong st_mode)
{
   static char errorString[256];
   const char *ftype;
   int err, rc = no_error;

   switch (st_mode & S_IFMT)
   {
      case S_IFDIR:      // A directory.
         if (path[pl-1] != '/')
            cmp2(path+pl++, "/");
         chflags(path, 0);
         if (err = deleteDirectory(path, pl))
            rc = err;
         else if (rmdir(path) != no_error)
         {
            rc = errno;
            strerror_r(rc, errorString, 256);
            syslog(LOG_ERR, "\nDirectory %s could not be deleted: %s.\n", path, errorString);
         }
         break;

      case S_IFIFO:      // A named pipe or FIFO.
      case S_IFREG:      // A regular file.
      case S_IFLNK:      // A symbolic link.
      case S_IFSOCK:     // A local-domain socket.
      case S_IFWHT:      // A whiteout file. (somehow deleted, but not eventually yet)
         lchflags(path, 0);
         if (unlink(path) != no_error)
         {
            rc = errno;
            strerror_r(rc, errorString, 256);
            syslog(LOG_ERR, "\nFile %s could not be deleted: %s.\n", path, errorString);
         }
         break;

      case S_IFCHR:      // A character device.
         ftype = "a character device";
         goto special;
      case S_IFBLK:      // A block device.
         ftype = "a block device";
         goto special;
      default:
         ftype = "of unknown type";
      special:
         syslog(LOG_ERR, "\n%s is %s, it could not be deleted.\n", path, ftype);
         break;
   }

   return rc;
}

int deleteDirectory(char *path, size_t pl)
{
   int rc = no_error;

   DIR   *dp;
   struct dirent bep, *ep;

   if (dp = opendir(path))
   {
      struct stat st;
      while (readdir_r(dp, &bep, &ep) == 0 && ep)
         if ( ep->d_name[0] != '.' || (ep->d_name[1] != '\0' &&
             (ep->d_name[1] != '.' ||  ep->d_name[2] != '\0')))
         {
            // next path
            size_t npl   = pl + ep->d_namlen;
            char  *npath = strcpy(allocate(npl+2, default_align, false), path); strcpy(npath+pl, ep->d_name);

            if (ep->d_type != DT_UNKNOWN)
               rc = deleteDirEntity(npath, npl, dtType2stFmt(ep->d_type));
            else if (lstat(npath, &st) != -1)
               rc = deleteDirEntity(npath, npl, st.st_mode);
            else
               rc = errno;

            deallocate(VPR(npath), false);
         }

      closedir(dp);
   }

   return rc;
}


#pragma mark ••• MIME Types •••

// Internet Media Types (originally MIME). http://en.wikipedia.org/wiki/Internet_media_type
const char *extensionToType(char *fnam, int flen)
{
   const char *mime = "text/plain";

   if (fnam && *fnam)
   {
      if (!flen)
         flen = strvlen(fnam);

      char *ext;
      for (ext = fnam+flen-1; ext >= fnam && *ext != '.'; ext--);
      if (ext < fnam)
         return NULL;

      switch (FourLoChars(ext += 1))
      {
         case 'html':
         if (ext[4] != '\0')
            break;
         case 'htm\0':
            mime = "text/html; charset=utf-8";
            break;
         case 'css\0':
            mime = "text/css; charset=utf-8";
            break;
         case 'ics\0':
            mime = "text/calendar; charset=utf-8";
            break;
         case 'png\0':
            mime = "image/png";
            break;
         case 'jpeg':
            if (ext[4] != '\0')
               break;
         case 'jpg\0':
            mime = "image/jpeg";
            break;
         case 'gif\0':
            mime = "image/gif";
            break;
         case 'ico\0':
            mime = "image/x-icon";
            break;
         case 'svg\0':
            mime = "image/svg+xml; charset=utf-8";
            break;
         case 'woff':
            if (ext[4] == '\0')
               mime = "application/font-woff";
            break;
         case 'pdf\0':
            mime = "application/pdf";
            break;
         case 'crt\0':
            mime = "application/x-x509-ca-cert";
            break;
         case 'xml\0':
            mime = "application/xml; charset=utf-8";
            break;
         case 'xhtm':
            if (LoChar(ext[4]) == 'l' && ext[5] == '\0')
               mime = "application/xhtml+xml; charset=utf-8";
            break;
         case 'zip\0':
            mime = "application/zip";
            break;
         case 'cgi\0':
            mime = "excecutable/cgi";
            break;
         case 'cva\0':
         case 'tui\0':
         case 'txy\0':
         case 'zva\0':
            mime = "application/cva";
            break;
         case 'appc':
            if (FourLoChars(&ext[4]) == 'ache' && ext[8] == '\0')
               mime = "text/cache-manifest";
            break;
         default:
            if (LoChar(ext[0]) == 'j' && LoChar(ext[1]) == 's' && ext[2] == '\0')
               mime = "application/x-javascript";
            break;
      }
   }

   return mime;
}
