//  cycalc.h
//  CyCalc Scientific Calculator Library
//
//  Created by Dr. Rolf Jansen on 2006-02-27.
//  Copyright © 2006-2018 Dr. Rolf Jansen. All rights reserved.

#warning: \
IMPORTANT: The CyCalc Library is Open Soruce but it is NOT FREE. \
Copyright © 2006-2018 Dr. Rolf Jansen. All rights reserved.

//
//  You may solely evaluate this Software in your develpoment projects.
//
//  Without express permissions by the copyright holder you MAY NOT distribute this software:
//  - neither as a compiled-in binary nor as a separate binary library,
//  - neither as is nor as mofified source code or as part of other sources.
//
//  As well, you MAY NOT deploy calculators based on the CyCalc Library as web service,
//  other than on a test server for your evaluation for your development projects.
//
//  Please ask Dr. Rolf Jansen for a non-abusive commercial license -> cycalc(at)cyclaero.com


#import "CyObject.h"
#import "delegate-utils.h"

#pragma GCC visibility push(hidden)

#if __PTR_WIDTH__ == 32
   #pragma pack(4)
#else
   #pragma pack(8)
#endif

#ifdef __FreeBSD__

   // Missing definitions of math functions in FreeBSD

   #if defined(__i386__) || defined(__x86_64__)

      // long double is IEEE 80bit extended

      #define powl(x, y) _powl(x, y)
      #define tgammal(x) _tgammal(x)

      long double _powl(long double x, long double y);
      long double _tgammal(long double x);

      long double complex cpowl(long double complex x, long double complex y);
      long double complex csinl(long double complex z);
      long double complex casinl(long double complex z);
      long double complex ccosl(long double complex z);
      long double complex cacosl(long double complex z);
      long double complex ctanl(long double complex z);
      long double complex catanl(long double complex z);
      long double complex cexpl(long double complex z);
      long double complex clogl(long double complex z);
      long double complex csinhl(long double complex z);
      long double complex casinhl(long double complex z);
      long double complex ccoshl(long double complex z);
      long double complex cacoshl(long double complex z);
      long double complex ctanhl(long double complex z);
      long double complex catanhl(long double complex z);

   #elif defined(__arm__)

      // long double is double

      #define erfl(x)    erf(x)
      #define powl(x,y)  pow(x,y)
      #define tgammal(x) tgamma(x)

      #define csinl(z)   csin(z)
      #define casinl(z)  casin(z)
      #define ccosl(z)   ccos(z)
      #define cacosl(z)  cacos(z)
      #define ctanl(z)   ctan(z)
      #define catanl(z)  catan(z)
      #define cexpl(z)   cexp(z)
      #define csinhl(z)  csinh(z)
      #define casinhl(z) casinh(z)
      #define ccoshl(z)  ccosh(z)
      #define cacoshl(z) cacosh(z)
      #define ctanhl(z)  ctanh(z)
      #define catanhl(z) catanh(z)

      static inline long double complex cpowl(long double complex x, long double complex y) { return (long double complex){0.0L, 0.0L}; }
      static inline long double complex clogl(long double complex z)                        { return (long double complex){0.0L, 0.0L}; }

   #endif
#endif


#pragma mark ••• Calculator definitions and class interfaces •••

typedef enum
{
   noError        = 0,
   syntaxError    = 1,
   semanticError  = 2,
   paramError     = 4,
   logicalError   = 8,
   typeError      = 16,
   nanError       = 32,
   singularError  = 64,
   oorError       = 128,
   recursionError = 256
} ErrorFlags;

typedef enum
{
   noResult      = -1,
   plainResult   =  0,
   binResult     =  1,
   hexResult     =  2,
   fractResult   =  4,
   numResult     =  8,
   strResult     = 16,
   percentResult = 32
} ResultModifier;

typedef enum
{
   rtNone      = 0,
   rtBoolean   = 1,
   rtInteger   = 2,
   rtReal      = 4,
   rtComplex   = 8,
   rtVector    = 16,
   rtString    = 32,
   rtUndefined = 64,
   rtError     = 128,
   rtScalar    = rtBoolean|rtInteger|rtReal
} ResultTypeFlags;

typedef enum
{
   factor,
   function,
   monadic,
   special,
   exproot,
   muldiv,
   addsub,
   bshift,
   compare,
   band,
   bxor,
   bor,
   land,
   lxor,
   lor,
   equate,
   assign,
   separate
} Precedence;

typedef enum
{
   param         = 0,
   unary         = 1,
   binary        = 2,
   ternary       = 3,
   quaternary    = 4,
   quinary       = 5,
   multiple      = 0x7FFFFFFF
} OpKind;

typedef enum
{
   openParent    = 1,
   openComplex   = 2,
   openVector    = 4,
   closeBrackets = 8,
   listSep       = 16,
   unaryOp       = 32,
   binaryOp      = 64,
   aPlus         = 128,
   aMinus        = 256,
   aPoint        = 512,
   anE           = 1024,
   numPlusMinus  = 2048,
   numDigit      = 4096,
   numPoint      = 8192,
   numExponent   = 16384,
   numPercent    = 32768,
   hexNum        = 65536,
   binNum        = 131072,
   other         = 262144,
   numVarFunc    = 524288,
   blank         = 1048576,
   assignment    = 2097152
} SyntaxFlags;

typedef enum
{
   Enter         = closeBrackets | listSep | numPlusMinus | numDigit | numPoint | numExponent | numPercent | hexNum | binNum | other | numVarFunc | blank,
   Digit         = openParent | openComplex | openVector | listSep | unaryOp | binaryOp | aPlus | aMinus | aPoint | anE | numPlusMinus | numDigit | numPoint | numExponent | hexNum | binNum | other | blank,
   DecSeparator  = openParent | openComplex | openVector | listSep | unaryOp | binaryOp | aPlus | aMinus | numPlusMinus | numDigit | blank,
   Hex           = openParent | openComplex | openVector | listSep | unaryOp | binaryOp | aPlus | aMinus | numPlusMinus | numDigit | blank,
   Bin           = openParent | openComplex | openVector | listSep | unaryOp | binaryOp | aPlus | aMinus | numPlusMinus | numDigit | blank,
   PlusCheck     = openParent | openComplex | openVector | closeBrackets | listSep | unaryOp | binaryOp | aMinus | anE | numPlusMinus | numDigit | numPoint | numExponent | numPercent | hexNum | binNum | other | numVarFunc | blank,
   MinusCheck    = openParent | openComplex | openVector | closeBrackets | listSep | unaryOp | binaryOp | aPlus  | anE | numPlusMinus | numDigit | numPoint | numExponent | numPercent | hexNum | binNum | other | numVarFunc | blank,
   BinOperator   = closeBrackets | numPlusMinus | numDigit | numPoint | numExponent | numPercent | hexNum | binNum | other | numVarFunc | blank,
   UnOperator    = openParent | openComplex | openVector | listSep | unaryOp | binaryOp | aPlus | aMinus | blank,
   ParentOpen    = openParent | openComplex | openVector | listSep | unaryOp | binaryOp | aPlus | aMinus | other | numVarFunc | blank,
   ComplexOpen   = openParent | openComplex | openVector | listSep | unaryOp | binaryOp | aPlus | aMinus | blank,
   VectorOpen    = openParent | openComplex | openVector | listSep | unaryOp | binaryOp | aPlus | aMinus | blank,
   BracketsClose = closeBrackets | numPlusMinus | numDigit | numPoint | numExponent | numPercent | hexNum | binNum | other | numVarFunc | blank,
   Name          = openParent | openComplex | openVector | listSep | unaryOp | binaryOp | aPlus | aMinus | other | blank,
   NumState      = numPlusMinus | numDigit | numPoint | numExponent | numPercent | hexNum | binNum,
   Assignment    = other | numVarFunc | blank
} SyntaxStates;


typedef int          *Index;
typedef long double  *Vector;
typedef long double **Matrix;

typedef struct
{
   ErrorFlags   flag;
   unsigned     begin, count;
} ErrorRecord;

typedef struct ResultType
{
   ResultTypeFlags     f;
   unsigned            n;
   boolean             b;
   llong               i;
   long double         r;
   long double complex z;
   struct ResultType  *v;
   char               *s;
   ErrorRecord         e;
} ResultType;


ResultType *copyVector(ResultType *v);
void freeVector(ResultType *v);


typedef struct TokenRecord *TokenPtr;
@class Calculator;

@interface CalcObject : CyObject
{
   boolean     isPercent;
   TokenPtr    itsToken;
   Precedence  itsPrecedence;
   OpKind      itsOpKind;
   CalcObject *itsParent;
   Calculator *itsCalculator;
}

- (id)initWithToken:(TokenPtr)token :(Precedence)precedence :(OpKind)opKind;
- (boolean)percent;
- (void)setPercent:(boolean)flag;
- (TokenPtr)itsToken;
- (void)setToken:(TokenPtr)token;
- (void)setCalculator:(Calculator *)calculator;
- (Precedence)itsPrecedence;
- (id)itsParent;
- (void)setErrorInToken:(ErrorFlags)flag :(ErrorRecord *)error;
- (void)setErrorInEvaluation:(ErrorFlags)flag :(ResultType *)evalError :(unsigned)actualEnd;
- (ResultType)evaluate:(unsigned)index;
- (long double)evaluateReal:(unsigned)index;

@end

typedef struct TokenRecord
{
   unsigned     tBegin;
   unsigned     tCount;
   SyntaxFlags  tCheck;
   char         tLiteral[256];
   CalcObject  *tObject;
   TokenPtr     tNext;
} TokenRecord;


@interface CalcFactor : CalcObject
{
   ResultType itsValue;
}

- (id)initWithValue:(ResultType *)value :(Precedence)precedence :(OpKind)opKind;
- (ResultType)itsValue;
- (void)setValue:(ResultType *)value;

@end


@interface CalcExternal : CalcFactor
{
   void *itsReference;
}

- (void)setReference:(void *)reference of:(ResultTypeFlags)type;

@end


@interface CalcSeries : CalcExternal
@end


@interface CalcCurrency : CalcFactor

- (void)freeCurrencyName;

@end


@interface CalcComplex : CalcFactor
{
   int         count;
   CalcObject *cplx[2];
}

- (ErrorFlags)addNextElement:(CalcObject *)node;

@end


@interface CalcVector : CalcFactor
{
   int          elemCount;
   CalcObject **elements;
}

- (void)addNextElement:(CalcObject *)node;

@end


@interface CalcUni : CalcObject
{
   int         paramCount;
   CalcObject *lastTerm, *nextTerm;
}

- (id)nextTerm;
- (void)addNextNode:(CalcObject *)node;
- (boolean)checkParamCount:(ErrorRecord *)error;
- (boolean)typeEnforce:(ResultTypeFlags)rtCheck :(ResultType *)r;

- (void)evalScalar:(ResultType *)s;
- (void)evalVector:(ResultType *)v;

@end


@interface CalcDuo : CalcUni
{
   CalcObject *prevTerm;
}

- (id)prevTerm;
- (void)addPrevNode:(CalcObject *)node;
- (ResultTypeFlags)typeAdjust:(ResultTypeFlags)rtCheck :(ResultType *)r1 :(ResultType *)r2 :(ResultType *)r;

- (void)evalScalar:(ResultType *)s withScalar:(ResultType *)t result:(ResultType *)r;
- (void)evalVector:(ResultType *)v withScalar:(ResultType *)s;
- (void)evalScalar:(ResultType *)s withVector:(ResultType *)v;
- (void)evalVector:(ResultType *)v withVector:(ResultType *)w;

@end


@interface CalcMulti : CalcDuo
{
   CalcObject **multi;
}
@end


@interface Calculator : CyObject
{
   boolean isMaster;
   int     decDigits, sigDigits;
   Node  **variableStore;
   Node ***variableStoreHandle;
}

- (void)storeVariable:(const char *)identifier :(ssize_t)identlen :(CalcObject **)variable;
- (void)storeIntegerVariable:(const char *)identifier value:(llong)integer;
- (void)storeRealVariable:(const char *)identifier value:(long double)real;
- (void)storeExternalVariable:(const char *)identifier reference:(void *)reference of:(ResultTypeFlags)type;
- (void)storeSeriesVariable:(const char *)identifier reference:(void *)reference of:(ResultTypeFlags)type;
- (void)storeTemplate:(const char *)identifier :(CalcObject *)template;
- (void)storeAtomMass:(const char *)elementSymbol value:(long double)atomicWeight name:(const char *)elementName;

- (void)initIntrinsics;
- (void)disposeTokens:(TokenPtr)token;
- (TokenPtr)scan:(char *)s error:(ErrorRecord *)calcError;
- (CalcObject *)parse:(TokenPtr *)curTokenPtr error:(ErrorRecord *)calcError;

- (ResultModifier)preProcess:(char **)function;
- (char *)postProcess:(ResultType *)result modifier:(ResultModifier)resultModifier resultBuffer:(char **)result;

// generic calculate method
- (ResultType)calculate:(char *)function index:(unsigned)idx;

@end

typedef struct
{
   Calculator *calc;
   CalcObject *func;
   TokenPtr    tokens;
   ErrorRecord errRec;
} CalcPrep;

#pragma pack()


#pragma mark ••• Global Calculator Parameters •••

// Tolerances
#define RelTol ldexpl(__LDBL_EPSILON__, 22)
#define AbsTol ldexpl(__LDBL_EPSILON__, 12)

// Calculator Settings
char    gDecSep             = ',';
int     gSigDigits          = 10;
int     gDecDigits          = 10;
boolean gLazyPercentFlag    = true;
boolean gAutoReal2CmplxFlag = true;

ResultType gNoneResult = {rtNone, 0, false, 0LL, __builtin_nanl("255"), {0.0L, 0.0L}, NULL, NULL, {noError, 0, 0}};
ResultType gNullResult = {rtReal, 0, false, 0LL,                  0.0L, {0.0L, 0.0L}, NULL, NULL, {noError, 0, 0}};


ResultType *copyVector(ResultType *v)
{
   unsigned i, n;
   n = v->n;
   v = v->v;

   if (v)
   {
      ResultType *u = allocate(n*sizeof(ResultType), default_align, false);

      for (i = 0; i < n; i++)
      {
         u[i] = v[i];
         if (v[i].f == rtVector)
            u[i].v = copyVector(&v[i]);
      }

      return u;
   }

   return NULL;
}

void freeVector(ResultType *v)
{
   ResultType *u = v->v;

   if (u)
   {
      unsigned i, n = v->n;

      for (i = 0; i < n; i++)
         freeVector(&u[i]);
      deallocate(VPR(u), false);

      v->n = 0;
      v->v = NULL;
   }
}

void simplifyVector(ResultType *v)
{
   if (v->f == rtComplex && cimagl(v->z) == 0.0L)
      v->f = rtReal, v->r = creall(v->z);

   else while (v->f == rtVector)
   {
      ResultType *u = v->v;
      unsigned i, n = v->n;

      if (n > 1)
      {
         for (i = 0; i < n; i++)
            simplifyVector(&u[i]);
         return;
      }

      else // (n == 1)
      {
         *v = *u;
         deallocate(VPR(u), false);
      }
   }
}


static inline long double complex cdivl(long double complex dividend, long double complex divisor)
{
   if (creall(divisor) == 0.0L && cimagl(divisor) == 0.0L)
      dividend = __builtin_infl();
   else if (isinf(creall(divisor)) || isinf(cimagl(divisor)))
      dividend = 0.0L;
   else
      dividend /= divisor;
   return dividend;
}


long double sqrsum(ResultType *v)
{
   long double s = 0.0L;
   unsigned i, n = v->n;
   v = v->v;
   for (i = 0; i < n; i++)
      switch (v[i].f)
      {
         case rtBoolean:
            s += v[i].b;
            break;

         case rtInteger:
            s += v[i].i*v[i].i;
            break;

         case rtReal:
            s += sqrl(v[i].r);
            break;

         case rtComplex:
            s += sqrl(cabsl(v[i].z));

         case rtVector:
            s += sqrsum(&v[i]);
      }

   return s;
}


#pragma mark ••• Calculator Objects •••

@implementation CalcObject

- (id)initWithToken:(TokenPtr)token :(Precedence)precedence :(OpKind)opKind
{
   if (self = [super init])
   {
      itsToken      = token;
      itsPrecedence = precedence;
      itsOpKind     = opKind;
   }
   return self;
}

- (id)copyWithZone:(void *)zone
{
   return [[[self class] alloc] initWithToken:itsToken :itsPrecedence :itsOpKind];
}

- (boolean)percent
{
   return isPercent;
}

- (void)setPercent:(boolean)flag
{
   isPercent = YES;
}

- (TokenPtr)itsToken
{
   return itsToken;
}

- (void)setToken:(TokenPtr)token
{
   itsToken = token;
}

- (void)setCalculator:(Calculator *)calculator
{
   itsCalculator = calculator;
}

- (Precedence)itsPrecedence
{
   return itsPrecedence;
}

- (id)itsParent
{
   return itsParent;
}

- (void)setParent:(CalcObject *)parent
{
   itsParent = parent;
}

- (void)setErrorInToken:(ErrorFlags)flag :(ErrorRecord *)error
{
   if (flag > noError && itsToken != NULL)
   {
      error->flag  = flag;
      error->begin = itsToken->tBegin;
      error->count = itsToken->tCount;
   }

   else
   {
      error->flag  = flag;
      error->begin = 0;
      error->count = 0;
   }
}

- (void)setErrorInEvaluation:(ErrorFlags)flag :(ResultType *)evalError :(unsigned)actualEnd
{
   if (flag > noError)
      evalError->f = rtError;

   if (flag > noError && itsToken != NULL)
   {
      evalError->e.flag  = flag;
      evalError->e.begin = itsToken->tBegin;
      evalError->e.count = (actualEnd) ? actualEnd-itsToken->tBegin : itsToken->tCount;
   }

   else
   {
      evalError->e.flag  = flag;
      evalError->e.begin = 0;
      evalError->e.count = 0;
   }
}

- (ResultType)evaluate:(unsigned)index
{
   return gNoneResult;
}

- (long double)evaluateReal:(unsigned)index
{
   ResultType result = [self evaluate:index];
   if (result.e.flag > noError)
      return __builtin_nanl("0");

   switch (result.f)
   {
      case rtBoolean:
         return (int)result.b;

      case rtInteger:
         return result.i;

      case rtReal:
         return result.r;

      default:
         return __builtin_nanl("0");
   }
}

@end


@implementation CalcFactor

- (id)copyWithZone:(void *)zone
{
   CalcFactor *cf = [super copyWithZone:zone];
   [cf setValue:&itsValue];
   return cf;
}

- (id)initWithValue:(ResultType *)value :(Precedence)precedence :(OpKind)opKind
{
   if (self = [super init])
   {
      itsToken      = NULL;
      itsPrecedence = precedence;
      itsOpKind     = opKind;

      if (value)
      {
         itsValue = *value;
         if (itsValue.f == rtVector)
            itsValue.v = copyVector(value);
      }
      else
         itsValue = gNoneResult;
   }
   return self;
}

- (ResultType)itsValue
{
   return itsValue;
}

- (void)setValue:(ResultType *)value
{
   freeVector(&itsValue);

   if (value)
   {
      itsValue = *value;
      if (itsValue.f == rtVector)
         itsValue.v = copyVector(value);
   }
   else
      itsValue = gNoneResult;
}

- (void)setIntegerValue:(llong)value
{
   itsValue.f = rtInteger;
   itsValue.i = value;
}

- (void)setRealValue:(long double)value
{
   itsValue.f = rtReal;
   itsValue.r = value;
}

- (ResultType)evaluate:(unsigned)index
{
   ResultType value = itsValue;
   if (value.f == rtVector)
      value.v = copyVector(&itsValue);
   return value;
}

@end


@implementation CalcExternal

- (id)copyWithZone:(void *)zone
{
   CalcExternal *ce = [super copyWithZone:zone];
   [ce setReference:itsReference of:itsValue.f];
   return ce;
}

- (void)setReference:(void *)reference of:(ResultTypeFlags)type
{
   itsReference = reference;
   itsValue.f = type;
}

- (ResultType)evaluate:(unsigned)index
{
   if (itsReference)
   {
      switch (itsValue.f)
      {
         case rtBoolean:
            itsValue.b = *((boolean *)itsReference);

         case rtInteger:
            itsValue.i = *((int *)itsReference);

         case rtReal:
            itsValue.r = *((double *)itsReference);
      }
   }

   return itsValue;
}

@end


@implementation CalcSeries

- (ResultType)evaluate:(unsigned)index
{
   if (itsReference)
   {
      switch (itsValue.f)
      {
         case rtBoolean:
            itsValue.b = ((boolean *)itsReference)[index];

         case rtInteger:
            itsValue.i = ((int *)itsReference)[index];

         case rtReal:
            itsValue.r = ((double *)itsReference)[index];
      }
   }

   return itsValue;
}

@end


@implementation CalcComplex

- (ErrorFlags)addNextElement:(CalcObject *)node
{
   ErrorFlags e = noError;

   if (node != nil)
      if ([node itsPrecedence] == separate)
      {
         e |= [self addNextElement:[(CalcDuo *)node prevTerm]];
         e |= [self addNextElement:[(CalcDuo *)node nextTerm]];
      }

      else if (count < 2)
      {
         [node setParent:self];
         cplx[count++] = node;
      }

      else
         e = paramError;

   return e;
}

- (ResultType)evaluate:(unsigned)index
{
   ResultType re = [cplx[0] evaluate:index];
   ResultType im = (cplx[1])
                 ? [cplx[1] evaluate:index]
                 : gNullResult;

   ResultType zt = {rtComplex, 0, false, 0LL, 0.0L, {0.0L, 0.0L}, NULL, NULL, {noError, 0, 0}};

   switch (re.f)
   {
      case rtBoolean:
         zt.z = re.b;
         break;

      case rtInteger:
         zt.z = re.i;
         break;

      case rtReal:
         zt.z = re.r;
         break;

      default:
         [cplx[0] setErrorInEvaluation:typeError :&zt :0];
         break;
   }

   switch (im.f)
   {
      case rtBoolean:
         zt.z += I*im.b;
         break;

      case rtInteger:
         zt.z += I*im.i;
         break;

      case rtReal:
         zt.z += I*im.r;
         break;

      default:
         [cplx[1] setErrorInEvaluation:typeError :&zt :0];
         break;
   }

   freeVector(&re);
   freeVector(&im);
   return zt;
}

@end


@implementation CalcVector

- (void)dealloc
{
   if (elements)
      deallocate(VPR(elements), false);
   [super dealloc];
}

- (void)addNextElement:(CalcObject *)node
{
   if (node != nil)
      if ([node itsPrecedence] == separate)
      {
         [self addNextElement:[(CalcDuo *)node prevTerm]];
         [self addNextElement:[(CalcDuo *)node nextTerm]];
      }

      else
      {
         if (elemCount == 0)
            elements = allocate(16*sizeof(CalcObject *), default_align, false);

         else if (elemCount % 16 == 0)
            elements = reallocate(elements, (elemCount + 16)*sizeof(CalcObject *), false, true);

         [node setParent:self];
         elements[elemCount++] = node;
      }
}

- (ResultType)evaluate:(unsigned)index
{
   ResultType vt = {rtVector, elemCount, false, 0LL, 0.0L, {0.0L, 0.0L}, allocate(elemCount*sizeof(ResultType), default_align, false), NULL, {noError, 0, 0}};
   for (unsigned i = 0; i < elemCount; i++)
      vt.v[i] = [elements[i] evaluate:index];
   return vt;
}

@end


@implementation CalcUni

- (id)nextTerm
{
   return nextTerm;
}


- (void)addNextNode:(CalcObject *)node
{
   if (node != nil)
   {
      paramCount += ([node itsPrecedence] != separate) ? 1 : 2;
      [node setParent:self];
      nextTerm = lastTerm = node;
   }
}


- (boolean)checkParamCount:(ErrorRecord *)error
{
   if (paramCount == itsOpKind || itsOpKind == multiple)
      return false;
   else
   {
      if (lastTerm != nil)
         [lastTerm setErrorInToken:paramError:error];
      else
         [self setErrorInToken:paramError:error];
      return true;
   }
}


- (boolean)typeEnforce:(ResultTypeFlags)rtCheck :(ResultType *)r
{
   boolean rf = true;

reenforce:
   if (rtCheck & r->f)
      return true;

   else switch (r->f)
   {
      case rtBoolean:
         if (rtCheck & rtInteger)
            r->f = rtInteger, r->i = r->b;
         else if (rtCheck & rtReal)
            r->f = rtReal, r->r = r->b;
         else
            rf = false;
         break;

      case rtInteger:
         if (rtCheck & rtReal)
            r->f = rtReal, r->r = r->i;
         else
            rf = false;
         break;

      case rtReal:
         if ((rtCheck & rtInteger) && r->r == roundl(r->r))
            r->f = rtInteger, r->i = llroundl(r->r);
         else
            rf = false;
         break;

      case rtComplex:
         if (cimagl(r->z) == 0.0L)
            if (rtCheck & rtReal)
               r->f = rtReal, r->r = creall(r->z);
            else if (rtCheck & rtInteger && creall(r->z) == roundl(creall(r->z)))
               r->f = rtInteger, r->i = llroundl(creall(r->z));
            else
               rf = false;
         else
            rf = false;
         break;

      case rtVector:
         simplifyVector(r);
         if (r->f != rtVector)
            goto reenforce;
         else
            rf = false;
         break;

      default:
         rf = false;
         break;
   }

   return rf;
}


- (void)evalScalar:(ResultType *)s
{
   // do nothing, i.e. s is kept unaltered
}


- (void)evalVector:(ResultType *)v
{
   unsigned i, n;
   n = v->n;
   v = v->v;

   for (i = 0; i < n; i++)
      if (v[i].f & (rtScalar|rtComplex))
         [self evalScalar:&v[i]];
      else if (v[i].f == rtVector)
         [self evalVector:&v[i]];
      else
         v[i].f = rtError;
}


- (ResultType)evaluate:(unsigned)index
{
   ResultType r = [nextTerm evaluate:index];

   if (r.f & (rtScalar|rtComplex))
      [self evalScalar:&r];
   else if (r.f == rtVector)
      [self evalVector:&r];
   else
      r.f = rtError;

   if (r.f == rtError)
      [nextTerm setErrorInEvaluation:(r.e.flag)?:typeError :&r :0];

   return r;
}

@end


@implementation CalcDuo

- (id)prevTerm
{
   return prevTerm;
}

- (void)addPrevNode:(CalcObject *)node
{
   if (node != nil)
   {
      paramCount++;
      [node setParent:self];
      prevTerm = lastTerm = node;
   }
}

- (void)addNextNode:(CalcObject *)node
{
   if (node != nil)
   {
      if ([self itsPrecedence] != separate && [node itsPrecedence] == separate)
      {
         CalcObject* term;

         if (term = [(CalcDuo *)node prevTerm])
         {
            paramCount += ([term itsPrecedence] == separate) ? 2 : 1;
            [term setParent:self];
            prevTerm = term;
         }

         if (term = [(CalcDuo *)node nextTerm])
         {
            paramCount += ([term itsPrecedence] == separate) ? 2 : 1;
            [term setParent:self];
            nextTerm = lastTerm = term;
         }
      }

      else
      {
         paramCount++;
         [node setParent:self];
         nextTerm = lastTerm = node;
      }
   }
}


- (ResultTypeFlags)typeAdjust:(ResultTypeFlags)rtCheck :(ResultType *)r1 :(ResultType *)r2 :(ResultType *)r
{
   if (![self typeEnforce:rtCheck :r1])
      [prevTerm setErrorInEvaluation:typeError :r :0];

   else if (![self typeEnforce:rtCheck :r2])
      [nextTerm setErrorInEvaluation:typeError :r :0];

   else if (r1->f == r2->f)
      r->f = r1->f;

   else
   {
      ResultType *hi, *lo, *v;
      if (r1->f > r2->f)
         hi = r1, lo = r2;
      else
         hi = r2, lo = r1;

   readjust:
      switch (hi->f)
      {
         case rtInteger:      // lo->f can only be rtBoolean
            lo->i = lo->b;
            break;

         case rtReal:         // lo->f can be rtBoolean or rtInteger
            if (lo->f == rtBoolean)
               lo->r = lo->b;
            else
               lo->r = lo->i;
            break;

         case rtComplex:      // lo->f can be rtBoolean, rtInteger, or rtReal
            switch (lo->f)
            {
               case rtBoolean:
                  lo->z = lo->b;
                  break;

               case rtInteger:
                  lo->z = lo->i;
                  break;

               case rtReal:
                  lo->z = lo->r;
                  break;
            }
            break;

         case rtVector:
            simplifyVector(hi);
            if (hi->f < lo->f)
            {
               v = hi, hi = lo, lo = v;
               goto readjust;
            }
            break;
      }

      r->f = hi->f;
   }

   return r->f;
}


- (void)evalScalar:(ResultType *)s withScalar:(ResultType *)t result:(ResultType *)r
{
   r->f = rtError;
}


- (void)evalVector:(ResultType *)v withScalar:(ResultType *)s
{
   unsigned i, n;
   n = v->n;
   v = v->v;

   for (i = 0; i < n; i++)
   {
      if (v[i].f & (rtScalar|rtComplex))
         [self evalScalar:&v[i] withScalar:s result:&v[i]];

      else if (v[i].f == rtVector)
         [self evalVector:&v[i] withScalar:s];

      else
         v[i].f = rtError;
   }
}


- (void)evalScalar:(ResultType *)s withVector:(ResultType *)v
{
   unsigned i, n;
   n = v->n;
   v = v->v;

   for (i = 0; i < n; i++)
   {
      if (v[i].f & (rtScalar|rtComplex))
         [self evalScalar:s withScalar:&v[i] result:&v[i]];

      else if (v[i].f == rtVector)
         [self evalScalar:s withVector:&v[i]];

      else
         v[i].f = rtError;
   }
}


- (void)evalVector:(ResultType *)v withVector:(ResultType *)w
{
   if (v->n == w->n)
   {
      unsigned i, n;
      n = v->n;
      v = v->v;
      w = w->v;

      for (i = 0; i < n; i++)
         if (v[i].f == rtVector && w[i].f == rtVector)
            [self evalVector:&v[i] withVector:&w[i]];

         else if (v[i].f == rtVector)
            [self evalVector:&v[i] withScalar:&w[i]];

         else if (w[i].f == rtVector)
         {
            [self evalScalar:&v[i] withVector:&w[i]];
            v[i] = w[i], w[i].v = NULL;
         }

         else
            [self evalScalar:&v[i] withScalar:&w[i] result:&v[i]];
   }

   else
      v->f = rtError;
}


- (ResultType)evaluate:(unsigned)index
{
   ResultType r1, r2;

   r1 = [prevTerm evaluate:index];
   if (r1.f == rtError)
      return r1;

   r2 = [nextTerm evaluate:index];
   if (r2.f == rtError)
   {
      freeVector(&r1);
      return r2;
   }

   if (r1.f == rtVector && r2.f == rtVector)
   {
      [self evalVector:&r1 withVector:&r2];
      freeVector(&r2);
   }

   else if (r1.f == rtVector)
      [self evalVector:&r1 withScalar:&r2];

   else if (r2.f == rtVector)
   {
      [self evalScalar:&r1 withVector:&r2];
      r1 = r2;
   }

   else
      [self evalScalar:&r1 withScalar:&r2 result:&r1];

   if (r1.f == rtError)
   {
      if (r1.e.flag == noError)
         r1.e.flag  = typeError;
      if (r1.e.count == 0)
      {
         r1.e.begin = [nextTerm itsToken]->tBegin;
         r1.e.count = [nextTerm itsToken]->tCount;
      }
   }

   return r1;
}

@end


@implementation CalcMulti

- (void)dealloc
{
   if (multi)
      deallocate(VPR(multi), false);
   [super dealloc];
}

- (void)addNextNode:(CalcObject *)node
{
   if (node != nil)
      if ([node itsPrecedence] == separate)
      {
         [self addNextNode:[(CalcDuo *)node prevTerm]];
         [self addNextNode:[(CalcDuo *)node nextTerm]];
      }

      else
      {
         if (paramCount == 0)
            multi = allocate(16*sizeof(CalcObject *), default_align, false);

         else if (paramCount % 16 == 0)
            multi = reallocate(multi, (paramCount + 16)*sizeof(CalcObject *), false, true);

         [node setParent:self];
         multi[paramCount++] = lastTerm = node;
      }
}

@end;


@interface Separation : CalcDuo @end

@implementation Separation

- (ResultType)evaluate:(unsigned)index
{
   ResultType r1 = [prevTerm evaluate:index];

   if (r1.f == rtError)
      return r1;
   else
   {
      freeVector(&r1);
      return [nextTerm evaluate:index];
   }
}

@end


#pragma mark ••• Arithmetic Operators •••

@interface Plus : CalcUni @end
@interface Minus : CalcUni @end
@interface Addition : CalcDuo @end
@interface Subtraction : CalcDuo @end
@interface Multiplication : CalcDuo @end
@interface Division : CalcDuo @end
@interface Power : CalcDuo @end
@interface Root : CalcDuo @end
@interface Pythagoras2D : CalcDuo @end
@interface Pythagoras3D : CalcMulti @end
@interface IntegerMOD : CalcDuo @end
@interface IntegerDIV : CalcDuo @end

@implementation Plus

- (ResultType)evaluate:(unsigned)index
{
   ResultType r = [nextTerm evaluate:index];

   if ((r.f & (rtScalar|rtComplex|rtVector)) == 0)
      [nextTerm setErrorInEvaluation:typeError :&r :0];

   return r;
}

@end


@implementation Minus

- (void)evalScalar:(ResultType *)s
{
   switch (s->f)
   {
      case rtBoolean:
         s->f = rtInteger;
         s->i = -s->b;
         break;

      case rtInteger:
         s->i = -s->i;
         break;

      case rtReal:
         s->r = -s->r;
         break;

      case rtComplex:
         s->z = -s->z;
   }
}

@end


@implementation Addition

- (void)evalScalar:(ResultType *)s withScalar:(ResultType *)t result:(ResultType *)r
{
   switch ([self typeAdjust:rtScalar|rtComplex :s :t :r])
   {
      case rtBoolean:
         r->f = rtInteger;
         r->i = s->b + t->b;
         break;

      case rtInteger:
         r->i = s->i + t->i;
         break;

      case rtReal:
         if (gLazyPercentFlag && itsPrecedence == addsub)
            if ((isPercent = [prevTerm percent] && [nextTerm percent]) || ![nextTerm percent])
               r->r = s->r + t->r;
            else
               r->r = s->r*(1.0L + t->r);
         else
            r->r = s->r + t->r;
         break;

      case rtComplex:
         r->z = s->z + t->z;
         break;
   }
}

