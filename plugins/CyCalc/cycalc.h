//  cycalc.h
//  CyCalc Scientific Calculator Library
//
//  Created by Dr. Rolf Jansen on 2006-02-27.
//  Copyright © 2006-2018 Dr. Rolf Jansen. All rights reserved.

#warning: \
    IMPORTANT: The CyCalc Library is Open Soruce but it is NOT FREE. \
    Copyright © 2006-2018 Dr. Rolf Jansen. All rights reserved.

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


#if __PTR_WIDTH__ == 32
   #pragma pack(4)
#else
   #pragma pack(8)
#endif

#pragma mark ••• C wrapper for the calculater methods •••

// Global CyCalc Settings           Defaults
extern char    gDecSep;             // = ','
extern int     gSigDigits;          // = 10
extern int     gDecDigits;          // = 10
extern boolean gLazyPercentFlag;    // = true
extern boolean gAutoReal2CmplxFlag; // = true

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
   recursionError = 256,
} ErrorFlags;

typedef struct
{
   ErrorFlags flag;
   unsigned   begin, count;
} ErrorRecord;

typedef struct
{
   opaque      calc;
   opaque      func;
   opaque      tokens;
   ErrorRecord errRec;
} CalcPrep;

opaque sharedCalculator(void);
opaque clonedCalculator(void);
void releaseCalculator(opaque calculator);

void insertExternInt(opaque calculator, const char *identifier,    int *extint);
void insertExternDbl(opaque calculator, const char *identifier, double *extdbl);
void insertSeriesDbl(opaque calculator, const char *identifier, double *serdbl);

CalcPrep prepareFunction(opaque calculator, const char *funcStr);
double evaluatePrepFunc(opaque prepFunc, unsigned i, ErrorRecord *errRec);
void disposeCalcPrep(CalcPrep *prep);

char *calculate(opaque calculator, const char *funcStr, unsigned idx);

#pragma pack()
