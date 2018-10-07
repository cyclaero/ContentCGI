//  interim.h
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
int sprintTable(Node *table[], uint *nameWidth, dynhdl output);