@end


@implementation Subtraction

- (void)evalScalar:(ResultType *)s withScalar:(ResultType *)t result:(ResultType *)r
{
   switch ([self typeAdjust:rtScalar|rtComplex :s :t :r])
   {
      case rtBoolean:
         r->f = rtInteger;
         r->i = s->b - t->b;
         break;

      case rtInteger:
         r->i = s->i - t->i;
         break;

      case rtReal:
         if (gLazyPercentFlag && itsPrecedence == addsub)
            if ((isPercent = [prevTerm percent] && [nextTerm percent]) || ![nextTerm percent])
               r->r = s->r - t->r;
            else
               r->r = s->r*(1.0L - t->r);
         else
            r->r = s->r - t->r;
         break;

      case rtComplex:
         r->z = s->z - t->z;
         break;
   }
}

@end


@implementation Multiplication

- (void)evalScalar:(ResultType *)s withScalar:(ResultType *)t result:(ResultType *)r
{
   switch ([self typeAdjust:rtScalar|rtComplex :s :t :r])
   {
      case rtBoolean:
         r->f = rtInteger;
         r->i = s->b * t->b;
         break;

      case rtInteger:
         r->i = s->i * t->i;
         break;

      case rtReal:
         if (gLazyPercentFlag)
         {
            boolean pp = [prevTerm percent], np = [nextTerm percent];
            isPercent = (pp || np) && !(pp && np);
         }
         r->r = s->r * t->r;
         break;

      case rtComplex:
         r->z = s->z * t->z;
         break;
   }
}

@end


@implementation Division

- (void)evalScalar:(ResultType *)s withScalar:(ResultType *)t result:(ResultType *)r
{
   switch ([self typeAdjust:rtScalar|rtComplex :s :t :r])
   {
      case rtBoolean:
         r->f = rtReal;
         s->r = s->b, t->r = t->b;
         r->r = s->r / t->r;
         break;

      case rtInteger:
         r->f = rtReal;
         s->r = s->i, t->r = t->i;
         r->r = s->r / t->r;
         break;

      case rtReal:
         if (gLazyPercentFlag)
         {
            boolean pp = [prevTerm percent], np = [nextTerm percent];
            isPercent = (pp || np) && !(pp && np);
         }
         r->r = s->r / t->r;
         break;

      case rtComplex:
         r->z = cdivl(s->z, t->z);
         break;
   }
}

@end


@implementation Power

- (void)evalScalar:(ResultType *)s withScalar:(ResultType *)t result:(ResultType *)r
{
   if ([self typeAdjust:rtReal|rtComplex :s :t :r] == rtReal)
      r->r = powl(s->r, t->r);
   else // (... == rtComplex)
      r->z = cpowl(s->z, t->z);
}

@end


@implementation Root

- (void)evalScalar:(ResultType *)s withScalar:(ResultType *)t result:(ResultType *)r
{
   if ([self typeAdjust:rtReal|rtComplex :s :t :r] == rtReal)
   {
      boolean oddint = (s->r == truncl(s->r) && (llroundl(s->r)&1LL));

      if (!gAutoReal2CmplxFlag || t->r >= 0.0L || oddint)
         if (t->r < 0.0L && oddint)
            r->r = -powl(-t->r, 1.0L/s->r);
         else
            r->r =  powl( t->r, 1.0L/s->r);
      else
      {
         r->f = rtComplex;
         r->z = cpowl(t->r, 1.0L/s->r);
      }
   }
   else // (... == rtComplex)
      r->z = cpowl(t->z, cdivl(1.0L, s->z));
}

@end


@implementation Pythagoras2D

- (void)evalScalar:(ResultType *)s withScalar:(ResultType *)t result:(ResultType *)r
{
   if ([self typeAdjust:rtReal|rtComplex :s :t :r] == rtReal)
      r->r = sqrtl(sqrl(s->r) + sqrl(t->r));
   else // (... == rtComplex)
   {
      r->f = rtReal;
      r->z = s->z - t->z;
      r->r = sqrtl(sqrl(creall(r->z)) + sqrl(cimagl(r->z)));
   }
}

@end


@implementation Pythagoras3D

- (ResultType)evaluate:(unsigned)index
{
   ResultType r0 = [multi[0] evaluate:index];
   if (r0.f == rtError)
      return r0;
   else if (![self typeEnforce:rtReal :&r0])
   {
      [multi[0] setErrorInEvaluation:typeError:&r0 :0];
      return r0;
   }

   ResultType r1 = [multi[1] evaluate:index];
   if (r1.f == rtError)
      return r1;
   else if (![self typeEnforce:rtReal :&r1])
   {
      [multi[1] setErrorInEvaluation:typeError:&r1 :0];
      return r1;
   }

   ResultType r2 = [multi[2] evaluate:index];
   if (r2.f == rtError)
      return r2;
   else if (![self typeEnforce:rtReal :&r2])
   {
      [multi[2] setErrorInEvaluation:typeError:&r2 :0];
      return r2;
   }

   r0.f = rtReal;
   r0.r = sqrtl(sqrl(r0.r) + sqrl(r1.r) + sqrl(r2.r));
   return r0;
}

@end


@implementation IntegerMOD

- (void)evalScalar:(ResultType *)s withScalar:(ResultType *)t result:(ResultType *)r
{
   if ([self typeAdjust:rtInteger :s :t :r] == rtInteger)
      r->i = s->i % t->i;
}

@end


@implementation IntegerDIV

- (void)evalScalar:(ResultType *)s withScalar:(ResultType *)t result:(ResultType *)r
{
   if ([self typeAdjust:rtInteger :s :t :r] == rtInteger)
      r->i = s->i / t->i;
}

@end


#pragma mark ••• GGT, KGV •••

@interface GGT : CalcDuo @end
@interface KGV : CalcDuo @end

@interface GCD : CalcMulti @end
@interface LCM : CalcMulti @end

static inline llong ggT(llong A, llong B)
{
   llong C;
   while (B != 0)
      C = A % B, A = B, B = C;
   return A;
}

static inline llong kgV(llong A, llong B)
{
   return A*B/ggT(A, B);
}

@implementation GGT

- (void)evalScalar:(ResultType *)s withScalar:(ResultType *)t result:(ResultType *)r
{
   if ([self typeAdjust:rtInteger :s :t :r] == rtInteger)
      r->i = ggT(s->i, t->i);
}

@end

@implementation KGV

- (void)evalScalar:(ResultType *)s withScalar:(ResultType *)t result:(ResultType *)r
{
   if ([self typeAdjust:rtInteger :s :t :r] == rtInteger)
      r->i = kgV(s->i, t->i);
}

@end


@implementation GCD

- (ResultType)evaluate:(unsigned)index
{
   int        j;
   ResultType r, gcd = gNoneResult;

   for (j = 0; j < paramCount; j++)
   {
      r = [multi[j] evaluate:index];
      switch (r.f)
      {
         case rtError:
            return r;

         case rtBoolean:
            gcd.i = (j == 0) ? r.b : ggT(gcd.i, r.b);
            break;

         case rtInteger:
            gcd.i = (j == 0) ? r.i : ggT(gcd.i, r.i);
            break;

         case rtReal:
            if ((r.i = llroundl(r.r)) == r.r)
            {
               gcd.i = (j == 0) ? r.i : ggT(gcd.i, r.i);
               break;
            }

         default:
            [multi[j] setErrorInEvaluation:typeError:&r :0];
            return r;
      }

      freeVector(&r);
   }

   gcd.f = rtInteger;
   return gcd;
}

@end


@implementation LCM

- (ResultType)evaluate:(unsigned)index
{
   int        j;
   ResultType r, lcm = gNoneResult;

   for (j = 0; j < paramCount; j++)
   {
      r = [multi[j] evaluate:index];
      switch (r.f)
      {
         case rtError:
            return r;

         case rtBoolean:
            lcm.i = (j == 0) ? r.b : kgV(lcm.i, r.b);
            break;

         case rtInteger:
            lcm.i = (j == 0) ? r.i : kgV(lcm.i, r.i);
            break;

         case rtReal:
            if ((r.i = llroundl(r.r)) == r.r)
            {
               lcm.i = (j == 0) ? r.i : kgV(lcm.i, r.i);
               break;
            }

         default:
            [multi[j] setErrorInEvaluation:typeError:&r :0];
            return r;
      }

      freeVector(&r);
   }

   lcm.f = rtInteger;
   return lcm;
}

@end


#pragma mark ••• IF, SetEqual •••

@interface IF : CalcMulti @end
@interface SetEqual : CalcDuo @end

@implementation IF

- (ResultType)evaluate:(unsigned)index
{
   ResultType r0 = [multi[0] evaluate:index];
   if (r0.f == rtError ||
       r0.f == rtReal && isnan(r0.r) ||
       r0.f == rtComplex && (isnan(creall(r0.z)) || isnan(cimagl(r0.z))))
      return r0;

   if ((r0.f == rtBoolean && r0.b)         ||
       (r0.f == rtInteger && r0.i != 0)    ||
       (r0.f == rtReal    && r0.r != 0.0L) ||
       (r0.f == rtComplex && r0.z != 0.0L))
      return [multi[1] evaluate:index];

   if (r0.f == rtVector)
   {
      r0.r = sqrsum(&r0);
      freeVector(&r0);
      if (isnan(r0.r))
      {
         r0.f = rtReal;
         return r0;
      }
      else if (r0.r != 0.0L)
         return [multi[1] evaluate:index];
   }

   return [multi[2] evaluate:index];
}

@end


@implementation SetEqual

- (ResultType)evaluate:(unsigned)index
{
   ResultType r = [nextTerm evaluate:index];

   if ([prevTerm isKindOfClass:[CalcFactor class]])
      [(CalcFactor *)prevTerm setValue:&r];
   else
      [prevTerm setErrorInEvaluation:paramError :&r :0];

   return r;
}

@end


#pragma mark ••• Relational Operators •••

@interface RelationalOP : CalcDuo @end
@interface Equal : RelationalOP @end
@interface UnEqual : Equal @end        // inverse result of Equal
@interface LessEqual : RelationalOP @end
@interface GreaterEqual : RelationalOP @end
@interface Less : RelationalOP @end
@interface Greater : RelationalOP @end

@implementation RelationalOP

- (void)evalVector:(ResultType *)v withVector:(ResultType *)w
{
   ResultType     *u = v;
   ResultTypeFlags f = rtError;
   boolean         b = v->n == w->n, c = false;

   if (b)
   {
      unsigned i, n;
      n = v->n;
      v = v->v;
      w = w->v;

      for (i = 0; b && i < n; i++)
         if (v[i].f != rtVector && w[i].f != rtVector)
         {
            [self evalScalar:&v[i] withScalar:&w[i] result:&v[i]];
            f = v[i].f;
            b = b && v[i].b;
            c = c || v[i].i;
         }

         else if (v[i].f == rtVector && w[i].f == rtVector)
         {
            [self evalVector:&v[i] withVector:&w[i]];
            f = v[i].f;
            b = b && v[i].b;
            c = c || v[i].i;
         }

         else
         {
            f = rtError;
            b = false;
         }
   }

   u->f = f;
   u->b = b && c;
}

- (ResultType)evaluate:(unsigned)index
{
   ResultType r1, r2;

   r1 = [prevTerm evaluate:index];
   if (r1.f == rtError)
      return r1;

   r2 = [nextTerm evaluate:index];
   if (r2.f == rtError)
   {
      freeVector(&r1);
      return r2;
   }

   simplifyVector(&r1);
   simplifyVector(&r2);

   if (r1.f != rtVector && r2.f != rtVector)
   {
      [self evalScalar:&r1 withScalar:&r2 result:&r1];
      r1.b = r1.b && r1.i;
   }

   else if (r1.f == rtVector && r2.f == rtVector)
   {
      [self evalVector:&r1 withVector:&r2];
      freeVector(&r2);
   }

   else
      r1.f = rtError;

   if (r1.f == rtError)
   {
      if (r1.e.flag == noError)
         r1.e.flag  = typeError;
      if (r1.e.count == 0)
      {
         r1.e.begin = [prevTerm itsToken]->tBegin;
         r1.e.count = [nextTerm itsToken]->tBegin - [prevTerm itsToken]->tBegin + [nextTerm itsToken]->tCount;
      }
   }

   return r1;
}

@end


@implementation Equal

- (void)evalScalar:(ResultType *)s withScalar:(ResultType *)t result:(ResultType *)r
{
   switch ([self typeAdjust:rtScalar|rtComplex :s :t :r])
   {
      case rtBoolean:
         r->b = s->b == t->b;
         break;

      case rtInteger:
         r->b = s->i == t->i;
         break;

      case rtReal:
         if (isnan(s->r) || isnan(t->r))
         {
            r->f = rtError;
            r->e.flag = nanError;
         }
         else
            r->b = s->r == t->r;
         break;

      case rtComplex:
         if (isnan(creall(s->z)) || isnan(cimagl(s->z)) || isnan(creall(t->z)) || isnan(cimagl(t->z)))
         {
            r->f = rtError;
            r->e.flag = nanError;
         }
         else
            r->b = s->z == t->z;
         break;
   }

   if (r->f != rtError)
      r->f = rtBoolean, r->i = 1;
}

@end


@implementation UnEqual                // inverse result of Equal

- (ResultType)evaluate:(unsigned)index
{
   ResultType r = [super evaluate:index];
   r.b = !r.b;
   return r;
}

@end


@implementation LessEqual

- (void)evalScalar:(ResultType *)s withScalar:(ResultType *)t result:(ResultType *)r
{
   switch ([self typeAdjust:rtScalar|rtComplex :s :t :r])
   {
      case rtBoolean:
         r->b = s->b <= t->b;
         break;

      case rtInteger:
         r->b = s->i <= t->i;
         break;

      case rtReal:
         if (isnan(s->r) || isnan(t->r))
         {
            r->f = rtError;
            r->e.flag = nanError;
         }
         else
            r->b = s->r <= t->r;
         break;

      case rtComplex:
         if (isnan(creall(s->z)) || isnan(cimagl(s->z)) || isnan(creall(t->z)) || isnan(cimagl(t->z)))
         {
            r->f = rtError;
            r->e.flag = nanError;
         }
         else
            r->b = creall(s->z) <= creall(t->z) && cimagl(s->z) <= cimagl(t->z);
         break;
   }

   if (r->f != rtError)
      r->f = rtBoolean, r->i = 1;
}

@end


@implementation GreaterEqual

- (void)evalScalar:(ResultType *)s withScalar:(ResultType *)t result:(ResultType *)r
{
   switch ([self typeAdjust:rtScalar|rtComplex :s :t :r])
   {
      case rtBoolean:
         r->b = s->b >= t->b;
         break;

      case rtInteger:
         r->b = s->i >= t->i;
         break;

      case rtReal:
         if (isnan(s->r) || isnan(t->r))
         {
            r->f = rtError;
            r->e.flag = nanError;
         }
         else
            r->b = s->r >= t->r;
         break;

      case rtComplex:
         if (isnan(creall(s->z)) || isnan(cimagl(s->z)) || isnan(creall(t->z)) || isnan(cimagl(t->z)))
         {
            r->f = rtError;
            r->e.flag = nanError;
         }
         else
            r->b = creall(s->z) >= creall(t->z) && cimagl(s->z) >= cimagl(t->z);
         break;
   }

   if (r->f != rtError)
      r->f = rtBoolean, r->i = 1;
}

@end


@implementation Less

- (void)evalScalar:(ResultType *)s withScalar:(ResultType *)t result:(ResultType *)r
{
   switch ([self typeAdjust:rtScalar|rtComplex :s :t :r])
   {
      case rtBoolean:
         r->b = s->b <= t->b;
         r->i = s->b <  t->b;
         break;

      case rtInteger:
         r->b = s->i <= t->i;
         r->i = s->i <  t->i;
         break;

      case rtReal:
         if (isnan(s->r) || isnan(t->r))
         {
            r->f = rtError;
            r->e.flag = nanError;
         }
         else
         {
            r->b = s->r <= t->r;
            r->i = s->r <  t->r;
         }
         break;

      case rtComplex:
         if (isnan(creall(s->z)) || isnan(cimagl(s->z)) || isnan(creall(t->z)) || isnan(cimagl(t->z)))
         {
            r->f = rtError;
            r->e.flag = nanError;
         }
         else
         {
            r->b = creall(s->z) <= creall(t->z) && cimagl(s->z) <= cimagl(t->z);
            r->i = creall(s->z) <  creall(t->z) && cimagl(s->z) <= cimagl(t->z) ||
                   creall(s->z) <= creall(t->z) && cimagl(s->z) <  cimagl(t->z);
         }
         break;
   }

   if (r->f != rtError)
      r->f = rtBoolean;
}

@end


@implementation Greater

- (void)evalScalar:(ResultType *)s withScalar:(ResultType *)t result:(ResultType *)r
{
   switch ([self typeAdjust:rtScalar|rtComplex :s :t :r])
   {
      case rtBoolean:
         r->b = s->b >= t->b;
         r->i = s->b >  t->b;
         break;

      case rtInteger:
         r->b = s->i >= t->i;
         r->i = s->i >  t->i;
         break;

      case rtReal:
         if (isnan(s->r) || isnan(t->r))
         {
            r->f = rtError;
            r->e.flag = nanError;
         }
         else
         {
            r->b = s->r >= t->r;
            r->i = s->r >  t->r;
         }
         break;

      case rtComplex:
         if (isnan(creall(s->z)) || isnan(cimagl(s->z)) || isnan(creall(t->z)) || isnan(cimagl(t->z)))
         {
            r->f = rtError;
            r->e.flag = nanError;
         }
         else
         {
            r->b = creall(s->z) >= creall(t->z) && cimagl(s->z) >= cimagl(t->z);
            r->i = creall(s->z) >  creall(t->z) && cimagl(s->z) >= cimagl(t->z) ||
                   creall(s->z) >= creall(t->z) && cimagl(s->z) >  cimagl(t->z);
         }
         break;
   }

   if (r->f != rtError)
      r->f = rtBoolean;
}

@end


#pragma mark ••• Bitwise Operators •••

@interface BitwiseINV : CalcUni @end
@interface BitwiseAND : CalcDuo @end
@interface BitwiseOR  : CalcDuo @end
@interface BitwiseXOR : CalcDuo @end
@interface BitwiseSHL : CalcDuo @end
@interface BitwiseSHR : CalcDuo @end

@implementation BitwiseINV

- (void)evalScalar:(ResultType *)s
{
   if ([self typeEnforce:rtInteger :s])
      s->i = ~s->i;
   else
      [nextTerm setErrorInEvaluation:typeError :s :0];
}

@end


@implementation BitwiseAND

- (void)evalScalar:(ResultType *)s withScalar:(ResultType *)t result:(ResultType *)r
{
   if ([self typeAdjust:rtInteger :s :t :r] == rtInteger)
      r->i = s->i & t->i;
}

@end


@implementation BitwiseOR

- (void)evalScalar:(ResultType *)s withScalar:(ResultType *)t result:(ResultType *)r
{
   if ([self typeAdjust:rtInteger :s :t :r] == rtInteger)
      r->i = s->i | t->i;
}

@end


@implementation BitwiseXOR

- (void)evalScalar:(ResultType *)s withScalar:(ResultType *)t result:(ResultType *)r
{
   if ([self typeAdjust:rtInteger :s :t :r] == rtInteger)
      r->i = s->i ^ t->i;
}

@end


@implementation BitwiseSHL

- (void)evalScalar:(ResultType *)s withScalar:(ResultType *)t result:(ResultType *)r
{
   if ([self typeAdjust:rtInteger :s :t :r] == rtInteger)
      r->i = s->i << t->i;
}

@end


@implementation BitwiseSHR

- (void)evalScalar:(ResultType *)s withScalar:(ResultType *)t result:(ResultType *)r
{
   if ([self typeAdjust:rtInteger :s :t :r] == rtInteger)
      r->i = s->i >> t->i;
}

@end


#pragma mark ••• Logical Operators •••

@interface LogicalNOT : CalcUni @end

@implementation LogicalNOT

- (void)evalScalar:(ResultType *)s
{
   switch (s->f)
   {
      case rtBoolean:
         s->b = !s->b;
         break;

      case rtInteger:
         s->b = s->i == 0LL;
         break;

      case rtReal:
         if (isnan(s->r))
            return;
         s->b = s->r == 0.0L;
         break;

      case rtComplex:
         if (isnan(creall(s->z)) || isnan(cimagl(s->z)))
            return;
         s->b = creall(s->z) == 0.0L && cimagl(s->z) == 0.0L;
         break;
   }

   s->f = rtBoolean;
}

- (void)evalVector:(ResultType *)v
{
   if (isnan(v->r = sqrsum(v)))
      return;

   v->f = rtBoolean;
   v->b = v->r == 0.0L;
}

@end


@interface LogicalOp  : CalcDuo @end
@interface LogicalAND : LogicalOp @end
@interface LogicalOR  : LogicalOp @end
@interface LogicalXOR : LogicalOp @end

@implementation LogicalOp

- (boolean)typeEnforce:(ResultTypeFlags)rtCheck :(ResultType *)r
{
   switch (r->f)
   {
      case rtBoolean:
         break;

      case rtInteger:
         r->b = r->i != 0LL;
         break;

      case rtReal:
         if (isnan(r->r))
         {
            r->f = rtError;
            r->e.flag = nanError;
         }
         else
            r->b = r->r != 0.0L;
         break;

      case rtComplex:
         if (isnan(creall(r->z)) || isnan(cimagl(r->z)))
         {
            r->f = rtError;
            r->e.flag = nanError;
         }
         else
            r->b = creall(r->z) != 0.0L || cimagl(r->z) != 0.0L;
         break;

      case rtVector:
         if (isnan(r->r = sqrsum(r)))
         {
            r->f = rtError;
            r->e.flag = nanError;
         }
         else
            r->b = r->r != 0.0L;
         break;

      default:
         r->f = rtError;
         return false;
   }

   if (r->f != rtError)
      r->f = rtBoolean;

   return true;
}

- (ResultTypeFlags)typeAdjust:(ResultTypeFlags)rtCheck :(ResultType *)r1 :(ResultType *)r2 :(ResultType *)r
{
   if (![self typeEnforce:rtCheck :r1])
      [prevTerm setErrorInEvaluation:r1->e.flag :r :0];

   else if (![self typeEnforce:rtCheck :r2])
      [nextTerm setErrorInEvaluation:r2->e.flag :r :0];

   return r->f = r1->f;
}

- (ResultType)evaluate:(unsigned)index
{
   ResultType r1, r2;

   r1 = [prevTerm evaluate:index];
   if (r1.f == rtError)
      return r1;

   r2 = [nextTerm evaluate:index];
   if (r2.f == rtError)
   {
      freeVector(&r1);
      return r2;
   }

   [self evalScalar:&r1 withScalar:&r2 result:&r1];
   freeVector(&r2);

   if (r1.f == rtError)
   {
      if (r1.e.flag == noError)
         r1.e.flag  = typeError;
      if (r1.e.count == 0)
      {
         r1.e.begin = [prevTerm itsToken]->tBegin;
         r1.e.count = [nextTerm itsToken]->tBegin - [prevTerm itsToken]->tBegin + [nextTerm itsToken]->tCount;
      }
   }

   return r1;
}

@end


@implementation LogicalAND

- (void)evalScalar:(ResultType *)s withScalar:(ResultType *)t result:(ResultType *)r
{
   if ([self typeAdjust:rtBoolean :s :t :r] == rtBoolean)
      r->b = s->b & t->b;
}

@end


@implementation LogicalOR

- (void)evalScalar:(ResultType *)s withScalar:(ResultType *)t result:(ResultType *)r
{
   if ([self typeAdjust:rtBoolean :s :t :r] == rtBoolean)
      r->b = s->b | t->b;
}

@end


@implementation LogicalXOR

- (void)evalScalar:(ResultType *)s withScalar:(ResultType *)t result:(ResultType *)r
{
   if ([self typeAdjust:rtBoolean :s :t :r] == rtBoolean)
      r->b = s->b ^ t->b;
}

@end


#pragma mark ••• Standard Math Functions •••

@interface Truncation : CalcUni @end
@interface Round : CalcUni @end
@interface Floor : CalcUni @end
@interface Ceil : CalcUni @end
@interface Absolute : CalcUni @end
@interface Scalb : CalcDuo @end
@interface Signum : CalcUni @end
@interface Square : CalcUni @end
@interface Cube : CalcUni @end
@interface SquareRoot : CalcUni @end
@interface Sinus : CalcUni @end
@interface ArcSinus : CalcUni @end
@interface Cosinus : CalcUni @end
@interface ArcCosinus : CalcUni @end
@interface Tangens : CalcUni @end
@interface ArcTangens : CalcUni @end
@interface ArcTangens2 : CalcDuo @end
@interface Cotangens : CalcUni @end
@interface ArcCotangens : CalcUni @end
@interface Exponential : CalcUni @end
@interface ExpMinus1 : CalcUni @end
@interface Exponential10 : CalcUni @end
@interface Exponential2 : CalcUni @end
@interface Logarithm : CalcUni @end
@interface Log1Plus : CalcUni @end
@interface Logarithm10 : CalcUni @end
@interface Logarithm2 : CalcUni @end
@interface SinusHyperbolicus : CalcUni @end
@interface AreaSinusHyperbolicus : CalcUni @end
@interface CosinusHyperbolicus : CalcUni @end
@interface AreaCosinusHyperbolicus : CalcUni @end
@interface TangensHyperbolicus : CalcUni @end
@interface AreaTangensHyperbolicus : CalcUni @end
@interface CotangensHyperbolicus : CalcUni @end
@interface AreaCotangensHyperbolicus : CalcUni @end

@implementation Truncation

- (void)evalScalar:(ResultType *)s
{
   switch (s->f)
   {
      case rtBoolean:
         s->f = rtInteger;
         s->i = s->b;
         break;

      case rtReal:
         s->f = rtInteger;
         s->i = (llong)truncl(s->r);
         break;

      case rtComplex:
         s->z = truncl(creall(s->z)) + I*truncl(cimagl(s->z));
   }
}

@end


@implementation Round

- (void)evalScalar:(ResultType *)s
{
   switch (s->f)
   {
      case rtBoolean:
         s->f = rtInteger;
         s->i = s->b;
         break;

      case rtReal:
         s->f = rtInteger;
         s->i = llroundl(s->r);
         break;

      case rtComplex:
         s->z = roundl(creall(s->z)) + I*roundl(cimagl(s->z));
   }
}

@end


@implementation Floor

- (void)evalScalar:(ResultType *)s
{
   switch (s->f)
   {
      case rtBoolean:
         s->f = rtInteger;
         s->i = s->b;
         break;

      case rtReal:
         s->f = rtInteger;
         s->i = (llong)floorl(s->r);
         break;

      case rtComplex:
         s->z = floorl(creall(s->z)) + I*floorl(cimagl(s->z));
   }
}

@end


@implementation Ceil

- (void)evalScalar:(ResultType *)s
{
   switch (s->f)
   {
      case rtBoolean:
         s->f = rtInteger;
         s->i = s->b;
         break;

      case rtReal:
         s->f = rtInteger;
         s->i = (llong)ceill(s->r);
         break;

      case rtComplex:
         s->z = ceill(creall(s->z)) + I*ceill(cimagl(s->z));
   }
}

@end


@implementation Absolute

- (void)evalScalar:(ResultType *)s
{
   switch (s->f)
   {
      case rtBoolean:
         s->f = rtInteger;
         s->i = s->b;
         break;

      case rtInteger:
         s->i = llabs(s->i);
         break;

      case rtReal:
         s->r = fabsl(s->r);
         break;

      case rtComplex:
         s->f = rtReal;
         s->r = cabsl(s->z);
   }
}

@end


@implementation Scalb

- (ResultType)evaluate:(unsigned)index
{
   ResultType x = [prevTerm evaluate:index];
   if (x.f == rtError || (x.f & rtScalar) == 0)
      return x;

   if (x.f == rtInteger)
      x.r = x.i;

   ResultType n = [nextTerm evaluate:index];
   if (n.f == rtError || (x.f & rtScalar) == 0)
      return n;

   ResultType result = gNullResult;
   if (n.f == rtInteger)
      result.r = scalblnl(x.r, (long)n.i);
   else // if (n.f == rtReal)
      result.r = x.r*powl(2.0L, n.r);

   return result;
}

@end


@implementation Signum

- (void)evalScalar:(ResultType *)s
{
   switch (s->f)
   {
      case rtBoolean:
         s->f = rtInteger;
         s->i = s->b;
         break;

      case rtInteger:
         if (s->i < 0)
            s->i = -1;
         else if (s->i > 0)
            s->i = 1;
         break;

      case rtReal:
         if (isnan(s->r))
            break;

         s->f = rtInteger;
         if (s->r < 0.0L)
            s->i = -1;
         else if (s->r > 0.0L)
            s->i = 1;
         else // (s->r == 0.0L)
            s->i = 0;
         break;

      case rtComplex:
         if ((creall(s->z) != 0.0L || cimagl(s->z) != 0.0L) && !isinf(creall(s->z)) && !isinf(cimagl(s->z)))
            s->z = s->z/cabsl(s->z);
   }
}

@end


@implementation Square

- (void)evalScalar:(ResultType *)s
{
   switch (s->f)
   {
      case rtBoolean:
         s->f = rtInteger;
         s->i = s->b;
         break;

      case rtInteger:
         s->i = s->i*s->i;
         break;

      case rtReal:
         s->r = s->r*s->r;
         break;

      case rtComplex:
         s->z = s->z*s->z;
   }
}

@end


@implementation Cube

- (void)evalScalar:(ResultType *)s
{
   switch (s->f)
   {
      case rtBoolean:
         s->f = rtInteger;
         s->i = s->b;
         break;

      case rtInteger:
         s->i = s->i*s->i*s->i;
         break;

      case rtReal:
         s->r = s->r*s->r*s->r;
         break;

      case rtComplex:
         s->z = s->z*s->z*s->z;
   }
}

@end


@implementation SquareRoot

- (void)evalScalar:(ResultType *)s
{
   [self typeEnforce:rtReal|rtComplex :s];
   if (s->f == rtReal)
      if (!gAutoReal2CmplxFlag || s->r >= 0.0L)
         s->r = sqrtl(s->r);
      else
      {
         s->f = rtComplex;
         s->z = csqrtl(s->r);
      }
   else // (s->f == rtComplex)
      s->z = csqrtl(s->z);
}

@end


@implementation Sinus

- (void)evalScalar:(ResultType *)s
{
   [self typeEnforce:rtReal|rtComplex :s];
   if (s->f == rtReal)
      s->r = sinl(s->r);
   else // (s->f == rtComplex)
      s->z = csinl(s->z);
}

@end


@implementation ArcSinus

- (void)evalScalar:(ResultType *)s
{
   [self typeEnforce:rtReal|rtComplex :s];
   if (s->f == rtReal)
      if (!gAutoReal2CmplxFlag || -1.0L <= s->r && s->r <= 1.0L)
         s->r = asinl(s->r);
      else
      {
         s->f = rtComplex;
         s->z = casinl(s->r);
      }
   else // (s->f == rtComplex)
      s->z = casinl(s->z);
}

@end


@implementation Cosinus

- (void)evalScalar:(ResultType *)s
{
   [self typeEnforce:rtReal|rtComplex :s];
   if (s->f == rtReal)
      s->r = cosl(s->r);
   else // (s->f == rtComplex)
      s->z = ccosl(s->z);
}

@end


@implementation ArcCosinus

- (void)evalScalar:(ResultType *)s
{
   [self typeEnforce:rtReal|rtComplex :s];
   if (s->f == rtReal)
      if (!gAutoReal2CmplxFlag || -1.0L <= s->r && s->r <= 1.0L)
         s->r = acosl(s->r);
      else
      {
         s->f = rtComplex;
         s->z = cacosl(s->r);
      }
   else // (s->f == rtComplex)
      s->z = cacosl(s->z);
}

@end


@implementation Tangens

- (void)evalScalar:(ResultType *)s
{
   [self typeEnforce:rtReal|rtComplex :s];
   if (s->f == rtReal)
      s->r = tanl(s->r);
   else // (s->f == rtComplex)
      s->z = ctanl(s->z);
}

@end


@implementation ArcTangens

- (void)evalScalar:(ResultType *)s
{
   [self typeEnforce:rtReal|rtComplex :s];
   if (s->f == rtReal)
      s->r = atanl(s->r);
   else // (s->f == rtComplex)
      s->z = catanl(s->z);
}

@end


@implementation ArcTangens2

- (void)evalScalar:(ResultType *)s withScalar:(ResultType *)t result:(ResultType *)r
{
   if ([self typeAdjust:rtReal :s :t :r] == rtReal)
      r->r = atan2l(s->r, t->r);
}

@end


@implementation Cotangens

- (void)evalScalar:(ResultType *)s
{
   [self typeEnforce:rtReal|rtComplex :s];
   if (s->f == rtReal)
      s->r = 1.0L/tanl(s->r);
   else // (s->f == rtComplex)
      s->z = cdivl(1.0L, ctanl(s->z));
}

@end


@implementation ArcCotangens

- (void)evalScalar:(ResultType *)s
{
   [self typeEnforce:rtReal|rtComplex :s];
   if (s->f == rtReal)
      s->r = atanl(1.0L/s->r);
   else // (s->f == rtComplex)
      s->z = catanl(cdivl(1.0L,s->z));
}

@end


@implementation Exponential

- (void)evalScalar:(ResultType *)s
{
   [self typeEnforce:rtReal|rtComplex :s];
   if (s->f == rtReal)
      s->r = expl(s->r);
   else // (s->f == rtComplex)
      s->z = cexpl(s->z);
}

@end


@implementation ExpMinus1

- (void)evalScalar:(ResultType *)s
{
   [self typeEnforce:rtReal|rtComplex :s];
   if (s->f == rtReal)
      s->r = expm1l(s->r);
   else // (s->f == rtComplex)
      s->z = cexpl(s->z) - 1.0L;
}

@end


@implementation Exponential10

- (void)evalScalar:(ResultType *)s
{
   [self typeEnforce:rtReal|rtComplex :s];
   if (s->f == rtReal)
      s->r = powl(10.0L, s->r);
   else // (s->f == rtComplex)
      s->z = cpowl(10.0L, s->z);
}

@end


@implementation Exponential2

- (void)evalScalar:(ResultType *)s
{
   [self typeEnforce:rtReal|rtComplex :s];
   if (s->f == rtReal)
      s->r = exp2l(s->r);
   else // (s->f == rtComplex)
      s->z = cpowl(2.0L, s->z);
}

@end


@implementation Logarithm

- (void)evalScalar:(ResultType *)s
{
   [self typeEnforce:rtReal|rtComplex :s];
   if (s->f == rtReal)
      if (!gAutoReal2CmplxFlag || s->r >= 0.0L)
         s->r = logl(s->r);
      else
      {
         s->f = rtComplex;
         s->z = clogl(s->r);
      }
   else // (s->f == rtComplex)
      s->z = clogl(s->z);
}

@end


@implementation Log1Plus

- (void)evalScalar:(ResultType *)s
{
   [self typeEnforce:rtReal|rtComplex :s];
   if (s->f == rtReal)
      if (!gAutoReal2CmplxFlag || s->r >= 1.0L)
         s->r = log1pl(s->r);
      else
      {
         s->f = rtComplex;
         s->z = clogl(s->r + 1.0L);
      }
   else // (s->f == rtComplex)
      s->z = clogl(s->z + 1.0L);
}

@end


@implementation Logarithm10

- (void)evalScalar:(ResultType *)s
{
   [self typeEnforce:rtReal|rtComplex :s];
   if (s->f == rtReal)
      if (!gAutoReal2CmplxFlag || s->r >= 0.0L)
         s->r = log10l(s->r);
      else
      {
         s->f = rtComplex;
         s->z = clogl(s->r)/2.3025850929940459010936137929093L;
      }
   else // (s->f == rtComplex)
      s->z = clogl(s->z)/2.3025850929940459010936137929093L;
}

@end


@implementation Logarithm2

- (void)evalScalar:(ResultType *)s
{
   [self typeEnforce:rtReal|rtComplex :s];
   if (s->f == rtReal)
      if (!gAutoReal2CmplxFlag || s->r >= 0.0L)
         s->r = log2l(s->r);
      else
      {
         s->f = rtComplex;
         s->z = clogl(s->r)/0.69314718055994530941723L;
      }
   else // (s->f == rtComplex)
      s->z = clogl(s->z)/0.69314718055994530941723L;
}

@end


@implementation SinusHyperbolicus

- (void)evalScalar:(ResultType *)s
{
   [self typeEnforce:rtReal|rtComplex :s];
   if (s->f == rtReal)
      s->r = sinhl(s->r);
   else // (s->f == rtComplex)
      s->z = csinhl(s->z);
}

@end


@implementation AreaSinusHyperbolicus

- (void)evalScalar:(ResultType *)s
{
   [self typeEnforce:rtReal|rtComplex :s];
   if (s->f == rtReal)
      s->r = asinhl(s->r);
   else // (s->f == rtComplex)
      s->z = casinhl(s->z);
}

@end


@implementation CosinusHyperbolicus

- (void)evalScalar:(ResultType *)s
{
   [self typeEnforce:rtReal|rtComplex :s];
   if (s->f == rtReal)
      s->r = coshl(s->r);
   else // (s->f == rtComplex)
      s->z = ccoshl(s->z);
}

@end


@implementation AreaCosinusHyperbolicus

- (void)evalScalar:(ResultType *)s
{
   [self typeEnforce:rtReal|rtComplex :s];
   if (s->f == rtReal)
      if (!gAutoReal2CmplxFlag || s->r >= 1.0L)
         s->r = acoshl(s->r);
      else
      {
         s->f = rtComplex;
         s->z = cacoshl(s->r);
      }
   else // (s->f == rtComplex)
      s->z = cacoshl(s->z);
}

@end


@implementation TangensHyperbolicus

- (void)evalScalar:(ResultType *)s
{
   [self typeEnforce:rtReal|rtComplex :s];
   if (s->f == rtReal)
      s->r = tanhl(s->r);
   else // (s->f == rtComplex)
      s->z = ctanhl(s->z);
}

@end


@implementation AreaTangensHyperbolicus

- (void)evalScalar:(ResultType *)s
{
   [self typeEnforce:rtReal|rtComplex :s];
   if (s->f == rtReal)
      s->r = atanhl(s->r);
   else // (s->f == rtComplex)
      s->z = catanhl(s->z);
}

@end


@implementation CotangensHyperbolicus

- (void)evalScalar:(ResultType *)s
{
   [self typeEnforce:rtReal|rtComplex :s];
   if (s->f == rtReal)
      s->r = 1.0L/tanhl(s->r);
   else // (s->f == rtComplex)
      s->z = cdivl(1.0L, ctanhl(s->z));
}

@end


@implementation AreaCotangensHyperbolicus

- (void)evalScalar:(ResultType *)s
{
   [self typeEnforce:rtReal|rtComplex :s];
   if (s->f == rtReal)
      s->r = atanhl(1.0L/s->r);
   else // (s->f == rtComplex)
      s->z = catanhl(cdivl(1.0L, s->z));
}

@end


#pragma mark ••• Unit Coversions •••

@interface Radian2Degree : CalcUni @end
@interface Degree2Radian : CalcUni @end
@interface pt2cm : CalcUni @end
@interface cm2pt : CalcUni @end
@interface Celsius2Fahrenheit : CalcUni @end
@interface Fahrenheit2Celsius : CalcUni @end

@implementation Radian2Degree

- (void)evalScalar:(ResultType *)s
{
   [self typeEnforce:rtReal|rtComplex :s];
   if (s->f == rtReal)
      s->r = s->r*(180.0L/3.141592653589793238462643383279502L);
   else // (s->f == rtComplex)
      s->z = s->z*(180.0L/3.141592653589793238462643383279502L);
}

@end


@implementation Degree2Radian

- (void)evalScalar:(ResultType *)s
{
   [self typeEnforce:rtReal|rtComplex :s];
   if (s->f == rtReal)
      s->r = s->r*(3.141592653589793238462643383279502L/180.0L);
   else // (s->f == rtComplex)
      s->z = s->z*(3.141592653589793238462643383279502L/180.0L);
}

@end


@implementation pt2cm

- (void)evalScalar:(ResultType *)s
{
   [self typeEnforce:rtReal|rtComplex :s];
   if (s->f == rtReal)
      s->r = s->r*(2.54L/72.0L);
   else // (s->f == rtComplex)
      s->z = s->z*(2.54L/72.0L);
}

@end


@implementation cm2pt

- (void)evalScalar:(ResultType *)s
{
   [self typeEnforce:rtReal|rtComplex :s];
   if (s->f == rtReal)
      s->r = s->r*(72.0L/2.54L);
   else // (s->f == rtComplex)
      s->z = s->z*(72.0L/2.54L);
}

@end


@implementation Celsius2Fahrenheit

- (void)evalScalar:(ResultType *)s
{
   [self typeEnforce:rtReal|rtComplex :s];
   if (s->f == rtReal)
      s->r = s->r*1.8L + 32.0L;
   else // (s->f == rtComplex)
      s->z = s->z*1.8L + 32.0L;
}

@end


@implementation Fahrenheit2Celsius

- (void)evalScalar:(ResultType *)s
{
   [self typeEnforce:rtReal|rtComplex :s];
   if (s->f == rtReal)
      s->r = (s->r - 32.0L)/1.8L;
   else // (s->f == rtComplex)
      s->z = (s->z - 32.0L)/1.8L;
}

@end


#pragma mark ••• Special Functions •••

@interface IndexOfPoint : CalcFactor @end
@interface RandomNumber : CalcFactor @end
@interface Annuity : CalcDuo @end
@interface Compound : CalcDuo @end
@interface Factorial : CalcUni @end
@interface FactorialLn : CalcUni @end
@interface Gamma : CalcUni @end
@interface GammaLn : CalcUni @end
@interface Combinations : CalcDuo @end
@interface Variations : CalcDuo @end
@interface ErrorFunction : CalcUni @end
@interface ProbabilityFunction : CalcUni @end
@interface Gauss : CalcMulti @end
@interface GaussLn : CalcMulti @end
@interface Resistance : CalcMulti @end
@interface Capacitance : CalcMulti @end

@implementation IndexOfPoint

- (ResultType)evaluate:(unsigned)index
{
   return (ResultType){rtInteger, 0, false, (int64_t)index, 0.0L, {0.0L, 0.0L}, NULL, NULL, {noError, 0, 0}};
}

@end


@implementation RandomNumber

- (ResultType)evaluate:(unsigned)index
{
   uint64_t rand; arc4random_buf(&rand, sizeof(uint64_t));
   return (ResultType){rtReal, 0, false, 0LL, (long double)rand/0xFFFFFFFFFFFFFFFFull, {0.0L, 0.0L}, NULL, NULL, {noError, 0, 0}};
}

@end


@implementation Annuity

- (void)evalScalar:(ResultType *)s withScalar:(ResultType *)t result:(ResultType *)r
{
   if ([self typeAdjust:rtReal :s :t :r] == rtReal)
      r->r = (1.0L - powl(1.0L + s->r, -t->r))/s->r;
}

@end


@implementation Compound

- (void)evalScalar:(ResultType *)s withScalar:(ResultType *)t result:(ResultType *)r
{
   if ([self typeAdjust:rtReal :s :t :r] == rtReal)
      r->r = powl(1.0L + s->r, t->r);
}

@end


llong factorials[21] =
{
   1LL, 1LL, 2LL, 6LL, 24LL, 120LL, 720LL, 5040LL, 40320LL, 362880LL, 3628800LL,
   39916800LL, 479001600LL, 6227020800LL, 87178291200LL, 1307674368000LL,
   20922789888000LL, 355687428096000LL, 6402373705728000LL,
   121645100408832000LL, 2432902008176640000LL
};

@implementation Factorial

- (void)evalScalar:(ResultType *)s
{
   switch (s->f)
   {
      case rtBoolean:
         s->f = rtInteger;
         s->i = 1LL;
         break;

      case rtInteger:
         if (s->i < 0LL)
            s->f = rtReal, s->r = __builtin_nanl("0");

         else if (s->i <= 20)
            s->i = factorials[s->i];

         else
            s->f = rtReal, s->r = tgammal(s->i + 1LL);
         break;

      case rtReal:
         s->r = tgammal(s->r + 1.0L);
         break;

      default:
         s->f = rtError;
         break;
   }
}

@end


@implementation FactorialLn

- (void)evalScalar:(ResultType *)s
{
   switch (s->f)
   {
      case rtBoolean:
         s->f = rtReal;
         s->i = 0.0L;
         break;

      case rtInteger:
         s->f = rtReal;
         if (s->i < 0LL)
            s->r = __builtin_nanl("0");

         else if (s->i <= 20)
            s->r = logl(factorials[s->i]);

         else
            s->r = lgammal(s->i + 1LL);
         break;

      case rtReal:
         s->r = lgammal(s->r + 1.0L);
         break;

      default:
         s->f = rtError;
         break;
   }
}

@end


@implementation Gamma

- (void)evalScalar:(ResultType *)s
{
   if ([self typeEnforce:rtReal :s])
      s->r = tgammal(s->r);
   else
      s->f = rtError;
}

@end


@implementation GammaLn

- (void)evalScalar:(ResultType *)s
{
   if ([self typeEnforce:rtReal :s])
      s->r = lgammal(s->r);
   else
      s->f = rtError;
}

@end


@implementation Combinations

- (void)evalScalar:(ResultType *)n withScalar:(ResultType *)k result:(ResultType *)r
{
   if ([self typeAdjust:rtReal :n :k :r] == rtReal)
      // n!/[k!(n-k)!]
      r->r = expl(lgammal(n->r + 1.0L) - (lgammal(k->r + 1.0L) + lgammal(n->r - k->r + 1.0L)));
}

@end


@implementation Variations

- (void)evalScalar:(ResultType *)n withScalar:(ResultType *)k result:(ResultType *)r
{
   if ([self typeAdjust:rtReal :n :k :r] == rtReal)
      // n!/(n-k)!
      r->r = expl(lgammal(n->r + 1.0L) - lgammal(n->r - k->r + 1.0L));
}

@end


@implementation ErrorFunction

- (void)evalScalar:(ResultType *)s
{
   if ([self typeEnforce:rtReal :s])
      s->r = erfl(s->r);
   else
      s->f = rtError;
}

@end


@implementation ProbabilityFunction

- (void)evalScalar:(ResultType *)s
{
   if ([self typeEnforce:rtReal :s])
      s->r = erfl(s->r/1.4142135623730951454746218587388L);
   else
      s->f = rtError;
}

@end


@implementation Gauss

- (ResultType)evaluate:(unsigned)index
{
   ResultType x, m, s;

   x = [multi[0] evaluate:index];
   if (![self typeEnforce:rtReal :&x])
   {
      [multi[0] setErrorInEvaluation:typeError :&x :0];
      return x;
   }

   m = [multi[1] evaluate:index];
   if (![self typeEnforce:rtReal :&m])
   {
      [multi[1] setErrorInEvaluation:typeError :&m :0];
      freeVector(&x);
      return m;
   }

   s = [multi[2] evaluate:index];
   if (![self typeEnforce:rtReal :&s])
   {
      [multi[2] setErrorInEvaluation:typeError :&s :0];
      freeVector(&x);
      freeVector(&m);
      return s;
   }

   x.f = rtReal;
   x.r = 0.398942280401432719448097943893554247L/s.r * expl(-0.5L*sqrl((x.r - m.r)/s.r));
   if (isnan(x.r))
      [self setErrorInEvaluation:nanError :&x :0];

   freeVector(&m);
   freeVector(&s);
   return x;
}

@end


@implementation GaussLn

- (ResultType)evaluate:(unsigned)index
{
   ResultType x, m, s;

   x = [multi[0] evaluate:index];
   if (![self typeEnforce:rtReal :&x])
   {
      [multi[0] setErrorInEvaluation:typeError :&x :0];
      return x;
   }

   m = [multi[1] evaluate:index];
   if (![self typeEnforce:rtReal :&m])
   {
      [multi[1] setErrorInEvaluation:typeError :&m :0];
      freeVector(&x);
      return m;
   }

   s = [multi[2] evaluate:index];
   if (![self typeEnforce:rtReal :&s])
   {
      [multi[2] setErrorInEvaluation:typeError :&s :0];
      freeVector(&x);
      freeVector(&m);
      return s;
   }

   x.f = rtReal;
   x.r = (x.r > 0.0L)
       ? 0.398942280401432719448097943893554247L/(s.r*x.r) * expl(-0.5L*sqrl((logl(x.r) - m.r)/s.r))
       : 0.0L;
   if (isnan(x.r))
      [self setErrorInEvaluation:nanError :&x :0];

   freeVector(&m);
   freeVector(&s);
   return x;
}

@end


@implementation Resistance

static inline long double resistance(long double Y, long double phi, long double R0, long double n, long double F)
{
   long double Z1p = cosl(phi)/Y - R0;
   long double Z2  = sinl(phi)/Y;
   long double Zp  = Z1p*Z1p + Z2*Z2;
   long double cpe = tanl(n*1.5707963267948966192313216916397514L);

   return 1.0L/(Z1p/Zp + Z2/(Zp*cpe));
}

- (ResultType)evaluate:(unsigned)index
{
   ResultType Y, phi, R0, n, F;

   Y = [multi[0] evaluate:index];
   if (![self typeEnforce:rtReal :&Y])
   {
      [multi[0] setErrorInEvaluation:typeError :&Y :0];
      return Y;
   }

   phi = [multi[1] evaluate:index];
   if (![self typeEnforce:rtReal :&phi])
   {
      [multi[1] setErrorInEvaluation:typeError :&phi :0];
      freeVector(&Y);
      return phi;
   }

   R0 = [multi[2] evaluate:index];
   if (![self typeEnforce:rtReal :&R0])
   {
      [multi[2] setErrorInEvaluation:typeError :&R0 :0];
      freeVector(&Y);
      freeVector(&phi);
      return R0;
   }


   n = [multi[3] evaluate:index];
   if (![self typeEnforce:rtReal :&n])
   {
      [multi[3] setErrorInEvaluation:typeError :&n :0];
      freeVector(&Y);
      freeVector(&phi);
      freeVector(&R0);
      return n;
   }

   F = [multi[4] evaluate:index];
   if (![self typeEnforce:rtReal :&F])
   {
      [multi[4] setErrorInEvaluation:typeError :&F :0];
      freeVector(&Y);
      freeVector(&phi);
      freeVector(&R0);
      freeVector(&n);
      return F;
   }

   Y.f = rtReal;
   Y.r = resistance(Y.r, phi.r, R0.r, n.r, F.r);
   if (isnan(Y.r))
      [self setErrorInEvaluation:nanError :&Y :0];

   return Y;
}

@end

@implementation Capacitance

static inline long double capacitance(long double Y, long double phi, long double R0, long double n, long double F)
{
   long double Z1p = cosl(phi)/Y - R0;
   long double Z2  = sinl(phi)/Y;
   long double Zp  = Z1p*Z1p + Z2*Z2;
   long double cpe = expl(n * logl(F*6.2831853071795864769252867665590058L));

   return -Z2/(Zp*cpe*sinl(n*1.5707963267948966192313216916397514L));
}

- (ResultType)evaluate:(unsigned)index
{
   ResultType Y, phi, R0, n, F;

   Y = [multi[0] evaluate:index];
   if (![self typeEnforce:rtReal :&Y])
   {
      [multi[0] setErrorInEvaluation:typeError :&Y :0];
      return Y;
   }

   phi = [multi[1] evaluate:index];
   if (![self typeEnforce:rtReal :&phi])
   {
      [multi[1] setErrorInEvaluation:typeError :&phi :0];
      freeVector(&Y);
      return phi;
   }

   R0 = [multi[2] evaluate:index];
   if (![self typeEnforce:rtReal :&R0])
   {
      [multi[2] setErrorInEvaluation:typeError :&R0 :0];
      freeVector(&Y);
      freeVector(&phi);
      return R0;
   }


   n = [multi[3] evaluate:index];
   if (![self typeEnforce:rtReal :&n])
   {
      [multi[3] setErrorInEvaluation:typeError :&n :0];
      freeVector(&Y);
      freeVector(&phi);
      freeVector(&R0);
      return n;
   }

   F = [multi[4] evaluate:index];
   if (![self typeEnforce:rtReal :&F])
   {
      [multi[4] setErrorInEvaluation:typeError :&F :0];
      freeVector(&Y);
      freeVector(&phi);
      freeVector(&R0);
      freeVector(&n);
      return F;
   }

   Y.f = rtReal;
   Y.r = capacitance(Y.r, phi.r, R0.r, n.r, F.r);
   if (isnan(Y.r))
      [self setErrorInEvaluation:nanError :&Y :0];

   return Y;
}

@end


#pragma mark ••• Special Complex Functions •••

@interface CReal : CalcUni @end
@interface CImag : CalcUni @end
@interface CConjugate : CalcUni @end
@interface CArgument : CalcUni @end

@implementation CReal

- (void)evalScalar:(ResultType *)s
{
   switch (s->f)
   {
      case rtBoolean:
         s->f = rtInteger;
         s->i = s->b;
         break;

      case rtComplex:
         s->f = rtReal;
         s->r = creall(s->z);
         break;
   }
}

@end


@implementation CImag

- (void)evalScalar:(ResultType *)s
{
   switch (s->f)
   {
      case rtBoolean:
         s->f = rtInteger;

      case rtInteger:
         s->i = 0;
         break;

      case rtReal:
         s->r = 0.0L;
         break;

      case rtComplex:
         s->f = rtReal;
         s->r = cimagl(s->z);
         break;
   }
}

@end


@implementation CConjugate

- (void)evalScalar:(ResultType *)s
{
   switch (s->f)
   {
      case rtBoolean:
         s->f = rtInteger;
         s->i = s->b;
         break;

      case rtComplex:
         s->z = conjl(s->z);
         break;
   }
}

@end



@implementation CArgument

- (void)evalScalar:(ResultType *)s
{
   switch (s->f)
   {
      case rtBoolean:
         s->f = rtInteger;

      case rtInteger:
         s->i = 0;
         break;

      case rtReal:
         s->r = 0.0L;
         break;

      case rtComplex:
         s->f = rtReal;
         s->r = atan2l(cimagl(s->z), creall(s->z));
         break;
   }
}

@end



#pragma mark ••• Vector and Matrix Operations •••

@interface MakeVector : CalcDuo @end
@interface MakeDiagonal : CalcDuo @end
@interface MakeMatrix : CalcMulti @end
@interface Element : CalcMulti @end
@interface Simplify : CalcMulti @end
@interface Norm : CalcUni @end
@interface Determinant : CalcUni @end
@interface MatrixTransposition : CalcUni @end
@interface SingularValueDecomp : CalcUni @end
@interface MatrixInversion : CalcUni @end
@interface VectorCrossProduct : CalcDuo @end
@interface MatrixMultiplication : CalcDuo @end
@interface MatrixDivision : CalcDuo @end

@implementation MakeVector

- (ResultType)evaluate:(unsigned)index
{
   ResultType e = [prevTerm evaluate:index];
   if (![self typeEnforce:rtScalar|rtComplex|rtVector :&e])
   {
      [prevTerm setErrorInEvaluation:typeError :&e :0];
      return e;
   }

   ResultType m = [nextTerm evaluate:index];
   if (![self typeEnforce:rtInteger :&m])
   {
      [nextTerm setErrorInEvaluation:typeError :&m :0];
      freeVector(&e);
      return m;
   }
   else if (m.i <= 0LL || 100LL < m.i)
   {
      [nextTerm setErrorInEvaluation:oorError :&m :0];
      freeVector(&e);
      return m;
   }

   ResultType v = gNoneResult;
   v.f = rtVector;
   v.v = allocate((v.n = (unsigned)m.i)*sizeof(ResultType), default_align, true);
   for (unsigned i = 0; i < v.n; i++)
   {
      v.v[i] = e;
      if (e.f == rtVector)
         v.v[i].v = copyVector(&e);
   }

   freeVector(&e);
   return v;
}

@end


@implementation MakeDiagonal

- (ResultType)evaluate:(unsigned)index
{
   ResultType d = [prevTerm evaluate:index];
   if (![self typeEnforce:rtScalar|rtComplex|rtVector :&d])
   {
      [prevTerm setErrorInEvaluation:typeError :&d :0];
      return d;
   }

   ResultType m = [nextTerm evaluate:index];
   if (![self typeEnforce:rtInteger :&m])
   {
      [nextTerm setErrorInEvaluation:typeError :&m :0];
      freeVector(&d);
      return m;
   }
   else if (m.i <= 0LL || 100LL < m.i)
   {
      [nextTerm setErrorInEvaluation:oorError :&m :0];
      freeVector(&d);
      return m;
   }

   ResultType e = gNoneResult; e.f = rtInteger;
   ResultType v = gNoneResult;
   v.f = rtVector;
   v.v = allocate((v.n = (unsigned)m.i)*sizeof(ResultType), default_align, true);
   for (unsigned i = 0; i < v.n; i++)
   {
      v.v[i].f = rtVector;
      v.v[i].v = allocate((v.v[i].n = (unsigned)m.i)*sizeof(ResultType), default_align, true);
      for (unsigned j = 0; j < v.v[i].n; j++)
         if (i == j)
         {
            v.v[i].v[j] = d;
            if (d.f == rtVector)
               v.v[i].v[j].v = copyVector(&d);
         }
         else
            v.v[i].v[j] = e;
   }

   freeVector(&d);
   return v;
}

@end


@implementation MakeMatrix

- (ResultType)evaluate:(unsigned)index
{
   ResultType e = [multi[0] evaluate:index];
   if (![self typeEnforce:rtScalar|rtComplex|rtVector :&e])
   {
      [multi[0] setErrorInEvaluation:typeError :&e :0];
      return e;
   }

   ResultType m = [multi[1] evaluate:index];
   if (![self typeEnforce:rtInteger :&m])
   {
      [multi[1] setErrorInEvaluation:typeError :&m :0];
      freeVector(&e);
      return m;
   }
   else if (m.i <= 0LL || 100LL < m.i)
   {
      [multi[1] setErrorInEvaluation:oorError :&m :0];
      freeVector(&e);
      return m;
   }

   ResultType n = [multi[2] evaluate:index];
   if (![self typeEnforce:rtInteger :&n])
   {
      [multi[2] setErrorInEvaluation:typeError :&n :0];
      freeVector(&e);
      freeVector(&m);
      return n;
   }
   else if (n.i <= 0LL || 100LL < n.i)
   {
      [multi[2] setErrorInEvaluation:oorError :&n :0];
      freeVector(&e);
      freeVector(&m);
      return n;
   }

   ResultType v = gNoneResult;
   v.f = rtVector;
   v.v = allocate((v.n = (unsigned)m.i)*sizeof(ResultType), default_align, true);
   for (unsigned i = 0; i < v.n; i++)
   {
      v.v[i].f = rtVector;
      v.v[i].v = allocate((v.v[i].n = (unsigned)n.i)*sizeof(ResultType), default_align, true);
      for (unsigned j = 0; j < v.v[i].n; j++)
      {
         v.v[i].v[j] = e;
         if (e.f == rtVector)
            v.v[i].v[j].v = copyVector(&e);
      }
   }

   freeVector(&e);
   return v;
}

@end


@implementation Element

- (ResultType)evaluate:(unsigned)index
{
   ResultType v = gNoneResult;
   if (paramCount <= 1)
   {
      [multi[0] setErrorInEvaluation:paramError :&v :0];
      return v;
   }

   v = [multi[0] evaluate:index];
   if (v.f != rtVector)
   {
      [multi[0] setErrorInEvaluation:typeError :&v :0];
      return v;
   }

   ResultType i, *r = &v;
   for (int j = 1; j < paramCount; j++)
   {
      i = [multi[j] evaluate:index];
      if ([self typeEnforce:rtInteger :&i] && r->f == rtVector && 0 < i.i && i.i <= r->n)
         r = &r->v[i.i-1];

      else if (i.f != rtError)
      {
         [multi[j] setErrorInEvaluation:oorError:&i :0];
         freeVector(&v);
         return i;
      }

      else // (i.f == rtError)
      {
         freeVector(&v);
         return i;
      }

      freeVector(&i);
   }

   i = *r;
   i.v = copyVector(&i);
   freeVector(&v);
   return i;
}

@end


@implementation Simplify

static inline void sieve(ResultType *v, long double thresh)
{
   switch (v->f)
   {
      case rtBoolean:
         if (v->b < thresh)
            v->b = false;
         break;

      case rtInteger:
         if (llabs(v->i) < thresh)
            v->i = 0LL;
         break;

      case rtReal:
         if (fabsl(v->r) < thresh)
            v->r = 0.0L;
         break;

      case rtComplex:
         if (fabsl(creall(v->z)) < thresh && fabsl(cimagl(v->z)) < thresh)
            v->f = rtReal, v->r = 0.0L;
         else if (fabsl(cimagl(v->z)) < thresh)
            v->f = rtReal, v->r = creall(v->z);
         else if (fabsl(creall(v->z)) < thresh)
            v->z = 0.0L + I*cimagl(v->z);
         break;

      case rtVector:
         for (int i = 0; i < v->n; i++)
            sieve(&v->v[i], thresh);
         break;
   }
}

- (ResultType)evaluate:(unsigned)index
{
   ResultType t = gNullResult;

   if (paramCount > 2)
   {
      [multi[2] setErrorInEvaluation:paramError :&t :0];
      return t;
   }

   else if (paramCount == 2)
   {
      t = [multi[1] evaluate:index];
      if (![self typeEnforce:rtReal :&t])
      {
         [multi[1] setErrorInEvaluation:typeError :&t :0];
         return t;
      }

      t.r = fabsl(t.r);
   }

   ResultType v = [multi[0] evaluate:index];
   if (v.f & (rtScalar|rtComplex|rtVector))
   {
      if (t.r > 0.0L)
         sieve(&v, t.r);
      simplifyVector(&v);
   }

   else if (v.f != rtError)
      [multi[0] setErrorInEvaluation:typeError :&v :0];

   return v;
}

@end


@implementation Norm

- (void)evalScalar:(ResultType *)s
{
   switch (s->f)
   {
      case rtBoolean:
         s->f = rtInteger;
         s->i = s->b;
         break;

      case rtInteger:
         s->i = llabs(s->i);
         break;

      case rtReal:
         s->r = fabsl(s->r);
         break;

      case rtComplex:
         s->f = rtReal;
         s->r = cabsl(s->z);
         break;
   }
}

- (void)evalVector:(ResultType *)v
{
   simplifyVector(v);
   if (v->f != rtVector)
      [self evalScalar:v];
   else
   {
      v->f = rtReal;
      v->r = sqrtl(sqrsum(v));
      freeVector(v);
   }
}

@end


@implementation Determinant

static long double LUdcmp(int m, Matrix A, Matrix LU, Index idx);

- (void)evalVector:(ResultType *)v
{
   unsigned i, j, n;

   // require a square regular n x n matrix, i.e. all n rows have the same number of elements n
   if (n = v->n)
   {
      for (i = 0; i < n; i++)
         if (v->v[i].n != n)
            goto error;

      if (n > 1)
      {
         Matrix M = alloca(n*sizeof(long double));
         for (i = 0; i < n; i++)
         {
            M[i] = alloca(n*sizeof(long double));
            for (j = 0; j < n; j++)
               if ([self typeEnforce:rtReal :&v->v[i].v[j]])
                  M[i][j] = v->v[i].v[j].r;
               else
                  goto error;
         }

         long double det = LUdcmp(n, M, M, NULL);
         for (i = 0; i < n; i++)
            det *= M[i][i];
         v->r = det;
      }
      else if ([self typeEnforce:rtReal :v->v->v])
         v->r = v->v->v->r;
      else
         goto error;
   }

   else // the determinant of a 0 x 0 matrix is 1.
      v->r = 1.0L;

   freeVector(v);
   v->f = rtReal;
   return;

error:
   v->f = rtError;
   return;
}

@end


@implementation MatrixTransposition

- (void)evalVector:(ResultType *)v
{
   unsigned i, j, m, n;

   // require a regular m x n matrix, i.e. all rows have the same number of elements n
   m = v->v[0].n;
   if (n = v->n)
   {
      for (i = 1; i < n; i++)
         if (v->v[i].n != m)
         {
            v->f = rtError;
            return;
         }

      if (!m) m = 1;

      ResultType *w = allocate(m*sizeof(ResultType), default_align, true);
      for (i = 0; i < m; i++)
      {
         w[i].f = rtVector;
         w[i].v = allocate((w[i].n = n)*sizeof(ResultType), default_align, true);
         for (j = 0; j < n; j++)
            w[i].v[j] = (v->v[j].f == rtVector) ? v->v[j].v[i] : v->v[j];
      }

      freeVector(v);
      v->n = m;
      v->v = w;
   }
   else
      v->f = rtError;
}

@end


@implementation SingularValueDecomp

static boolean svd(int m, int n, Matrix M, Matrix U, Matrix V, Vector S);
static void svs(int m, int n, Matrix U, Matrix V, Vector S);
static void m_T(int m, int n, Matrix M, Matrix T);
static boolean m_x_v(int m, int n, Matrix M, Vector B, Vector X) __attribute__((unused));
static boolean m_x_m(int m, int l, int n, Matrix A, Matrix B, Matrix C);
static void m_x_d(int m, int n, Matrix A, Vector D, Matrix C);
static boolean d_i(int n, Vector D, Vector iD, long double *thresh, int *rank, int *nullity);

- (void)evalVector:(ResultType *)v
{
   ResultType *w;
   unsigned i, j, m, n;

   // require a regular m x n matrix, i.e. all rows have the same number of elements n
   if (m = v->n)
   {
      n = v->v[0].n;
      for (i = 1; i < m; i++)
         if (v->v[i].n != n)
         {
            v->f = rtError;
            return;
         }

      if (n == 0)
      {
         n = m;
         w = allocate(sizeof(ResultType), default_align, false);
         *w = *v;
         v->n = m = 1;
         v->v = w;
      }

      Matrix M = alloca(m*sizeof(long double));
      for (i = 0; i < m; i++)
      {
         M[i] = alloca(n*sizeof(long double));
         for (j = 0; j < n; j++)
            if ([self typeEnforce:rtReal :&v->v[i].v[j]])
               M[i][j] = v->v[i].v[j].r;
            else
            {
               v->f = rtError;
               return;
            }
      }

      Matrix V = alloca(n*sizeof(long double));
      for (i = 0; i < n; i++)
         V[i] = alloca(n*sizeof(long double));

      Vector S = alloca(n*sizeof(long double));

      svd(m, n, M, M, V, S);     // Singular Value Decomposition:  M = U∑V^T
      svs(m, n, M, V, S);

      w = allocate(n*sizeof(ResultType), default_align, true);
      for (i = 0; i < n; i++)
         w[i].f = rtReal, w[i].r = S[i];

      freeVector(v);
      v->n = n;
      v->v = w;
   }
   else
      v->f = rtError;
}

@end


@implementation MatrixInversion

- (void)evalScalar:(ResultType *)s
{
   switch (s->f)
   {
      case rtBoolean:
         s->f = rtReal;
         s->r = 1.0L/s->b;

      case rtInteger:
         s->f = rtReal;
         s->r = 1.0L/s->i;
         break;

      case rtReal:
         s->r = 1.0L/s->r;
         break;

      case rtComplex:
         if (creall(s->z) == 0.0L && cimagl(s->z) == 0.0L)
            s->z = __builtin_infl();
         else if (isinf(creall(s->z)) || isinf(cimagl(s->z)))
            s->z = 0.0L;
         else
            s->z = 1.0L/s->z;
         break;
   }
}

- (void)evalVector:(ResultType *)v
{
   ResultType *w;
   unsigned i, j, k, m, n;

   // require a regular m x n matrix, i.e. all rows have the same number of elements n
   if (m = v->n)
   {
      n = v->v[0].n;
      for (i = 1; i < m; i++)
         if (v->v[i].n != n)
         {
            v->f = rtError;
            return;
         }

      if (n == 0)
      {
         n = m;
         w = allocate(sizeof(ResultType), default_align, false);
         *w = *v;
         v->n = m = 1;
         v->v = w;
      }

      k = (m >= n) ? m : n;

      Matrix M = alloca(k*sizeof(long double));
      Matrix U = alloca(k*sizeof(long double));
      Matrix T = alloca(k*sizeof(long double));
      for (i = 0; i < k; i++)
      {
         M[i] = alloca(k*sizeof(long double));
         U[i] = alloca(k*sizeof(long double));
         T[i] = alloca(k*sizeof(long double));
      }

      Matrix V = alloca(n*sizeof(long double));
      for (i = 0; i < n; i++)
         V[i] = alloca(n*sizeof(long double));

      Vector S = alloca(n*sizeof(long double));

      for (i = 0; i < m; i++)
         for (j = 0; j < n; j++)
            if ([self typeEnforce:rtReal :&v->v[i].v[j]])
               M[i][j] = v->v[i].v[j].r;
            else
            {
               v->f = rtError;
               return;
            }

      for (; i < k; i++)
         for (j = 0; j < n; j++)
            M[i][j] = 0.0L;

      long double thresh = __LDBL_EPSILON__;
                                                          // Matrix inversion
      if (svd(k, n, M, U, V, S) &&                        // 1. Singular Value Decomposition:  M = U∑V^T
          d_i(n, S, S, &thresh, NULL, NULL) ||            // 2. Singular Value Inversion:      S^-1
          m != n)                                         // flag singularError only for square matrices
      {
         m_x_d(n, n, V, S, M);                            // 3. Compute the inverse Matrix:    M^-1 = VS^-1U^T
         m_T(m, n, U, T);
         m_x_m(n, n, m, M, T, M);

         w = allocate(n*sizeof(ResultType), default_align, true);
         for (i = 0; i < n; i++)
         {
            w[i].f = rtVector;
            w[i].v = allocate((w[i].n = m)*sizeof(ResultType), default_align, true);
            for (j = 0; j < m; j++)
               w[i].v[j].f = rtReal, w[i].v[j].r = (fabsl(M[i][j]) > thresh) ? M[i][j] : 0.0L;
         }

         freeVector(v);
         v->n = n;
         v->v = w;
      }

      else // (!svd() || !d_i())
      {
         v->f = rtError;
         v->e.flag = singularError;
      }
   }
   else
      v->f = rtError;
}

@end


@implementation VectorCrossProduct

- (ResultType)evaluate:(unsigned)index
{
   ResultType r = gNoneResult;
   ResultType r1, r2;

   r1 = [prevTerm evaluate:index];
   if (r1.f == rtError)
      return r1;

   r2 = [nextTerm evaluate:index];
   if (r2.f == rtError)
   {
      freeVector(&r1);
      return r2;
   }

   if (r1.f == rtVector && r2.f == rtVector && r1.n == r2.n && r1.n == 3)
   {
      ResultTypeFlags t1, t2;
      unsigned i, j, k;
      r.v = allocate((r.n = 3)*sizeof(ResultType), default_align, true);
      r.f = rtVector;
      for (i = 0, j = 1, k = 2; i < 3; i++, (j<2)?j++:(j=0), (k<2)?k++:(k=0))
      {
         switch (t1 = [self typeAdjust:rtScalar :&r1.v[j] :&r2.v[k] :&r.v[i]])
         {
            case rtInteger:
               r.v[i].i = r1.v[j].i * r2.v[k].i;
               break;

            case rtReal:
               r.v[i].r = r1.v[j].r * r2.v[k].r;
               break;

            default:
               [self setErrorInEvaluation:typeError :&r.v[i] :0];
               goto error;
         }

         switch (t2 = [self typeAdjust:rtScalar :&r1.v[k] :&r2.v[j] :&r.v[i]])
         {
            case rtInteger:
               r.v[i].i -= r1.v[k].i * r2.v[j].i;
               break;

            case rtReal:
               r.v[i].r -= r1.v[k].r * r2.v[j].r;
               break;

            default:
               [self setErrorInEvaluation:typeError :&r.v[i] :0];
               goto error;
         }

         if (t1 == t2)
            r.v[i].f = t1;
         else
            r.v[i].f = rtReal, r.v[i].r += r.v[i].i;
      }
   }

   else if (r1.f != rtVector || r1.n != 3)
      [prevTerm setErrorInEvaluation:typeError :&r :0];

   else // (r2.f != rtVector || r1.n != r2.n)
      [nextTerm setErrorInEvaluation:typeError :&r :0];

error:
   freeVector(&r1);
   freeVector(&r2);
   return r;
}

@end


@implementation MatrixMultiplication

- (ResultType)evaluate:(unsigned)index
{
   ResultType  r = gNoneResult;
   ResultType  r1, r2;
   ResultType *v;

   r1 = [prevTerm evaluate:index];
   if (r1.f == rtError)
      return r1;

   r2 = [nextTerm evaluate:index];
   if (r2.f == rtError)
   {
      freeVector(&r1);
      return r2;
   }

   if (r1.f == rtVector && r2.f == rtVector)
   {
      unsigned i, j, m, k, l, n;

      // require a regular m x k matrix, i.e. all rows have the same number of elements k
      if (m = r1.n)
      {
         k = r1.v[0].n;
         for (i = 1; i < m; i++)
            if (r1.v[i].n != k)
            {
               [prevTerm setErrorInEvaluation:typeError :&r :0];
               goto error;
            }

         if (k == 0)
         {
            k = m;
            v = allocate(sizeof(ResultType), default_align, false);
            *v = r1;
            r1.n = m = 1;
            r1.v = v;
         }

         // require a regular l x n matrix, i.e. all rows have the same number of elements n
         l = r2.n;
         n = r2.v[0].n;
         for (i = 1; i < l; i++)
            if (r2.v[i].n != n)
            {
               [nextTerm setErrorInEvaluation:typeError :&r :0];
               goto error;
            }

         if (n == 0)
            if (l != k)
            {
               n = l;
               v = allocate(sizeof(ResultType), default_align, false);
               *v = r2;
               r2.n = l = 1;
               r2.v = v;
            }

            else
            {
               n = 1;
               for (i = 0; i < l; i++)
               {
                  r2.v[i].n = n;
                  v = allocate(sizeof(ResultType), default_align, false);
                  *v = r2.v[i];
                  r2.v[i].v = v;
               }
            }

         // the number of columns k of the left matrix must be equal to the number rows l of the right matrix
         if (n == 0 || l != k)
         {
            [nextTerm setErrorInEvaluation:typeError :&r :0];
            goto error;
         }

         ResultTypeFlags t, t0 = rtNone;
         r.f = rtVector;
         r.v = allocate((r.n = m)*sizeof(ResultType), default_align, true);
         for (i = 0; i < m; i++)
         {
            r.v[i].f = rtVector;
            r.v[i].v = allocate((r.v[i].n = n)*sizeof(ResultType), default_align, true);
            for (j = 0; j < n; j++)
               for (k = 0; k < l; k++)
               {
                  switch (t = [self typeAdjust:rtScalar :&r1.v[i].v[k] :&r2.v[k].v[j] :&r.v[i].v[j]])
                  {
                     case rtInteger:
                        r.v[i].v[j].i += r1.v[i].v[k].i * r2.v[k].v[j].i;
                        break;

                     case rtReal:
                        r.v[i].v[j].r += r1.v[i].v[k].r * r2.v[k].v[j].r;
                        break;

                     default:
                        [self setErrorInEvaluation:typeError :&r.v[i].v[j] :0];
                        goto error;
                  }

                  if (t0 == rtNone)
                     r.v[i].v[j].f = t0 = t;

                  else if (t != t0)
                     r.v[i].v[j].f = t0 = rtReal, r.v[i].v[j].r += r.v[i].v[j].i, r.v[i].v[j].i = 0;
               }
         }
      }

      else
      {
         [prevTerm setErrorInEvaluation:typeError :&r :0];
         goto error;
      }
   }

   else if (r1.f != rtVector)
      [prevTerm setErrorInEvaluation:typeError :&r :0];

   else // (r2.f != rtVector)
      [nextTerm setErrorInEvaluation:typeError :&r :0];

error:
   freeVector(&r1);
   freeVector(&r2);
   simplifyVector(&r);
   return r;
}

@end


@implementation MatrixDivision

- (ResultType)evaluate:(unsigned)index
{
   ResultType  x = gNoneResult;
   ResultType  A, b;
   ResultType *v;

   A = [prevTerm evaluate:index];
   if (A.f == rtError)
      return A;

   b = [nextTerm evaluate:index];
   if (b.f == rtError)
   {
      freeVector(&A);
      return b;
   }

   if (A.f == rtVector)
   {
      unsigned i, j, m, k, l, n;

      // require a regular k x m matrix, i.e. all rows have the same number of elements m
      if (k = A.n)
      {
         m = A.v[0].n;
         for (i = 1; i < k; i++)
            if (A.v[i].n != m)
            {
               [prevTerm setErrorInEvaluation:typeError :&x :itsToken->tBegin];
               goto error;
            }

         if (m == 0)
         {
            m = k;
            v = allocate(sizeof(ResultType), default_align, false);
            *v = A;
            A.n = k = 1;
            A.v = v;
         }

         if (b.f == rtVector)
         {
            // require a regular l x n matrix, i.e. all rows have the same number of elements n
            l = b.n;
            n = b.v[0].n;
            for (i = 1; i < l; i++)
               if (b.v[i].n != n)
               {
                  [nextTerm setErrorInEvaluation:typeError :&x :0];
                  goto error;
               }

            if (n == 0)
               if (l != k)
               {
                  n = l;
                  v = allocate(sizeof(ResultType), default_align, false);
                  *v = b;
                  b.n = l = 1;
                  b.v = v;
               }

               else
               {
                  n = 1;
                  for (i = 0; i < l; i++)
                  {
                     b.v[i].n = n;
                     v = allocate(sizeof(ResultType), default_align, false);
                     *v = b.v[i];
                     b.v[i].v = v;
                  }
               }

            // if b is a matrix then its number of rows k must be equal to the number of rows l of the left hand divisor (i.e. inverse matrix)
            if (n == 0 || l != k)
            {
               [nextTerm setErrorInEvaluation:typeError :&x :0];
               goto error;
            }
         }

         else
         {
            n = 0;
            l = k;
            if (![self typeEnforce:rtReal :&b])
            {
               [nextTerm setErrorInEvaluation:typeError :&x :0];
               goto error;
            }
         }

         if (m > k) k = m;

         Matrix M = alloca(k*sizeof(long double));
         Matrix U = alloca(k*sizeof(long double));
         Matrix T = alloca(k*sizeof(long double));
         for (i = 0; i < k; i++)
         {
            M[i] = alloca(k*sizeof(long double));
            U[i] = alloca(k*sizeof(long double));
            T[i] = alloca(k*sizeof(long double));
         }

         Matrix V = alloca(m*sizeof(long double));
         for (i = 0; i < m; i++)
            V[i] = alloca(m*sizeof(long double));

         Vector S = alloca(m*sizeof(long double));

         for (i = 0; i < l; i++)
            for (j = 0; j < m; j++)
               if ([self typeEnforce:rtReal :&A.v[i].v[j]])
                  M[i][j] = A.v[i].v[j].r;
               else
               {
                  [prevTerm setErrorInEvaluation:typeError :&x :itsToken->tBegin];
                  goto error;
               }

         for (; i < k; i++)
            for (j = 0; j < m; j++)
               M[i][j] = 0.0L;

         long double thresh = __LDBL_EPSILON__;
                                                      // Matrix inversion
         if (svd(k, m, M, U, V, S) &&                 // 1. Singular Value Decomposition:  M = U∑V^T
             d_i(m, S, S, &thresh, NULL, NULL) ||     // 2. Singular Value Inversion:      S^-1
             l != m)                                  // flag singularError only for square matrices
         {
            m_x_d(m, m, V, S, M);                     // 3. Compute the inverse Matrix:    M^-1 = VS^-1U^T
            m_T(l, m, U, T);
            m_x_m(m, m, l, M, T, M);

            if (n == 0)
            {
               x.f = rtVector;
               x.v = allocate((x.n = m)*sizeof(ResultType), default_align, true);
               for (i = 0; i < m; i++)
               {
                  x.v[i].f = rtVector;
                  x.v[i].v = allocate((x.v[i].n = l)*sizeof(ResultType), default_align, true);
                  for (j = 0; j < l; j++)
                     x.v[i].v[j].f = rtReal, x.v[i].v[j].r = b.r * ((fabsl(M[i][j]) > thresh) ? M[i][j] : 0.0L);
               }
            }

            else
            {
               Matrix B = alloca(l*sizeof(long double));
               for (i = 0; i < l; i++)
               {
                  B[i] = alloca(n*sizeof(long double));
                  for (j = 0; j < n; j++)
                     if ([self typeEnforce:rtReal :&b.v[i].v[j]])
                        B[i][j] = b.v[i].v[j].r;
                     else
                     {
                        [nextTerm setErrorInEvaluation:typeError :&x :0];
                        goto error;
                     }
               }

               Matrix X = alloca(m*sizeof(long double));
               for (i = 0; i < m; i++)
                  X[i] = alloca(n*sizeof(long double));

               m_x_m(m, l, n, M, B, X);

               x.f = rtVector;
               x.v = allocate((x.n = m)*sizeof(ResultType), default_align, true);
               for (i = 0; i < m; i++)
               {
                  x.v[i].f = rtVector;
                  x.v[i].v = allocate((x.v[i].n = n)*sizeof(ResultType), default_align, true);
                  for (j = 0; j < n; j++)
                     x.v[i].v[j].f = rtReal, x.v[i].v[j].r = X[i][j];
               }
            }
         }
         else // (!svd() || !d_i())
            [prevTerm setErrorInEvaluation:singularError :&x :itsToken->tBegin];
      }
      else
         [prevTerm setErrorInEvaluation:typeError :&x :itsToken->tBegin];
   }
   else // (A.f != rtVector)
      [prevTerm setErrorInEvaluation:typeError :&x :itsToken->tBegin];

error:
   freeVector(&A);
   freeVector(&b);
   simplifyVector(&x);
   return x;
}

@end


#pragma mark ••• Numerical Mathematics •••

@interface ExplicitSum : CalcMulti @end
@interface ExplicitProduct : CalcMulti @end
@interface ArithmeticAverage : CalcMulti @end
@interface GeometricAverage : CalcMulti @end
@interface HarmonicAverage : CalcMulti @end
@interface StandardDeviation : CalcMulti @end
@interface Summation : CalcMulti @end
@interface SerialProduct : CalcMulti @end
@interface Integration : CalcMulti @end
@interface Differentiation : CalcDuo @end
@interface Solver : CalcDuo @end
@interface LinPol : CalcMulti @end
@interface Regression : CalcMulti @end

@implementation ExplicitSum

- (ResultType)evaluate:(unsigned)index
{
   int        j;
   ResultType r, sum = gNoneResult;

   for (j = 0; j < paramCount; j++)
   {
      r = [multi[j] evaluate:index];
      switch (r.f)
      {
         case rtError:
            return r;

         case rtBoolean:
            sum.i += r.b;
            break;

         case rtInteger:
            sum.i += r.i;
            break;

         case rtReal:
            if (!isnan(r.r))
               sum.r += r.r;
            else
            {
               [multi[j] setErrorInEvaluation:nanError:&r :0];
               return r;
            }
            break;

         default:
            [multi[j] setErrorInEvaluation:typeError:&r :0];
            return r;
      }

      freeVector(&r);
   }

   if (sum.r == 0.0L)
      sum.f = rtInteger;
   else
   {
      sum.f = rtReal;
      sum.r += sum.i;
   }

   return sum;
}

@end


@implementation ExplicitProduct

- (ResultType)evaluate:(unsigned)index
{
   int        j;
   ResultType r, prod = gNoneResult;

   prod.f = rtInteger;
   prod.i = 1;
   prod.r = 1.0L;
   for (j = 0; j < paramCount; j++)
   {
      r = [multi[j] evaluate:index];
      switch (r.f)
      {
         case rtError:
            return r;

         case rtBoolean:
            prod.i *= r.b;
            break;

         case rtInteger:
            prod.i *= r.i;
            break;

         case rtReal:
            if (!isnan(r.r))
            {
               prod.f = rtReal;
               prod.r *= r.r;
            }
            else
            {
               [multi[j] setErrorInEvaluation:nanError:&r :0];
               return r;
            }
            break;

         default:
            [multi[j] setErrorInEvaluation:typeError:&r :0];
            return r;
      }

      freeVector(&r);
   }

   if (prod.f == rtReal)
      prod.r *= prod.i;

   return prod;
}

@end


@implementation ArithmeticAverage

- (ResultType)evaluate:(unsigned)index
{
   int         j;
   long double sum = 0.0L;
   ResultType  r;

   for (j = 0; j < paramCount; j++)
   {
      r = [multi[j] evaluate:index];
      switch (r.f)
      {
         case rtError:
            return r;

         case rtBoolean:
            sum += r.b;
            break;

         case rtInteger:
            sum += r.i;
            break;

         case rtReal:
            if (!isnan(r.r))
               sum += r.r;
            else
            {
               [multi[j] setErrorInEvaluation:nanError:&r :0];
               return r;
            }
            break;

         default:
            [multi[j] setErrorInEvaluation:typeError:&r :0];
            return r;
      }

      freeVector(&r);
   }

   r.f = rtReal;
   r.r = sum/paramCount;
   return r;
}

@end


@implementation GeometricAverage

- (ResultType)evaluate:(unsigned)index
{
   int         j;
   long double sum = 0.0L;
   ResultType  r;

   for (j = 0; j < paramCount; j++)
   {
      r = [multi[j] evaluate:index];
      switch (r.f)
      {
         case rtError:
            return r;

         case rtBoolean:
            sum += logl(r.b);
            break;

         case rtInteger:
            sum += logl(r.i);
            break;

         case rtReal:
            if (!isnan(r.r))
               sum += logl(r.r);
            else
            {
               [multi[j] setErrorInEvaluation:nanError:&r :0];
               return r;
            }
            break;

         default:
            [multi[j] setErrorInEvaluation:typeError:&r :0];
            return r;
      }

      freeVector(&r);
   }

   if (!isnan(sum))
   {
      r.f = rtReal;
      r.r = expl(sum/paramCount);
      return r;
   }
   else
   {
      [self setErrorInEvaluation:nanError:&r :0];
      return r;
   }
}

@end


@implementation HarmonicAverage

- (ResultType)evaluate:(unsigned)index
{
   int         j;
   long double sum = 0.0L;
   ResultType  r;

   for (j = 0; j < paramCount; j++)
   {
      r = [multi[j] evaluate:index];
      switch (r.f)
      {
         case rtError:
            return r;

         case rtBoolean:
            sum += 1.0L/r.b;
            break;

         case rtInteger:
            sum += 1.0L/r.i;
            break;

         case rtReal:
            if (!isnan(r.r))
               sum += 1.0L/r.r;
            else
            {
               [multi[j] setErrorInEvaluation:nanError:&r :0];
               return r;
            }
            break;

         default:
            [multi[j] setErrorInEvaluation:typeError:&r :0];
            return r;
      }

      freeVector(&r);
   }

   r.f = rtReal;
   r.r = (long double)paramCount/sum;
   return r;
}

@end


@implementation StandardDeviation

- (ResultType)evaluate:(unsigned)index
{
   int         j;
   long double sum = 0.0L;
   long double sqsum = 0.0L;
   ResultType  r;

   for (j = 0; j < paramCount; j++)
   {
      r = [multi[j] evaluate:index];
      switch (r.f)
      {
         case rtError:
            return r;

         case rtBoolean:
            sum   += r.b;
            sqsum += r.b*r.b;
            break;

         case rtInteger:
            sum   += r.i;
            sqsum += r.i*r.i;
            break;

         case rtReal:
            if (!isnan(r.r))
            {
               sum   += r.r;
               sqsum += r.r*r.r;
            }
            else
            {
               [multi[j] setErrorInEvaluation:nanError:&r :0];
               return r;
            }
            break;

         default:
            [multi[j] setErrorInEvaluation:typeError:&r :0];
            return r;
      }

      freeVector(&r);
   }

   r.f = rtReal;
   r.r = sqrtl((sqsum - sum*sum/paramCount)/(paramCount - 1));
   return r;
}

@end


@implementation Summation

static long double summation(long double* a, long double* b, CalcFactor *variable, CalcObject* function, unsigned index)
{
   llong       i, k, n;
   long double sum;
   ResultType  y;

   k = llroundl(*a);
   n = llroundl(*b);
   if (fabsl((*a + *b) - (k + n)) > AbsTol)
      return __builtin_nanl("0");

   if (k > n)
   {
      i = k;
      k = n;
      n = i;
   }

   sum = 0;
   for (i = k; i <= n; i++)
   {
      [variable setRealValue:i];
      y = [function evaluate:index];
      if (y.f & rtScalar)
         sum += (y.f == rtReal) ? y.r : y.i;
      else
         return __builtin_nanl("0");
   }

   return sum;
}

- (ResultType)evaluate:(unsigned)index
{
   ResultType r0, r1, r2;

   r0 = [multi[0] evaluate:index];
   if (r0.f == rtError || r0.f == rtReal && isnan(r0.r))
      return r0;
   else if (r0.f == rtInteger)
   {
      r0.f = rtReal;
      r0.r = r0.i;
   }
   else if ((r0.f & rtScalar) == 0)
   {
      [multi[0] setErrorInEvaluation:typeError :&r0 :0];
      return r0;
   }

   r1 = [multi[1] evaluate:index];
   if (r1.f == rtError || r1.f == rtReal && isnan(r1.r))
      return r1;
   else if (r1.f == rtInteger)
   {
      r1.f = rtReal;
      r1.r = r1.i;
   }
   else if ((r1.f & rtScalar) == 0)
   {
      [multi[1] setErrorInEvaluation:typeError :&r1 :0];
      return r1;
   }

   r2 = [multi[2] evaluate:index];
   if (r2.f == rtError || r2.f == rtReal && isnan(r2.r))
      return r2;
   else if ((r2.f & rtScalar) == 0)
   {
      [multi[2] setErrorInEvaluation:typeError :&r2 :0];
      return r2;
   }

   if ([multi[0] isMemberOfClass:[CalcFactor class]])
      r0.r = summation(&r0.r, &r1.r, (CalcFactor *)multi[0], multi[2], index);
   else if ([multi[0] isMemberOfClass:[SetEqual class]] && [[(SetEqual *)multi[0] prevTerm] isMemberOfClass:[CalcFactor class]])
      r0.r = summation(&r0.r, &r1.r, [(SetEqual *)multi[0] prevTerm], multi[2], index);
   else
   {
      [multi[0] setErrorInEvaluation:typeError :&r0 :0];
      return r0;
   }

   r0.f = rtReal;
   if (isnan(r0.r))
      [self setErrorInEvaluation:nanError :&r0 :0];

   return r0;
}

@end


@implementation SerialProduct

static long double serialProduct(long double* a, long double* b, CalcFactor* variable, CalcObject* function, unsigned index)
{
   llong       i, k, n;
   long double prod;
   ResultType  y;

   k = llroundl(*a);
   n = llroundl(*b);
   if (fabsl((*a + *b) - (k + n)) > AbsTol)
      return __builtin_nanl("0");

   if (k > n)
   {
      i = k;
      k = n;
      n = i;
   }

   prod = 1.0L;
   for (i = k; i <= n; i++)
   {
      [variable setRealValue:i];
      y = [function evaluate:index];
      if (y.f & rtScalar)
         prod *= (y.f == rtReal) ? y.r : y.i;
      else
         return __builtin_nanl("0");
   }

   return prod;
}

- (ResultType)evaluate:(unsigned)index
{
   ResultType r0, r1, r2;

   r0 = [multi[0] evaluate:index];
   if (r0.f == rtError || r0.f == rtReal && isnan(r0.r))
      return r0;
   else if (r0.f == rtInteger)
   {
      r0.f = rtReal;
      r0.r = r0.i;
   }
   else if ((r0.f & rtScalar) == 0)
   {
      [multi[0] setErrorInEvaluation:typeError :&r0 :0];
      return r0;
   }

   r1 = [multi[1] evaluate:index];
   if (r1.f == rtError || r1.f == rtReal && isnan(r1.r))
      return r1;
   else if (r1.f == rtInteger)
   {
      r1.f = rtReal;
      r1.r = r1.i;
   }
   else if ((r1.f & rtScalar) == 0)
   {
      [multi[1] setErrorInEvaluation:typeError :&r1 :0];
      return r1;
   }

   r2 = [multi[2] evaluate:index];
   if (r2.f == rtError || r2.f == rtReal && isnan(r2.r))
      return r2;
   else if ((r2.f & rtScalar) == 0)
   {
      [multi[2] setErrorInEvaluation:typeError :&r2 :0];
      return r2;
   }

   if ([multi[0] isMemberOfClass:[CalcFactor class]])
      r0.r = serialProduct(&r0.r, &r1.r, (CalcFactor *)multi[0], multi[2], index);
   else if ([multi[0] isMemberOfClass:[SetEqual class]] && [[(SetEqual *)multi[0] prevTerm] isMemberOfClass:[CalcFactor class]])
      r0.r = serialProduct(&r0.r, &r1.r, [(SetEqual *)multi[0] prevTerm], multi[2], index);
   else
   {
      [multi[0] setErrorInEvaluation:typeError :&r0 :0];
      return r0;
   }

   r0.f = rtReal;
   if (isnan(r0.r))
      [self setErrorInEvaluation:nanError :&r0 :0];

   return r0;
}

@end


@implementation Integration

#define jMax   20
#define supPts  5

static boolean polint(long double* xa, long double* ya, long double* y, long double* dy)
{
   boolean      exact = true;
   int          i, p;
   long double  w, hp, ho, den;
   long double  C[jMax], D[jMax];

   for (i = 0; i < supPts; i++)
   {
      C[i] = ya[i];
      D[i] = ya[i];
   }

   *y = ya[supPts-1];
   for (p = 1; p < supPts; p++)
   {
      for (i = 0; i < supPts - p; i++)
      {
         ho  = xa[i];
         hp  = xa[i+p];
         w   = C[i+1] - D[i];
         den = ho - hp;
         if (den == 0.0L)
         {
            exact = false;
            break;
         }
         den = w / den;
         D[i] = hp * den;
         C[i] = ho * den;
      }
      *dy = D[i-1];
      *y += *dy;
   }
   return exact;
}

static void midpnt(int* iter, long double* a, long double* b, long double* Q, long double* diff, CalcFactor* variable, CalcObject* function, unsigned index)
{
   int         i, n;
   long double x, dx, ddx, dy, ddy, sum;
   long double bma;
   ResultType  result;

   if (*iter == 0)
   {
      *iter = 1;
      *diff = 1.0L;
      [variable setRealValue:0.5L*(*a + *b)];
      result = [function evaluate:index];
      if (result.f & rtScalar)
         *Q = (*b - *a) * ((result.f == rtReal) ? result.r : result.i);
      else
         *Q = __builtin_nanl("0");
   }

   else
   {
      n   = *iter;
      bma = *b - *a;
      dx  = bma/(3*n);
      ddx = dx + dx;
      sum = 0.0L;
      *diff = 0.0L;
      x = 0.5L*dx + *a;
      for (i = 0; i < n; i++)
      {
         [variable setRealValue:x];
         result = [function evaluate:index];
         if (result.f & rtScalar)
            sum += dy = (result.f == rtReal) ? result.r : result.i;
         else
         {
            *Q = __builtin_nanl("0");
            return;
         }

         x += ddx;
         [variable setRealValue:x];
         result = [function evaluate:index];
         if (result.f & rtScalar)
            sum += ddy = (result.f == rtReal) ? result.r : result.i;
         else
         {
            *Q = __builtin_nanl("0");
            return;
         }
         *diff += fabsl(ddy - dy);
         x += dx;
      }
      *Q = (*Q + bma*sum/n)/3.0L;
      *diff = __LDBL_EPSILON__ + *diff/(ddx*n);
      *iter = 3*n;
   }
}

static long double integration(long double* a, long double* b, CalcFactor* variable, CalcObject* function, unsigned index)
{
   boolean      exact;
   int          j;
   int          iter;
   long double  dQ, diff, diff0, Q = 0.0L;
   long double  H[jMax], S[jMax];

   if (*a == *b)
      return 0;

   iter  = 0;
   H[0]  = 1.0L;
   diff0 = 1.0L;
   for (j = 0; j < jMax; j++)
   {
      midpnt(&iter, a, b, &S[j], &diff, variable, function, index);
      if (isnan(S[j]) || iter > 100000)
         return __builtin_nanl("0");

      dQ    = (diff > diff0) ? diff/diff0 : diff0/diff;
      diff0 = diff;
      if ((j >= supPts-1 && dQ < 1.25L) || (j == jMax-1))
      {
         exact = polint(&H[j-(supPts-1)], &S[j-(supPts-1)], &Q, &dQ);
         if (fabsl(dQ) <= AbsTol || fabsl(dQ) <= RelTol*fabsl(Q))
            return Q;

         else if (!exact || j == jMax-1)
            return __builtin_nanl("0");
      }
      S[j+1] = S[j];
      H[j+1] = H[j]/9.0L;
   }

   return Q;
}

#undef jMax
#undef supPts

- (ResultType)evaluate:(unsigned)index
{
   ResultType r0, r1, r2;

   r0 = [multi[0] evaluate:index];
   if (r0.f == rtError || r0.f == rtReal && isnan(r0.r))
      return r0;
   else if (r0.f == rtInteger)
   {
      r0.f = rtReal;
      r0.r = r0.i;
   }
   else if ((r0.f & rtScalar) == 0)
   {
      [multi[0] setErrorInEvaluation:typeError :&r0 :0];
      return r0;
   }

   r1 = [multi[1] evaluate:index];
   if (r1.f == rtError || r1.f == rtReal && isnan(r1.r))
      return r1;
   else if (r1.f == rtInteger)
   {
      r1.f = rtReal;
      r1.r = r1.i;
   }
   else if ((r1.f & rtScalar) == 0)
   {
      [multi[1] setErrorInEvaluation:typeError :&r1 :0];
      return r1;
   }

   r2 = [multi[2] evaluate:index];
   if (r2.f == rtError || r2.f == rtReal && isnan(r2.r))
      return r2;
   else if ((r2.f & rtScalar) == 0)
   {
      [multi[2] setErrorInEvaluation:typeError :&r2 :0];
      return r2;
   }

   if ([multi[0] isMemberOfClass:[CalcFactor class]])
      r0.r = integration(&r0.r, &r1.r, (CalcFactor *)multi[0], multi[2], index);
   else if ([multi[0] isMemberOfClass:[SetEqual class]] && [[(SetEqual *)multi[0] prevTerm] isMemberOfClass:[CalcFactor class]])
      r0.r = integration(&r0.r, &r1.r, [(SetEqual *)multi[0] prevTerm], multi[2], index);
   else
   {
      [multi[0] setErrorInEvaluation:typeError :&r0 :0];
      return r0;
   }

   r0.f = rtReal;
   if (isnan(r0.r))
      [self setErrorInEvaluation:nanError :&r0 :0];

   return r0;
}

@end


@implementation Differentiation

static long double differentiation(long double x, CalcFactor* variable, CalcObject* function, unsigned index)
{
   ResultType  y;
   long double d, d0, dd, dd0, ddmin, dL, dR, f;
   long double dbest = __builtin_nanl("0");
   long double eps   = (x != 0.0L) ? fabsl(x*0.5L) : 0.5L;
   long double eps0  = eps*RelTol;

   [variable setRealValue:x];
   y = [function evaluate:index];
   if (y.f & rtScalar)
      f = (y.f == rtReal) ? y.r : y.i;
   else
      return __builtin_nanl("0");

   d = dd = ddmin = __LDBL_MAX__;
   do
   {
      d0  = d;
      dd0 = dd;

      eps = eps*0.1L;
      [variable setRealValue:x - eps];
      y = [function evaluate:index];
      if (y.f & rtScalar)
         dL = f - ((y.f == rtReal) ? y.r : y.i);
      else
         dL = __builtin_nanl("0");

      [variable setRealValue:x + eps];
      y = [function evaluate:index];
      if (y.f & rtScalar)
         dR = ((y.f == rtReal) ? y.r : y.i) - f;
      else
         dR = __builtin_nanl("0");

      if (isfinite(dL) && isfinite(dR))
         d = (dR + dL)/(eps+eps);
      else if (isfinite(dL))
         d = dL/eps;
      else if (isfinite(dR))
         d = dR/eps;
      else
         return __builtin_nanl("0");

      if (isfinite(d))
      {
         dd = fabsl(d - d0);
         if (dd < ddmin)
         {
            ddmin = dd;
            dbest = d;
         }
      }
   } while (eps > AbsTol && dd > f*RelTol && (dd < dd0 || eps > eps0));

   // reset the variable to its original value
   [variable setRealValue:x];

   return dbest;
}

- (ResultType)evaluate:(unsigned)index
{
   ResultType r1, r2;

   r1 = [prevTerm evaluate:index];
   if (r1.f == rtError || r1.f == rtReal && isnan(r1.r))
      return r1;
   else if (r1.f == rtInteger)
   {
      r1.f = rtReal;
      r1.r = r1.i;
   }
   else if ((r1.f & rtScalar) == 0)
   {
      [prevTerm setErrorInEvaluation:typeError :&r1 :0];
      return r1;
   }

   r2 = [nextTerm evaluate:index];
   if (r2.f == rtError || r2.f == rtReal && isnan(r2.r))
      return r2;
   else if ((r2.f & rtScalar) == 0)
   {
      [nextTerm setErrorInEvaluation:typeError :&r2 :0];
      return r2;
   }

   if ([prevTerm isMemberOfClass:[CalcFactor class]])
      r1.r = differentiation(r1.r, (CalcFactor *)prevTerm, nextTerm, index);
   else if ([prevTerm isMemberOfClass:[SetEqual class]] && [[(SetEqual *)prevTerm prevTerm] isMemberOfClass:[CalcFactor class]])
      r1.r = differentiation(r1.r, [(SetEqual *)prevTerm prevTerm], nextTerm, index);
   else
   {
      [prevTerm setErrorInEvaluation:typeError :&r1 :0];
      return r1;
   }

   r1.f = rtReal;
   if (isnan(r1.r))
      [self setErrorInEvaluation:nanError :&r1 :0];

   return r1;
}

@end


@implementation Solver

static long double solver(long double x, CalcFactor* variable, CalcObject* equation, unsigned index)
{
   int         iterCount = 0;
   long double fx0, fx1, dx0, dx = __builtin_infl();
   ResultType  fx;

   do
   {
      iterCount++;

      dx0 = dx;
      dx = fabsl(x*RelTol);
      if (dx < AbsTol)
         dx = AbsTol;

      [variable setRealValue:x];
      fx = [equation evaluate:index]; if (!(fx.f & rtScalar)) return __builtin_nanl("0");
      fx0 = (fx.f == rtReal) ? fx.r : fx.i;

      [variable setRealValue:x + dx];
      fx = [equation evaluate:index]; if (!(fx.f & rtScalar)) return __builtin_nanl("0");
      fx1 = (fx.f == rtReal) ? fx.r : fx.i;

      dx *= fx0/(fx1 - fx0);
      x  -= dx;

      if (isinf(dx) || isnan(dx))
         return __builtin_nanl("0");

      dx = fabsl(dx);
   } while (fabsl(dx - dx0) > AbsTol && dx > RelTol && iterCount < 100);

   // set the variable and the dependent equation to the final solution
   [variable setRealValue:x];
   [equation evaluate:index];

   if (iterCount < 100)
      return x;
   else
      return __builtin_nanl("0");
}

- (ResultType)evaluate:(unsigned)index
{
   ResultType r1, r2;

   r1 = [prevTerm evaluate:index];
   if (r1.f == rtError || r1.f == rtReal && isnan(r1.r))
      return r1;
   else if (r1.f == rtInteger)
   {
      r1.f = rtReal;
      r1.r = r1.i;
   }
   else if ((r1.f & rtScalar) == 0)
   {
      [prevTerm setErrorInEvaluation:typeError :&r1 :0];
      return r1;
   }

   r2 = [nextTerm evaluate:index];
   if (r2.f == rtError || r2.f == rtReal && isnan(r2.r))
      return r2;
   else if ((r2.f & rtScalar) == 0)
   {
      [nextTerm setErrorInEvaluation:typeError :&r2 :0];
      return r2;
   }

   if ([prevTerm isMemberOfClass:[CalcFactor class]])
      r1.r = solver(r1.r, (CalcFactor *)prevTerm, nextTerm, index);
   else if ([prevTerm isMemberOfClass:[SetEqual class]] && [[(SetEqual *)prevTerm prevTerm] isMemberOfClass:[CalcFactor class]])
      r1.r = solver(r1.r, [(SetEqual *)prevTerm prevTerm], nextTerm, index);
   else
   {
      [prevTerm setErrorInEvaluation:typeError :&r1 :0];
      return r1;
   }

   r1.f = rtReal;
   if (isnan(r1.r))
      [self setErrorInEvaluation:nanError :&r1 :0];

   return r1;
}

@end


@implementation LinPol

- (ResultType)evaluate:(unsigned)index
{
   ResultType r0, r1, r2, r3, r4;

   r0 = [multi[0] evaluate:index];
   if (r0.f == rtError)
      return r0;
   else if (r0.f == rtInteger)
      r0.r = r0.i;
   else if ((r0.f & rtScalar) == 0)
   {
      [multi[0] setErrorInEvaluation:typeError :&r0 :0];
      return r0;
   }

   r1 = [multi[1] evaluate:index];
   if (r1.f == rtError)
      return r1;
   else if (r1.f == rtInteger)
      r1.r = r1.i;
   else if ((r1.f & rtScalar) == 0)
   {
      [multi[1] setErrorInEvaluation:typeError :&r1 :0];
      return r1;
   }

   r2 = [multi[2] evaluate:index];
   if (r2.f == rtError)
      return r2;
   else if (r2.f == rtInteger)
      r2.r = r2.i;
   else if ((r2.f & rtScalar) == 0)
   {
      [multi[2] setErrorInEvaluation:typeError :&r2 :0];
      return r2;
   }

   r3 = [multi[3] evaluate:index];
   if (r3.f == rtError)
      return r3;
   else if (r3.f == rtInteger)
      r3.r = r3.i;
   else if ((r3.f & rtScalar) == 0)
   {
      [multi[3] setErrorInEvaluation:typeError :&r3 :0];
      return r3;
   }

   r4 = [multi[4] evaluate:index];
   if (r4.f == rtError)
      return r4;
   else if (r4.f == rtInteger)
      r4.r = r4.i;
   else if ((r4.f & rtScalar) == 0)
   {
      [multi[4] setErrorInEvaluation:typeError :&r4 :0];
      return r4;
   }

   r0.r = (r4.r - r2.r)/(r3.r - r1.r)*(r0.r - r1.r) + r2.r;
   r0.f = rtReal;
   if (isnan(r0.r))
      [self setErrorInEvaluation:nanError :&r0 :0];

   return r0;
}

@end


@implementation Regression

static inline long double sum(unsigned n, long double *x)
{
   unsigned i;
   long double sum = 0;
   for (i = 0; i < n; i++)
      sum += x[i];
   return sum;
}

static inline long double sqx(unsigned n, long double *x)
{
   unsigned i;
   long double sum = 0;
   for (i = 0; i < n; i++)
      sum += x[i]*x[i];
   return sum;
}

static inline long double sxy(unsigned n, long double *x, long double *y)
{
   unsigned i;
   long double sum = 0;
   for (i = 0; i < n; i++)
      sum += x[i]*y[i];
   return sum;
}

static long double regression(unsigned n, long double *x, long double *y, long double *a, long double *b, long double *s, long double *sa, long double *sb)
{
   long double sumx = sum(n, x);
   long double sumy = sum(n, y);
   long double avex = sumx/n;
   long double avey = sumy/n;
   long double qx   = sqx(n, x) - sqrl(sumx)/n;
   long double qy   = sqx(n, y) - sqrl(sumy)/n;
   long double qxy  = sxy(n, x, y) - (sumx*sumy)/n;

   *b  = qxy/qx;
   *a  = avey - *b*avex;
   *s  = sqrtl((qy - sqrl(qxy)/qx)/(n-2.0L)); // standard deviation for y being estimated using y = a + b*x
   *sb = *s/qx;
   *sa = *s*sqrtl(1.0L/n + sqrl(avex)/qx);
   return qxy/sqrtl(qx*qy);
}

- (ResultType)evaluate:(unsigned)index
{
   unsigned   i, j;
   ResultType r;

   if (paramCount & 1)
   {
      [multi[paramCount-1] setErrorInEvaluation:paramError:&r :0];
      return r;
   }

   unsigned    n = paramCount/2;
   long double x[n], y[n];

   for (i = 0, j = 0; i < n; i++, j += 2)
   {
      r = [multi[j] evaluate:index];
      switch (r.f)
      {
         case rtError:
            return r;

         case rtInteger:
            r.r = r.i;
            break;

         case rtReal:
            if (isnan(r.r))
            {
               [multi[j] setErrorInEvaluation:nanError:&r :0];
               return r;
            }
            break;

         default:
            [multi[j] setErrorInEvaluation:typeError:&r :0];
            return r;
      }
      x[i] = r.r;

      r = [multi[j+1] evaluate:index];
      switch (r.f)
      {
         case rtError:
            return r;

         case rtInteger:
            r.r = r.i;
            break;

         case rtReal:
            if (isnan(r.r))
            {
               [multi[j+1] setErrorInEvaluation:nanError:&r :0];
               return r;
            }
            break;

         default:
            [multi[j+1] setErrorInEvaluation:typeError:&r :0];
            return r;
      }
      y[i] = r.r;
   }

   long double a, b, sy, sa, sb, cc = regression(n, x, y, &a, &b, &sy, &sa, &sb);
   [itsCalculator storeRealVariable:"a"  value:a];
   [itsCalculator storeRealVariable:"b"  value:b];
   [itsCalculator storeRealVariable:"sy" value:sy];
   [itsCalculator storeRealVariable:"sa" value:sa];
   [itsCalculator storeRealVariable:"sb" value:sb];
   return (ResultType){rtReal, 0, false, 0LL, cc, {0.0L, 0.0L}, NULL, NULL, {noError, 0, 0}};
}

@end


#pragma mark ••• Calculator •••

@implementation Calculator

static pthread_mutex_t init_mutex = PTHREAD_MUTEX_INITIALIZER;

static Node **gTemplateStore = NULL;
static Node **gVariableStore = NULL;

- (id)init
{
   if (self = [super init])
   {
      pthread_mutex_lock(&init_mutex);

      if (!gTemplateStore)
      {
         gTemplateStore = createTable(1024);
         [self initIntrinsics];
      }

      variableStoreHandle = &gVariableStore;
      if (!gVariableStore)
      {
         isMaster = YES;
         gVariableStore = createTable(1024);
      }

      pthread_mutex_unlock(&init_mutex);
   }

   return self;
}


- (void)copyVariableTree:(Node *)node
{
#ifndef __clang_analyzer__
   CalcObject *copy = [(CalcObject *)node->value.o copy];
   [self storeVariable:node->name :node->naml :&copy];

   if (node->L)
      [self copyVariableTree:node->L];

   if (node->R)
      [self copyVariableTree:node->R];
#endif
}


- (id)initWithVariables:(Node **)store
{
   if (self = [super init])
   {
      if (store)
      {
         pthread_mutex_lock(&init_mutex);

         variableStoreHandle = &variableStore;

         uint i, n = *(uint *)store;
         variableStore = createTable(n);
         for (i = 1; i <= n; i++)
            if (store[i])
               [self copyVariableTree:store[i]];

         pthread_mutex_unlock(&init_mutex);
      }
   }
   return self;
}


- (id)copyWithZone:(void *)zone
{
   return [[Calculator alloc] initWithVariables:*variableStoreHandle];
}


- (void)dealloc
{
   if (isMaster)
   {
      if (gVariableStore)
         releaseTable(gVariableStore);

      if (gTemplateStore)
         releaseTable(gTemplateStore);
   }

   else
      if (variableStoreHandle && *variableStoreHandle && variableStoreHandle != &gVariableStore)
         releaseTable(*variableStoreHandle);

   [super dealloc];
}


- (void)storeVariable:(const char *)identifier :(ssize_t)identlen :(CalcObject **)variable
{
#ifndef __clang_analyzer__
   if (!*variable)
      *variable = [[CalcFactor alloc] initWithToken:NULL:factor:param];
   Value value = {.o = *variable, -Opaque};
   storeName(*variableStoreHandle, identifier, (identlen) ?: strvlen(identifier), &value);
#endif
}

- (void)storeIntegerVariable:(const char *)identifier value:(llong)integer
{
#ifndef __clang_analyzer__
   ResultType rt = {rtInteger, 0, false, integer, 0.0L, {0.0L, 0.0L}, NULL, NULL, {noError, 0, 0}};
   Value value = {.o = [[CalcFactor alloc] initWithValue:&rt:factor:param], -Opaque};
   storeName(*variableStoreHandle, identifier, strvlen(identifier), &value);
#endif
}

- (void)storeRealVariable:(const char *)identifier value:(long double)real
{
#ifndef __clang_analyzer__
   ResultType rt = {rtReal, 0, false, 0LL, real, {0.0L, 0.0L}, NULL, NULL, {noError, 0, 0}};
   Value value = {.o = [[CalcFactor alloc] initWithValue:&rt:factor:param], -Opaque};
   storeName(*variableStoreHandle, identifier, strvlen(identifier), &value);
#endif
}

- (void)storeExternalVariable:(const char *)identifier reference:(void *)reference of:(ResultTypeFlags)type
{
#ifndef __clang_analyzer__
   CalcExternal *variable = [[CalcExternal alloc] initWithToken:NULL:factor:param];
   [variable setReference:reference of:type];
   Value value = {.o = variable, -Opaque};
   storeName(*variableStoreHandle, identifier, strvlen(identifier), &value);
#endif
}

- (void)storeSeriesVariable:(const char *)identifier reference:(void *)reference of:(ResultTypeFlags)type
{
#ifndef __clang_analyzer__
   CalcSeries *variable = [[CalcSeries alloc] initWithToken:NULL:factor:param];
   [variable setReference:reference of:type];
   Value value = {.o = variable, -Opaque};
   storeName(*variableStoreHandle, identifier, strvlen(identifier), &value);
#endif
}


- (void)storeTemplate:(const char *)identifier :(CalcObject *)template
{
#ifndef __clang_analyzer__
   Value value = {.o = template, -Opaque};
   storeName(gTemplateStore, identifier, strvlen(identifier), &value);
#endif
}

- (void)storeAtomMass:(const char *)elementSymbol value:(long double)atomicWeight name:(const char *)elementName
{
#ifndef __clang_analyzer__
   ResultType val = {rtReal, 0, false, 0LL, atomicWeight, {0.0L, 0.0L}, NULL, (char *)elementName, {noError, 0, 0}};
   [self storeTemplate:elementSymbol :[[CalcFactor alloc] initWithValue:&val:factor:param]];
#endif
}

- (void)initIntrinsics
{
#ifndef __clang_analyzer__
   ResultType val = gNullResult;
   [self storeTemplate:"abs"      :[[Absolute                  alloc] initWithToken:NULL:function:unary]   ];
   [self storeTemplate:"acos"     :[[ArcCosinus                alloc] initWithToken:NULL:function:unary]   ];
   [self storeTemplate:"acosh"    :[[AreaCosinusHyperbolicus   alloc] initWithToken:NULL:function:unary]   ];
   [self storeTemplate:"acot"     :[[ArcCotangens              alloc] initWithToken:NULL:function:unary]   ];
   [self storeTemplate:"acoth"    :[[AreaCotangensHyperbolicus alloc] initWithToken:NULL:function:unary]   ];
   [self storeTemplate:"annuity"  :[[Annuity                   alloc] initWithToken:NULL:function:binary]  ];
   [self storeTemplate:"arg"      :[[CArgument                 alloc] initWithToken:NULL:function:unary]   ];
   [self storeTemplate:"asin"     :[[ArcSinus                  alloc] initWithToken:NULL:function:unary]   ];
   [self storeTemplate:"asinh"    :[[AreaSinusHyperbolicus     alloc] initWithToken:NULL:function:unary]   ];
   [self storeTemplate:"atan"     :[[ArcTangens                alloc] initWithToken:NULL:function:unary]   ];
   [self storeTemplate:"atan2"    :[[ArcTangens2               alloc] initWithToken:NULL:function:binary]  ];
   [self storeTemplate:"atanh"    :[[AreaTangensHyperbolicus   alloc] initWithToken:NULL:function:unary]   ];
   [self storeTemplate:"ave"      :[[ArithmeticAverage         alloc] initWithToken:NULL:function:multiple]]; val.s = "Speed of Light in vacuum in m÷s"; val.r = 299792458.0L;
   [self storeTemplate:"c0"       :[[CalcFactor                alloc] initWithValue:&val:factor:param]     ]; val.s = NULL;
   [self storeTemplate:"cdl"      :[[Capacitance               alloc] initWithToken:NULL:function:quinary] ];
   [self storeTemplate:"ceil"     :[[Ceil                      alloc] initWithToken:NULL:function:unary]   ];
   [self storeTemplate:"comb"     :[[Combinations              alloc] initWithToken:NULL:function:binary]  ];
   [self storeTemplate:"compound" :[[Compound                  alloc] initWithToken:NULL:function:binary]  ];
   [self storeTemplate:"conj"     :[[CConjugate                alloc] initWithToken:NULL:function:unary]   ];
   [self storeTemplate:"cos"      :[[Cosinus                   alloc] initWithToken:NULL:function:unary]   ];
   [self storeTemplate:"cosh"     :[[CosinusHyperbolicus       alloc] initWithToken:NULL:function:unary]   ];
   [self storeTemplate:"cot"      :[[Cotangens                 alloc] initWithToken:NULL:function:unary]   ];
   [self storeTemplate:"coth"     :[[CotangensHyperbolicus     alloc] initWithToken:NULL:function:unary]   ];
   [self storeTemplate:"ctof"     :[[Celsius2Fahrenheit        alloc] initWithToken:NULL:function:unary]   ];
   [self storeTemplate:"cube"     :[[Cube                      alloc] initWithToken:NULL:function:unary]   ];
   [self storeTemplate:"det"      :[[Determinant               alloc] initWithToken:NULL:function:unary]   ];
   [self storeTemplate:"dgr"      :[[Radian2Degree             alloc] initWithToken:NULL:function:unary]   ];
   [self storeTemplate:"diag"     :[[MakeDiagonal              alloc] initWithToken:NULL:function:binary]  ]; val.s = "Euler´s Number"; val.r = 2.718281828459045235360287471352662L;
   [self storeTemplate:"e"        :[[CalcFactor                alloc] initWithValue:&val:factor:param]     ]; val.s = NULL;
   [self storeTemplate:"elem"     :[[Element                   alloc] initWithToken:NULL:function:multiple]];
   [self storeTemplate:"erf"      :[[ErrorFunction             alloc] initWithToken:NULL:function:unary]   ];
   [self storeTemplate:"exp"      :[[Exponential               alloc] initWithToken:NULL:function:unary]   ];
   [self storeTemplate:"exp10"    :[[Exponential10             alloc] initWithToken:NULL:function:unary]   ];
   [self storeTemplate:"exp2"     :[[Exponential2              alloc] initWithToken:NULL:function:unary]   ];
   [self storeTemplate:"expm1"    :[[ExpMinus1                 alloc] initWithToken:NULL:function:unary]   ];
   [self storeTemplate:"fact"     :[[Factorial                 alloc] initWithToken:NULL:function:unary]   ];
   [self storeTemplate:"factln"   :[[FactorialLn               alloc] initWithToken:NULL:function:unary]   ]; val.f = rtBoolean; val.b = false;
   [self storeTemplate:"false"    :[[CalcFactor                alloc] initWithValue:&val:factor:param]     ];
   [self storeTemplate:"floor"    :[[Floor                     alloc] initWithToken:NULL:function:unary]   ];
   [self storeTemplate:"ftoc"     :[[Fahrenheit2Celsius        alloc] initWithToken:NULL:function:unary]   ];
   [self storeTemplate:"gamma"    :[[Gamma                     alloc] initWithToken:NULL:function:unary]   ];
   [self storeTemplate:"gammaln"  :[[GammaLn                   alloc] initWithToken:NULL:function:unary]   ];
   [self storeTemplate:"gauss"    :[[Gauss                     alloc] initWithToken:NULL:function:ternary] ];
   [self storeTemplate:"gaussln"  :[[GaussLn                   alloc] initWithToken:NULL:function:ternary] ];
   [self storeTemplate:"gave"     :[[GeometricAverage          alloc] initWithToken:NULL:function:multiple]];
   [self storeTemplate:"gcd"      :[[GCD                       alloc] initWithToken:NULL:function:multiple]]; val.s = "Golden Ratio"; val.f = rtReal; val.r = 1.618033988749894848204586834365638L;
   [self storeTemplate:"gold"     :[[CalcFactor                alloc] initWithValue:&val:factor:param]     ]; val.s = NULL;
   [self storeTemplate:"have"     :[[HarmonicAverage           alloc] initWithToken:NULL:function:multiple]];
   [self storeTemplate:"if"       :[[IF                        alloc] initWithToken:NULL:function:ternary] ];
   [self storeTemplate:"imag"     :[[CImag                     alloc] initWithToken:NULL:function:unary]   ]; val.s = "Infinity"; val.r = __builtin_infl();
   [self storeTemplate:"inf"      :[[CalcFactor                alloc] initWithValue:&val:factor:param]     ]; val.s = NULL;
   [self storeTemplate:"inv"      :[[MatrixInversion           alloc] initWithToken:NULL:function:unary]   ];
   [self storeTemplate:"lb"       :[[Logarithm2                alloc] initWithToken:NULL:function:unary]   ];
   [self storeTemplate:"lcm"      :[[LCM                       alloc] initWithToken:NULL:function:multiple]];
   [self storeTemplate:"lg"       :[[Logarithm10               alloc] initWithToken:NULL:function:unary]   ];
   [self storeTemplate:"linpol"   :[[LinPol                    alloc] initWithToken:NULL:function:quinary] ];
   [self storeTemplate:"linreg"   :[[Regression                alloc] initWithToken:NULL:function:multiple]];
   [self storeTemplate:"ln"       :[[Logarithm                 alloc] initWithToken:NULL:function:unary]   ]; val.r = 2.3025850929940459010936137929093L;
   [self storeTemplate:"ln10"     :[[CalcFactor                alloc] initWithValue:&val:factor:param]     ];
   [self storeTemplate:"ln1p"     :[[Log1Plus                  alloc] initWithToken:NULL:function:unary]   ];
   [self storeTemplate:"mat"      :[[MakeMatrix                alloc] initWithToken:NULL:function:ternary] ]; val.f = rtInteger; val.i = 0x7FFFFFFF; val.r = 0.0L;
   [self storeTemplate:"maxint"   :[[CalcFactor                alloc] initWithValue:&val:factor:param]     ];                    val.i = 0x7FFFFFFFFFFFFFFFLL;
   [self storeTemplate:"maxlong"  :[[CalcFactor                alloc] initWithValue:&val:factor:param]     ]; val.f = rtReal;    val.i = 0;          val.r = __LDBL_MAX__;
   [self storeTemplate:"maxreal"  :[[CalcFactor                alloc] initWithValue:&val:factor:param]     ]; val.f = rtInteger; val.i = 0x7FFF;     val.r = 0.0L;
   [self storeTemplate:"maxshort" :[[CalcFactor                alloc] initWithValue:&val:factor:param]     ]; val.f = rtReal;    val.i = 0;          val.r = __LDBL_DENORM_MIN__;
   [self storeTemplate:"minreal"  :[[CalcFactor                alloc] initWithValue:&val:factor:param]     ];                                        val.r = __builtin_nanl("0");
   [self storeTemplate:"nan"      :[[CalcFactor                alloc] initWithValue:&val:factor:param]     ]; val.f = rtNone;                        val.r = __builtin_nanl("255");
   [self storeTemplate:"none"     :[[CalcFactor                alloc] initWithValue:&val:factor:param]     ];
   [self storeTemplate:"norm"     :[[Norm                      alloc] initWithToken:NULL:function:unary]   ];
   [self storeTemplate:"p"        :[[IndexOfPoint              alloc] initWithToken:NULL:factor:param]     ];
   [self storeTemplate:"perm"     :[[Factorial                 alloc] initWithToken:NULL:function:unary]   ]; val.f = rtReal; val.r = 3.1415926535897932384626433832795029L;
   [self storeTemplate:"pi"       :[[CalcFactor                alloc] initWithValue:&val:factor:param]     ]; val.r = __LDBL_EPSILON__;
   [self storeTemplate:"prec"     :[[CalcFactor                alloc] initWithValue:&val:factor:param]     ];
   [self storeTemplate:"prob"     :[[ProbabilityFunction       alloc] initWithToken:NULL:function:unary]   ];
   [self storeTemplate:"prod"     :[[ExplicitProduct           alloc] initWithToken:NULL:function:multiple]];
   [self storeTemplate:"pyth2d"   :[[Pythagoras2D              alloc] initWithToken:NULL:function:binary]  ];
   [self storeTemplate:"pyth3d"   :[[Pythagoras3D              alloc] initWithToken:NULL:function:ternary] ];
   [self storeTemplate:"rad"      :[[Degree2Radian             alloc] initWithToken:NULL:function:unary]   ];
   [self storeTemplate:"rand"     :[[RandomNumber              alloc] initWithToken:NULL:factor:param]     ];
   [self storeTemplate:"real"     :[[CReal                     alloc] initWithToken:NULL:function:unary]   ];
   [self storeTemplate:"root"     :[[Root                      alloc] initWithToken:NULL:function:binary]  ];
   [self storeTemplate:"round"    :[[Round                     alloc] initWithToken:NULL:function:unary]   ];
   [self storeTemplate:"rp"       :[[Resistance                alloc] initWithToken:NULL:function:quinary] ];
   [self storeTemplate:"scalb"    :[[Scalb                     alloc] initWithToken:NULL:function:binary]  ];
   [self storeTemplate:"sign"     :[[Signum                    alloc] initWithToken:NULL:function:unary]   ];
   [self storeTemplate:"simpl"    :[[Simplify                  alloc] initWithToken:NULL:function:multiple]];
   [self storeTemplate:"sin"      :[[Sinus                     alloc] initWithToken:NULL:function:unary]   ];
   [self storeTemplate:"sinh"     :[[SinusHyperbolicus         alloc] initWithToken:NULL:function:unary]   ];
   [self storeTemplate:"solve"    :[[Solver                    alloc] initWithToken:NULL:function:binary]  ];
   [self storeTemplate:"sqr"      :[[Square                    alloc] initWithToken:NULL:function:unary]   ];
   [self storeTemplate:"sqrt"     :[[SquareRoot                alloc] initWithToken:NULL:function:unary]   ];
   [self storeTemplate:"stdev"    :[[StandardDeviation         alloc] initWithToken:NULL:function:multiple]];
   [self storeTemplate:"sum"      :[[ExplicitSum               alloc] initWithToken:NULL:function:multiple]];
   [self storeTemplate:"svd"      :[[SingularValueDecomp       alloc] initWithToken:NULL:function:unary]   ];
   [self storeTemplate:"tan"      :[[Tangens                   alloc] initWithToken:NULL:function:unary]   ];
   [self storeTemplate:"tanh"     :[[TangensHyperbolicus       alloc] initWithToken:NULL:function:unary]   ];
   [self storeTemplate:"trans"    :[[MatrixTransposition       alloc] initWithToken:NULL:function:unary]   ]; val.f = rtBoolean; val.b = true;
   [self storeTemplate:"true"     :[[CalcFactor                alloc] initWithValue:&val:factor:param]     ];
   [self storeTemplate:"trunc"    :[[Truncation                alloc] initWithToken:NULL:function:unary]   ];
   [self storeTemplate:"var"      :[[Variations                alloc] initWithToken:NULL:function:binary]  ];
   [self storeTemplate:"vec"      :[[MakeVector                alloc] initWithToken:NULL:function:binary]  ]; val.f = rtReal;    val.b = false;      val.r = 3.1415926535897932384626433832795029L;
   [self storeTemplate:"π"        :[[CalcFactor                alloc] initWithValue:&val:factor:param]     ];
   [self storeTemplate:"∆"        :[[Differentiation           alloc] initWithToken:NULL:function:binary]  ];
   [self storeTemplate:"∏"        :[[SerialProduct             alloc] initWithToken:NULL:function:ternary] ];
   [self storeTemplate:"∑"        :[[Summation                 alloc] initWithToken:NULL:function:ternary] ]; val.s = "Infinity"; val.r = __builtin_infl();
   [self storeTemplate:"∞"        :[[CalcFactor                alloc] initWithValue:&val:factor:param]     ]; val.s = NULL;
   [self storeTemplate:"∫"        :[[Integration               alloc] initWithToken:NULL:function:ternary] ];

   [self storeAtomMass:"H"   value:1.008L       name:"Hydrogen [1.00784; 1.00811]"];
   [self storeAtomMass:"He"  value:4.002602L    name:"Helium"];
   [self storeAtomMass:"Li"  value:6.94L        name:"Lithium [6.938; 6.997]"];
   [self storeAtomMass:"Be"  value:9.012182L    name:"Beryllium"];
   [self storeAtomMass:"B"   value:10.81L       name:"Boron [10.806; 10.821]"];
   [self storeAtomMass:"C"   value:12.011L      name:"Carbon [12.0096; 12.0116]"];
   [self storeAtomMass:"N"   value:14.007L      name:"Nitrogen [14.00643; 14.00728]"];
   [self storeAtomMass:"O"   value:15.999L      name:"Oxygen [15.99903; 15.99977]"];
   [self storeAtomMass:"F"   value:18.9984032L  name:"Fluorine"];
   [self storeAtomMass:"Ne"  value:20.1797L     name:"Neon"];
   [self storeAtomMass:"Na"  value:22.98976928L name:"Sodium"];
   [self storeAtomMass:"Mg"  value:24.3050L     name:"Magnesium"];
   [self storeAtomMass:"Al"  value:26.9815386L  name:"Aluminium"];
   [self storeAtomMass:"Si"  value:28.085L      name:"Silicon [28.084; 28.086]"];
   [self storeAtomMass:"P"   value:30.973762L   name:"Phosphorous"];
   [self storeAtomMass:"S"   value:32.06L       name:"Sulfur [32.059; 32.076]"];
   [self storeAtomMass:"Cl"  value:35.45L       name:"Chlorine [35.446; 35.457]"];
   [self storeAtomMass:"Ar"  value:39.948L      name:"Argon"];
   [self storeAtomMass:"K"   value:39.0983L     name:"Potassium"];
   [self storeAtomMass:"Ca"  value:40.078L      name:"Calcium"];
   [self storeAtomMass:"Sc"  value:44.955912L   name:"Scandium"];
   [self storeAtomMass:"Ti"  value:47.867L      name:"Titanium"];
   [self storeAtomMass:"V"   value:50.9415L     name:"Vanadium"];
   [self storeAtomMass:"Cr"  value:51.9961L     name:"Chromium"];
   [self storeAtomMass:"Mn"  value:54.938045L   name:"Manganese"];
   [self storeAtomMass:"Fe"  value:55.845L      name:"Iron"];
   [self storeAtomMass:"Co"  value:58.933195L   name:"Cobalt"];
   [self storeAtomMass:"Ni"  value:58.6934L     name:"Nickel"];
   [self storeAtomMass:"Cu"  value:63.546L      name:"Copper"];
   [self storeAtomMass:"Zn"  value:65.38L       name:"Zinc"];
   [self storeAtomMass:"Ga"  value:69.723L      name:"Gallium"];
   [self storeAtomMass:"Ge"  value:72.63L       name:"Germanium"];
   [self storeAtomMass:"As"  value:74.92160L    name:"Arsenic"];
   [self storeAtomMass:"Se"  value:78.96L       name:"Selenium"];
   [self storeAtomMass:"Br"  value:79.904L      name:"Bromine"];
   [self storeAtomMass:"Kr"  value:83.798L      name:"Krypton"];
   [self storeAtomMass:"Rb"  value:85.4678L     name:"Rubidium"];
   [self storeAtomMass:"Sr"  value:87.62L       name:"Strontium"];
   [self storeAtomMass:"Y"   value:88.90585L    name:"Yttrium"];
   [self storeAtomMass:"Zr"  value:91.224L      name:"Zirconium"];
   [self storeAtomMass:"Nb"  value:92.90638L    name:"Niobium"];
   [self storeAtomMass:"Mo"  value:95.96L       name:"Molybdenum"];
   [self storeAtomMass:"Tc"  value:97.9072L     name:"Technetium"];
   [self storeAtomMass:"Ru"  value:101.07L      name:"Ruthenium"];
   [self storeAtomMass:"Rh"  value:102.90550L   name:"Rhodium"];
   [self storeAtomMass:"Pd"  value:106.42L      name:"Palladium"];
   [self storeAtomMass:"Ag"  value:107.8682L    name:"Silver"];
   [self storeAtomMass:"Cd"  value:112.411L     name:"Cadmium"];
   [self storeAtomMass:"In"  value:114.818L     name:"Indium"];
   [self storeAtomMass:"Sn"  value:118.710L     name:"Tin"];
   [self storeAtomMass:"Sb"  value:121.760L     name:"Antimony"];
   [self storeAtomMass:"Te"  value:127.60L      name:"Tellurium"];
   [self storeAtomMass:"I"   value:126.90447L   name:"Iodine"];
   [self storeAtomMass:"Xe"  value:131.293L     name:"Xenon"];
   [self storeAtomMass:"Cs"  value:132.9054519L name:"Caesium"];
   [self storeAtomMass:"Ba"  value:137.327L     name:"Barium"];
   [self storeAtomMass:"La"  value:138.90547L   name:"Lanthanum"];
   [self storeAtomMass:"Ce"  value:140.116L     name:"Cerium"];
   [self storeAtomMass:"Pr"  value:140.90765L   name:"Praseodymium"];
   [self storeAtomMass:"Nd"  value:144.242L     name:"Neodymium"];
   [self storeAtomMass:"Pm"  value:144.9127L    name:"Promethium"];
   [self storeAtomMass:"Sm"  value:150.36L      name:"Samarium"];
   [self storeAtomMass:"Eu"  value:151.964L     name:"Europium"];
   [self storeAtomMass:"Gd"  value:157.25L      name:"Gadolinium"];
   [self storeAtomMass:"Tb"  value:158.92535L   name:"Terbium"];
   [self storeAtomMass:"Dy"  value:162.500L     name:"Dysprosium"];
   [self storeAtomMass:"Ho"  value:164.93032L   name:"Holmium"];
   [self storeAtomMass:"Er"  value:167.259L     name:"Erbium"];
   [self storeAtomMass:"Tm"  value:168.93421L   name:"Thulium"];
   [self storeAtomMass:"Yb"  value:173.054L     name:"Ytterbium"];
   [self storeAtomMass:"Lu"  value:174.9668L    name:"Lutetium"];
   [self storeAtomMass:"Hf"  value:178.49L      name:"Hafnium"];
   [self storeAtomMass:"Ta"  value:180.94788L   name:"Tantalum"];
   [self storeAtomMass:"W"   value:183.84L      name:"Tungsten"];
   [self storeAtomMass:"Re"  value:186.207L     name:"Rhenium"];
   [self storeAtomMass:"Os"  value:190.23L      name:"Osmium"];
   [self storeAtomMass:"Ir"  value:192.217L     name:"Iridium"];
   [self storeAtomMass:"Pt"  value:195.084L     name:"Platinum"];
   [self storeAtomMass:"Au"  value:196.966569L  name:"Gold"];
   [self storeAtomMass:"Hg"  value:200.59L      name:"Mercury"];
   [self storeAtomMass:"Tl"  value:204.38L      name:"Thallium [204.382; 204.385]"];
   [self storeAtomMass:"Pb"  value:207.2L       name:"Lead"];
   [self storeAtomMass:"Bi"  value:208.98040L   name:"Bismuth"];
   [self storeAtomMass:"Po"  value:208.9824L    name:"Polonium"];
   [self storeAtomMass:"At"  value:209.9871L    name:"Astatine"];
   [self storeAtomMass:"Rn"  value:222.0176L    name:"Radon"];
   [self storeAtomMass:"Fr"  value:223.0197L    name:"Francium"];
   [self storeAtomMass:"Ra"  value:226.0254L    name:"Radium"];
   [self storeAtomMass:"Ac"  value:227.0278L    name:"Actinium"];
   [self storeAtomMass:"Th"  value:232.03806L   name:"Thorium"];
   [self storeAtomMass:"Pa"  value:231.03588L   name:"Protactinium"];
   [self storeAtomMass:"U"   value:238.02891L   name:"Uranium"];
   [self storeAtomMass:"Np"  value:237.0482L    name:"Neptunium"];
   [self storeAtomMass:"Pu"  value:244.0642L    name:"Plutonium"];
   [self storeAtomMass:"Am"  value:243.0614L    name:"Americium"];
   [self storeAtomMass:"Cm"  value:247.0704L    name:"Curium"];
   [self storeAtomMass:"Bk"  value:247.0703L    name:"Berkelium"];
   [self storeAtomMass:"Cf"  value:251.0796L    name:"Californium"];
   [self storeAtomMass:"Es"  value:252.0830L    name:"Einsteinium"];
   [self storeAtomMass:"Fm"  value:257.0951L    name:"Fermium"];
   [self storeAtomMass:"Md"  value:258.0984L    name:"Mendelevium*"];
   [self storeAtomMass:"No"  value:259.1010L    name:"Nobelium"];
   [self storeAtomMass:"Lr"  value:262.1096L    name:"Lawrencium"];
   [self storeAtomMass:"Rf"  value:265.11167L   name:"Rutherfordium"];
   [self storeAtomMass:"Db"  value:268.125L     name:"Dubnium"];
   [self storeAtomMass:"Sg"  value:271.133L     name:"Seaborgium"];
   [self storeAtomMass:"Bh"  value:267.1277L    name:"Bohrium"];
   [self storeAtomMass:"Hs"  value:277.150L     name:"Hassium"];
   [self storeAtomMass:"Mt"  value:276.151L     name:"Meitnerium"];
   [self storeAtomMass:"Ds"  value:281.162L     name:"Darmstadtium"];
   [self storeAtomMass:"Rg"  value:280.164L     name:"Roentgenium"];
   [self storeAtomMass:"Cn"  value:285.174L     name:"Copernicium"];
   [self storeAtomMass:"Uut" value:284.178L     name:"Ununtrium"];
   [self storeAtomMass:"Fl"  value:289.187L     name:"Flerovium"];
   [self storeAtomMass:"Uup" value:288.192L     name:"Ununpentium"];
   [self storeAtomMass:"Lv"  value:292.200L     name:"Livermorium"];
   [self storeAtomMass:"Uus" value:293.2L       name:"Ununseptium"];
   [self storeAtomMass:"Uuo" value:294.2L       name:"Ununoctium"];
#endif
}


static llong binStr2Num(char *s)
{
   boolean pos = true;
   int     i, n;
   llong   num;

   if (s[0] == '-')
      pos = false, s++;

   n = strvlen(s) - 1;
   for (num = 0LL, i = 0; i <= n; i++)
      if (s[i] == '1')
         num |= 1LL << (n - i);

   return (pos) ? num : -num;
}

static inline void replaceSeparator(utf8 oldSep, utf8 newSep, char *old, char *new, unsigned n)
{
   utf8 c;

   for (unsigned i = 0; i < n && *old; i++)
      if ((c = getu(&old)) == oldSep)
         new += putu(newSep, new);
      else
         new += putu(c, new);

   *new = '\0';
}

- (boolean)lookUp:(utf8)separator :(TokenPtr)curToken :(CalcObject **)curObjectPtr :(ErrorRecord *)calcError
{
   llong       sign = 1LL;
   char       *t, v[256];
   CalcObject *curObject = nil;
   Node       *node;

   ResultType  value = {rtInteger, 0, false, 0LL, 0.0L, {0.0L, 0.0L}, NULL, NULL, {noError, 0, 0}};

   if (curToken->tCheck & NumState)
   {
      curObject = [[CalcFactor alloc] initWithToken:curToken:factor:param];

      t = curToken->tLiteral;
      if ((curToken->tCheck & (hexNum|binNum)) && t[0] == '-')
      {
         t++;
         sign = -1LL;
      }

      if (hexNum & curToken->tCheck)
         value.i = sign*strtoll(t, NULL, 16);

      else if (binNum & curToken->tCheck)
         value.i = sign*binStr2Num(t);

      else if (numPoint & curToken->tCheck || numExponent & curToken->tCheck)
      {
         replaceSeparator(gDecSep, '.', curToken->tLiteral, v, 256);
         value.r = strtold(v, NULL);
         value.f = rtReal;
      }

      else
         value.i = strtoll(curToken->tLiteral, NULL, 10);

      if (curToken->tCheck & numPercent)
      {
         if (value.f == rtInteger)
         {
            value.r = value.i/100.0L;
            value.i = 0LL;
         }
         else
            value.r /= 100.0L;
         value.f = rtReal;
         [curObject setPercent:YES];
      }

      [(CalcFactor *)curObject setValue:&value];
   }

   else
   {
      if (curToken->tCheck & other && separator != '(')
      {
         if ((curToken->tCheck & assignment) == assignment)
            [self storeVariable:curToken->tLiteral :curToken->tCount :&curObject];
         else if (node = findName(*variableStoreHandle, curToken->tLiteral, curToken->tCount))
            curObject = node->value.o;
         else
            curObject = nil;

         if (curObject)
            [curObject retain];
      }

      if (curObject == nil)
         if (node = findName(gTemplateStore, curToken->tLiteral, curToken->tCount))
         {
            curObject = [(CalcObject *)node->value.o copy];
            [curObject setCalculator:self];
         }

      if (curObject == nil)
      {
         calcError->flag  = semanticError;
         calcError->begin = curToken->tBegin;
         calcError->count = curToken->tCount;
         return false;
      }

      else
         [curObject setToken:curToken];
   }

   if ([curObject itsPrecedence] == factor || [curObject itsPrecedence] == function)
      curToken->tCheck = numVarFunc;

   *curObjectPtr = curObject;
   return true;
}


- (boolean)newToken:(utf8)curChar :(unsigned)pos :(SyntaxFlags *)syntaxCheck :(TokenPtr *)curTokenPtr :(CalcObject **)curObjectPtr :(ErrorRecord *)calcError
{
   boolean     result    = true;
   TokenPtr    curToken  = *curTokenPtr;
   CalcObject *curObject = *curObjectPtr;

   if ((*syntaxCheck & blank) == 0)
   {
      if (*syntaxCheck == (unaryOp|other))
      {
         curToken->tBegin = pos;
         curToken->tCount = 0;
      }

      else
      {
         curToken->tCheck = *syntaxCheck;
         if (curObject == nil && (*syntaxCheck & (openParent|openVector|closeBrackets)) == 0)
         {
            result = [self lookUp:curChar:curToken:&curObject:calcError];
            *syntaxCheck = curToken->tCheck;
         }         

         curToken->tObject = curObject;
         curToken->tNext   = allocate(sizeof(TokenRecord), default_align, true);
         curToken->tNext->tBegin = pos;

         *curTokenPtr  = curToken->tNext;
         *curObjectPtr = nil;
      }
   }

   return result;
}


- (void)disposeTokens:(TokenPtr)token
{
   TokenPtr next;

   while (token != NULL)
   {
      next = token->tNext;
      if (token->tObject != nil)
         [token->tObject release];
      deallocate(VPR(token), false);
      token = next;
   }
}


- (TokenPtr)scan:(char *)s error:(ErrorRecord *)calcError
{
   char       *p = s,
              *q = s + strvlen(s);
   utf8        c;
   char        d;
   unsigned    j, k;
   int         digitCount   = 0;
   int         parentCount  = 0;
   int         complexCount = 0;
   int         vectorCount  = 0;
   SyntaxFlags syntaxCheck  = openParent;
   TokenPtr    rootToken    = allocate(sizeof(TokenRecord), default_align, true);
   TokenPtr    curToken     = rootToken;
   CalcObject *curObject    = nil;

   curToken->tBegin = j = 0;
   while (c = getu(&p))
   {
      if (c <= ' ' && c != '\n' && c != '\r')
      {
         for (j++; '\0' < *p && *p <= ' ' && *p != '\n' && *p != '\r'; p++, j++);

         digitCount = 0;
         if (cmp2(p, ":="))
            if ((syntaxCheck | Assignment) == Assignment)
               syntaxCheck |= assignment;
            else
               goto SyntaxError;

         if (![self newToken:c:j:&syntaxCheck:&curToken:&curObject:calcError])
            goto SemanticError;

         syntaxCheck |= blank;
         continue;
      }

      else if (c == gDecSep)
      {
         if ((syntaxCheck | DecSeparator) == DecSeparator)
         {
            if (aPlus & syntaxCheck || aMinus & syntaxCheck)
               syntaxCheck |= numPlusMinus;

            else if (digitCount == 0)
               if (![self newToken:c:j:&syntaxCheck:&curToken:&curObject:calcError])
                  goto SemanticError;

            syntaxCheck &= NumState;
            syntaxCheck |= aPoint;
         }
         else
            goto SyntaxError;
      }

      else switch (c)
      {
         case '\r':
            if (*p == '\n')
            {
               p++, j++;
               continue;
            }
         case '\n':
            for (k = 0; '\0' < p[k] && p[k] <= ' '; k++);
            if (syntaxCheck == openParent || syntaxCheck == openVector || syntaxCheck == listSep || syntaxCheck == binaryOp || p[k] == ')' || p[k] == ']' || p[k] == '}')
            {
               j++;
               continue;
            }
            else if (parentCount > 0 || complexCount > 0 || vectorCount > 0)
            {
               c = ';';
               goto separator;
            }

         case '+':
         case 0xC2A0:   // ' ' non breaking space
            if ((syntaxCheck | PlusCheck) == PlusCheck)
            {
               if (aMinus & syntaxCheck)
               {
                  digitCount = 0;
                  curObject = [[Minus alloc] initWithToken:curToken:monadic:unary];
                  syntaxCheck = unaryOp;
                  if (![self newToken:c:j:&syntaxCheck:&curToken:&curObject:calcError])
                     goto SemanticError;

                  syntaxCheck = aPlus;
                }

                else if (anE & syntaxCheck)
                {
                  syntaxCheck &= ~anE;
                  syntaxCheck |= numExponent | numPlusMinus;
                  digitCount = 0;
                }

                else if ((syntaxCheck | BinOperator) == BinOperator)
                {
                  digitCount = 0;
                  if (![self newToken:c:j:&syntaxCheck:&curToken:&curObject:calcError])
                     goto SemanticError;

                  syntaxCheck = binaryOp;
                  curObject = [[Addition alloc] initWithToken:curToken:addsub:binary];
                }

                else if ((syntaxCheck | UnOperator) == UnOperator)
                {
                  digitCount = 0;
                  if (![self newToken:c:j:&syntaxCheck:&curToken:&curObject:calcError])
                     goto SemanticError;

                  syntaxCheck = aPlus;
                }
            }
            else
               goto SyntaxError;
            break;

         case '-':
            if ((syntaxCheck | MinusCheck) == MinusCheck)
            {
               if (aPlus & syntaxCheck)
               {
                  digitCount = 0;
                  curObject = [[Plus alloc] initWithToken:curToken:monadic:unary];
                  syntaxCheck = unaryOp;
                  if (![self newToken:c:j:&syntaxCheck:&curToken:&curObject:calcError])
                     goto SemanticError;

                  syntaxCheck = aMinus;
               }

               else if (anE & syntaxCheck)
               {
                  syntaxCheck &= ~anE;
                  syntaxCheck |= numExponent | numPlusMinus;
                  digitCount = 0;
               }

               else if ((syntaxCheck | BinOperator) == BinOperator)
               {
                  digitCount = 0;
                  if (![self newToken:c:j:&syntaxCheck:&curToken:&curObject:calcError])
                     goto SemanticError;

                  syntaxCheck = binaryOp;
                  curObject = [[Subtraction alloc] initWithToken:curToken:addsub:binary];
               }

               else if ((syntaxCheck | UnOperator) == UnOperator)
               {
                  digitCount = 0;
                  if (![self newToken:c:j:&syntaxCheck:&curToken:&curObject:calcError])
                     goto SemanticError;

                  syntaxCheck = aMinus;
               }
            }
            else
               goto SyntaxError;
            break;

         separator:
         case ';':
         case '*':
         case 0xC2B7:      // '·' Middle Dot
         case '/':
         case '^':
         case '@':
         case 0xC397:      // '×' Multiplication Sign
         case 0xE280A2:    // '•' Bullet
         case '\\':
            if ((syntaxCheck | BinOperator) == BinOperator)
            {
               digitCount = 0;
               if (![self newToken:c:j:&syntaxCheck:&curToken:&curObject:calcError])
                  goto SemanticError;

               switch (c)
               {
                  case ';':
                     syntaxCheck = listSep;
                     curObject = [[Separation alloc] initWithToken:curToken:separate:binary];
                     break;

                  case '*':
                  case 0xC2B7:   // '·' Middle Dot
                     syntaxCheck = binaryOp;
                     curObject = [[Multiplication alloc] initWithToken:curToken:muldiv:binary];
                     break;

                  case '/':
                     syntaxCheck = binaryOp;
                     curObject = [[Division alloc] initWithToken:curToken:muldiv:binary];
                     break;

                  case '^':
                     syntaxCheck = binaryOp;
                     curObject = [[Power alloc] initWithToken:curToken:exproot:binary];
                     break;

                  case '@':
                     syntaxCheck = binaryOp;
                     curObject = [[Pythagoras2D alloc] initWithToken:curToken:special:binary];
                     break;

                  case 0xC397:   // '×' Multiplication Sign
                     syntaxCheck = binaryOp;
                     curObject = [[VectorCrossProduct alloc] initWithToken:curToken:special:binary];
                     break;

                  case 0xE280A2: // '•' Bullet
                     syntaxCheck = binaryOp;
                     curObject = [[MatrixMultiplication alloc] initWithToken:curToken:special:binary];
                     break;

                  case '\\':
                     syntaxCheck = binaryOp;
                     curObject = [[MatrixDivision alloc] initWithToken:curToken:special:binary];
                     break;
               }
            }
            else
               goto SyntaxError;
            break;

         case 0xE2889A:    // '√' Root symbol
            if ((syntaxCheck | BinOperator) == BinOperator)
            {
               digitCount = 0;
               if (![self newToken:c:j:&syntaxCheck:&curToken:&curObject:calcError])
                  goto SemanticError;

               syntaxCheck = binaryOp;
               curObject = [[Root alloc] initWithToken:curToken:exproot:binary];
            }

            else if ((syntaxCheck | UnOperator) == UnOperator && p < q)
            {
               if (aPlus & syntaxCheck)
                  curObject = [[Plus alloc] initWithToken:curToken:monadic:unary];

               else if (aMinus & syntaxCheck)
                  curObject = [[Minus alloc] initWithToken:curToken:monadic:unary];

               digitCount = 0;
               if (![self newToken:c:j:&syntaxCheck:&curToken:&curObject:calcError])
                  goto SemanticError;

               syntaxCheck = unaryOp;
               curObject = [[SquareRoot alloc] initWithToken:curToken:monadic:unary];
            }
            else
               goto SyntaxError;
            break;

         case '~':
         case 0xC2B0:      // '°' Degree Sign
         case 0xC2AE:      // '®' Registered Sign
         case 0xC3A7:      // 'ç' c w/ cedilla
         case 0xC2B6:      // '¶' Pilcrow Sign
            if ((syntaxCheck | UnOperator) == UnOperator && p < q)
            {
               if (aPlus & syntaxCheck)
                  curObject = [[Plus alloc] initWithToken:curToken:monadic:unary];

               else if (aMinus & syntaxCheck)
                  curObject = [[Minus alloc] initWithToken:curToken:monadic:unary];

               digitCount = 0;
               if (![self newToken:c:j:&syntaxCheck:&curToken:&curObject:calcError])
                  goto SemanticError;

               syntaxCheck = unaryOp;
               switch (c)
               {
                  case '~':
                     curObject = [[BitwiseINV alloc] initWithToken:curToken:monadic:unary];
                     break;

                  case 0xC2B0:   // '°' Degree Sign
                     curObject = [[Radian2Degree alloc] initWithToken:curToken:monadic:unary];
                     break;

                  case 0xC2AE:   // '®' Registered Sign
                     curObject = [[Degree2Radian alloc] initWithToken:curToken:monadic:unary];
                     break;

                  case 0xC3A7:   // 'ç' c w/ cedilla
                     curObject = [[pt2cm alloc] initWithToken:curToken:monadic:unary];
                     break;

                  case 0xC2B6:   // '¶' Pilcrow Sign
                     curObject = [[cm2pt alloc] initWithToken:curToken:monadic:unary];
                     break;
               }
            }
            else
               goto SyntaxError;
            break;

         case 0xE28988:    // '≈' almost equal to
         case '&':
         case '|':
            if ((syntaxCheck | BinOperator) == BinOperator)
            {
               digitCount = 0;
               if (![self newToken:c:j:&syntaxCheck:&curToken:&curObject:calcError])
                  goto SemanticError;

               syntaxCheck = binaryOp;
               switch (c)
               {
                  case 0xE28988: // '≈' almost equal to
                     curObject = [[BitwiseXOR alloc] initWithToken:curToken:bxor:binary];
                     break;

                  case '&':
                     if (*p == '&')
                     {
                        curObject = [[LogicalAND alloc] initWithToken:curToken:land:binary];
                        curToken->tCount = 2;
                        cpy2(curToken->tLiteral, "&&");
                        p++, j += 2;
                        continue;
                     }
                     else
                        curObject = [[BitwiseAND alloc] initWithToken:curToken:band:binary];
                     break;

                  case '|':
                     if (*p == '|')
                     {
                        curObject = [[LogicalOR alloc] initWithToken:curToken:lor:binary];
                        cpy2(curToken->tLiteral, "||");
                        p++, j += 2;
                        continue;
                     }
                     else
                        curObject = [[BitwiseOR  alloc] initWithToken:curToken:bor:binary];
                     break;
               }
            }
            else
               goto SyntaxError;
            break;

         case ':':
            if (*p == '=' && (syntaxCheck | Assignment) == Assignment && p < q)
            {
               digitCount = 0;
               syntaxCheck |= assignment;
               if (![self newToken:c:j:&syntaxCheck:&curToken:&curObject:calcError])
                  goto SemanticError;

               syntaxCheck = binaryOp;
               curObject = [[SetEqual alloc] initWithToken:curToken:assign:binary];
               [curObject setCalculator:self];
               curToken->tCount = 2;
               cpy2(curToken->tLiteral, ":=");
               p++, j += 2;
               continue;
            }
            else
               goto SyntaxError;
            break;

         case '<':
         case '>':
         case 0xE289A4:    // '≤' less than or equal to
         case 0xE289A5:    // '≥' greater than or equal to
         case '!':
         case '=':
            if ((syntaxCheck | BinOperator) == BinOperator && p < q)
            {
               digitCount = 0;
               if (![self newToken:c:j:&syntaxCheck:&curToken:&curObject:calcError])
                  goto SemanticError;

               syntaxCheck = binaryOp;
               uint16_t cc = TwoChars(p-1);
               if (cc == '==' || cc == '!=' || cc == '<=' || cc == '<>' || cc == '>=' || cc == '<<' || cc == '>>')
               {
                  switch (cc)
                  {
                     case '==':
                        curObject = [[Equal alloc] initWithToken:curToken:compare:binary];
                        break;

                     case '!=':
                        curObject = [[UnEqual alloc] initWithToken:curToken:compare:binary];
                        break;

                     case '<=':
                        curObject = [[LessEqual alloc] initWithToken:curToken:compare:binary];
                        break;

                     case '<>':
                        curObject = [[UnEqual alloc] initWithToken:curToken:compare:binary];
                        break;

                     case '>=':
                        curObject = [[GreaterEqual alloc] initWithToken:curToken:compare:binary];
                        break;

                     case '<<':
                        curObject = [[BitwiseSHL alloc] initWithToken:curToken:bshift:binary];
                        break;

                     case '>>':
                        curObject = [[BitwiseSHR alloc] initWithToken:curToken:bshift:binary];
                        break;
                  }
                  curToken->tCount = 2;
                  curToken->tLiteral[0] = (char)c;
                  curToken->tLiteral[1] = *p;
                  p++, j += 2;
                  continue;
               }

               else switch (c)
               {
                  case '=':
                     curObject = [[Subtraction alloc] initWithToken:curToken:equate:binary];
                     break;

                  case '<':
                     curObject = [[Less alloc] initWithToken:curToken:compare:binary];
                     break;

                  case '>':
                     curObject = [[Greater alloc] initWithToken:curToken:compare:binary];
                     break;

                  case 0xE289A4:    // '≤' less than or equal to
                     curObject = [[LessEqual alloc] initWithToken:curToken:compare:binary];
                     break;

                  case 0xE289A5:    // '≥' greater than or equal to
                     curObject = [[GreaterEqual alloc] initWithToken:curToken:compare:binary];
                     break;

                  case '!':
                     goto SyntaxError;
                     break;
               }
            }

            else if (c == '!' && (syntaxCheck | UnOperator) == UnOperator && p < q)
            {
               digitCount = 0;
               if (![self newToken:c:j:&syntaxCheck:&curToken:&curObject:calcError])
                  goto SemanticError;

               syntaxCheck = unaryOp;
               curObject = [[LogicalNOT alloc] initWithToken:curToken:monadic:unary];
            }
            else
               goto SyntaxError;
            break;

         case '(':
            if ((syntaxCheck | ParentOpen) == ParentOpen && p < q)
            {
               digitCount = 0;
               if (aPlus & syntaxCheck)
               {
                  syntaxCheck = unaryOp;
                  curObject = [[Plus alloc] initWithToken:curToken:monadic:unary];
               }

               else if (aMinus & syntaxCheck)
               {
                  syntaxCheck = unaryOp;
                  curObject = [[Minus alloc] initWithToken:curToken:monadic:unary];
               }

               if (![self newToken:c:j:&syntaxCheck:&curToken:&curObject:calcError])
                  goto SemanticError;

               syntaxCheck = openParent;
               parentCount++;
            }
            else
               goto SyntaxError;
            break;

         case '{':
            if ((syntaxCheck | ComplexOpen) == ComplexOpen && p < q)
            {
               digitCount = 0;
               if (aPlus & syntaxCheck)
               {
                  syntaxCheck = unaryOp;
                  curObject = [[Plus alloc] initWithToken:curToken:monadic:unary];
               }

               else if (aMinus & syntaxCheck)
               {
                  syntaxCheck = unaryOp;
                  curObject = [[Minus alloc] initWithToken:curToken:monadic:unary];
               }

               if (![self newToken:c:j:&syntaxCheck:&curToken:&curObject:calcError])
                  goto SemanticError;

               curObject = [[CalcComplex alloc] initWithToken:curToken:factor:param];

               syntaxCheck = openComplex;
               complexCount++;
            }
            else
               goto SyntaxError;
            break;

         case '[':
            if ((syntaxCheck | VectorOpen) == VectorOpen && p < q)
            {
               digitCount = 0;
               if (aPlus & syntaxCheck)
               {
                  syntaxCheck = unaryOp;
                  curObject = [[Plus alloc] initWithToken:curToken:monadic:unary];
               }

               else if (aMinus & syntaxCheck)
               {
                  syntaxCheck = unaryOp;
                  curObject = [[Minus alloc] initWithToken:curToken:monadic:unary];
               }

               if (![self newToken:c:j:&syntaxCheck:&curToken:&curObject:calcError])
                  goto SemanticError;

               curObject = [[CalcVector alloc] initWithToken:curToken:factor:param];

               syntaxCheck = openVector;
               vectorCount++;
            }
            else
               goto SyntaxError;
            break;

         case ']':
            if (--vectorCount  < 0) goto SyntaxError; else goto closeBracket;
         case '}':
            if (--complexCount < 0) goto SyntaxError; else goto closeBracket;
         case ')':
            if (--parentCount  < 0) goto SyntaxError;
         closeBracket:
            if ((syntaxCheck | BracketsClose) == BracketsClose)
            {
               digitCount = 0;
               if (![self newToken:c:j:&syntaxCheck:&curToken:&curObject:calcError])
                  goto SemanticError;
               syntaxCheck = closeBrackets;
            }
            else
               goto SyntaxError;
            break;

         case '0':
            if (p[1] == 'x')
            {
               if ((syntaxCheck | Hex) == Hex)
               {
                  digitCount = 0;
                  if (aPlus & syntaxCheck || aMinus & syntaxCheck)
                     syntaxCheck |= numPlusMinus;

                  else if (![self newToken:c:j:&syntaxCheck:&curToken:&curObject:calcError])
                     goto SemanticError;

                  syntaxCheck &= NumState;
                  syntaxCheck |= hexNum;

                  if (aMinus && (syntaxCheck & numPlusMinus))
                  {
                     curToken->tCount = 2;
                     cpy2(curToken->tLiteral, "-0");
                  }

                  else
                  {
                     curToken->tCount = 1;
                     curToken->tLiteral[0] = '0';
                  }
                  c = 'x';
                  p++;
               }
               else
                  goto SyntaxError;
               break;
            }
         case '1'...'9':
            if ((syntaxCheck | Digit) == Digit && (digitCount < 34 ||
                ((binNum          & syntaxCheck) == 0 || ((c == '0' || c == '1') && digitCount < 64))) &&
                ((binNum+numPoint & syntaxCheck) != 0 || digitCount < 19) &&
                ((hexNum          & syntaxCheck) == 0 || digitCount < 16) &&
                ((numExponent     & syntaxCheck) == 0 || digitCount <  4))
            {
               if (syntaxCheck != other)
               {
                  if (aPlus & syntaxCheck || aMinus & syntaxCheck)
                     syntaxCheck |= numPlusMinus;

                  else if (aPoint & syntaxCheck)
                     syntaxCheck |= numPoint;

                  else if (anE & syntaxCheck)
                  {
                     syntaxCheck |= numExponent;
                     digitCount = 0;
                  }

                  else if (digitCount == 0 && (numExponent & syntaxCheck) == 0
                                           && (hexNum      & syntaxCheck) == 0
                                           && (binNum      & syntaxCheck) == 0)
                     if (![self newToken:c:j:&syntaxCheck:&curToken:&curObject:calcError])
                        goto SemanticError;

                  syntaxCheck &= NumState;
                  syntaxCheck |= numDigit;

                  digitCount++;
               }
            }
            else
               goto SyntaxError;
            break;

         case '%':
            if ((syntaxCheck | Digit) == Digit && digitCount != 0)
            {
               syntaxCheck &= NumState;
               syntaxCheck |= numPercent;
            }
            else
               goto SyntaxError;
            break;

         case '$':
            // HexNum Initial
            if ((syntaxCheck | Hex) == Hex)
            {
               digitCount = 0;
               if (aPlus & syntaxCheck || aMinus & syntaxCheck)
                  syntaxCheck |= numPlusMinus;

               else if (![self newToken:c:j:&syntaxCheck:&curToken:&curObject:calcError])
                  goto SemanticError;

               syntaxCheck &= NumState;
               syntaxCheck |= hexNum;

               if (aMinus && (syntaxCheck & numPlusMinus))
               {
                  curToken->tCount = 2;
                  cpy2(curToken->tLiteral, "-0");
               }

               else
               {
                  curToken->tCount = 1;
                  curToken->tLiteral[0] = '0';
               }
               c = 'x';
            }
            else
               goto SyntaxError;
            break;

         case '#':
            // BinNum Initial
            if ((syntaxCheck | Bin) == Bin)
            {
               digitCount = 0;
               if (aPlus & syntaxCheck || aMinus & syntaxCheck)
                  syntaxCheck |= numPlusMinus;

               else if (![self newToken:c:j:&syntaxCheck:&curToken:&curObject:calcError])
                  goto SemanticError;

               syntaxCheck &= NumState;
               syntaxCheck |= binNum;

               if (aMinus && (syntaxCheck & numPlusMinus))
               {
                  curToken->tCount = 1;
                  curToken->tLiteral[0] = '-';
               }
            }
            else
               goto SyntaxError;
            break;

         case 'A'...'F':
         case 'a'...'f':
            if (hexNum & syntaxCheck && (blank & syntaxCheck) == 0)
               if (digitCount < 16)
                  digitCount++;
               else
                  goto SyntaxError;

            else if ((c == 'e' || c == 'E') && numDigit & syntaxCheck)
            {
               syntaxCheck |= anE;
               syntaxCheck &= ~numPlusMinus;
            }

            // binary operators and, div
            else if (syntaxCheck != other && (c == 'a' || c == 'd') && p < q-2 && (cmp2(p, "nd") || cmp2(p, "iv")) &&
                     ((d = p[2]) == ' ' || d == '#' || d == '$' || d == '\''|| d == '(' || d == '+' || d == '-' || d == '@' || d == '[' || d == '{'))
               if ((syntaxCheck | BinOperator) == BinOperator)
               {
                  digitCount = 0;
                  if (![self newToken:c:j:&syntaxCheck:&curToken:&curObject:calcError])
                     goto SemanticError;

                  syntaxCheck = binaryOp;
                  if (c == 'a')
                     curObject = [[LogicalAND alloc] initWithToken:curToken:land:binary];
                  else // c == 'd'
                     curObject = [[IntegerDIV alloc] initWithToken:curToken:muldiv:binary];
                  curToken->tCount = 3;
                  curToken->tLiteral[0] = (char)c;
                  curToken->tLiteral[1] = p[0];
                  curToken->tLiteral[2] = p[1];
                  p += 2, j += 3;
                  continue;
               }

               else
               {
                  p += 2, j += 3;
                  goto SyntaxError;
               }
            else
               goto OtherChar;
            break;

         case 'm':
            // binary operator mod
            if (syntaxCheck != other && p < q-2 && cmp2(p, "od") &&
                ((d = p[2]) == ' ' || d == '#' || d == '$' || d == '\''|| d == '(' || d == '+' || d == '-' || d == '@' || d == '[' || d == '{'))
               if ((syntaxCheck | BinOperator) == BinOperator)
               {
                  digitCount = 0;
                  if (![self newToken:c:j:&syntaxCheck:&curToken:&curObject:calcError])
                     goto SemanticError;

                  syntaxCheck = binaryOp;
                  curObject = [[IntegerMOD alloc] initWithToken:curToken:muldiv:binary];
                  curToken->tCount = 3;
                  cpy3(curToken->tLiteral, "mod");
                  p += 2, j += 3;
                  continue;
               }
               else
               {
                  p += 2, j += 3;
                  goto SyntaxError;
               }
            else
               goto OtherChar;
            break;

         case 'n':
            // unary operator not
            if (syntaxCheck != other && p < q-2 && cmp2(p, "ot") &&
                ((d = p[2]) == ' ' || d == '#' || d == '$' || d == '\''|| d == '(' || d == '+' || d == '-' || d == '@' || d == '[' || d == '{'))
               if ((syntaxCheck | UnOperator) == UnOperator)
               {
                  digitCount = 0;
                  if (![self newToken:c:j:&syntaxCheck:&curToken:&curObject:calcError])
                     goto SemanticError;

                  syntaxCheck = unaryOp;
                  curObject = [[LogicalNOT alloc] initWithToken:curToken:monadic:unary];
                  curToken->tCount = 3;
                  cpy3(curToken->tLiteral, "not");
                  p += 2, j += 3;
                  continue;
               }
               else
               {
                  p += 2, j += 3;
                  goto SyntaxError;
               }
            else
               goto OtherChar;
            break;

         case 'o':
            // binary operator or
            if (syntaxCheck != other && p < q-1 && *p == 'r' &&
                ((d = p[1]) == ' ' || d == '#' || d == '$' || d == '\''|| d == '(' || d == '+' || d == '-' || d == '@' || d == '[' || d == '{'))
               if ((syntaxCheck | BinOperator) == BinOperator)
               {
                  digitCount = 0;
                  if (![self newToken:c:j:&syntaxCheck:&curToken:&curObject:calcError])
                     goto SemanticError;

                  syntaxCheck = binaryOp;
                  curObject = [[LogicalOR alloc] initWithToken:curToken:lor:binary];
                  curToken->tCount = 2;
                  cpy2(curToken->tLiteral, "or");
                  p++, j += 2;
                  continue;
               }
               else
               {
                  p++, j += 2;
                  goto SyntaxError;
               }
            else
               goto OtherChar;
            break;

         case 'u':
            // unary operator undefined
            if (syntaxCheck != other && p < q-8 && cmp8(p, "ndefined") &&
                ((d = p[8]) == ' ' || d == '#' || d == '$' || d == '\''|| d == '(' || d == '+' || d == '-' || d == '@' || d == '[' || d == '{'))
               if ((syntaxCheck | UnOperator) == UnOperator)
               {
                  digitCount = 0;
                  if (![self newToken:c:j:&syntaxCheck:&curToken:&curObject:calcError])
                     goto SemanticError;

                  syntaxCheck = unaryOp | other;
                  curToken->tCount = 9;
                  cpy9(curToken->tLiteral, "undefined");
                  p += 8, j += 9;
                  continue;
               }
               else
               {
                  p += 8; j += 9;
                  goto SyntaxError;
               }
            else
               goto OtherChar;
            break;

         case 'x':
            // binary operator xor
            if (syntaxCheck != other && p < q-2 &&  cmp2(p, "or") &&
                ((d = p[2]) == ' ' || d == '#' || d == '$' || d == '\''|| d == '(' || d == '+' || d == '-' || d == '@' || d == '[' || d == '{'))
            {
               if ((syntaxCheck | BinOperator) == BinOperator)
               {
                  digitCount = 0;
                  if (![self newToken:c:j:&syntaxCheck:&curToken:&curObject:calcError])
                     goto SemanticError;

                  syntaxCheck = binaryOp;
                  curObject = [[LogicalXOR alloc] initWithToken:curToken:lxor:binary];
                  curToken->tCount = 3;
                  cpy3(curToken->tLiteral, "xor");
                  p += 2; j += 3;
                  continue;
               }
               else
               {
                  p += 2; j += 3;
                  goto SyntaxError;
               }
            }

       OtherChar:
         default:
            if ((syntaxCheck | Name) == Name && ('A' <= c && c <= 'Z' ||
                                                 'a' <= c && c <= 'z' ||
                                                 c == '?' || c == '_' ||
                                                 c == 0xCF80   /*'π'*/||
                                                 c == 0xE28886 /*'∆'*/||
                                                 c == 0xE2888F /*'∏'*/||
                                                 c == 0xE28891 /*'∑'*/||
                                                 c == 0xE288AB /*'∫'*/||
                                                 c == 0xE2889E /*'∞'*/))
            {
               if (syntaxCheck != other)
               {
                  digitCount = 0;
                  if (aPlus & syntaxCheck)
                  {
                     syntaxCheck = unaryOp;
                     curObject = [[Plus alloc] initWithToken:curToken:monadic:unary];
                  }

                  else if (aMinus & syntaxCheck)
                  {
                     syntaxCheck = unaryOp;
                     curObject = [[Minus alloc] initWithToken:curToken:monadic:unary];
                  }

                  if (![self newToken:c:j:&syntaxCheck:&curToken:&curObject:calcError])
                     goto SemanticError;

                  syntaxCheck = other;
               }
            }
            else
               goto SyntaxError;
            break;
      }

      curToken->tCount += putu(c, &curToken->tLiteral[curToken->tCount]);
      j++;
   }

   if ((syntaxCheck | Enter) == Enter && parentCount == 0 && vectorCount == 0)
   {
      if (syntaxCheck != listSep && ![self newToken:c:j:&syntaxCheck:&curToken:&curObject:calcError])
         goto SemanticError;
   }
   else
      goto SyntaxError;

   if (curToken->tNext)
      deallocate(VPR(curToken->tNext), false);
   curToken = rootToken->tNext;
   deallocate(VPR(rootToken), false);
   return curToken;

SyntaxError:
   calcError->flag  = syntaxError;
   calcError->begin = curToken->tBegin;
   calcError->count = j - curToken->tBegin + 1;

SemanticError:
   if (curObject != nil)
      [curObject release];

   return rootToken;
}


- (CalcObject *)parse:(TokenPtr *)curTokenPtr error:(ErrorRecord *)calcError
{
   static unsigned closePos = 0;

   TokenPtr    curToken     = *curTokenPtr;

   boolean     compareFlag  = false;
   CalcObject *curFactor    = nil;
   CalcDuo    *curFunc      = nil;
   CalcDuo    *curTerm      = nil;
   CalcDuo    *rootTerm     = nil;

   while (curToken != NULL && curToken->tCheck != 0)
   {
      if (curToken->tCheck == openParent)
      {
         curToken = curToken->tNext;

         if (curFactor != nil)
         {
            [curFactor setErrorInToken:paramError :calcError];
            curFactor = nil;
            goto ParameterError;
         }

         else if (curFunc != nil)
         {
            [curFunc addNextNode:[self parse:&curToken error:calcError]];
            [curFunc itsToken]->tCount = closePos - [curFunc itsToken]->tBegin + 1;
            if (calcError->flag == noError)
               [curFunc checkParamCount:calcError];
            curFactor = curFunc;
            curFunc = nil;
         }

         else
            curFactor = (CalcFactor *)[self parse:&curToken error:calcError];

         if (calcError->flag > noError || curFactor == nil)
            goto ParameterError;

         continue;
      }

      else if (curToken->tCheck == openComplex)
      {
         if (curFactor == nil)
         {
            if ((curFactor = (CalcFactor *)curToken->tObject) == nil)
               goto ParameterError;

            curToken = curToken->tNext;
            calcError->flag |= [(CalcComplex *)curFactor addNextElement:[self parse:&curToken error:calcError]];
            [curFactor itsToken]->tCount = closePos - [curFactor itsToken]->tBegin + 1;

            if (calcError->flag > noError)
               goto ParameterError;

            if (curFunc != nil)
            {
               [curFunc addNextNode:curFactor];
               [curFunc checkParamCount:calcError];
               curFactor = curFunc;
               curFunc = nil;
            }

            continue;
         }

         else
         {
            [curFactor setErrorInToken:paramError :calcError];
            curFactor = nil;
            goto ParameterError;
         }
      }

      else if (curToken->tCheck == openVector)
      {
         if (curFactor == nil)
         {
            if ((curFactor = (CalcFactor *)curToken->tObject) == nil)
               goto ParameterError;

            curToken = curToken->tNext;
            [(CalcVector *)curFactor addNextElement:[self parse:&curToken error:calcError]];
            [curFactor itsToken]->tCount = closePos - [curFactor itsToken]->tBegin + 1;

            if (calcError->flag > noError)
               goto ParameterError;

            if (curFunc != nil)
            {
               [curFunc addNextNode:curFactor];
               [curFunc checkParamCount:calcError];
               curFactor = curFunc;
               curFunc = nil;
            }

            continue;
         }

         else
         {
            [curFactor setErrorInToken:paramError :calcError];
            curFactor = nil;
            goto ParameterError;
         }
      }

      else if (curToken->tCheck == closeBrackets)
      {
         closePos = curToken->tBegin;
         curToken = curToken->tNext;
         break;
      }

      else if ([curToken->tObject itsPrecedence] == factor)
      {
         if (curFactor != nil)
         {
            [curToken->tObject setErrorInToken:paramError :calcError];
            curFactor = nil;
            goto ParameterError;
         }

         else if (curFunc != nil)
         {
            [curFunc addNextNode:curToken->tObject];
            curFactor = curFunc;
            curFunc = nil;
         }

         else
            curFactor = curToken->tObject;
      }

      else if (rootTerm == nil)
      {
         compareFlag = ([curToken->tObject itsPrecedence] == compare);
         rootTerm = curTerm = (CalcDuo *)curToken->tObject;

         if (curFactor != nil)
         {
            [curTerm addPrevNode:curFactor];
            curFactor = nil;
         }
      }

      else if ([curToken->tObject itsPrecedence] == monadic || [curToken->tObject itsPrecedence] == function)
      {
         if (curFunc != nil)
         {
            [curTerm addNextNode:curFunc];
            if ([curTerm checkParamCount:calcError])
               goto ParameterError;

            curTerm = curFunc;
         }

         curFunc = (CalcDuo *)curToken->tObject;
      }

      else if ([curToken->tObject itsPrecedence] < [curTerm itsPrecedence])
      {
         compareFlag = ([curToken->tObject itsPrecedence] == compare);
         [curTerm addNextNode:curToken->tObject];
         if ([curTerm checkParamCount:calcError])
            goto ParameterError;

         curTerm = (CalcDuo *)curToken->tObject;
         [curTerm addPrevNode:curFactor];
         curFactor = nil;
      }

      else if (compareFlag && [curToken->tObject itsPrecedence] == compare)
      {
         [curToken->tObject setErrorInToken:logicalError :calcError];
         goto ParameterError;
      }

      else
      {
         compareFlag = ([curToken->tObject itsPrecedence] == compare);
         [curTerm addNextNode:curFactor];
         if ([curTerm checkParamCount:calcError])
            goto ParameterError;
         curFactor = nil;

         while (curTerm != rootTerm && [curToken->tObject itsPrecedence] >= [curTerm itsPrecedence])
            curTerm = [curTerm itsParent];

         if ([curToken->tObject itsPrecedence] < [curTerm itsPrecedence])
         {
            [(CalcDuo *)curToken->tObject addPrevNode:[curTerm nextTerm]];
            [curTerm addNextNode:curToken->tObject];
         }

         else
         {
            [(CalcDuo *)curToken->tObject addPrevNode:rootTerm];
            rootTerm = (CalcDuo *)curToken->tObject;
         }

         curTerm = (CalcDuo *)curToken->tObject;
      }

      curToken = curToken->tNext;
   }

   if (curFunc != nil)
      [curFunc setErrorInToken:paramError :calcError];

   else if (curTerm != nil)
   {
      if (curFactor != nil)
         [curTerm addNextNode:curFactor];

      [curTerm checkParamCount:calcError];
   }

ParameterError:
   *curTokenPtr = curToken;

   if (rootTerm != nil)
      return rootTerm;

   else if (curFactor != nil)
      return curFactor;

   else
      return nil;
}


#pragma mark ••• Calculate •••

- (ResultModifier)preProcess:(char **)function
{
   if (*function && **function)
   {
      char          *p, *s = trim(*function);
      unsigned       l = strvlen(s);
      ResultModifier modifier;

      int d;
      decDigits = -1;
      sigDigits = -1;

      if (cmp2(s+l-2, " %"))
      {
         modifier = percentResult;
         s[l-2] = '\0';
      }
      else
         modifier = plainResult;

      p = s;
      while (*p)
      {
         switch (getu(&p))
         {
            case '"':
               *(p -= 1) = '\0';
               break;

            case 0xC2B4:      // '´' Acute accent
               *(p -= 2) = '\0';
               if ((d = (int)strtol(p, NULL, 10)) >= 0)
               {
                  if (d > 500)
                     d = 500;
                  sigDigits = 0, decDigits = d;
               }
               break;

            case '`':
               *(p -= 2) = '\0';
               if ((d = (int)strtol(p, NULL, 10)) >= 0)
               {
                  if (d > __LDBL_DIG__)
                     d = __LDBL_DIG__;
                  else if (d == 0)
                     d = 1;
                  sigDigits = decDigits = d;
               }
               break;
         }
      }

      if (sigDigits < 0)
         sigDigits = gSigDigits;

      if (decDigits < 0)
         decDigits = gDecDigits;

      if (*s == '\\')
      {
         modifier = binResult;
         s++;
      }
      else if (*s == '&')
      {
         modifier = hexResult;
         s++;
      }
      else if (cmp2(s, "§"))
      {
         modifier = hexResult|binResult;
         s += 2;
      }
      else if (cmp2(s, "ƒ"))
      {
         modifier = fractResult;
         s += 2;
      }
      else if (*s == '?')
      {
         modifier = strResult;
         s++;
      }

      *function = s;
      return modifier;
   }

   else
      return noResult;
}


#define calcInOutSize 65536

static inline int magni(long double x)
{
   int m = intlgl(fabsl(x));
   return (m > -100) ? m : 0;
}

- (char *)vStrIterate:(ResultType *)v :(char *)r :(char *)s
{
   unsigned i, n, len;
   n = v->n;
   v = v->v;

   if (v)
   {
      for (i = 0; i < n; i++)
      {
         switch (v[i].f)
         {
            default:
            case rtError:
               cpy5(s, "error"),    s += 5;
               break;

            case rtBoolean:
               if (v[i].b)
                  cpy4(s, "true"),  s += 4;
               else
                  cpy5(s, "false"), s += 5;
               break;

            case rtInteger:
               s += int2str(s, v[i].i, calcInOutSize-1-(int)(s-r), 0);
               break;

            case rtReal:
               if (0 < sigDigits && sigDigits <= decDigits)
                  s += num2str(s, v[i].r, calcInOutSize-1-(int)(s-r), 0, sigDigits, g_form|non_zero, gDecSep);
               else if (decDigits + magni(v[i].r) < 0)
                  s += num2str(s, v[i].r, calcInOutSize-1-(int)(s-r), 0, decDigits, e_form|non_zero, gDecSep);
               else
                  s += num2str(s, v[i].r, calcInOutSize-1-(int)(s-r), 0, decDigits, f_form|non_zero, gDecSep);
               break;

            case rtComplex:
               *s++ = '{';
               if (0 < sigDigits && sigDigits <= decDigits)
                  s += num2str(s, creall(v[i].z), calcInOutSize-1-(int)(s-r), 0, sigDigits, g_form|non_zero, gDecSep);
               else if (decDigits + magni(creall(v[i].z)) < 0)
                  s += num2str(s, creall(v[i].z), calcInOutSize-1-(int)(s-r), 0, decDigits, e_form|non_zero, gDecSep);
               else
                  s += num2str(s, creall(v[i].z), calcInOutSize-1-(int)(s-r), 0, decDigits, f_form|non_zero, gDecSep);
               *s++ = ';';
               if (0 < sigDigits && sigDigits <= decDigits)
                  s += num2str(s, cimagl(v[i].z), calcInOutSize-1-(int)(s-r), 0, sigDigits, g_form|non_zero, gDecSep);
               else if (decDigits + magni(cimagl(v[i].z)) < 0)
                  s += num2str(s, cimagl(v[i].z), calcInOutSize-1-(int)(s-r), 0, decDigits, e_form|non_zero, gDecSep);
               else
                  s += num2str(s, cimagl(v[i].z), calcInOutSize-1-(int)(s-r), 0, decDigits, f_form|non_zero, gDecSep);
               cpy2(s++, "}");
               break;

            case rtVector:
               *s++ = '[';
               s = [self vStrIterate:&v[i] :r :s];
               cpy2(s++, "]");
               break;

            case rtString:
               len = (unsigned)strvlen(v[i].s);
               if (len < calcInOutSize-3-(s-r))
               {
                  *s++ = '"';
                  strcpy(s, v[i].s); s += len;
                  cpy2(s, "\"");
               }
               break;
         }

         if (i < n-1)
            *s++ = ';';
      }
   }
   *s = '\0';

   return s;
}


static void num2BinStr(char *s, llong num)
{
   int i, k;
   for (*s = '#', k = 1, i = 63; i >= 0; i--)
      if ((ullong)num & (1LL << i))
         s[k++] = '1';
      else if (k > 1)      // skip leading zeros
         s[k++] = '0';

   if (k > 1)
      s[k] = '\0';
   else
      cpy2(s+1, "0");
}


static void makeFraction(long double q, llong *a, llong *b, double eps)
{
   int   i  = 0;
   llong am = 0;
   llong bm = 1;
   llong t, amm, bmm;

   long double qvor, qnk;
   long double qabs = fabsl(q);
   long double q0   = qabs;

   *a = 1;
   *b = 0;
   do
   {
      qvor = floorl(q0 + eps);
      qnk  = q0 - qvor;
      q0   = 1.0L/qnk;

      amm  = am;
      bmm  = bm;
      am   = *a;
      bm   = *b;

      *a   = (llong)floorl(qvor*am + amm);
      *b   = (llong)floorl(qvor*bm + bmm);
      t    = ggT(*a, *b);
      *a  /= t;
      *b  /= t;

   } while (i++ < 32 && qnk > eps && fabsl(qabs - (*a)/(*b)) >= eps);

   if (fabsl(qabs - (*a)/(*b)) <= eps && q < 0)
      *a = -*a;
}

- (char *)postProcess:(ResultType *)result modifier:(ResultModifier)resultModifier resultBuffer:(char **)buffer
{
   static char localResultBuffer[calcInOutSize];   // static fallback result buffer in case buffer or *buffer is NULL

   boolean negative = false;
   int     l;
   llong   i, n, d;
   char   *s, *r = (buffer && *buffer)
                 ? *buffer
                 : localResultBuffer;

   if (resultModifier == strResult && result->s != NULL)
      result->f = rtString;

   if ((resultModifier & (hexResult|binResult)) && result->f == rtReal && result->r == truncl(result->r))
      result->f = rtInteger, result->i = llroundl(result->r);

   switch (result->f)
   {
      case rtNone:
         strcpy(r, "none");
         break;

      case rtBoolean:
         if (!(resultModifier & percentResult))
         {
            strcpy(r, (result->b) ? "true" : "false");
            break;
         }
         else
            result->i = (result->b) ? 1 : 0;

      case rtInteger:
         if (resultModifier & hexResult)
         {
            if (resultModifier & binResult)
               snprintf(r, calcInOutSize, "0x%llX", result->i);
            else
               snprintf(r, calcInOutSize, "$%llX", result->i);
         }
         else if (resultModifier & binResult)
            num2BinStr(r, result->i);
         else
            int2str(r, result->i, calcInOutSize, 0);

         if (resultModifier & percentResult)
         {
            if ((n = strvlen(r)) < calcInOutSize-2)
               cpy3(r+n, " %");
            result->f = rtReal;
            result->r = (long double)result->i/100.0L;
         }
         break;

      case rtReal:
         if (isnan(result->r))
         {
            result->e.flag = nanError;
            goto errors;
         }

         if (resultModifier & fractResult)
         {
            if (result->r < 0.0L)
            {
               result->r = fabsl(result->r);
               negative = true;
            }

            makeFraction(result->r, &n, &d, 1e-9);
            i = (llong)floorl(result->r);
            n = n - d*i;

            if (negative)
               if (i != 0 && n != 0)
                  snprintf(r, calcInOutSize, "-(%lld %lld/%lld)", i, n, d);
               else if (i == 0)
                  snprintf(r, calcInOutSize, "-%lld/%lld", n, d);
               else // (n == 0)
                  snprintf(r, calcInOutSize, "-%lld", i);
            else
               if (i != 0 && n != 0)
                  snprintf(r, calcInOutSize, "%lld %lld/%lld", i, n, d);
               else if (i == 0)
                  snprintf(r, calcInOutSize, "%lld/%lld", n, d);
               else // (n == 0)
                  snprintf(r, calcInOutSize, "%lld", i);
         }

         else
         {
            if (0 < sigDigits && sigDigits <= decDigits)
               num2str(r, result->r, calcInOutSize, 0, sigDigits, g_form|non_zero, gDecSep);
            else if (decDigits + magni(result->r) < 0)
               num2str(r, result->r, calcInOutSize, 0, decDigits, e_form|non_zero, gDecSep);
            else
               num2str(r, result->r, calcInOutSize, 0, decDigits, f_form|non_zero, gDecSep);
         }

         if (resultModifier & percentResult)
         {
            if ((n = strvlen(r)) < calcInOutSize-2)
               cpy3(r+n, " %");
            result->r = result->r/100.0L;
         }
         break;

      case rtComplex:
         s = r;
         *s++ = '{';
         if (0 < sigDigits && sigDigits <= decDigits)
            s += num2str(s, creall(result->z), calcInOutSize-1-(int)(s-r), 0, sigDigits, g_form|non_zero, gDecSep);
         else if (decDigits + magni(creall(result->z)) < 0)
            s += num2str(s, creall(result->z), calcInOutSize-1-(int)(s-r), 0, decDigits, e_form|non_zero, gDecSep);
         else
            s += num2str(s, creall(result->z), calcInOutSize-1-(int)(s-r), 0, decDigits, f_form|non_zero, gDecSep);
         *s++ = ';';
         if (0 < sigDigits && sigDigits <= decDigits)
            s += num2str(s, cimagl(result->z), calcInOutSize-1-(int)(s-r), 0, sigDigits, g_form|non_zero, gDecSep);
         else if (decDigits + magni(cimagl(result->z)) < 0)
            s += num2str(s, cimagl(result->z), calcInOutSize-1-(int)(s-r), 0, decDigits, e_form|non_zero, gDecSep);
         else
            s += num2str(s, cimagl(result->z), calcInOutSize-1-(int)(s-r), 0, decDigits, f_form|non_zero, gDecSep);
         cpy2(s, "}");
         break;

      case rtVector:
         *r = '[';
         cpy2([self vStrIterate:result :r :r+1], "]");
         freeVector(result);
         break;

      case rtString:
         *r = '"';
         if ((l = (unsigned)strlcpy(r+1, result->s, calcInOutSize-1)) < calcInOutSize-1)
            cpy2(r+l+1, "\"");
         break;

      errors:
      case rtError:
         switch (result->e.flag)
         {
            case syntaxError:
               s = "Syntax Error";
               break;

            case semanticError:
               s = "Semantic Error";
               break;

            case paramError:
               s = "Wrong Number of Parameters";
               break;

            case logicalError:
               s = "Error in Logical Expression";
               break;

            case typeError:
               s = "Type Mismatch";
               break;

            case nanError:
               s = "Not a Number";
               break;

            case singularError:
               s = "Singular Matrix";
               break;

            case oorError:
               s = "Invalid Index";
               break;

            case recursionError:
               s = "Invalid Recursion";
               break;

            default:
               s = "";
         }

         strmlcpy(r, s, calcInOutSize, NULL);
         break;
   }

   return r;
}


#pragma mark ••• generic calculate method •••

- (ResultType)calculate:(char *)function index:(unsigned)idx
{
   TokenPtr    rootToken, token;
   CalcObject *calcNode;
   ResultType  result = gNullResult;

   if (function && *function)
   {
      token = rootToken = [self scan:function error:&result.e];
      if (result.e.flag <= noError)
      {
         calcNode = [self parse:&token error:&result.e];

         if (result.e.flag <= noError)
            result = [calcNode evaluate:idx];
      }

      if (result.e.flag > noError)
         result.f = rtError;

      [self disposeTokens:rootToken];
   }

   return result;
}

@end


#pragma mark ••• Singular Value Decomposition •••

// SVD Implementation that constructs the singular value decomposition
// of any matrix. Note that all the hard work is done by decompose; reorder simply
// orders the columns into canonical order (decreasing S[j]) and with sign flips
// to get the maximum number of positive elements. The function pythl does just
// what you might guess from its name, coded so as avoid overflow or underflow.

static inline long double pythl(long double a, long double b)
{  // Computes sqrt(sqr(a) + sqr(b)) without destructive underflow or overflow.
   long double absa = fabsl(a);
   long double absb = fabsl(b);
   return (absa > absb) ? absa*sqrtl(1.0L + sqrl(absb/absa)) : (absb == 0.0L) ? 0.0L : absb*sqrtl(1.0L + sqrl(absa/absb));
}

static inline long double sgncpyl(long double a, long double b)
{
   ((char *)&a)[9] = ((char *)&a)[9]&0x7F | ((char *)&b)[9]&0x80;
   return a;
}

static boolean svd(int m, int n, Matrix M, Matrix U, Matrix V, Vector S)
{  // Singular Value Decomposition
   // Given the matrix M[m][n], this routine computes its singular value decomposition,
   // M = U∑V^T and stores the results in the matrices U and V, and the vector S.
   // S contains the diagonal elements of the diagonal matrix ∑.

   boolean     flag;
   int         i, its, j, jj, k, nm = 0, l = 0;
   long double anorm, c, f, g, h, s, scale, x, y, z;
   long double rv1[n];

   if (U != M)
      for (i = 0; i < m; i++)
         for (j = 0; j < m; j++)
            U[i][j] = M[i][j];

   g = scale = anorm = 0.0L;

   // Householder reduction to bidiagonal form.
   for (i = 0; i < n; i++)
   {
      l = i + 2;
      rv1[i] = scale*g;
      g = scale = s = 0.0L;
      if (i < m)
      {
         for (k = i; k < m; k++)
            scale += fabsl(U[k][i]);
         if (scale != 0.0L)
         {
            for (k = i; k < m; k++)
            {
               U[k][i] /= scale;
               s += U[k][i]*U[k][i];
            }
            f = U[i][i];
            g = -sgncpyl(sqrtl(s), f);
            h = f*g - s;
            U[i][i] = f - g;
            for (j = l-1; j < n; j++)
            {
               s = 0.0L;
               for (k = i; k < m; k++)
                  s += U[k][i]*U[k][j];
               f = s/h;
               for (k = i; k < m; k++)
                  U[k][j] += f*U[k][i];
            }
            for (k = i; k < m; k++)
               U[k][i] *= scale;
         }
      }

      S[i] = scale*g;
      g = s = scale = 0.0L;
      if (i+1 <= m && i+1 != n)
      {
         for (k = l-1; k < n; k++)
            scale += fabsl(U[i][k]);
         if (scale != 0.0L)
         {
            for (k = l-1; k < n; k++)
            {
               U[i][k] /= scale;
               s += U[i][k]*U[i][k];
            }
            f = U[i][l-1];
            g = -sgncpyl(sqrtl(s), f);
            h = f*g - s;
            U[i][l-1] = f - g;
            for (k = l-1; k < n; k++)
               rv1[k] = U[i][k]/h;
            for (j=l-1;j<m;j++)
            {
               s = 0.0L;
               for (k = l-1; k < n; k++)
                  s += U[j][k]*U[i][k];
               for (k = l-1; k < n; k++)
                  U[j][k] += s*rv1[k];
            }
            for (k = l-1; k < n; k++)
               U[i][k] *= scale;
         }
      }

      anorm = fmaxl(anorm, fabsl(S[i]) + fabsl(rv1[i]));
   }

   // Accumulation of right-hand transformations.
   for (i = n-1; i >= 0; i--)
   {
      if (i < n-1)
      {
         if (g != 0.0L)
         {
            for (j = l; j < n; j++)
               V[j][i] = (U[i][j]/U[i][l])/g; // Double division to avoid possible underflow.
            for (j = l; j < n; j++)
            {
               s = 0.0L;
               for (k = l; k <n; k++)
                  s += U[i][k]*V[k][j];
               for (k = l; k <n; k++)
                  V[k][j] += s*V[k][i];
            }
         }
         for (j = l; j < n; j++)
            V[i][j] = V[j][i] = 0.0L;
      }
      V[i][i] = 1.0L;
      g = rv1[i];
      l = i;
   }

   // Accumulation of left-hand transformations.
   for (i = ((m<=n)?m:n)-1; i >= 0; i--)
   {
      l = i+1;
      g = S[i];
      for (j = l; j < n; j++)
         U[i][j] = 0.0L;
      if (g != 0.0L)
      {
         g = 1.0L/g;
         for (j = l; j < n; j++)
         {
            s = 0.0L;
            for (k = l; k < m; k++)
               s += U[k][i]*U[k][j];
            f = (s/U[i][i])*g;
            for (k = i; k < m; k++)
               U[k][j] += f*U[k][i];
         }
         for (j = i; j < m; j++)
            U[j][i] *= g;
      }
      else
         for (j = i; j < m; j++)
            U[j][i] = 0.0L;
      ++U[i][i];
   }

   // Diagonalization of the bidiagonal form.
   // Loop over singular values.
   for (k = n-1; k >= 0; k--)
   {
      // Loop over allowed iterations.
      for (its = 0; its < 30; its++)
      {
         // Test for splitting.
         flag = true;
         for (l = k; l >= 0; l--)
         {
            nm = l-1;
            if (l == 0 || fabsl(rv1[l]) <= __LDBL_EPSILON__*anorm)
            {
               flag = false;
               break;
            }

            if (fabsl(S[nm]) <= __LDBL_EPSILON__*anorm)
               break;
         }

         if (flag)
         {
            c = 0.0L;      // Cancellation of rv1[l], if l > 0.
            s = 1.0L;
            for (i = l; i < k+1; i++)
            {
               f = s*rv1[i];
               rv1[i] = c*rv1[i];
               if (fabsl(f) <= __LDBL_EPSILON__*anorm)
                  break;

               g = S[i];
               h = pythl(f, g);
               S[i] = h;
               h = 1.0L/h;
               c = g*h;
               s = -f*h;
               for (j= 0; j < m; j++)
               {
                  y = U[j][nm];
                  z = U[j][i];
                  U[j][nm] = y*c + z*s;
                  U[j][i]  = z*c - y*s;
               }
            }
         }

         z = S[k];
         if (l == k)       // Convergence.
         {
            if (z < 0.0L)  // Singular value is made nonnegative.
            {
               S[k] = -z;
               for (j = 0; j < n; j++)
                  V[j][k] = -V[j][k];
            }
            break;
         }

         if (its == 29)
            return false;  // No convergence, give up

         x  = S[l];        // Shift from bottom 2-by-2 minor.
         nm = k-1;
         y  = S[nm];
         g  = rv1[nm];
         h  = rv1[k];
         f  = ((y - z)*(y + z) + (g - h)*(g + h))/(2.0L*h*y);
         g  = pythl(f, 1.0L);
         f  = ((x - z)*(x + z) + h*((y/(f + sgncpyl(g, f))) - h))/x;

         c = s = 1.0L;     // Next QR transformation:
         for (j = l; j <= nm; j++)
         {
            i = j+1;
            g = rv1[i];
            y = S[i];
            h = s*g;
            g = c*g;
            z = pythl(f, h);
            rv1[j] = z;
            c =f/z;
            s =h/z;
            f = x*c + g*s;
            g = g*c - x*s;
            h = y*s;
            y *= c;
            for (jj = 0; jj < n; jj++)
            {
               x = V[jj][j];
               z = V[jj][i];
               V[jj][j] = x*c + z*s;
               V[jj][i] = z*c - x*s;
            }
            z = pythl(f, h);
            S[j] = z;
            if (z != 0.0L) // Rotation can be arbitrary if z = 0.
            {
               z = 1.0L/z;
               c = f*z;
               s = h*z;
            }
            f = c*g + s*y;
            x = c*y - s*g;
            for (jj = 0; jj < m; jj++)
            {
               y = U[jj][j];
               z = U[jj][i];
               U[jj][j] = y*c + z*s;
               U[jj][i] = z*c - y*s;
            }
         }
         rv1[l] = 0.0L;
         rv1[k] = f;
         S[k] = x;
      }
   }

   return true;
}

static void svs(int m, int n, Matrix U, Matrix V, Vector S)
{  // Singular Value Sort
   // Given the output of svd(), this routine sorts the singular values S, and corresponding columns
   // of U and V, by decreasing magnitude. Also, signs of corresponding columns are flipped so as to
   // maximize the number of positive elements.

   int         i, j, k, s, inc = 1;
   long double ss;
   long double su[m], sv[n];

   // Shells sort. The work is negligible as compared to that already done in decompose.
   do { inc *= 3; inc++; } while (inc <= n);
   do
   {
      inc /= 3;
      for (i=inc; i < n; i++)
      {
         ss = S[i];
         for (k = 0; k < m; k++)
            su[k] = U[k][i];
         for (k = 0; k < n; k++)
            sv[k] = V[k][i];
         j = i;
         while (S[j-inc] < ss)
         {
            S[j] = S[j-inc];
            for (k = 0; k < m; k++)
               U[k][j] = U[k][j-inc];
            for (k = 0; k < n; k++)
               V[k][j] = V[k][j-inc];
            j -= inc;
            if (j < inc)
               break;
         }
         S[j] = ss;
         for (k = 0; k < m; k++)
            U[k][j] = su[k];
         for (k = 0; k < n; k++)
            V[k][j] = sv[k];
      }
   } while (inc > 1);

   for (k = 0; k < n; k++) // Flip signs.
   {
      s = 0;
      for (i = 0; i < m; i++)
         if (U[i][k] < 0.0L)
            s++;
      for (j = 0; j < n; j++)
         if (V[j][k] < 0.0L)
            s++;
      if (s > (m+n)/2)
      {
         for (i = 0; i < m; i++)
            U[i][k] = -U[i][k];
         for (j = 0; j < n; j++)
            V[j][k] = -V[j][k];
      }
   }
}

static void m_T(int m, int n, Matrix M, Matrix T)
{  // performs T[n][m] = (M[m][n])^T
   int i, j;

   for (i = 0; i < m; i++)
      for (j = 0; j < n; j++)
         T[j][i] = M[i][j];
}

static boolean m_x_v(int m, int n, Matrix M, Vector B, Vector X)
{  // performs X[m] = M[m][n]·B[n];
   int     i, j;
   boolean replace = (B == X);

   if (replace)
   {
      if (m == n)
         X = allocate(m*sizeof(long double), default_align, true);
      else
         return false;     // Invalid matrix/vector dimensions for in place mat*vec multiplication.
   }
   else
      for (i = 0; i < m; i++)
         X[i] = 0;

   for (i = 0; i < m; i++)
      for (j = 0; j < n; j++)
         X[i] += M[i][j]*B[j];

   if (replace)
   {
      for (i = 0; i < m; i++)
         B[i] = X[i];
      deallocate(VPR(X), false);
   }

   return true;
}

static boolean m_x_m(int m, int l, int n, Matrix A, Matrix B, Matrix C)
{  // performs C[m][n] = A[m][l]·B[l][n]
   int     i, j, k;
   boolean replaceA = (A == C);
   boolean replaceB = (B == C);

   if (replaceA || replaceB)
   {
      C = allocate(m*sizeof(Vector), default_align, true);
      for (i = 0; i < m; i++)
         C[i] = allocate(n*sizeof(long double), default_align, true);
   }

   else
      for (i = 0; i < m; i++)
         for (k = 0; k < n; k++)
            C[i][k] = 0.0L;

   for (i = 0; i < m; i++)
      for (j = 0; j < l; j++)
         for (k = 0; k < n; k++)
            C[i][k] += A[i][j]*B[j][k];

   if (replaceA || replaceB)
   {
      if (replaceB)
         A = B;
      for (i = 0; i < m; i++)
      {
         for (k = 0; k < n; k++)
            A[i][k] = C[i][k];
         deallocate(VPR(C[i]), false);
      }
      deallocate(VPR(C), false);
   }

   return true;
}

static void m_x_d(int m, int n, Matrix A, Vector D, Matrix C)
{  // performs C[m][n] = A[m][n]*diag(D[n])
   int i, j;
   for (i = 0; i < m; i++)
      for (j = 0; j < n; j++)
         C[i][j] = A[i][j]*D[j];
}

static boolean d_i(int n, Vector D, Vector iD, long double *thresh, int *rank, int *nullity)
{  // performs iD[n] = 1/D[n], and
   // computes the reverse condition number
   // computes the threshhold below which elements are considered numerically zero
   int         j, rnk = 0, nlt = 0;
   long double dj, dmin, dmax;

   dmin = dmax = D[0];
   for (j = 1; j < n; j++)
   {
      dj = D[j];
      if (dj < dmin)
         dmin = dj;
      else if (dj > dmax)
         dmax = dj;
   }

   *thresh = 0.5L*sqrtl(n+n+1.0L)*dmax*__LDBL_EPSILON__;

   for (j = 0; j < n; j++)
   {
      if (fabsl(D[j]) > *thresh)
         iD[j] = 1.0L/D[j], rnk++;
      else
         iD[j] = 0.0L, nlt++;
   }

   if (rank)    *rank    = rnk;
   if (nullity) *nullity = nlt;

   long double rcond = dmin/dmax;
   return !isnan(rcond) && fabsl(rcond) > __LDBL_EPSILON__;
}


#pragma mark ••• LU Decomposition •••

static long double LUdcmp(int m, Matrix A, Matrix LU, Index idx)
{
   int         i, j, k, imax = 0;
   long double max, sum, dum, d;
   Vector      V = allocate(m*sizeof(long double), default_align, true);

   if (LU != A)
      for (i = 0; i < m; i++)
         for (j = 0; j < m; j++)
            LU[i][j] = A[i][j];

   for (i = 0; i < m; i++)
   {
      max = 0.0L;
      for (j = 0; j < m; j++)
         if ((dum = fabsl(LU[i][j])) > max)
            max = dum;

      if (max != 0.0L)
         V[i] = 1.0L/max;
      else
      {
         deallocate(VPR(V), false);
         return __builtin_nanl("0");
      }
   }

   d = 1.0L;
   for (j = 0; j < m; j++)
   {
      for (i = 0; i < j; i++)
      {
         sum = LU[i][j];
         for (k = 0; k < i; k++)
            sum -= LU[i][k]*LU[k][j];
         LU[i][j] = sum;
      }

      max = 0.0L;
      for (; i < m; i++)
      {
         sum = LU[i][j];
         for (k = 0; k < j; k++)
            sum -= LU[i][k]*LU[k][j];
         LU[i][j] = sum;

         if ((dum = V[i]*fabsl(sum)) >= max)
         {
            max = dum;
            imax = i;
         }
      }

      if (j != imax)
      {
         for (k = 0; k < m; k++)
         {
            dum = LU[imax][k];
            LU[imax][k] = LU[j][k];
            LU[j][k] = dum;
         }
         V[imax] = V[j];
         d = -d;
      }

      if (idx)
         idx[j] = imax;

      if (LU[j][j] == 0.0L)
         LU[j][j] = __LDBL_EPSILON__;

      if (j < m-1)
      {
         dum = 1.0L/LU[j][j];
         for (i = j+1; i < m; i++)
            LU[i][j] *= dum;
      }
   }

   deallocate(VPR(V), false);
   return d;
}


static void LUbksb(int m, Matrix LU, Index idx, Vector B, Vector X)
{
   int         i, j, k, l = -1;
   long double sum;

   if (X != B)
      for (i = 0; i < m; i++)
         X[i] = B[i];

   for (i = 0; i < m; i++)
   {
      k = idx[i];
      sum = X[k];
      X[k] = X[i];
      if (l >= 0)
         for (j = l; j <= i-1; j++)
            sum -= LU[i][j]*X[j];
      else if (sum != 0)
         l = i;
      X[i] = sum;
   }

   for (i = m-1; i >= 0; i--)
   {
      sum = X[i];
      for (j = i+1; j < m; j++)
         sum -= LU[i][j]*X[j];
      X[i] = sum/LU[i][i];
   }
}


static void LUimpr(int m, Matrix A, Matrix LU, Index idx, Vector B, Vector X) __attribute__((unused));
static void LUimpr(int m, Matrix A, Matrix LU, Index idx, Vector B, Vector X)
{
   int         i, j;
   long double sdp;
   Vector      R = allocate(m*sizeof(long double), default_align, true);

   for (i = 0; i < m; i++)
   {
      sdp = -B[i];
      for (j = 0; j < m; j++)
         sdp += A[i][j]*X[j];
      R[i] = sdp;
   }
   LUbksb(m, LU, idx, R, R);

   for (i = 0; i < m; i++)
      X[i] -= R[i];

   deallocate(VPR(R), false);
}


static void LUInvr(int m, Matrix A, Matrix LU, Index idx) __attribute__((unused));
static void LUInvr(int m, Matrix A, Matrix LU, Index idx)
{
   int     i, j;
   Matrix  Ai = allocate(m*sizeof(long double*), default_align, true);
   for (j = 0; j < m; j++)
      Ai[j] = allocate(m*sizeof(long double), default_align, true);

   for (i = 0; i < m; i++)
      Ai[i][i] = 1.0L;

   for (j = 0; j < m; j++)
      LUbksb(m, LU, idx, Ai[j], Ai[j]);

   for (i = 0; i < m; i++)
      for (j = 0; j < m; j++)
         A[i][j] = Ai[i][j];

   for (j = 0; j < m; j++)
      deallocate(VPR(Ai[j]), false);
   deallocate(VPR(Ai), false);
}


#pragma mark ••• Implementation of Missing Functions in FreeBSD •••

#ifdef __FreeBSD__
   #if defined(__i386__) || defined(__x86_64__)

      #define SET_INVALID_FLAG() { __m128d __x = _mm_setzero_pd(); __asm__ __volatile__( "pcmpeqd %0, %0 \n\t cmpltsd %0, %0" : "+x" (__x) ); }

      long double _powl(long double x, long double y)
      {
         // if x = 1, return x for any y, even NaN
         if (x == 1.0L)
            return x;
         
         // if y = 0, return 1 for any x, even NaN
         if (y == 0.0L)
            return 1.0L;

         // get NaNs out of the way
         if (x != x  || y != y)
            return x + y;
         
         // do the work required to sort out edge cases
         long double fabsy = __builtin_fabsl(y);
         long double fabsx = __builtin_fabsl(x);
         long double iy = __builtin_nearbyintl(fabsy);            // we do round to nearest here so that |fy| <= 0.5
         if (iy > fabsy)                                          // convert nearbyint to floor
            iy -= 1.0L;

         int isOddInt = 0;
         if (fabsy == iy && fabsy != __builtin_infl() && iy < 0x1.0p63L)
            isOddInt = iy - 2.0L*__builtin_nearbyintl(0.5L*iy);   // might be 0, -1, or 1

         // test a few more edge cases, deal with x = 0 cases
         if (x == 0.0L)
         {
            if (!isOddInt)
               x = 0.0L;

            if (y < 0.0L)
               x = 1.0L/x;

            return x;
         }

         // x = +/-Inf cases
         if (fabsx == __builtin_infl())
         {
            if (x < 0.0L)
               if (isOddInt)
                  if (y < 0.0L)
                     return -0.0L;
                  else
                     return -__builtin_infl();

               else
                  if (y < 0.0L)
                     return 0.0L;
                  else
                     return __builtin_infl();

            if (y < 0.0L)
               return 0.0L;

            return __builtin_infl();
         }

         // y = +/-inf cases
         if (fabsy == __builtin_infl())
         {
            if (x == -1.0L)
               return 1.0L;

            if (y < 0.0L)
            {
               if (fabsx < 1.0L)
                  return __builtin_infl();

               return 0.0L;
            }

            if (fabsx < 1.0L)
               return 0.0L;

            return __builtin_infl();
         }

         // x < 0 and y non integer case
         if (x < 0.0L && iy != fabsy)
         {
            SET_INVALID_FLAG();
            return __builtin_nanl("37");
         }
         
         // speedy resolution of sqrt and reciprocal sqrt
         if (fabsy == 0.5L)
         {
            x = sqrtl(x);
            if (y < 0.0L)
               x = 1.0L/x;
            return x;
         }

         // enter the main power function. This is done by splitting up x**y:
         //   x**y = x**(i+f)     -- where i = integer part of y, f = positive fractional part
         //        = x**f * x**i
         long double fy = fabsy - iy;
         long double fx = 1.0L;
         long double ix = 1.0L;

         // Calculate fx = x**f
         if (fy != 0.0L)      // this is expensive and may set unwanted flags. skip if unneeded
         {
            fx =log2l(x);
            long double fabsfx = __builtin_fabsl(fx);
            long double min = __builtin_fminl(fy, fabsfx);
            long double max = __builtin_fmaxl(fy, fabsfx);

            if (y < 0.0L)
               fy = -fy;

            // if fx*fy is a denormal, we get spurious underflow here, so try to avoid that
            if (min < 0x1.0p-8191L && max < 0x1.0p63L)   // a crude test for a denormal product
               fx = 1.0L;                                // for small numbers, skip straight to the result
            else                                         // safe to do the work
               fx = exp2l(fx*fy);
         }

         // Calculate ix = f**i
         // if y is negative, we will need to take the reciprocal eventually.
         // do it now to avoid underflow when we should get overflow,
         // but don't do it if iy is zero to avoid spurious overflow
         if (y < 0.0L && iy != 0)
            x = 1.0L/x;

         // calculate x**i by doing lots of multiplication
         while (iy != 0.0L)
         {
            long double ylo;

            // early exit for underflow and overflow. Otherwise we may end up looping up to 16383 times here.
            if (x == 0.0L || x == __builtin_infl())
            {
               ix *= x;    // we know this is the right thing to do, because iy != 0
               break;
            }

            // chop off 30 bits at a time
            if (iy > 0x1.0p30L)
            {
               long double scaled = iy*0x1.0p-30L;
               long double yhi = __builtin_nearbyintl(scaled);
               if (yhi > scaled)
                  yhi -= 1.0L;
               ylo = iy - 0x1.0p30L*yhi;
               iy = yhi;
            }

            else           // faster code for the common case
               ylo = iy, iy = 0;

            int j;
            int i = ylo;
            int mask = 1;
            // for each of the 30 bits set in i, multiply ix by x**(2**bit_position)
            if (i & 1)
               ix *= x, i -= mask;

            for (j = 0; j < 30 && i != 0; j++)
            {
               mask += mask;
               x *= x;
               if (i & mask)
                  ix *= x, i -= mask;
            }
            
            // we may have exited early from the loop above, if so, and there are still bits in iy finish out the multiplies.
            if (iy != 0.0L)
               for (; j < 30; j++)
                  x *= x;
         }

         return fx*ix;
      }


      long double _tgammal(long double x)
      {
         // Coefficients for P in gamma approximation over {1, 2} in decreasing order.
         static const long double P[8] = {-1.71618513886549492533811e+0L,
                                           2.47656508055759199108314e+1L,
                                          -3.79804256470945635097577e+2L,
                                           6.29331155312818442661052e+2L,
                                           8.66966202790413211295064e+2L,
                                          -3.14512729688483675254357e+4L,
                                          -3.61444134186911729807069e+4L,
                                           6.64561438202405440627855e+4L};

         // Coefficients for Q in gamma approximation over {1, 2} in decreasing order.
         static const long double Q[8] = {-3.08402300119738975254353e+1L,
                                           3.15350626979604161529144e+2L,
                                          -1.01515636749021914166146e+3L,
                                          -3.10777167157231109440444e+3L,
                                           2.25381184209801510330112e+4L,
                                           4.75584627752788110767815e+3L,
                                          -1.34659959864969306392456e+5L,
                                          -1.15132259675553483497211e+5L};

         // Coefficients for Stirling's Approximation to ln(Gamma) on {12, inf}
         static const long double C[7] = { 0xa.aaaaaaaaaaaaaabp-7L,
                                          -0xb.60b60b60b60b60bp-12L,
                                           0xd.00d00d00d00d00dp-14L,
                                          -0x9.c09c09c09c09c0ap-14L,
                                           0xd.ca8f158c7f91ab8p-14L,
                                          -0xf.b5586ccc9e3e41p-13L,
                                           0xd.20d20d20d20d20dp-11L};

         static const long double lnSqrt2pi = 0.9189385332046727417803297e+0L;  // ln(sqrt(2*pi))
         static const long double pi        = 3.1415926535897932384626434e+0L;  // pi
         static const long double xbig      = 0xd.b718c066b352e21p+7L;          // cutoff for overflow condition = 1755.54...
         static const long double minX      = 1.0022L*__LDBL_MIN__;
         static const long double eps       = 0.9998L*__LDBL_EPSILON__;

         // The next switch will decipher what sort of argument we have. If argument
         // is SNaN then a QNaN has to be returned and the invalid flag signaled.
         if (x != x)
            return x + x;                    // silence NaN

         if (x == 0.0L)
            return lnSqrt2pi/x;

         if (__builtin_fabsl(x) == __builtin_infl())
         {
            if (x < 0.0L)
            {
               SET_INVALID_FLAG();
               return __builtin_nanl("42");  // GAMMA_NAN = "42"
            }

            return x;
         }

         int i, n = 0, par = 0;
         long double f = 1.0L, y = x,
                     y1, z, fract, numer, denom, ysqr, sum, result;

         // The argument is negative.
         if  (y <= 0.0L)
         {
            y = -x;
            if (y < minX)
               return 1.0L/x;

            y1 = truncl(y);
            fract = y - y1;
            if (fract != 0.0L)               // is it an integer?
            {                                // is it odd or even?
               if (y1 != truncl(y1*0.5L)*2.0L)
                  par = 1;
               f = -pi/sinl(pi*fract);
               y += 1.0L;
            }

            else
            {
               SET_INVALID_FLAG();
               return __builtin_nanl("42");  // GAMMA_NAN = "42"
            }
         }

         // The argument is positive.
         if (y < eps)                        // argument is less than epsilon.
            result = 1.0L/y;

         else if (y < 12.0L)                 // argument is in eps < x < 12.
         {
            y1 = y;
            if (y < 1.0L)                    // argument is in {eps, 1}.
               z = y, y += 1.0L;
            else                             // argument is in {1, 12}.
               n = (int)y - 1, y -= (long double)n, z = y - 1.0L;

            for (numer = 0.0L, denom = 1.0L, i = 0; i < 8; i++)
               numer = (numer + P[i])*z, denom = denom*z + Q[i];
            result = numer/denom + 1.0L;

            if (y1 < y)
               result /= y1;

            else if (y1 > y)
               for (i = 0; i < n; i++)
                  result *= y, y += 1.0L;
         }

         else
         {
            if (x <= xbig)
            {
               ysqr = sqrl(y);
               sum = C[6];
               for (i = 5; i >= 0; i--)
                  sum = sum/ysqr + C[i];
               sum = sum/y - y + lnSqrt2pi;
               sum += (y - 0.5L)*logl(y);
               result = expl(sum);
            }
            else
               return x*0x1.0p16383L;        // set overflow, return inf
         }

         if (par)
            result = -result;

         if (f != 1.0L)
            result = f/result;

         return result;
      }


      static long double coshmull(long double x, long double y)
      {
         // y*cosh(x)
         long double ax = __builtin_fabsl(x);

         if (ax <= 11356.5L)                                // cosh(x) is finite?
            return y*coshl(x);

         else if (__fpclassifyl(x) < FP_ZERO)               // x is NaN or infinite?
            return y*ax;

         else if (ax > 22713.0L)                            // probable overflow case?
            return y*__builtin_infl();                      // at least preserve the sign

         else                                               // cosh(x) overflows but y*cosh(x) may not
         {
            long double r = y*5.81103831035141751e+4931L;   // initialize result to y*cosh(11356.5)

            // exponential reduction loop
            for (ax -= 11356.5L; ax > 11356.5L; ax -= 11356.5L)
               r *= 5.81103831035141751e+4931L;
            return r*expl(ax);                              // final multiplication
         }
      }

      static long double sinhmull(long double x, long double y)
      {
         // y*sinh(x)
         long double ax = __builtin_fabsl(x);

         if (ax <= 11356.5L)                                // sinh(x) is finite?
            return y*sinhl(x);

         else if (__fpclassifyl(x) < FP_ZERO)               // x is NaN or infinite?
            return y*x;

         else if (ax > 22713.0L)                            // probable overflow case?
            return y*x*__builtin_infl();                    // at least preserve the sign

         else                                               // sinh(x) overflows but y*sinh(x) may not
         {
            long double r = y*5.81103831035141751e+4931L;   // initialize result to y*sinh(11356.5)

            // exponential reduction loop
            for (ax -= 11356.5L; ax > 11356.5L; ax -= 11356.5L)
               r *= 5.81103831035141751e+4931L;
            r *= expl(ax);                                  // final multiplication

            return (__builtin_signbitl(x)) ? r : -r;        // take care of sign of result
         }
      }


      #define re(z) (__real__ z)
      #define im(z) (__imag__ z)

      static long double cssqsl(long double complex z, int *k)
      {
         // r = |z/(2^*k)|^2 -- with scale factor *k set to avoid overflow/underflow
         long double a = __builtin_fabsl(re(z)),
                     b = __builtin_fabsl(im(z));

         int fpclass_a = __fpclassifyl(a),
             fpclass_b = __fpclassifyl(b);

         if (fpclass_a < FP_ZERO || fpclass_b < FP_ZERO)
         {
            *k = 0x7FFFFFFF;
            if (fpclass_a == FP_NAN || fpclass_b == FP_NAN)
            {
               SET_INVALID_FLAG();
               return __builtin_nanl("0");
            }
            else
               return __builtin_infl();
         }

         int    e;                              // scaling exponent
         fenv_t env;
         feholdexcept(&env);
         long double r = sqrl(a) + sqrl(b);
         if (fetestexcept(FE_OVERFLOW) || fetestexcept(FE_UNDERFLOW) && r < 0x8p-16322L)
         {
            e = logbl(__builtin_fmaxl(a, b));   // scaling necessary
            a = scalbnl(a, -e);
            b = scalbnl(b, -e);
            r = sqrl(a) + sqrl(b);              // re-calculate scaled square magnitude
         }
         else
            e = 0;

         feclearexcept(FE_OVERFLOW + FE_UNDERFLOW);
         feupdateenv(&env);                     // restore environment

         *k = e;
         return r;
      }

      long double complex cpowl(long double complex x, long double complex y)
      {
         // x^y = cexp(y*clog(x))
         long double complex lx = clogl(x);
         return cexpl((long double complex){re(y)*re(lx) - im(y)*im(lx), re(y)*im(lx) + im(y)*re(lx)});
      }

      long double complex csinl(long double complex z)
      {
         // csin(re + i*im) = cosh(im)*sin(re) + i*sinh(im)*cos(re)
         return (long double complex){coshmull(im(z), sinl(re(z))), sinhmull(im(z), cosl(re(z)))};
      }

      long double complex casinl(long double complex z)
      {
         // casin(re + i*im) = atan(re/re(csqrt(1 + z)*csqrt(1 - z)))
         //                  + i*arcsinh(im(csqrt(1 + z)*csqrt(1 - cconj(z))))
         long double complex zp1 = csqrtl((long double complex){1.0L + re(z),  im(z)}),   // zp1 = csqrt(1 + z)
                             zm1 = csqrtl((long double complex){1.0L - re(z), -im(z)}),   // zm1 = csqrt(1 - z)
                             zcm = csqrtl((long double complex){1.0L - re(z),  im(z)});   // zc1 = csqrt(1 - cconj(z))
         return (long double complex){atanl(re(z)/(re(zp1)*re(zm1) - im(zp1)*im(zm1))), asinhl(re(zp1)*im(zcm) + im(zp1)*re(zcm))};
      }

      long double complex ccosl(long double complex z)
      {
         // ccos(re + i*im) = cosh(im)*cos(re) - i*sinh(im)*sin(re)
         return (long double complex){coshmull(im(z), cosl(re(z))), -sinhmull(im(z), sinl(re(z)))};
      }

      long double complex cacosl(long double complex z)
      {
         // cacos(re + i*im) =    2*atan(re(csqrt(1 - z)/re(csqrt(1 + z))))
         //                  + i*arcsinh(im(csqrt(1 - z)*csqrt(cconj(1 + z))))
         long double complex zp1 = csqrtl((long double complex){1.0L + re(z),  im(z)}),   // zp1 = csqrt(1 + z)
                             zm1 = csqrtl((long double complex){1.0L - re(z), -im(z)}),   // zm1 = csqrt(1 - z)
                             zcp = csqrtl((long double complex){1.0L + re(z), -im(z)});   // zcp = csqrt(cconj(1 + z))
         return (long double complex){2.0L*atanl(re(zm1)/re(zp1)), asinhl(re(zcp)*im(zm1) + im(zcp)*re(zm1))};
      }

      long double complex ctanl(long double complex z)
      {
         // ctan(re + i*im) = (sin(2*re) + i*sinh(2*im))/(cos(2*re) + cosh(2*im))
         //                 = (tan(re)+i*cosh(im)*sinh(im)*cscsq)/(1+cscsq*sinh(im)*sinh(im))
         fenv_t env;
         long double tanval, beta, sinhval, coshval, denom;
         long double complex w;

         feholdexcept(&env);                                               // save environment and clear flags

         if (__builtin_fabsl(im(z)) > 0xb.174ddc031aec0eap+8)              // avoid overflow for large |im(z)| -- asinhl(nextafterl(__builtin_infl(), 0.0L))/4.0L;
         {
            re(w) = __builtin_copysignl(0.0L, re(z));                      // real result is signed zero
            im(w) = __builtin_copysignl(1.0L, im(z));                      // imaginary result has unit magnitude
            if (__builtin_fabsl(im(z)) != __builtin_infl())                // set inexact for finite im(z)
               feraiseexcept(FE_INEXACT);
            feupdateenv(&env);                                             // update environment
         }                                                                 // end large |im(z)| case

         else                                                              // usual case
         {
            tanval = tanl(re(z));                                          // evaluate tangent
            feclearexcept(FE_DIVBYZERO);                                   // in case tangent is infinite
            feupdateenv(&env);                                             // update environment
            beta = 1.0L + sqrl(tanval);                                    // 1/(cos(re(z)))^2
            sinhval = sinhl(im(z));                                        // evaluate sinh
            coshval = sqrtl(1.0L + sqrl(sinhval));                         // evaluate cosh

            if (__builtin_fabsl(tanval) == __builtin_infl())               // infinite tangent
            {
               re(w) = 1.0L/tanval;
               im(w) = coshval/sinhval;
            }

            else                                                           // finite tangent
            {
               denom = 1.0L + beta*sqrl(sinhval);
               re(w) = tanval/denom;
               im(w) = beta*coshval*sinhval/denom;
            }
         }                                                                 // end usual case

         return w;
      }

      long double complex catanl(long double complex z)
      {
         // catan(z) = i*(clog(1 - i*z) - clog(1 + i*z))/2
         long double complex rz, w;
         long double t1, t2, zi, eta, beta;

         zi   = -im(z);
         beta = __builtin_copysignl(1.0L, zi);                             // copes with unsigned zero

         im(z) = -beta*re(z);                                              // transform real & imag components
         re(z) =  beta*zi;

         if (re(z) > 0x8p+8187L || __builtin_fabsl(im(z)) > 0x8p+8187L)    // 0x8p+8187L = sqrtl(nextafterl(__builtin_infl(), 0.0L))/4.0L
         {                                                                 // avoid spurious overflow
            zi  = __builtin_copysignl(1.57079632679489661923132169163975144L, im(z));
            rz  = 1.0L/z;
            eta = re(rz);
         }

         else if (re(z) == 1.0L)
         {
            t1  = sqrl(__builtin_fabsl(im(z)) + 0x8p-8193L);               // 0x8p-8193L = 4.0L/sqrtl(nextafterl(__builtin_infl(), 0.0L))
            zi  = logl(sqrtl(sqrtl(4.0L + t1))/sqrtl(__builtin_fabsl(im(z))));
            eta = 0.5L*__builtin_copysignl(3.14159265358979323846264338327950288L - atanl(2.0L/(__builtin_fabsl(im(z))+0x8p-8193L)), im(z));
         }

         else                                                              // usual case
         {
            t1  = sqrl(1.0L - re(z));
            t2  = sqrl(__builtin_fabsl(im(z)) + 0x8p-8193L);
            zi  = 0.25L*log1pl(4.0L*re(z)/(t1 + t2));
            re(rz) = (1.0L - re(z))*(1.0L + re(z)) - t2;
            im(rz) = im(z) + im(z);
            eta = 0.5L*cargl(rz);
         }

         re(w) = -beta*eta;                                                // fix up signs of result
         im(w) = -beta*zi;
         return w;
      }

      long double complex cexpl(long double complex z)
      {
         // cexp(re + i*im) = exp(re)*cos(im) + i*exp(re)*sin(im)
         long double rez  = re(z),
                     cosi = cosl(im(z)),
                     sini = sinl(im(z));

         if (rez <= 11356.5L)                                              // exp(re(z)) is finite?
         {
            long double ere = expl(rez);
            return (long double complex){ere*cosi, ere*sini};
         }

         else if (fpclassify(rez) < FP_ZERO)                               // re(z) is +INF or a NaN
            return (long double complex){rez*cosi, rez*sini};              // deserved invalid may occur

         else if (rez > 22713.0L)                                          // probable overflow case?
            return (long double complex){__builtin_infl()*cosi, __builtin_infl()*sini};

         else                                                              // exp(re(z)) overflows but product with sin or cos may not
         {                                                                 // initialze complex result with exp(11356.5) = 1.16220766207028328e+4932L
            long double complex w = {1.16220766207028328e+4932L*cosi, 1.16220766207028328e+4932L*sini};
            for (rez -= 11356.5L; rez > 11356.5L; rez -= 11356.5L)
               w *= 1.16220766207028328e+4932L;
            return w*expl(rez);
         }
      }

      long double complex clogl(long double complex z)
      {
         long double complex w;
         long double dmax = __builtin_fabsl(re(z)),                        // order real and imaginary parts of z by magnitude
                     dmin = __builtin_fabsl(im(z)),
                     temp;

         if (dmax < dmin)
            temp = dmax, dmax = dmin, dmin = temp;

         int k;
         long double r = cssqsl(z, &k);                                    // scaled |z*z|
         if (k == 0x7FFFFFFF)
            return (long double complex){r, r};                            // either +inf or NaN

         if (k == 0
          && dmax > 0.707106781186547524400844362104849039L                // 1/sqrt(2)
          && (dmax <= 1.25L || r < 3.0L))
            re(w) = log1pl((dmax - 1.0L)*(dmax + 1.0L) + dmin*dmin)*0.5L;  // |z| near 1.0
         else
            re(w) = logl(r)*0.5L                                           // more naive approximation
                  + k*0.693147180559945309417232121458176568L;             // ln(2)
         im(w) = cargl(z);                                                 // imaginary part of logarithm

         return w;
      }

      long double complex csinhl(long double complex z)
      {
         // csinh(re + i*im) = sinh(re)*cos(im) + i*cosh(re)*sin(im)
         return (long double complex){sinhmull(re(z), cosl(im(z))), coshmull(re(z), sinl(im(z)))};
      }

      long double complex casinhl(long double complex z)
      {
         // casinh(z) = -i*casin(i*z)
         //
         //           = -i*(atan(-im(z)/re(csqrt(1 + i*z)*csqrt(1 - i*z)))
         //                 + i*arcsinh(im(csqrt(1 + i*z)*csqrt(1 - cconj(i*z)))))
         //
         //           = arcsinh(im(csqrt(1 + i*z)*csqrt(1 - cconj(i*z))))
         //           + atan(im(z)/re(csqrt(1 + i*z)*csqrt(1 - i*z)))
         long double complex zp1 = csqrtl((long double complex){1.0L - im(z),  re(z)}),   // zp1 = csqrt(1 + i*z)
                             zm1 = csqrtl((long double complex){1.0L + im(z), -re(z)}),   // zm1 = csqrt(1 - i*z)
                             zcm = csqrtl((long double complex){1.0L + im(z),  re(z)});   // zc1 = csqrt(1 - cconj(i*z))
         return (long double complex){asinhl(re(zp1)*im(zcm) + im(zp1)*re(zcm)), atanl(im(z)/(re(zp1)*re(zm1) - im(zp1)*im(zm1)))};
      }

      long double complex ccoshl(long double complex z)
      {
         // cosh(re + i*im) = cosh(re)*cos(im) + i*sinh(re)*sin(im)
         return (long double complex){coshmull(re(z), cosl(im(z))), sinhmull(re(z), sinl(im(z)))};
      }

      long double complex cacoshl(long double complex z)
      {
         // cacosh(re + i*im)) =  arcsinh(re(csqrt(z + 1)*csqrt(cconj(z) - 1)))
         //                    + i*2*atan(im(csqrt(z - 1)/re(csqrt(z + 1))))
         long double complex zp1 = csqrtl((long double complex){re(z) + 1.0L,  im(z)}),   // zp1 = csqrt(z + 1)
                             zm1 = csqrtl((long double complex){re(z) - 1.0L,  im(z)}),   // zm1 = csqrt(z - 1)
                             zcm = csqrtl((long double complex){re(z) - 1.0L, -im(z)});   // zcp = csqrt(cconj(z) - 1)
         return (long double complex){asinhl(re(zp1)*re(zcm) - im(zp1)*im(zcm)), 2.0L*atanl(im(zm1)/re(zp1))};
      }

      long double complex ctanhl(long double complex z)
      {
         // tanh(re + i*im) = (sinh(2*re) + i*sin(2*im))/(cosh(2*re) + cos(2*re))
         //                 = (cosh(re)*sinh(re)*cscsq + i*tan(im))/(1+cscsq*sinh(re)*sinh(re))
         fenv_t env;
         long double tanval, beta, sinhval, coshval, denom;
         long double complex w;

         feholdexcept(&env);                                               // save environment and clear flags

         if (__builtin_fabsl(re(z)) > 0xb.174ddc031aec0eap+8)              // avoid overflow for large |re(z)| -- asinhl(nextafterl(__builtin_infl(), 0.0L))/4.0L;
         {
            re(w) = __builtin_copysignl(1.0L, re(z));                      // real result has unit magnitude
            im(w) = __builtin_copysignl(0.0L, im(z));                      // imag result is signed zero
            if (__builtin_fabsl(re(z)) != __builtin_infl())                // set inexact for finite re(z)
               feraiseexcept(FE_INEXACT);
            feupdateenv(&env);                                             // update environment
         }                                                                 // end large |re(z)| case

         else                                                              // usual case
         {
            tanval = tanl(im(z));                                          // evaluate tangent
            feclearexcept(FE_DIVBYZERO);                                   // in case tangent is infinite
            feupdateenv(&env);                                             // update environment
            beta = 1.0L + sqrl(tanval);                                    // 1/(cos(im(z)))^2
            sinhval = sinhl(re(z));                                        // evaluate sinh
            coshval = sqrtl(1.0L+sinhval*sinhval);                         // evaluate cosh

            if (__builtin_fabsl(tanval) == __builtin_infl())               // infinite tangent
            {
               re(w) = coshval/sinhval;
               im(w) = 1.0L/tanval;
            }

            else                                                           // finite tangent
            {
               denom = 1.0L + beta*sqrl(sinhval);
               re(w) = beta*coshval*sinhval/denom;
               im(w) = tanval/denom;
            }
         }                                                                 // end usual case

         return w;
      }

      long double complex catanhl(long double complex z)
      {
         // catanh(z) = (clog(1 + z) - clog(1 - z))/2
         long double complex rz, w;
         long double t1, t2, zi, eta, beta;
         
         beta = __builtin_copysignl(1.0L, re(z));                          // copes with unsigned zero
         
         im(z) = -beta*im(z);                                              // transform real & imag components
         re(z) = beta*re(z);
         
         if (re(z) > 0x8p+8187L || __builtin_fabsl(im(z)) > 0x8p+8187L)    // 0x8p+8187L = sqrtl(nextafterl(__builtin_infl(), 0.0L))/4.0L
         {                                                                 // avoid overflow
            eta = __builtin_copysignl(1.57079632679489661923132169163975144L,im(z));
            rz = 1.0L/z;
            zi = re(rz);
         }
            
         else if (re(z) == 1.0L)
         {
            t1 = __builtin_fabsl(im(z)) + 0x8p-8193L;
            zi = logl(sqrtl(sqrtl(4.0L + t1*t1))/sqrtl(__builtin_fabsl(im(z))));
            eta = 0.5L*__builtin_copysignl(3.14159265358979323846264338327950288L - atanl(2.0L/(__builtin_fabsl(im(z))+0x8p-8193L)), im(z));
         }
         
         else                                                              // usual case
         {
            t1 = sqrl(1.0L - re(z));
            t2 = sqrl(__builtin_fabsl(im(z)) + 0x8p-8193L);
            zi = 0.25L*log1pl(4.0L*re(z)/(t1 + t2));
            re(rz) = (1.0L - re(z))*(1.0L + re(z)) - t2;
            im(rz) = im(z) + im(z);
            eta = 0.5L*cargl(rz);
         }
         
         re(w) =  beta*zi;                                                 // fix up signs of result
         im(w) = -beta*eta;
         return w;
      }

   #endif
#endif

#pragma GCC visibility pop


#pragma mark ••• C wrapper for calculater methods •••

void releaseObject(opaque object)
{
   [(CyObject *)object release];
}

static Calculator *gSharedCalculator = NULL;

Calculator *sharedCalculator(void)
{
   if (!gSharedCalculator)
      gSharedCalculator = [Calculator new];
   return gSharedCalculator;
}

Calculator *clonedCalculator(void)
{
   return [gSharedCalculator copy];
}

void releaseCalculator(Calculator *calculator)
{
   if (calculator == gSharedCalculator)
      gSharedCalculator = NULL;
   [calculator release];
}

void insertExternInt(Calculator *calculator, const char *identifier,    int *extint)
{
   [calculator storeExternalVariable:identifier reference:extint of:rtInteger];
}

void insertExternDbl(Calculator *calculator, const char *identifier, double *extdbl)
{
   [calculator storeExternalVariable:identifier reference:extdbl of:rtReal];
}

void insertSeriesDbl(Calculator *calculator, const char *identifier, double *serdbl)
{
   [calculator storeSeriesVariable:identifier reference:serdbl of:rtReal];
}

CalcPrep prepareFunction(Calculator *calculator, const char *functStr)
{
   CalcPrep prep = {calculator, nil, NULL, {noError, 0, 0}};

   if (functStr && *functStr)
   {
      char    *fstr  = strcpy(fstr = allocate(strvlen(functStr)+1, default_align, false), functStr);
      TokenPtr token = prep.tokens = [calculator scan:fstr error:&prep.errRec];
      if (prep.errRec.flag <= noError)
         prep.func = [calculator parse:&token error:&prep.errRec];

      if (prep.errRec.flag > noError)
      {
         [calculator disposeTokens:prep.tokens];
         prep.tokens = NULL;
         prep.func  = nil;
      }

      deallocate(VPR(fstr), false);
   }

   return prep;
}

double evaluatePrepFunc(CalcObject *prepFunc, unsigned i, ErrorRecord *errRec)
{
   ResultType v, rt = [prepFunc evaluate:i];

   if (errRec)
      *errRec = rt.e;

reswitch:
   switch (rt.f)
   {
      default:
         return __builtin_nan("0");

     case rtNone:
         return __builtin_nan("255");

      case rtBoolean:
         return (rt.b) ? 1.0 : 0.0;

      case rtInteger:
         return rt.i;

      case rtReal:
         return (double)rt.r;

      case rtComplex:
         return (double)__real__ rt.z;

      case rtVector:
         v = rt, rt = rt.v[0], rt.v[0] = gNullResult;
         freeVector(&v);
         goto reswitch;
   }
}

void disposeCalcPrep(CalcPrep *prep)
{
   [prep->calc disposeTokens:prep->tokens];
   *prep = (CalcPrep){nil, nil, NULL, {noError, 0, 0}};
}

char *calculate(Calculator *calculator, const char *funcStr, unsigned idx)
{
   char *r, *s;
   strmlcpy(r = s = allocate(calcInOutSize, default_align, false), funcStr, calcInOutSize, NULL);
   ResultModifier rm = [calculator preProcess:&s];
   ResultType     rt = [calculator calculate:s index:idx];
   // return calculator postProcess:&rt modifier:rm resultBuffer:&r];
   //
   // uncomment the line above and comment out the lines below, for removing the copyright notice from the result string.
   //
   int rl = strvlen([calculator postProcess:&rt modifier:rm resultBuffer:&r]);
   strmlcpy(r+rl, "\n \n \n"
                  "Please note, the CyCalc Library is Open Source Software, but it is not free.\n \n"
                  "     Copyright © 2006-2018 Dr. Rolf Jansen. All rights reserved.\n \n"
                  "Please ask for a non-abusive commercial license -> cycalc(at)cyclaero.com.\n",
                  calcInOutSize-rl, NULL);
   return r;
}
